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

.PARAMETER Console
  Use the *_console.exe build (stdout/stderr attached) instead of the windowed one.

.EXAMPLE
  ./tools/godot.ps1 -Console --headless --editor --quit --path .
  ./tools/godot.ps1 --path .
#>
[CmdletBinding()]
param(
    [switch]$Console,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GodotArgs
)

$ErrorActionPreference = 'Stop'

# Allow an explicit override for non-WinGet installs.
if ($env:GODOT_BIN -and (Test-Path $env:GODOT_BIN)) {
    $exe = $env:GODOT_BIN
} else {
    $packages = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    $pattern = if ($Console) { 'Godot_v*_mono_win64_console.exe' } else { 'Godot_v*_mono_win64.exe' }
    $exe = Get-ChildItem -Path $packages -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}

if (-not $exe) {
    throw "Could not locate a Godot mono executable. Set `$env:GODOT_BIN to its full path."
}

& $exe @GodotArgs
exit $LASTEXITCODE
