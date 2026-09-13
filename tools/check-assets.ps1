<#
.SYNOPSIS
  Repo-hygiene checks: .gd/.uid companion pairing, and the pixel-art import baseline.

.DESCRIPTION
  Two checks, both run on every invocation:

  1. UID pairing — every tracked .gd must have a tracked .gd.uid companion, and
     no .gd.uid may exist whose .gd is gone. Godot writes foo.gd.uid on the
     *next* import pass (after the commit that added foo.gd), so a commit that
     stages explicit paths (git add scripts/foo.gd) leaves the companion
     untracked; this check catches that after the fact.

  2. Sprite imports — every .import under assets/sprites/ must sit on the
     pixel-art baseline: compress/mode=0 (lossless), mipmaps/generate=false,
     detect_3d/compress_to=0. Anything else VRAM-compresses pixel art and
     softens its hard edges.

  Exits 0 when the tree is clean, 1 when any check reports a violation.
  Wired into .githooks/pre-commit.

.EXAMPLE
  pwsh -NoProfile -File tools/check-assets.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = (& git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "check-assets: not inside a git repository"
}

$violations = @()

# --- Check 1: .gd <-> .gd.uid pairing (AC2) ---
$gdBases  = & git -C $repoRoot ls-files '*.gd'     | ForEach-Object { $_ -replace '\.gd$', '' }
$uidBases = & git -C $repoRoot ls-files '*.gd.uid' | ForEach-Object { $_ -replace '\.gd\.uid$', '' }

foreach ($g in ($gdBases | Where-Object { $_ -notin $uidBases })) {
    $violations += "$g.gd is tracked but $g.gd.uid is missing/untracked — run the Godot import, then commit the .uid beside it"
}
foreach ($g in ($uidBases | Where-Object { $_ -notin $gdBases })) {
    $violations += "$g.gd.uid is tracked but $g.gd is gone — delete the stale .uid"
}

# --- Check 2: sprite import baseline (AC4) ---
foreach ($f in (& git -C $repoRoot ls-files 'assets/sprites/*.import')) {
    $lines = Get-Content (Join-Path $repoRoot $f) | ForEach-Object { $_.Trim() }
    if ($lines -notcontains 'detect_3d/compress_to=0') {
        $violations += "${f}: detect_3d/compress_to must be 0 (pixel art must opt out of Detect 3D VRAM compression)"
    }
    if ($lines -notcontains 'compress/mode=0') {
        $violations += "${f}: compress/mode must be 0 (pixel art must be lossless)"
    }
    if ($lines -notcontains 'mipmaps/generate=false') {
        $violations += "${f}: mipmaps/generate must be false (pixel art must not generate mipmaps)"
    }
}

if ($violations.Count -gt 0) {
    foreach ($v in $violations) { Write-Host "check-assets: $v" -ForegroundColor Red }
    Write-Host "check-assets: $($violations.Count) violation(s)." -ForegroundColor Red
    exit 1
}

Write-Host "check-assets: clean — every tracked .gd has its .uid, no orphan .uid, all sprite imports on the pixel-art baseline."
exit 0
