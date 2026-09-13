# Close Three Process Gaps (Issue #137) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Close the three repo-hygiene/process gaps surfaced by the #130 cantina 3D migration — untracked `.uid` companions, deletion blast-radius verified from prose instead of the tree, and the pixel-art import guard that was only a note — so the next room migration (workshop, #131) does not re-hit them.

**Architecture:** One PowerShell script, `tools/check-assets.ps1`, runs two repo-state checks — (1) every tracked `.gd` has a tracked `.gd.uid` companion and no orphan `.uid` lingers, and (2) every `.import` under `assets/sprites/` sits on the pixel-art baseline. It is wired into the repo's existing gate (the `.githooks/pre-commit` hook — the only gate this repo has; there is no CI test pipeline). Two prose edits encode the rules the checks enforce: a `.uid`-companion rule in `CLAUDE.md` (AC1) and a verify-before-delete step in the `executing-plans` skill (AC3). No game code, no autoloads, no GUT changes.

**Tech Stack:** PowerShell 7 (`pwsh`), `git` (`git ls-files` for the pairing check), plain-text `.import` parsing. No GDScript, no Godot runtime.

## Open questions (must resolve before starting)

None — resolved during planning:

- **One script or two (AC2 + AC4)?** One: `tools/check-assets.ps1` runs both checks. One wiring point in the pre-commit hook (the issue's stated advantage), and both checks are "repo hygiene" and always run together.
- **Where does the gate live?** The repo has no CI test pipeline — only `.github/workflows/close-issue-on-merge.yml` (merge hook, not a check gate) and the local `.githooks/pre-commit` hook. The checks are wired into the pre-commit hook (the issue's "whatever gate the project already uses").
- **PowerShell or Python for the scripts?** PowerShell, per the issue's "Files Impacted" ("both are natural PowerShell one-pass scripts; `tools/godot.ps1` is the existing precedent"). The pre-commit hook already requires `pwsh` implicitly (this is a Windows + pwsh repo per `CLAUDE.md`).

---

## Calibration facts (current `master`, head `0bfa7ba`)

These are the numbers the checks are calibrated against, verified against the real tree before writing this plan. AC5 is "the checks report zero violations against `master` at fix time" — so the plan must both write the checks *and* clear the one live violation they find.

- **164** tracked `.gd` files, **174** tracked `.gd.uid` files.
- **0** tracked `.gd` are missing a `.uid` (every `.gd` has its companion).
- **10** tracked `.gd.uid` files are **orphans** — their `.gd` was renamed `test_poc3d_*` → `test_world3d_*` during the #129 migration spine, but the old `.uid` files were left behind:

  ```
  tests/test_poc3d_interaction.gd.uid
  tests/test_poc3d_npc3d.gd.uid
  tests/test_poc3d_pipeline.gd.uid
  tests/test_poc3d_pixel_sprite.gd.uid
  tests/test_poc3d_player3d.gd.uid
  tests/test_poc3d_room_camera.gd.uid
  tests/test_poc3d_sprite_facing.gd.uid
  tests/test_poc3d_tile_collision.gd.uid
  tests/test_poc3d_tile_floor.gd.uid
  tests/test_poc3d_world_scale.gd.uid
  ```

- **18** `.import` files under `assets/sprites/` (9 `characters/`, 8 `kit/`, 1 `tiles/`). **All 18** are already on the pixel-art baseline: `compress/mode=0`, `mipmaps/generate=false`, `detect_3d/compress_to=0`.

The **pixel-art baseline** (the values the import check enforces) is, for every `.import` under `assets/sprites/`:

| Key | Required value | Meaning |
|-----|----------------|---------|
| `compress/mode` | `0` | Lossless — VRAM compression (mode 2/3) softens hard pixel edges |
| `mipmaps/generate` | `false` | No mipmaps — they blur pixel art at distance |
| `detect_3d/compress_to` | `0` | Opt out of "Detect 3D" VRAM reimport for `Sprite3D`/`AnimatedSprite3D`/`StandardMaterial3D` textures |

---

## Batch 1 — the check script, calibration, and the `.uid` rule

### Task 1: Write `tools/check-assets.ps1` (AC2 + AC4)

**Files:**
- Create: `tools/check-assets.ps1`

**Depends on:** none
**Parallelizable with:** Task 3, Task 4 (different files — this writes only `tools/check-assets.ps1`)

**Step 1: Write the script**

Create `tools/check-assets.ps1` with this exact content:

```powershell
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
        $violations += "$f: detect_3d/compress_to must be 0 (pixel art must opt out of Detect 3D VRAM compression)"
    }
    if ($lines -notcontains 'compress/mode=0') {
        $violations += "$f: compress/mode must be 0 (pixel art must be lossless)"
    }
    if ($lines -notcontains 'mipmaps/generate=false') {
        $violations += "$f: mipmaps/generate must be false (pixel art must not generate mipmaps)"
    }
}

if ($violations.Count -gt 0) {
    foreach ($v in $violations) { Write-Host "check-assets: $v" -ForegroundColor Red }
    Write-Host "check-assets: $($violations.Count) violation(s)." -ForegroundColor Red
    exit 1
}

Write-Host "check-assets: clean — every tracked .gd has its .uid, no orphan .uid, all sprite imports on the pixel-art baseline."
exit 0
```

**Step 2: Run it — expect it to flag the 10 orphans**

Run from the repo root:

```powershell
pwsh -NoProfile -File tools/check-assets.ps1
```

Expected output: ten red `check-assets: tests/test_poc3d_*.gd.uid is tracked but tests/test_poc3d_*.gd is gone …` lines (the orphan list above), then `check-assets: 10 violation(s).`, exit code 1. **Zero** "missing .uid" lines (there are none today). This proves both directions of the `-notin` compare are wired: the orphan direction is exercised live; the missing direction is the symmetric branch and is exercised in Task 6's hook test.

If the count is anything other than exactly 10 orphans (and zero missing), stop and fix — the check is miscalibrated against the tree.

**Step 3: Commit**

```powershell
git add tools/check-assets.ps1
git commit -m "chore: add repo-hygiene check script (.uid pairing + sprite import baseline)"
```

### Task 2: Delete the 10 orphan `.uid` files

**Files:**
- Delete: the 10 `tests/test_poc3d_*.gd.uid` files listed in the calibration facts above.

**Depends on:** Task 1 (the re-check in Step 2 needs the script to exist)
**Parallelizable with:** Task 5 (different files — this touches only `tests/*.uid`, Task 5 touches only `.githooks/pre-commit`)

**Step 1: Delete the 10 files**

```powershell
git rm tests/test_poc3d_interaction.gd.uid tests/test_poc3d_npc3d.gd.uid tests/test_poc3d_pipeline.gd.uid tests/test_poc3d_pixel_sprite.gd.uid tests/test_poc3d_player3d.gd.uid tests/test_poc3d_room_camera.gd.uid tests/test_poc3d_sprite_facing.gd.uid tests/test_poc3d_tile_collision.gd.uid tests/test_poc3d_tile_floor.gd.uid tests/test_poc3d_world_scale.gd.uid
```

Do **not** touch any `tests/test_world3d_*.gd` or `tests/test_world3d_*.gd.uid` — those are live.

**Step 2: Verify — the check now reports zero**

```powershell
pwsh -NoProfile -File tools/check-assets.ps1
```

Expected: `check-assets: clean — …`, exit code 0.

Also confirm no `test_poc3d_*` remains tracked:

```powershell
git ls-files 'tests/test_poc3d_*'
```

Expected: empty output.

**Step 3: Commit**

```powershell
git commit -m "chore: remove 10 orphan test_poc3d_*.uid left by the #129 rename"
```

*(`git rm` already staged the deletions; commit them.)*

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 1, Task 3, Task 4 | Different files (`tools/check-assets.ps1`, `CLAUDE.md`, `.claude/skills/executing-plans/SKILL.md`); each stages only its own paths |
| B (parallel) | Task 2, Task 5 | Task 2 touches only `tests/*.uid`; Task 5 touches only `.githooks/pre-commit`. Task 2 needs Task 1's script for its re-check; Task 5 needs Task 1's script to wire. Both are independent of each other and of Group A's Task 3/Task 4 |

### Smoketest Checkpoint 1 — checks exist, calibrated, and clean

**Note on this checkpoint:** this issue changes no game code, no autoloads, and no GUT-covered runtime logic (per the issue's "Notes": R1/R3 are repo-state checks, not runtime logic; R2 is prose). So there is no game-launch or GUT step. The "smoketest" is running the checks themselves against the real tree.

**Step 1: Fetch and merge latest master**

```bash
git fetch origin && git merge origin/master
```

**Step 2: Run both checks**

```powershell
pwsh -NoProfile -File tools/check-assets.ps1
```

Expected: `check-assets: clean — every tracked .gd has its .uid, no orphan .uid, all sprite imports on the pixel-art baseline.` — exit code 0.

**Step 3: Confirm with user**

Tell the user: the check script exists under `tools/check-assets.ps1`, the 10 orphan `.uid` files are gone, and the script reports a clean tree. Wait for confirmation before proceeding to Batch 2.

---

## Batch 2 — the two prose rules (AC1, AC3)

### Task 3: Add the `.uid` companion rule to `CLAUDE.md` (AC1)

**Files:**
- Modify: `CLAUDE.md`

**Depends on:** none
**Parallelizable with:** Task 1, Task 4 (different files)

**Step 1: Insert the rule**

In `CLAUDE.md`, insert a new note immediately **before** the `## Architecture` heading — i.e. after the last "Headless verification gotchas" bullet (the one ending `…hardcode the scene/output path in the throwaway script instead.`). The insertion:

```markdown
**`.uid` companions ship with the commit.** Godot writes `foo.gd.uid` on the
*next* import pass — after the commit that added `foo.gd` — so an explicit-path
`git add scripts/foo.gd` leaves the companion untracked, and it is silently
missing from the commit. After adding a `.gd`, run the import
(`./tools/godot.ps1 -Console --headless --path . --editor --quit`) so the `.uid`
exists, then commit the `.gd` and its `.uid` together. `tools/check-assets.ps1`
(wired into the pre-commit hook) flags a tracked `.gd` whose `.uid` is missing or
untracked, and a stale `.uid` whose `.gd` is gone — it is the gate, not a note.

```

(Keep the blank line before `## Architecture`.)

**Step 2: Verify**

Read the surrounding region of `CLAUDE.md`; confirm the note sits under the Commands section, before `## Architecture`, and the prose matches AC1 (states the rule + names the failure mode "Godot generates it on the next import").

**Step 3: Commit**

```powershell
git add CLAUDE.md
git commit -m "docs: state the .uid companion rule and its failure mode (AC1)"
```

### Task 4: Add the verify-before-delete step to `executing-plans` (AC3)

**Files:**
- Modify: `.claude/skills/executing-plans/SKILL.md`

**Depends on:** none
**Parallelizable with:** Task 1, Task 3 (different files)

**Step 1: Insert the gate**

In `.claude/skills/executing-plans/SKILL.md`, insert a new block **between** the end of the "Batch atomicity rule (HARD):" paragraph (it ends `…then re-dispatch the entire group from scratch.`) and the line `For each task (whether parallel or sequential):`. The insertion:

```markdown
**Before executing a deletion task (HARD):** confirm each target's blast radius
against the tree, never the plan prose. For every file a task says to delete:

- `grep` the repo for consumers of the target's symbol or filename — a file the
  plan did not list may still reference it (e.g. `grep -rn "<name>" scripts/ scenes/ tests/`).
- If the target is a script (`.gd`), check the inheritance chain: `grep -n "^extends"` on
  every script sharing the target's directory — a sibling may extend it and the
  plan may not have said so.
- If the plan's description of the target does not match the tree — it names a
  file that does not exist, or misreads an `ext_resource` id / scene sub-resource
  as a script filename — STOP and report the mismatch. Do not silently work
  around it by hunting "phantom" files or guessing.

The plan is a hypothesis; the tree is the fact. A deletion's real risk is often
adjacent to what the plan names (e.g. the inheritance chain of a script about to
be deleted), not the file the plan points at.

```

**Step 2: Verify**

Read the region of the skill; confirm the block sits inside Step 3 ("Execute Batch"), before "For each task", and that it names both the consumer `grep` and the `extends` check, and the "report the mismatch" instruction.

**Step 3: Commit**

```powershell
git add .claude/skills/executing-plans/SKILL.md
git commit -m "docs: executing-plans verifies a deletion's blast radius against the tree (AC3)"
```

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 3, Task 4 | Both are independent doc edits to different files (`CLAUDE.md` vs `.claude/skills/executing-plans/SKILL.md`); neither reads the other's output |

### Smoketest Checkpoint 2 — rules are documented

**Step 1: Fetch and merge latest master**

```bash
git fetch origin && git merge origin/master
```

**Step 2: Confirm the two prose rules read correctly**

Read the inserted `CLAUDE.md` note and the `executing-plans` skill block. Expected: AC1 states the `.uid`-companion rule *and* names the failure mode (Godot writes the `.uid` on the next import, so an explicit-path `git add` misses it); AC3 instructs verifying consumers + inheritance chain against the tree and reporting a plan/tree mismatch.

**Step 3: Confirm with user**

Tell the user the two doc rules landed. Wait for confirmation before proceeding to Batch 3.

---

## Batch 3 — wire the gate and prove AC5

### Task 5: Wire `tools/check-assets.ps1` into the pre-commit hook

**Files:**
- Modify: `.githooks/pre-commit`

**Depends on:** Task 1 (the script must exist to wire it)
**Parallelizable with:** Task 2 (different files)

**Step 1: Append the check to the hook**

In `.githooks/pre-commit`, the current last line is `git add .omp/agents/`. After it, append:

```sh

if command -v pwsh >/dev/null 2>&1; then
    if ! pwsh -NoProfile -File tools/check-assets.ps1; then
        echo "" >&2
        echo "pre-commit: tools/check-assets.ps1 reported violations — commit blocked." >&2
        exit 1
    fi
else
    echo "pre-commit: no pwsh on PATH — asset checks skipped" >&2
fi
```

(The leading blank line, then the block. `pwsh` is the only new dependency; the hook already runs `python tools/sync_agents.py` and `git`, and this repo already mandates `pwsh` in `CLAUDE.md`.)

**Step 2: Verify the hook runs clean on a clean tree**

Run the hook directly from the repo root:

```bash
./.githooks/pre-commit
```

Expected: the agent-mirror sync runs (idempotent), then `check-assets: clean — …`, and the hook exits 0. `echo $?` should be `0`.

**Step 3: Commit**

```powershell
git add .githooks/pre-commit
git commit -m "chore: gate commits on the repo-hygiene checks"
```

### Task 6: Final calibration — AC5, plus a negative hook test

**Files:**
- none (verification only; the only new artifact is a throwaway probe that is removed in the same step)

**Depends on:** Task 1 (script), Task 2 (orphans cleared), Task 5 (hook wired)
**Parallelizable with:** none — this is the terminal checkpoint; it verifies the combined result of Tasks 1, 2, and 5 and must run after all of them.

**Step 1: Confirm AC5 — all four checks report zero against the tree**

```powershell
pwsh -NoProfile -File tools/check-assets.ps1
```

Expected: `check-assets: clean — every tracked .gd has its .uid, no orphan .uid, all sprite imports on the pixel-art baseline.` — exit code 0.

**Step 2: Negative test — prove the hook actually blocks the R1 failure**

Create a throwaway `.gd` with no `.uid`, stage it, and confirm the hook refuses the commit:

```powershell
# from the repo root
New-Item -Path scripts/zz_probe.gd -ItemType File -Force | Out-Null
git add scripts/zz_probe.gd
```

Then run the hook (or attempt a commit):

```bash
./.githooks/pre-commit
echo $?
```

Expected: `check-assets: scripts/zz_probe.gd is tracked but scripts/zz_probe.gd.uid is missing/untracked …` and the hook exits **1** — the commit is blocked. This is the exact R1 failure mode (#130's `87f9a18` left `cantina.gd`'s `.uid` untracked).

Clean up the probe (reversible, nothing committed):

```powershell
git reset scripts/zz_probe.gd
Remove-Item scripts/zz_probe.gd
```

Then re-run `pwsh -NoProfile -File tools/check-assets.ps1` and confirm it is clean again.

**Step 3: Full GUT suite (regression guard only)**

This issue adds no game code, but run the suite once to confirm the worktree still imports and tests parse (the orphan `.uid` deletions and doc edits must not have disturbed the test suite):

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit 2>&1 |
  Select-String -Pattern "SCRIPT ERROR|Failing Tests|Passing Tests|Scripts "
```

Expected: zero `SCRIPT ERROR`, zero failing, and the Scripts/Tests count matches the pre-change count (no drop — the orphan files were `.uid`, not `.gd`, so no test script vanished).

**Step 4: Confirm with user**

Report the AC5 result (all four checks clean) and the negative hook test (hook blocked a `.gd`-without-`.uid` commit). This is the completion of issue #137's acceptance criteria.

#### Parallel Execution Groups — Smoketest Checkpoint 3

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 6 | Terminal verification; depends on the script (Task 1), the cleaned tree (Task 2), and the wired hook (Task 5). No parallel work remains |

### Smoketest Checkpoint 3 — final acceptance

**Step 1: Fetch and merge latest master**

```bash
git fetch origin && git merge origin/master
```

**Step 2: Re-run the checks post-merge**

```powershell
pwsh -NoProfile -File tools/check-assets.ps1
```

Expected: `check-assets: clean — …`, exit 0.

**Step 3: Confirm with user**

The four acceptance criteria are met: AC1 (`CLAUDE.md` `.uid` rule), AC2 (`.uid` pairing check + 10 orphans cleared), AC3 (`executing-plans` verify-before-delete), AC4 (sprite import baseline check), AC5 (all checks clean against `master`). Ask the user to confirm before the branch is handed to `finishing-a-development-branch`.

---

## Out of scope (from the issue)

- Re-authoring `docs/plans/2026-09-10-cantina-3d.md` — it is annotated history.
- Any change to the cantina, `Plot3D`, or the 3D spine — this issue is process only.
- The `scenes/characters/` pre-MVP cleanup (`npc_base.tscn` / `player.tscn` are live and unaffected).
- `.cs` companions: the issue scopes AC1/AC2 to `.gd`. The tree does track `.cs.uid` files (e.g. `scripts/YarnGameState.cs.uid`), but extending the check to `.cs` is not part of this issue — flag it as a follow-up if desired, not here.
- `scenes/poc3d/README.md`: the Detect 3D prose is already correct; it is **not** rewritten (per the issue). A pointer from it to the new check is optional and deliberately omitted to keep the diff minimal.
