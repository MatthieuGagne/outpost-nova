# Fix Out-of-Bounds Tileset Columns Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove 96 phantom tile definitions (columns 57–59, rows 0–31) from `station.tres` and erase any scene cells that reference those atlas coordinates, eliminating the startup `TileSetAtlasSource has no tile at (57+, N)` errors.

**Architecture:** A single EditorScript (`tools/fix_oob_tiles.gd`) first runs in dry-run mode to print a report of affected cells, then runs in fix mode to erase them and re-save the scenes. A PowerShell one-liner strips the 96 invalid tile definitions from `station.tres`. Both changes are committed together.

**Tech Stack:** GDScript `@tool` / `EditorScript`, Godot 4.6 `TileMapLayer` API, `ResourceSaver`, PowerShell string filtering.

---

## File Structure

| Action | Path | Purpose |
|--------|------|---------|
| Create | `tools/fix_oob_tiles.gd` | EditorScript: diagnose then erase out-of-bounds cells in all area scenes |
| Modify | `data/tilesets/station.tres` | Remove 96 tile definitions for columns 57, 58, 59 |
| Modify (via script) | `scenes/areas/cantina.tscn` | Erase any cells with atlas.x >= 57 |
| Modify (via script) | `scenes/areas/workshop.tscn` | Same |
| Modify (via script) | `scenes/areas/security_post.tscn` | Same |
| Modify (via script) | `scenes/areas/med_bay.tscn` | Same |
| Modify (via script) | `scenes/areas/quarters.tscn` | Same |
| Modify (via script) | `scenes/areas/derelict_entrance.tscn` | Same |

---

### Task 1: Create the EditorScript

**Files:**
- Create: `tools/fix_oob_tiles.gd`

The script has a `DRY_RUN` constant. When `true` it only prints; when `false` it erases cells and re-saves the scene. Run in dry-run mode first to confirm what will change.

- [ ] **Step 1: Create the script file**

```gdscript
# tools/fix_oob_tiles.gd
@tool
extends EditorScript

const DRY_RUN := true  # set false to apply fixes

const AREA_SCENES := [
	"res://scenes/areas/cantina.tscn",
	"res://scenes/areas/workshop.tscn",
	"res://scenes/areas/security_post.tscn",
	"res://scenes/areas/med_bay.tscn",
	"res://scenes/areas/quarters.tscn",
	"res://scenes/areas/derelict_entrance.tscn",
]

func _run() -> void:
	print("=== fix_oob_tiles — DRY_RUN=%s ===" % DRY_RUN)
	for path in AREA_SCENES:
		_process_scene(path)
	print("=== done ===")

func _process_scene(path: String) -> void:
	var packed := load(path) as PackedScene
	var root := packed.instantiate()
	var found := _scan_node(root, path)
	if found > 0 and not DRY_RUN:
		var new_packed := PackedScene.new()
		new_packed.pack(root)
		ResourceSaver.save(new_packed, path)
		print("[SAVED] %s (%d cells removed)" % [path, found])
	elif found == 0:
		print("[CLEAN] %s" % path)
	root.queue_free()

func _scan_node(node: Node, path: String) -> int:
	var count := 0
	if node is TileMapLayer:
		var layer := node as TileMapLayer
		for cell_pos in layer.get_used_cells():
			var atlas := layer.get_cell_atlas_coords(cell_pos)
			if atlas.x >= 57:
				var verb := "ERASE" if not DRY_RUN else "WOULD ERASE"
				print("  [%s] %s | node=%s | cell=%s | atlas=%s" % [
					verb, path, layer.get_path(), cell_pos, atlas
				])
				if not DRY_RUN:
					layer.erase_cell(cell_pos)
				count += 1
	for child in node.get_children():
		count += _scan_node(child, path)
	return count
```

- [ ] **Step 2: Close all area scenes in the Godot editor**

In Godot, go to Scene → Recent Scenes and close any open area scene tab (cantina, workshop, etc.) to prevent save conflicts with the script.

---

### Task 2: Run in dry-run mode to confirm scope

**Files:**
- Read: `tools/fix_oob_tiles.gd`

- [ ] **Step 1: Open the script in Godot and run it**

In Godot editor:
1. Open `tools/fix_oob_tiles.gd` in the Script tab
2. Verify `DRY_RUN := true` at the top
3. Click **File → Run** (or press Ctrl+Shift+X)

Expected Output panel output — example (actual cell positions will vary):
```
=== fix_oob_tiles — DRY_RUN=true ===
[CLEAN] res://scenes/areas/cantina.tscn
  [WOULD ERASE] res://scenes/areas/workshop.tscn | node=TileMapLayer | cell=Vector2i(3, 5) | atlas=Vector2i(57, 2)
[CLEAN] res://scenes/areas/security_post.tscn
...
=== done ===
```

If every scene prints `[CLEAN]`, there are no placed cells using out-of-bounds tiles — skip Task 3 (no scene edits needed) and proceed to Task 4.

- [ ] **Step 2: Note which scenes (if any) report `WOULD ERASE` lines**

These are the scenes the fix script will modify in Task 3.

---

### Task 3: Erase out-of-bounds cells in all area scenes

Skip this task if dry-run in Task 2 showed no `WOULD ERASE` lines.

**Files:**
- Modify: `tools/fix_oob_tiles.gd`
- Modify (via script): any `scenes/areas/*.tscn` files reported in Task 2

- [ ] **Step 1: Set `DRY_RUN := false` in the script**

```gdscript
# change line 6:
const DRY_RUN := false
```

- [ ] **Step 2: Run the script again**

In Godot: Script tab → File → Run

Expected Output panel output:
```
=== fix_oob_tiles — DRY_RUN=false ===
[CLEAN] res://scenes/areas/cantina.tscn
  [ERASE] res://scenes/areas/workshop.tscn | node=TileMapLayer | cell=Vector2i(3, 5) | atlas=Vector2i(57, 2)
[SAVED] res://scenes/areas/workshop.tscn (1 cells removed)
...
=== done ===
```

Every scene must end with either `[CLEAN]` or `[SAVED]`. If any scene throws an error, read the Output panel and check that the scene was closed before running.

- [ ] **Step 3: Revert `DRY_RUN` back to true**

```gdscript
const DRY_RUN := true
```

This prevents accidentally re-running the fix.

---

### Task 4: Remove invalid tile definitions from station.tres

**Files:**
- Modify: `data/tilesets/station.tres`

`station.tres` has 96 lines of the form `57:N/0 = 0`, `58:N/0 = 0`, `59:N/0 = 0` for rows 0–31. Strip them with PowerShell.

- [ ] **Step 1: Run the strip command in a terminal (not in Godot)**

```powershell
$path = "data/tilesets/station.tres"
$content = Get-Content $path
$filtered = $content | Where-Object { $_ -notmatch "^\s*(57|58|59):\d+/\d+ = " }
$filtered | Set-Content $path -Encoding UTF8
```

- [ ] **Step 2: Verify exactly 96 lines were removed**

```powershell
(Get-Content "data/tilesets/station.tres").Count
```

Expected: original line count (1924) minus 96 = **1828 lines**.

If the count doesn't match, check the regex. The pattern `^\s*(57|58|59):\d+/\d+ = ` should match only those three column numbers in the atlas source. Column numbers like `157:...` are NOT present in the file so there's no risk of over-matching — but verify if unexpected counts appear.

- [ ] **Step 3: Sanity-check the file still has the [resource] footer**

```powershell
Get-Content "data/tilesets/station.tres" | Select-Object -Last 5
```

Expected:
```
56:31/0 = 0

[resource]
physics_layer_0/collision_layer = 1
sources/0 = SubResource("TileSetAtlasSource_clk4h")
```

The last tile definition should be `56:31/0 = 0` with no 57/58/59 lines anywhere.

---

### Task 5: Verify — no startup errors remain

**Files:** none (read-only verification)

- [ ] **Step 1: Run the game headlessly and capture output**

```powershell
godot_console --headless --quit 2>&1 | Select-String "TileSetAtlasSource|ERROR|WARNING" | Select-Object -First 30
```

Expected: zero lines matching `TileSetAtlasSource has no tile at (5[789]`. Any remaining `TileSetAtlasSource` errors for columns 0–56 are pre-existing issues unrelated to this fix.

- [ ] **Step 2: Run the game in the editor and open each area**

Launch the game in the editor (F5). Navigate to each area (cantina, workshop, security_post, med_bay, quarters, derelict_entrance) and confirm no blank/invisible tile cells where doors might have been. The visual result for MVP is acceptable — if door graphics are missing, that's a follow-up art task.

- [ ] **Step 3: Re-run the diagnostic script in dry-run mode to confirm no cells remain**

In Godot: open `tools/fix_oob_tiles.gd`, confirm `DRY_RUN := true`, run it.

Expected: all six scenes print `[CLEAN]`.

---

### Task 6: Commit

**Files:**
- `tools/fix_oob_tiles.gd`
- `data/tilesets/station.tres`
- Any modified `scenes/areas/*.tscn`

- [ ] **Step 1: Stage and commit**

```powershell
git add tools/fix_oob_tiles.gd data/tilesets/station.tres scenes/areas/
git commit -m "fix: remove out-of-bounds tile columns 57-59 from station.tres and area scenes

Columns 57-59 don't exist in roguelikeSheet_transparent.png (only 0-56 valid).
Stripped 96 phantom tile definitions from station.tres and erased any placed
cells in area scenes that referenced those atlas coordinates.

Closes #89"
```

---

## Self-Review

**Spec coverage:**
- ✅ Remove columns 57–59 definitions from station.tres → Task 4
- ✅ Identify and fix placed cells in area scenes → Tasks 1–3
- ✅ Verify no more startup errors → Task 5
- ✅ Commit → Task 6

**No placeholders:** All steps include exact commands, exact expected output, and exact code.

**Type consistency:** `TileMapLayer` API calls (`get_used_cells()`, `get_cell_atlas_coords()`, `erase_cell()`) are consistent across Tasks 1–3. `DRY_RUN` constant name is consistent.
