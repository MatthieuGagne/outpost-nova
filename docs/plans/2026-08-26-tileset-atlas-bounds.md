# Tileset Atlas Bounds Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the 56 out-of-bounds atlas row-31 tile definitions from `data/tilesets/station.tres` (issue #97), add the 6 valid-range tiles it is missing, and lock both invariants behind a GUT regression test.

**Architecture:** A new GUT test reads each `.tres` under `data/tilesets/` **as text** rather than loading it as a resource — Godot silently drops out-of-bounds tiles during `create_tile`, so a loaded `TileSetAtlasSource` can never expose the bug. The test derives the valid atlas grid from the source texture's pixel size, `texture_region_size` and `separation`, so no grid dimension is hardcoded. Two PowerShell edits then bring `station.tres` into compliance.

**Tech Stack:** GDScript, GUT, Godot 4.7.1 `TileSetAtlasSource` / `FileAccess` / `RegEx` / `DirAccess`, PowerShell 7 for the file edits.

## Open questions (must resolve before starting)

None — all resolved during grill-me.

---

## Verified preconditions

Established before writing this plan. The executor does **not** need to re-verify these, but must not contradict them.

| Fact | Evidence |
|---|---|
| Texture `assets/sprites/tiles/roguelikeSheet_transparent.png` is 968 × 526 px | read from the PNG |
| `texture_region_size` is **absent** from `station.tres` → Godot default 16 × 16 | `grep` returns no match |
| `separation = Vector2i(1, 1)` is present | `data/tilesets/station.tres:7` |
| Valid grid is therefore exactly **57 cols (0–56) × 31 rows (0–30)** | `(968-16)/17+1 = 57`, `(526-16)/17+1 = 31` |
| `data/maps/station_tile.tsx` independently declares `columns="57" tilecount="1767"` = 57 × 31 | agrees with the computed grid |
| `station.tres` currently declares 1817 tiles: 1761 valid + **56 at row 31** | parsed from the file |
| Column 38 is already absent from row 31 (hence 56, not 57, errors) | parsed from the file |
| **No area scene paints row 31.** All 7 scenes in `scenes/areas/*.tscn` hold 480 cells each, every cell at atlas coord `(25, 15)` | decoded the base64 `tile_map_data` of all 7 scenes |
| `data/maps/trade_dock.tmx` uses only GIDs 874 / 881 → tile ids 873 / 880 → atlas row 15 | parsed from the file |
| Godot 4 keys tiles by `source_id` + atlas coord, **not** a sequential index — adding or removing definitions cannot renumber existing tiles | confirmed by the scene decode above |
| 6 coords inside the valid range are undeclared: `(0,18) (1,18) (0,25) (1,25) (29,8) (38,9)` | parsed from the file |
| Those 6 cells contain **real artwork** (alpha up to 255; `(1,25)` is fully opaque), while some *declared* tiles such as `(0,17)` and `(0,24)` are fully transparent | alpha channel sampled from the PNG |
| `tools/fix_oob_tiles.gd` hardcodes `atlas.x >= 57` (x-axis only) and its `AREA_SCENES` list omits `scenes/areas/trade_dock.tscn` | read the file |
| `*.uid` is gitignored (`.gitignore:2`), so no `.uid` companion needs deleting from git | `git ls-files tools/` |

**Consequence:** steps 2 of the issue's suggested fix ("remap painted row-31 cells") is a **no-op**. No scene, `.tscn`, or `.tmx` file is touched by this plan.

---

## File Structure

| Action | Path | Purpose |
|---|---|---|
| Create | `tests/test_tileset_bounds.gd` | Two-method GUT regression guard for atlas bounds and coverage |
| Modify | `data/tilesets/station.tres` | Remove 56 row-31 lines; add 6 missing valid-range lines |
| Delete | `tools/fix_oob_tiles.gd` | Spent one-shot migration tool, x-axis-only, under-scans scenes |
| Delete | `docs/superpowers/plans/2026-06-01-fix-oob-tileset-columns.md` | Completed predecessor plan referencing the deleted tool |

`docs/index.md` needs **no** edit: it links the `plans/` and `superpowers/plans/` *directories*, never individual plan files. Verified at `docs/index.md:50-51`.

---

## Batch 1 — fix the tileset

### Task 1: Bounds guard + remove out-of-bounds row 31

**Files:**
- Create: `tests/test_tileset_bounds.gd`
- Modify: `data/tilesets/station.tres`

**Depends on:** none
**Parallelizable with:** none — Task 2 writes both of these same two files and calls helper functions defined here, so it must run after this task completes.

**Step 1: Write the failing GUT test**

Create `tests/test_tileset_bounds.gd` with exactly this content:

```gdscript
extends GutTest

# Every .tres in this directory is checked, so adding a second tileset later
# needs no change to this test.
const TILESET_DIR := "res://data/tilesets"

# TileSetAtlasSource omits these keys from the .tres when they match the engine
# default, so an absent key means "default", not "zero". Values are the Godot 4
# documented defaults for TileSetAtlasSource.texture_region_size / .separation.
const GODOT_DEFAULT_REGION_SIZE := Vector2i(16, 16)
const GODOT_DEFAULT_SEPARATION := Vector2i(0, 0)


func _tileset_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	for file_name in DirAccess.get_files_at(TILESET_DIR):
		if file_name.ends_with(".tres"):
			paths.append("%s/%s" % [TILESET_DIR, file_name])
	assert_gt(paths.size(), 0, "no .tres tilesets found under %s" % TILESET_DIR)
	return paths


func _read_lines(path: String) -> PackedStringArray:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		fail_test("could not open %s" % path)
		return PackedStringArray()
	var text := file.get_as_text()
	file.close()
	return text.split("\n")


func _parse_vector2i(lines: PackedStringArray, key: String, fallback: Vector2i) -> Vector2i:
	var re := RegEx.new()
	re.compile("^%s *= *Vector2i\\( *(-?\\d+) *, *(-?\\d+) *\\)$" % key)
	for line in lines:
		var found := re.search(line.strip_edges())
		if found != null:
			return Vector2i(found.get_string(1).to_int(), found.get_string(2).to_int())
	return fallback


func _parse_texture_size(lines: PackedStringArray) -> Vector2i:
	# Only the PNG is loaded here, never the tileset itself: loading the .tres
	# would let Godot drop the out-of-bounds tiles before we could see them.
	var re := RegEx.new()
	re.compile("^\\[ext_resource type=\"Texture2D\".*path=\"([^\"]+)\"")
	for line in lines:
		var found := re.search(line)
		if found != null:
			var texture: Texture2D = load(found.get_string(1))
			if texture != null:
				return Vector2i(texture.get_size())
	return Vector2i.ZERO


func _parse_declared_coords(lines: PackedStringArray) -> Dictionary:
	# Tile entries look like "12:30/0 = 0"; per-tile property lines reuse the
	# same "<col>:<row>/" prefix, so match the prefix only and de-duplicate.
	var re := RegEx.new()
	re.compile("^(\\d+):(\\d+)/")
	var coords := {}
	for line in lines:
		var found := re.search(line)
		if found != null:
			coords[Vector2i(found.get_string(1).to_int(), found.get_string(2).to_int())] = true
	return coords


func _grid_size(texture_size: Vector2i, region_size: Vector2i, separation: Vector2i) -> Vector2i:
	# Tile (c, r) starts at c * (region + separation) and spans region px, so the
	# last valid index is floor((texture - region) / stride).
	var stride := region_size + separation
	if stride.x <= 0 or stride.y <= 0:
		fail_test("non-positive atlas stride %s" % stride)
		return Vector2i.ZERO
	var cols := 0 if texture_size.x < region_size.x else (texture_size.x - region_size.x) / stride.x + 1
	var rows := 0 if texture_size.y < region_size.y else (texture_size.y - region_size.y) / stride.y + 1
	return Vector2i(cols, rows)


func _atlas_report(path: String) -> Dictionary:
	var lines := _read_lines(path)
	var texture_size := _parse_texture_size(lines)
	var region_size := _parse_vector2i(lines, "texture_region_size", GODOT_DEFAULT_REGION_SIZE)
	var separation := _parse_vector2i(lines, "separation", GODOT_DEFAULT_SEPARATION)
	return {
		"path": path,
		"texture_size": texture_size,
		"region_size": region_size,
		"separation": separation,
		"grid": _grid_size(texture_size, region_size, separation),
		"coords": _parse_declared_coords(lines),
	}


func test_no_tiles_outside_texture():
	for path in _tileset_paths():
		var atlas := _atlas_report(path)
		var grid: Vector2i = atlas["grid"]
		var outside: Array[Vector2i] = []
		for coord in atlas["coords"]:
			if coord.x < 0 or coord.y < 0 or coord.x >= grid.x or coord.y >= grid.y:
				outside.append(coord)
		outside.sort()
		assert_eq(outside.size(), 0,
			"%s declares %d tile(s) outside the %d x %d atlas grid (texture %s, region %s, separation %s): %s"
			% [path, outside.size(), grid.x, grid.y,
				atlas["texture_size"], atlas["region_size"], atlas["separation"], outside])
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_tileset_bounds.gd" -gexit
```

Expected: **1 failing assertion**, message naming 56 tiles outside a `57 x 31` grid, listing `(0, 31)` through `(56, 31)` (column 38 absent).

**Step 3: Write minimal implementation**

Delete every row-31 declaration. `Set-Content` would rewrite the file's LF endings as CRLF and produce a 1829-line whitespace diff, so use `System.IO.File` directly:

```powershell
$path = "data/tilesets/station.tres"
$lines = [System.IO.File]::ReadAllText($path) -split "`n"
$kept = $lines | Where-Object { $_ -notmatch '^\d+:31/0 = 0$' }
[System.IO.File]::WriteAllText($path, ($kept -join "`n"))
```

Confirm the edit shape before running the test:

```powershell
(Select-String -Path "data/tilesets/station.tres" -Pattern '^\d+:31/0').Count
(Select-String -Path "data/tilesets/station.tres" -Pattern '^\d+:\d+/0 = 0').Count
git diff --stat data/tilesets/station.tres
```

Expected: `0`, then `1761`, then `1 file changed, 56 deletions(-)` with **zero** insertions. A non-zero insertion count means line endings were mangled — revert with `git checkout -- data/tilesets/station.tres` and re-run using the `System.IO.File` form above.

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_tileset_bounds.gd" -gexit
```

Expected: PASS, 1 test, 0 failures.

**Step 5: Refactor checkpoint**

Ask: "Does this implementation generalize, or did I hard-code something that breaks when N > 1?"
- The test globs the directory rather than naming `station.tres`, and derives `57 x 31` from the texture rather than asserting it, so a second tileset or a resized sheet is handled with no edit. Proceed.
- If you found yourself typing `57`, `31`, or `1767` anywhere in the test, that is a defect — fix it now.

**Step 6: Commit**

```powershell
git add tests/test_tileset_bounds.gd data/tilesets/station.tres
git commit -m "fix: remove out-of-bounds atlas row 31 from station.tres (#97)"
```

---

### Task 2: Coverage guard + add the 6 missing valid tiles

**Files:**
- Modify: `tests/test_tileset_bounds.gd`
- Modify: `data/tilesets/station.tres`

**Depends on:** Task 1
**Parallelizable with:** none — writes the same two files as Task 1 and reuses its `_atlas_report()` / `_grid_size()` helpers.

**Step 1: Write the failing GUT test**

Append this second test method to the end of `tests/test_tileset_bounds.gd`. Do not modify the helpers or the first test:

```gdscript


func test_all_valid_cells_declared():
	for path in _tileset_paths():
		var atlas := _atlas_report(path)
		var grid: Vector2i = atlas["grid"]
		var declared: Dictionary = atlas["coords"]
		var missing: Array[Vector2i] = []
		for row in grid.y:
			for col in grid.x:
				var coord := Vector2i(col, row)
				if not declared.has(coord):
					missing.append(coord)
		assert_eq(missing.size(), 0,
			"%s leaves %d of %d valid atlas cell(s) undeclared, so that artwork cannot be painted: %s"
			% [path, missing.size(), grid.x * grid.y, missing])
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_tileset_bounds.gd" -gexit
```

Expected: `test_no_tiles_outside_texture` PASSES, `test_all_valid_cells_declared` FAILS with exactly 6 undeclared cells of 1767: `(29, 8), (38, 9), (0, 18), (1, 18), (0, 25), (1, 25)`.

**Step 3: Write minimal implementation**

The file is ordered row-major in contiguous per-row blocks, so each new line goes at its sorted column position inside its own row's block. Insert each one immediately before its existing right-hand neighbour:

```powershell
$path = "data/tilesets/station.tres"
$lines = [System.IO.File]::ReadAllText($path) -split "`n"
$insertions = @(
    @{ Before = '30:8/0 = 0'; Lines = @('29:8/0 = 0') }
    @{ Before = '39:9/0 = 0'; Lines = @('38:9/0 = 0') }
    @{ Before = '2:18/0 = 0'; Lines = @('0:18/0 = 0', '1:18/0 = 0') }
    @{ Before = '2:25/0 = 0'; Lines = @('0:25/0 = 0', '1:25/0 = 0') }
)
$out = New-Object System.Collections.Generic.List[string]
foreach ($line in $lines) {
    $hit = $insertions | Where-Object { $_.Before -eq $line }
    if ($hit) { foreach ($new in $hit.Lines) { $out.Add($new) } }
    $out.Add($line)
}
[System.IO.File]::WriteAllText($path, ($out -join "`n"))
```

Confirm the edit shape:

```powershell
(Select-String -Path "data/tilesets/station.tres" -Pattern '^\d+:\d+/0 = 0').Count
git diff --stat data/tilesets/station.tres
```

Expected: `1767`, then `1 file changed, 6 insertions(+)` with **zero** deletions.

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_tileset_bounds.gd" -gexit
```

Expected: PASS, 2 tests, 0 failures.

**Step 5: Refactor checkpoint**

Ask: "Does this implementation generalize, or did I hard-code something that breaks when N > 1?"
- The 6 coordinates are hardcoded in the *edit command*, which is correct — it is a one-shot data repair, not shipped logic. The *test* must remain fully derived. Verify no coordinate literal leaked into `tests/test_tileset_bounds.gd`.
- If the `$insertions` anchors did not all match (insertion count below 6), stop: the file ordering assumption is wrong. Report rather than improvising.

**Step 6: Commit**

```powershell
git add tests/test_tileset_bounds.gd data/tilesets/station.tres
git commit -m "fix: declare the 6 missing in-bounds atlas tiles in station.tres"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|---|---|---|
| A (sequential) | Task 1 | Must complete first — defines the test helpers Task 2 reuses |
| B (sequential) | Task 2 | Depends on Task 1; writes the same two files |

No parallelism is available in this batch: both tasks write `tests/test_tileset_bounds.gd` and `data/tilesets/station.tres`.

### Smoketest Checkpoint 1 — console is clean across all 7 areas

**Step 1: Fetch and merge latest master**

```powershell
git fetch origin
git merge origin/master
```

**Step 2: Run all GUT tests**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```

Expected: all tests pass, zero failures. This includes the 6 pre-existing suites (`test_game_state`, `test_crafting_system`, `test_clock_manager`, `test_dialogue_wiring`, `test_resource_plot`, `test_ui_input`) plus the new `test_tileset_bounds`.

**Step 3: Build C# and launch the game with the log captured**

Dialogue is C#, so the assemblies must be built before launching:

```powershell
dotnet build "Outpost Nova.csproj"
$log = Join-Path $env:TEMP "outpost-nova-smoketest.log"
./tools/godot.ps1 -Console --path . 2>&1 | Tee-Object -FilePath $log
```

Do **not** read `$LASTEXITCODE` after that pipeline — the pipe masks it.

**Step 4: Walk all 7 areas, then grep the captured log**

In the running game, visit every area registered in `scripts/main.gd:4-11`: `trade_dock`, `cantina`, `workshop`, `quarters`, `security_post`, `med_bay`, `derelict_entrance`. The issue reports the error spam repeating on **every** area transition, so a single load is not sufficient evidence. Then quit the game and run:

```powershell
Select-String -Path $log -Pattern 'TileSetAtlasSource|Cannot create tile'
```

Expected: **no output**. Any match means the fix is incomplete — report it rather than proceeding.

**Step 5: Confirm with user**

Report to the user:
- the full GUT run result,
- that all 7 areas were visited,
- the (empty) grep output as evidence.

Ask the user to confirm the areas still render correctly — floors and walls unchanged, no missing or black tiles. The 6 added tiles are additive and unpainted, so nothing should look different; a visual change would indicate something went wrong. **Wait for confirmation before starting Batch 2.**

---

## Batch 2 — remove the spent migration artefacts

Neither task in this batch affects runtime behaviour: one deletes an `EditorScript` that is never autoloaded or referenced by game code, the other deletes a markdown file.

### Task 3: Delete the superseded `fix_oob_tiles` EditorScript

**Files:**
- Delete: `tools/fix_oob_tiles.gd`

**Depends on:** Task 1, Task 2
**Parallelizable with:** Task 4 — different files, no shared state.

**Step 1: Grep for references before deleting**

```powershell
git grep -n "fix_oob_tiles"
```

Expected hits, and only these:
- `tools/fix_oob_tiles.gd` itself (lines 1 and 17),
- `docs/superpowers/plans/2026-06-01-fix-oob-tileset-columns.md` (12 lines) — that file is deleted by Task 4.

If any hit appears in `scripts/`, `scenes/`, `data/`, `tests/`, or `project.godot`, **stop and report** — the tool is wired into something and this task's premise is wrong.

Note: `*.uid` is gitignored (`.gitignore:2`), so there is no tracked `.uid` companion to remove.

**Step 2: Delete the file**

```powershell
git rm tools/fix_oob_tiles.gd
```

**Step 3: Verify**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```

Expected: all tests still pass. `tools/generate_rooms.gd` and `tools/godot.ps1` remain in `tools/`.

**Step 4: Commit**

```powershell
git commit -m "chore: remove spent fix_oob_tiles migration script"
```

---

### Task 4: Delete the completed predecessor plan doc

**Files:**
- Delete: `docs/superpowers/plans/2026-06-01-fix-oob-tileset-columns.md`

**Depends on:** Task 1, Task 2
**Parallelizable with:** Task 3 — different files, no shared state.

**Step 1: Confirm the work it describes has landed**

```powershell
(Select-String -Path "data/tilesets/station.tres" -Pattern '^(5[789]|[6-9]\d|\d{3,}):\d+/0').Count
```

Expected: `0` — no column ≥ 57 remains, so the columns 57–59 removal that plan describes is complete. Per `CLAUDE.md`, completed plans are deleted.

**Step 2: Delete the file**

```powershell
git rm docs/superpowers/plans/2026-06-01-fix-oob-tileset-columns.md
```

**Step 3: Verify no index entry needs updating**

```powershell
git grep -n "fix-oob-tileset-columns"
```

Expected: no output. `docs/index.md:50-51` links the plan *directories*, not individual files.

Leave the other 8 plan docs (`docs/plans/` × 6, `docs/superpowers/plans/` × 2) untouched — their completion status has not been verified and auditing them is out of scope for #97.

**Step 4: Commit**

```powershell
git commit -m "docs: remove completed plan for out-of-bounds tileset columns"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|---|---|---|
| A (parallel) | Task 3, Task 4 | Different output files, no shared state — dispatch together |

### Smoketest Checkpoint 2 — nothing broke

**Step 1: Fetch and merge latest master**

```powershell
git fetch origin
git merge origin/master
```

**Step 2: Run all GUT tests**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```

Expected: all tests pass, zero failures.

**Step 3: Launch the game**

```powershell
dotnet build "Outpost Nova.csproj"
./tools/godot.ps1 -Console --path .
```

Expected: the game boots and the starting area renders. Only two files were deleted, neither reachable from game code, so this is a sanity check rather than a real risk.

**Step 4: Confirm with user**

Report the test result and that the game boots. Ask the user to confirm before finishing the branch.

---

## Acceptance criteria (issue #97)

| Criterion | How it is proven |
|---|---|
| No `TileSetAtlasSource` errors on area load | Checkpoint 1 Step 4 — grep of the captured runtime log across all 7 areas returns nothing |
| Row-31 definitions removed from `station.tres` | Task 1 Step 3 — 56 deletions, 0 insertions |
| No scene renders empty as a result | No scene paints row 31 (verified precondition); no `.tscn` or `.tmx` is modified |
| Regression cannot recur silently | `tests/test_tileset_bounds.gd::test_no_tiles_outside_texture` guards both axes, for every tileset in the directory |
