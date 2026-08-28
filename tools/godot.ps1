<#
.SYNOPSIS
  Launches the real Godot mono executable, forwarding all arguments.

.DESCRIPTION
  The `godot` / `godot_console` commands on PATH are WinGet shims living in
  %LOCALAPPDATA%\Microsoft\WinGet\Links. Godot resolves its bundled GodotSharp\
  directory relative to the executable it was launched as, so through the shim it
  never finds the .NET API assemblies and dies with:

      ERROR: .NET: Assemblies not found (gd_mono.cpp:650)
      CrashHandlerException: Program crashed with signal 11

  Invoking the real executable inside the WinGet package directory avoids this.

  On a checkout that has never been imported (a fresh clone, or a new git
  worktree) this script first runs Godot's asset import step, because
  `.godot/imported/` is generated and therefore git-ignored. Without it,
  resources fail to load at runtime with errors such as
  "No loader found for resource: res://data/dialogue/outpost-nova.yarnproject"
  and dialogue silently never starts.

.PARAMETER Console
  Use the *_console.exe build (stdout/stderr attached) instead of the windowed one.

  Set $env:GODOT_SKIP_IMPORT to any non-empty value to suppress that.

  This opt-out is an environment variable rather than a script parameter on
  purpose. PowerShell binds unambiguous parameter-name abbreviations, so adding
  a `-SkipImport` switch would make a bare `-s` bind to it instead of being
  forwarded to Godot — silently breaking `-s addons/gut/gut_cmdln.gd`, which is
  how this repo runs its tests.

.EXAMPLE
  ./tools/godot.ps1 -Console --headless --editor --quit --path .
  ./tools/godot.ps1 --path .
  ./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
#>
[CmdletBinding()]
param(
    [switch]$Console,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GodotArgs
)

$ErrorActionPreference = 'Stop'

function Resolve-GodotExe {
    param([switch]$ConsoleBuild)

    # Allow an explicit override for non-WinGet installs.
    if ($env:GODOT_BIN -and (Test-Path $env:GODOT_BIN)) {
        return $env:GODOT_BIN
    }

    $packages = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    $pattern = if ($ConsoleBuild) { 'Godot_v*_mono_win64_console.exe' } else { 'Godot_v*_mono_win64.exe' }
    return Get-ChildItem -Path $packages -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}

function Get-ProjectDir {
    param([string[]]$Arguments)

    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        if ($Arguments[$i] -eq '--path' -and ($i + 1) -lt $Arguments.Count) {
            $resolved = Resolve-Path $Arguments[$i + 1] -ErrorAction SilentlyContinue
            if ($resolved) { return $resolved.Path }
            return $null
        }
    }
    return (Get-Location).Path
}

# Success is judged by parsing the import run's output, so it must use the
# console build: the windowed build detaches stdout and would report zero errors
# regardless of what actually happened.
# The YarnSpinner importer is written in C#, so the .NET assemblies must exist
# before the import runs. Without them the import still reports success, but
# quietly produces no usable YarnProject and dialogue never starts.
function Invoke-DotnetBuild {
    param([string]$ProjectDir)

    $csproj = Get-ChildItem -Path $ProjectDir -Filter '*.csproj' -File -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $csproj) { return }

    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
        Write-Warning '[godot.ps1] .NET assemblies are missing and dotnet was not found on PATH. C# code, including dialogue, will not work.'
        return
    }

    Write-Host '[godot.ps1] No .NET assemblies found - building C# first.'
    & dotnet build $csproj.FullName | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning '[godot.ps1] dotnet build failed. Continuing, but C# code will not work.'
    }
}

function Invoke-GodotImport {
    param([string]$ProjectDir)

    $importExe = Resolve-GodotExe -ConsoleBuild
    if (-not $importExe) { return }

    Write-Host '[godot.ps1] No import cache found - running Godot asset import.'
    Write-Host '[godot.ps1] Assets import in dependency order, so early passes report errors'
    Write-Host '[godot.ps1] for resources whose dependencies are not imported yet. Repeating'
    Write-Host '[godot.ps1] until a pass completes cleanly.'

    $maxPasses = 6
    for ($pass = 1; $pass -le $maxPasses; $pass++) {
        $output = & $importExe --headless --path $ProjectDir --import 2>&1
        $errorCount = @($output | Select-String -Pattern '^ERROR:').Count
        Write-Host "[godot.ps1]   pass ${pass}: $errorCount error(s)"
        if ($errorCount -eq 0) {
            Write-Host '[godot.ps1] Import complete.'
            return
        }
    }

    Write-Warning "[godot.ps1] Import still reporting errors after $maxPasses passes. Continuing anyway - see output above."
}

$exe = Resolve-GodotExe -ConsoleBuild:$Console

if (-not $exe) {
    throw "Could not locate a Godot mono executable. Set `$env:GODOT_BIN to its full path."
}

# Skipped when this invocation IS the import (no recursion) or when opted out.
if (-not $env:GODOT_SKIP_IMPORT -and ($GodotArgs -notcontains '--import')) {
    $projectDir = Get-ProjectDir -Arguments $GodotArgs
    if ($projectDir -and (Test-Path (Join-Path $projectDir 'project.godot'))) {
        $binDir = Join-Path $projectDir '.godot/mono/temp/bin'
        $hasAssemblies = (Test-Path $binDir) -and
            $null -ne (Get-ChildItem -Path $binDir -Filter '*.dll' -File -Recurse -ErrorAction SilentlyContinue |
                Select-Object -First 1)
        if (-not $hasAssemblies) {
            Invoke-DotnetBuild -ProjectDir $projectDir
        }

        # Must follow the build: the C# importers cannot run without assemblies.
        $importedDir = Join-Path $projectDir '.godot/imported'
        $hasImportCache = (Test-Path $importedDir) -and
            $null -ne (Get-ChildItem -Path $importedDir -File -ErrorAction SilentlyContinue | Select-Object -First 1)
        if (-not $hasImportCache) {
            Invoke-GodotImport -ProjectDir $projectDir
        }
    }
}

& $exe @GodotArgs
exit $LASTEXITCODE
