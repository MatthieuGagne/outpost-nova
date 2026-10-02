# Security Post 3D Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the 2D security post with a live 3D room on the #129 hybrid spine, hosting Quen as a production `Npc3D` with three bidirectional exits (cantina, med_bay, trade_dock).

**Architecture:** A hand-composed `scenes/areas3d/security_post.tscn` built from the PRD 4 kit, following the exact conventions `workshop.tscn` and `cantina.tscn` established: one `TileFloor`, one `TileCollision` with `border_for_floor`, far walls at full height / near sides as 0.5-unit parapets, one `DirectionalLight3D` + one `WorldEnvironment`, an instanced `room_camera.tscn`, `ExitDoor` triggers over the first walkable tile row, and `EntryFrom<PascalCase>` markers as direct children of the room root. The room is the simplest migration yet: no `Plot3D`, no interactable — only the room shell, three exits, and Quen, exercising the established `Npc3D` + seam patterns and nothing new (issue R1–R4).

**Tech Stack:** Godot 4.7.1 (mono), GDScript, Mobile renderer, GUT for tests, YarnSpinner (C#) for dialogue.

## Open questions (must resolve before starting)

1. **Quen's sprite art.** Quen has no bespoke 3D sprite. `scenes/poc3d/npc3d.tscn` hardcodes `data/sprites/npc_frames.tres` (the Maris atlas), and **every** existing 3D NPC — Maris (cantina), Dex (workshop), Sable (trade_dock) — uses that same atlas with **no** `sprite_frames` override. The bespoke `dex.png`/`sable.png` in `assets/sprites/characters/` are not yet wired into any `.tres` for 3D. **Recommendation: reuse `npc_frames.tres` with no override** — full parity with Dex and Sable. A bespoke Quen atlas is a future art task, not part of this migration.
2. **Quen's portrait.** `NPC_PORTRAIT_INDEX` in `scripts/ui/dialogue_box.gd` is `{"Maris": 0, "Dex": 1, "Sable": 2}`; `FALLBACK_PORTRAIT_INDEX = 3`. There is no Quen portrait anywhere in `portrait_sheet.png` (indices 0–9 are generic placeholder art). Talking to Quen already renders the fallback portrait (index 3) in the 2D game. **Recommendation: make no portrait change** — `dialogue_node = "Quen"` resolves the portrait via the Yarn speaker name to the fallback, exactly as in 2D. A bespoke Quen portrait (plus a `"Quen"` key in `NPC_PORTRAIT_INDEX`) is a separate art task.

Both are "reuse the placeholder" decisions that match the current state of the other 3D NPCs. If you want bespoke Quen art, say so now and it becomes its own follow-up issue — it is not part of this migration's scope.

---

## Reference: room geometry (single source of truth for all numbers below)

Every literal in the scene tasks derives from these. Do not hand-place a number that is not on this list.

| Quantity | Value | Derivation |
|---|---|---|
| Floor tiles | `Vector2i(14, 10)` | Same as trade_dock and workshop; hosts 3 exits + Quen |
| Floor tile source | `tile_col = 7`, `tile_row = 0` | Distinct from trade_dock `(5,0)`, workshop `(6,0)`, cantina `(8,2)`; **verify by eye at Smoketest 1 — if `(7,0)` reads poorly pick any distinct tile from the shared sheet, no new PNG** |
| Walkable world extent | X ∈ [-7, 7], Z ∈ [-5, 5] | `TileFloor` centres the floor on the origin |
| Border ring tiles | x = -8 and 7; z = -6 and 5 | `TileCollision.border_tiles(Vector2i(14,10))` |
| Far wall lines (full height) | West X = -7.5, North Z = -5.5 | Wall mesh is 1 unit wide → occupies exactly the border tile |
| Near parapet lines (0.5 high) | East X = 7.5, South Z = 5.5 | Camera looks from +X/+Z; full walls there would occlude the interior |
| Exit trigger centres | 0.5 units inside the floor edge | `exit_door.tscn` box is `(2, 3, 1)` → covers the **first walkable tile row**, not the solid border row |
| Entry marker offset | 2 units inside the floor edge | Clear of the exit trigger box, so arriving does not instantly re-fire the door |
| Camera position | `(9, 9, 9)` | Same as workshop (also 14×10); **framing verified by eye at Smoketest 1** |

Door layout mirrors the 2D room (cantina west, med_bay east, trade_dock south, no north door):

| Door | Wall | Side | Treatment |
|---|---|---|---|
| Cantina | West | far | full-height wall + `doorframe.tscn`, yaw 90° |
| MedBay | East | near | 4-unit gap in the parapet, **no** doorframe |
| TradeDock | South | near | 4-unit gap in the parapet, **no** doorframe |

---

## Batch 1 — the 3D security post is walkable in and out of all three doors

### Task 1: Security post room shell (floor, walls, parapets, collision, light, camera)

**Files:**
- Create: `scenes/areas3d/security_post.tscn`

**Depends on:** none
**Parallelizable with:** none — every later scene task edits this same file, and it must exist first.

**Step 1: Write the content**

Create `scenes/areas3d/security_post.tscn` with root `SecurityPost` (Node3D, **no script yet** — Task 2 adds it). Author it in the Godot editor or by hand; the tree must be exactly:

```
SecurityPost                  Node3D
├── Floor                      MeshInstance3D  script = res://scripts/world3d/tile_floor.gd
│                              tiles = Vector2i(14, 10); tile_col = 7; tile_row = 0
├── Walls                      Node3D
│   ├── WestWall               Node3D                  (cantina side, full height)
│   │   ├── Seg0..Seg5         kit/wall_segment.tscn instances at
│   │   │                      (-7.5, 1.5, z) for z in [-4.5, -3.5, -2.5, 2.5, 3.5, 4.5]
│   │   └── CantinaDoorframe   kit/doorframe.tscn @ (-7.5, 0, 0), rotation_degrees = (0, 90, 0)
│   ├── NorthWall              Node3D                  (no door, full height)
│   │   └── Seg0..Seg13        kit/wall_segment.tscn instances at
│   │                          (x, 1.5, -5.5) for x in [-6.5, -5.5, -4.5, -3.5, -2.5, -1.5, -0.5,
│   │                                                       0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5]
│   ├── EastParapetNorth       MeshInstance3D  BoxMesh(1, 0.5, 3)  @ (7.5, 0.25, -3.5)
│   ├── EastParapetSouth       MeshInstance3D  BoxMesh(1, 0.5, 3)  @ (7.5, 0.25,  3.5)
│   ├── SouthParapetWest       MeshInstance3D  BoxMesh(5, 0.5, 1)  @ (-4.5, 0.25, 5.5)
│   └── SouthParapetEast       MeshInstance3D  BoxMesh(5, 0.5, 1)  @ ( 4.5, 0.25, 5.5)
├── Props                      Node3D
│   ├── Console                kit/console.tscn @ ( 6.5, 0.5, -4)
│   ├── CrateA                 kit/crate.tscn   @ (-6.5, 0.5, -4.5)
│   ├── CrateB                 kit/crate.tscn   @ (-6.5, 0.5, -3.5)
│   ├── Table                  kit/table.tscn   @ ( 3,   0.5, -3.5)
│   └── Pipe                   kit/pipe.tscn    @ (-6.5, 1.5,  4.5)
├── Collision                  Node3D  script = res://scripts/world3d/tile_collision.gd
├── Sun                        DirectionalLight3D  rotation_degrees = (-50, -40, 0), shadow_enabled = true
├── Env                        WorldEnvironment
└── RoomCamera                 scenes/poc3d/room_camera.tscn instance @ (9, 9, 9)
```

Kit scenes are at `res://scenes/poc3d/kit/{wall_segment,doorframe,console,crate,table,pipe}.tscn`.

The parapet gaps are deliberate: East leaves Z ∈ [-2, 2] open for the med_bay door, South leaves X ∈ [-2, 2] open for the trade_dock door. The West wall's segment gap (z ∈ [-2, 2]) is filled by `CantinaDoorframe`, and the North wall has no gap.

`Collision` properties:

```
blocked = Array[Vector2i]([
    Vector2i( 6, -5), Vector2i( 6, -4),   # Console — X[ 6, 7], Z[-5,-4]
    Vector2i(-7, -5),                     # CrateA  — X[-7,-6], Z[-5,-4]
    Vector2i(-7, -4),                     # CrateB  — X[-7,-6], Z[-4,-3]
    Vector2i( 2, -4), Vector2i( 3, -4),   # Table   — X[ 2, 4], Z[-4,-3]
    Vector2i(-7,  4),                     # Pipe    — X[-7,-6], Z[ 4, 5]
])
border_for_floor = Vector2i(14, 10)
```

The four parapet `MeshInstance3D` nodes each need a `material_override`. Copy the grey `StandardMaterial3D` sub-resource verbatim from `scenes/areas3d/workshop.tscn`'s `EastParapetNorth` (it sets `texture_filter = 0` and `albedo_color = (0.298, 0.318, 0.349)`), and reuse the single sub-resource across all four.

`Env` needs an `Environment` copied verbatim from workshop's `Env`: `background_mode = 1` (colour) with colour `(0.102, 0.114, 0.141)`, `ambient_light_source = 2`, ambient colour white, ambient energy `0.3`.

**Step 2: Verify**

Open the scene in the editor:

```powershell
./tools/godot.ps1
```

Confirm by eye: the floor is a 14×10 grid, the west wall is unbroken except for one 4-unit doorframe, the north wall is fully solid, the east and south parapets each have a 4-unit gap centred on the room axis, and the camera framing holds the whole floor with a little margin. Adjust **only** `RoomCamera.position` if the framing is off — never its rotation (the camera contract owns the angle; `room_camera.gd` overwrites rotation on load).

**Step 3: Commit**

```powershell
git add scenes/areas3d/security_post.tscn
git commit -m "feat: add 3D security post room shell"
```

---

### Task 2: Security post exits, entry markers, and room script

**Files:**
- Modify: `scenes/areas3d/security_post.tscn`
- Create: `scripts/areas3d/security_post.gd`
- Test: `tests/test_security_post3d.gd`

**Depends on:** Task 1
**Parallelizable with:** Task 3 — Task 3 touches only `scripts/main.gd` and its own test; no shared file, no shared symbol.

**Step 1: Write the failing GUT test**

```gdscript
# tests/test_security_post3d.gd
extends GutTest

## Seam test for the 3D security post (issue #132 R1/R3).

const SECURITY_POST_3D := "res://scenes/areas3d/security_post.tscn"

const EXPECTED_EXITS := {
	"CantinaExit":   "cantina",
	"MedBayExit":    "med_bay",
	"TradeDockExit": "trade_dock",
}

const EXPECTED_MARKERS := [
	"EntryFromCantina",
	"EntryFromMedBay",
	"EntryFromTradeDock",
	"DefaultSpawn",
]

func before_each():
	GameState.reset()
	ClockManager.reset()

func _room() -> Node3D:
	var room = load(SECURITY_POST_3D).instantiate()
	add_child_autofree(room)
	return room

func test_room_authors_an_exit_for_every_neighbour():
	var room := _room()
	for exit_name in EXPECTED_EXITS:
		var door = room.find_child(exit_name, false, false)
		assert_not_null(door, "3D security_post missing exit '%s'" % exit_name)
		assert_eq(door.destination_id, EXPECTED_EXITS[exit_name],
			"exit '%s' points at the wrong area" % exit_name)

func test_room_authors_entry_markers_as_direct_children():
	# main._find_3d_entry_marker searches non-recursively, so nesting a marker breaks spawning.
	var room := _room()
	for marker in EXPECTED_MARKERS:
		assert_not_null(room.find_child(marker, false, false),
			"3D security_post missing root-level marker '%s'" % marker)

func test_entry_markers_sit_inside_the_walkable_floor():
	# Floor is 14x10 centred on the origin: X in [-7,7], Z in [-5,5].
	var room := _room()
	for marker in EXPECTED_MARKERS:
		var node: Node3D = room.find_child(marker, false, false)
		assert_between(node.position.x, -7.0, 7.0, "%s is outside the floor in X" % marker)
		assert_between(node.position.z, -5.0, 5.0, "%s is outside the floor in Z" % marker)

func test_exits_forward_to_the_main_area_router():
	var room := _room()
	assert_true(room.has_method("_on_exit_triggered"),
		"security_post.gd must forward ExitDoor.triggered to Main.go_to_area")
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_security_post3d.gd" -gexit
```
Expected: FAIL — the exits, markers, and script do not exist yet.

**Step 3: Write minimal implementation**

Add to `scenes/areas3d/security_post.tscn`, all as **direct children of the root** (`_find_3d_entry_marker` searches non-recursively):

| Node | Type | Position | Rotation | Property |
|---|---|---|---|---|
| `CantinaExit` | `scenes/poc3d/exit_door.tscn` | `(-6.5, 1, 0)` | `(0, 90, 0)` | `destination_id = "cantina"` |
| `MedBayExit` | `scenes/poc3d/exit_door.tscn` | `(6.5, 1, 0)` | `(0, 90, 0)` | `destination_id = "med_bay"` |
| `TradeDockExit` | `scenes/poc3d/exit_door.tscn` | `(0, 1, 4.5)` | — | `destination_id = "trade_dock"` |
| `EntryFromCantina` | `Marker3D` | `(-5, 0, 0)` | — | — |
| `EntryFromMedBay` | `Marker3D` | `(5, 0, 0)` | — | — |
| `EntryFromTradeDock` | `Marker3D` | `(0, 0, 3)` | — | — |
| `DefaultSpawn` | `Marker3D` | `(0, 0, 0)` | — | — |

The `exit_door.tscn` collision box is `(2, 3, 1)` — 2 units wide in local X, 1 deep in local Z. The 90° yaw on the west/east doors turns that 2-unit span along Z so it spans the doorway rather than the wall. Each trigger centre sits 0.5 units inside the floor edge so its box covers the **first walkable tile row**; the border collision ring stays solid across the doorway and stops the player at the threshold, exactly as `exit_door.gd`'s doc comment describes.

Set the root's script to `res://scripts/areas3d/security_post.gd` and create it:

```gdscript
# scripts/areas3d/security_post.gd
extends Node3D

## The 3D security post (issue #132). Mirrors scripts/areas3d/workshop.gd: the room owns
## its door wiring and reaches /root/Main directly to request the area change.
##
## Quen is hosted in-scene as an Npc3D and is not flag-gated, so this is the plain
## workshop.gd shape — not trade_dock.gd's, which gates Sable behind sable_arrived.

const EXIT_NODES := ["CantinaExit", "MedBayExit", "TradeDockExit"]


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for exit_name in EXIT_NODES:
		var door := get_node_or_null(exit_name) as ExitDoor
		if door == null:
			push_error("security_post: missing exit '%s'" % exit_name)
			continue
		door.triggered.connect(_on_exit_triggered)


func _on_exit_triggered(destination_id: String) -> void:
	get_tree().get_root().get_node("Main").go_to_area(destination_id)
```

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_security_post3d.gd" -gexit
```
Expected: PASS, 4 tests.

If it reports `Identifier "ExitDoor" not declared`, the class cache is stale — rebuild and re-run:
```powershell
./tools/godot.ps1 -Console --headless --path . --editor --quit
```

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" The exit list is a named constant and the handler is destination-agnostic, so a fourth door is one array entry plus one scene node. If you instead wrote three `$XExit.triggered.connect(...)` lines, fix it now.

**Step 6: Commit**

```powershell
git add scenes/areas3d/security_post.tscn scripts/areas3d/security_post.gd tests/test_security_post3d.gd
git commit -m "feat: wire 3D security post exits and entry markers"
```

---

### Task 3: Flip the area registry to the 3D security post

**Files:**
- Modify: `scripts/main.gd`
- Modify: `tools/generate_rooms.gd`
- Test: `tests/test_security_post_registry.gd`

**Depends on:** Task 1 — the registry must not point at a scene that does not exist.
**Parallelizable with:** Task 2 — disjoint files (`scripts/main.gd` / `tools/generate_rooms.gd` vs the security_post scene/script) and no shared symbols.

**Step 1: Write the failing GUT test**

```gdscript
# tests/test_security_post_registry.gd
extends GutTest

## Guards the registry flip for issue #132 R4.

func _main_script():
	return load("res://scripts/main.gd")

func test_security_post_is_registered_as_a_3d_area():
	var entry: Dictionary = _main_script().AREA_SCENES["security_post"]
	assert_eq(entry["presentation"], "3d", "security_post must be dispatched through _enter_3d")
	assert_eq(entry["scene"], "res://scenes/areas3d/security_post.tscn")

func test_security_post_has_no_2d_entry_position_block():
	# 3D rooms spawn from EntryFrom* markers, never from AREA_ENTRY_POSITIONS.
	assert_false(_main_script().AREA_ENTRY_POSITIONS.has("security_post"),
		"the 2D entry-position block for security_post must be removed")

func test_surviving_2d_neighbours_keep_their_security_post_entry_positions():
	# This describes arrival INTO 2D med_bay FROM security_post, so it stays.
	var positions: Dictionary = _main_script().AREA_ENTRY_POSITIONS
	assert_true(positions["med_bay"].has("security_post"),
		"2D med_bay lost its security_post entry position")

func test_quen_is_no_longer_a_2d_roster_npc():
	# The 3D security post hosts Quen in-scene as an Npc3D, like the cantina hosts Maris.
	assert_false(_main_script().NPC_SPAWN_AREAS.has("quen"),
		"quen must be dropped from the 2D NPC roster")
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_security_post_registry.gd" -gexit
```
Expected: FAIL on all four.

**Step 3: Write minimal implementation**

In `scripts/main.gd`:

(a) Flip the registry entry:
```gdscript
	"security_post":     {"scene": "res://scenes/areas3d/security_post.tscn", "presentation": "3d"},
```

(b) Drop Quen from `NPC_SPAWN_AREAS` (leaving only velreth):
```gdscript
const NPC_SPAWN_AREAS = {
	"velreth": "med_bay",
}
```

(c) Drop Quen from the `npc_scripts` dict in `_spawn_npcs()`:
```gdscript
	var npc_scripts = {
		"velreth": "res://scripts/characters/velreth.gd",
	}
```

(d) Delete the whole `"security_post": { ... }` block from `AREA_ENTRY_POSITIONS`. Leave the `"security_post"` **key inside** `med_bay` untouched — it describes arrival into 2D med_bay from security_post and stays valid.

In `tools/generate_rooms.gd`:

(e) Delete the entire Security Post `_process_area(...)` block (the one opening `"res://scenes/areas/security_post.tscn"` with the `{CantinaDoor, MedBayDoor, TradeDockDoor}` key map). Per the README's "Migrating deletes the generator entry too" rule, the generator crashes on a deleted scene path. Do **not** touch the `"SecurityPostDoor"` key inside the still-2D `med_bay` block — that names a door leading into the migrated area, not a reference to the deleted scene (see the README's "Generator node keys are not stale references" rule).

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_security_post_registry.gd" -gexit
```
Expected: PASS, 4 tests.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" Migrating the next room (med_bay, M5) should be exactly steps (a), (b), (c), (d) again. If you had to touch `_enter_3d` or `_find_3d_entry_marker` to make security_post work, the spine is leaking room-specific knowledge — stop and report before continuing.

**Step 6: Commit**

```powershell
git add scripts/main.gd tools/generate_rooms.gd tests/test_security_post_registry.gd
git commit -m "feat: dispatch security post through the 3D presentation path"
```

---

### Task 4: Delete the 2D security post and update the hybrid seam test

**Files:**
- Delete: `scenes/areas/security_post.tscn`, `scripts/areas/security_post.gd`, `scripts/areas/security_post.gd.uid`
- Modify: `tests/test_hybrid_structure.gd`
- Modify: `tests/test_cantina_registry.gd` — **executor correction (not in the original plan):** `test_surviving_2d_neighbours_keep_their_cantina_entry_positions` iterates `["quarters", "security_post"]`; once Task 3 deletes the `security_post` entry-position block, that loop indexes a deleted dict block and errors. Narrow it to `["quarters"]` alongside the `test_hybrid_structure.gd` edit below.

**Depends on:** Task 3 — the registry must stop referencing the files before they are deleted.
**Parallelizable with:** none — it deletes files Task 3's registry flip is the precondition for, and its test edit asserts state Task 3 creates.

**Step 1: Write the failing GUT test**

Add to `tests/test_hybrid_structure.gd`, mirroring the existing `test_2d_workshop_files_are_gone`:

```gdscript
func test_2d_security_post_files_are_gone():
	assert_false(ResourceLoader.exists("res://scenes/areas/security_post.tscn"), "2D security_post scene must be deleted")
	assert_false(ResourceLoader.exists("res://scripts/areas/security_post.gd"), "2D security_post script must be deleted")
```

And delete `test_2d_neighbours_keep_entry_positions_keyed_by_trade_dock` in the same file. Its loop `["security_post"]` becomes empty once security_post migrates — and it is the **last** 2D area reachable from trade_dock, so there is no list left to loop over. (`derelict_entrance` still has a `"trade_dock"` entry position, but it is deliberately excluded: trade_dock has no `ExitDoor` pointing at it yet — derelict_entrance is a one-way neighbour whose presentation is deferred per epic #100 — so its entry position is unreachable. Do not add it to the list; delete the test instead of leaving a vacuous empty loop.)

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_hybrid_structure.gd" -gexit
```
Expected: FAIL on `test_2d_security_post_files_are_gone` (the files still exist).

**Step 3: Write minimal implementation**

```powershell
git rm scenes/areas/security_post.tscn scripts/areas/security_post.gd
git rm --ignore-unmatch scripts/areas/security_post.gd.uid
```

There is no `scenes/areas/security_post.tscn.uid` — the scene is `format=4` with an embedded uid.

Then confirm nothing still loads them. The surviving hits must be only: the 3D room, the neighbour rooms' `go_to_area("security_post")` calls, `cantina.tscn`'s and `trade_dock.tscn`'s `SecurityPostExit`/`EntryFromSecurityPost`, `med_bay.gd`/`med_bay.tscn`'s `SecurityPostDoor`, the legacy `data/maps/trade_dock.tmx`, tests, and docs.

```powershell
Get-ChildItem -Recurse -Include *.gd,*.tscn,*.cs -Path scripts,scenes,tests |
  Select-String -Pattern "areas/security_post"
```
Expected: **no output.**

Note: this migration leaves `scripts/characters/quen.gd` orphaned (its only loader was the 2D roster dropped in Task 3). Per the established convention — see issue #142, which batches `maris.gd` and `dex.gd` for a one-shot M6 sweep — **do not delete `quen.gd` here**. Add `quen.gd` to #142's scope (a one-line edit to that issue's body) so it is swept with the others.

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_hybrid_structure.gd" -gexit
```
Expected: PASS (one more test than before, minus the deleted one — net unchanged).

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" Not applicable — this is a deletion plus a test-list shrink. Confirm the deletion was complete and no `.uid` orphan was left behind.

**Step 6: Commit**

```powershell
git add -A scenes/areas scripts/areas tests/test_hybrid_structure.gd
git commit -m "feat: delete the 2D security post and update the hybrid seam test"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 1 | Creates `scenes/areas3d/security_post.tscn`, which Task 2 edits |
| B (parallel) | Task 2, Task 3 | Disjoint files: security_post scene/script vs `scripts/main.gd` + `tools/generate_rooms.gd`; no shared symbols |
| C (sequential) | Task 4 | Depends on Task 3's registry flip and edits the shared hybrid seam test |

### Smoketest Checkpoint 1 — all three security post doors walk in both directions

**Step 1: Fetch and merge latest master**
```powershell
git fetch origin; git merge origin/master
```

**Step 2: Run all GUT tests**
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit 2>&1 |
  Select-String -Pattern "SCRIPT ERROR|Failing Tests|Passing Tests|Scripts "
```
Expected: zero failures, zero `SCRIPT ERROR` lines. **Record the `Scripts` and `Tests` counts** — the "All tests passed" banner also prints when a test file failed to parse and was silently skipped, so the counts are the real signal. The `Scripts` count must be the pre-existing total plus 2 new scripts (`test_security_post3d.gd`, `test_security_post_registry.gd`).

**Step 3: Build and launch the game**
```powershell
dotnet build "Outpost Nova.csproj"
./tools/godot.ps1 --path .
```

**Step 4: Confirm with user**

Ask the user to verify in the running game:
- The security post renders in 3D (kit walls, floor) with the whole room in frame and no wall occluding the interior. If framing is off, adjust only `RoomCamera.position` in the scene.
- Walking into each of the three doorways transitions with a fade: **west → cantina, east → med_bay, south → trade_dock.**
- Coming back through each neighbour's door lands the player just inside the correct doorway — not in a wall, not instantly re-triggering the door they arrived through.
- cantina ↔ security_post and trade_dock ↔ security_post work (3D↔3D), and med_bay ↔ security_post works (2D↔3D).
- No `push_error` output about a missing `EntryFrom...` or `DefaultSpawn` marker.
- Quen is **absent** for now — its 2D roster entry is gone and its 3D placement lands in Batch 2. That is expected; do not flag it.

Wait for confirmation before starting Batch 2.

---

## Batch 2 — Quen is live in the room

### Task 5: Place Quen as a production `Npc3D`

**Files:**
- Modify: `scenes/areas3d/security_post.tscn`
- Test: `tests/test_security_post3d.gd`

**Depends on:** Task 1 (the scene exists)
**Parallelizable with:** none — the only remaining task in this batch; Task 6 depends on it.

**Step 1: Write the failing GUT test**

Append to `tests/test_security_post3d.gd`:

```gdscript
func test_room_hosts_quen_as_a_production_npc3d():
	var room := _room()
	var quen = room.find_child("Quen", false, false)
	assert_not_null(quen, "3D security_post must host Quen in-scene, like the cantina hosts Maris")
	assert_true(quen is Npc3D, "Quen must be an Npc3D instance")
	assert_eq(quen.dialogue_node, "Quen", "Quen must point at the 'Quen' Yarn node")

func test_quen_wander_box_stays_inside_the_walkable_floor():
	var room := _room()
	var quen: Npc3D = room.find_child("Quen", false, false)
	var half := quen.wander_half_extents
	assert_between(quen.position.x - half.x, -7.0, 7.0, "Quen can wander out of the floor in -X")
	assert_between(quen.position.x + half.x, -7.0, 7.0, "Quen can wander out of the floor in +X")
	assert_between(quen.position.z - half.y, -5.0, 5.0, "Quen can wander out of the floor in -Z")
	assert_between(quen.position.z + half.y, -5.0, 5.0, "Quen can wander out of the floor in +Z")
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_security_post3d.gd" -gexit
```
Expected: FAIL on the two new tests.

**Step 3: Write minimal implementation**

Add one direct child of the `SecurityPost` root in `scenes/areas3d/security_post.tscn`:

| Node | Instance of | Position | Properties |
|---|---|---|---|
| `Quen` | `scenes/poc3d/npc3d.tscn` | `(2.5, 0, 1)` | `dialogue_node = "Quen"`, `wander_half_extents = Vector2(2, 2)` |

Notes:
- **No `sprite_frames` override** — `npc3d.tscn` defaults to `data/sprites/npc_frames.tres`, the same atlas Maris, Dex, and Sable all use. Quen reusing it is full parity with the other 3D NPCs (see Open Question 1).
- **No portrait change** — `dialogue_box.gd` keys portraits off the Yarn *speaker* name, so `dialogue_node = "Quen"` resolves the portrait to `FALLBACK_PORTRAIT_INDEX` (3), exactly as the 2D game already does (see Open Question 2).
- `(2.5, 0, 1)` is the centre of tile `(2, 1)`: walkable, clear of every blocked prop tile and of all three exit trigger boxes.
- Quen's wander box is `X ∈ [0.5, 4.5]`, `Z ∈ [-1, 3]` — clear of the Table's blocked tiles at `X ∈ [2, 4]`, `Z ∈ [-4, -3]` and of the three doors.

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_security_post3d.gd" -gexit
```
Expected: PASS, 6 tests.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" A second NPC in this room should be one more `npc3d.tscn` instance with a different `dialogue_node` and position — nothing in `security_post.gd` should need to know about NPCs at all. If you added NPC wiring to `security_post.gd`, remove it: `Npc3D` is self-contained by design.

**Step 6: Commit**

```powershell
git add scenes/areas3d/security_post.tscn tests/test_security_post3d.gd
git commit -m "feat: place Quen in the 3D security post"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 5 | Only task in the batch; edits the room scene Task 1 created |

### Smoketest Checkpoint 2 — Quen dialogue behaves exactly as it did in 2D

**Step 1: Fetch and merge latest master**
```powershell
git fetch origin; git merge origin/master
```

**Step 2: Run all GUT tests**
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit 2>&1 |
  Select-String -Pattern "SCRIPT ERROR|Failing Tests|Passing Tests|Scripts "
```
Expected: zero failures, zero `SCRIPT ERROR` lines, and the same `Scripts` count as Checkpoint 1 (Task 5 appends tests to an existing file, adds no new file).

**Step 3: Build and launch the game**
```powershell
dotnet build "Outpost Nova.csproj"
./tools/godot.ps1 --path .
```

**Step 4: Confirm with user**

Ask the user to verify in the running game, standing in the security post:

- Quen wanders around its corner and stays on the floor — never inside a prop or a wall.
- Interacting starts a real YarnSpinner conversation. The first meeting plays `Quen_FirstMeeting`; after `met_quen` is set, a second interaction plays `Quen_Casual`.
- The portrait shown is the fallback portrait (the same one Quen has always shown in 2D) — not a crash, not a missing texture.
- Quen stops moving for the whole conversation and resumes after.
- Ending the conversation advances the clock by exactly **30 minutes, once** — not twice, not per line.

Wait for confirmation before starting Batch 3.

---

## Batch 3 — documentation and verification sweep

### Task 6: Record the placeholder-art Npc3D convention in the README

**Files:**
- Modify: `scenes/poc3d/README.md`

**Depends on:** Task 5
**Parallelizable with:** Task 7's README-independent steps — but Task 7's full-suite sweep must run last, so keep Task 7 sequential after Task 6.

**Step 1: Write the content**

`scenes/poc3d/README.md` is the de-facto 3D reference. Add a short subsection under a new `## Production rooms: what the security post added (#132)` heading, recording the one genuinely new rule so the next migration (med_bay → Velreth, M5) does not re-derive it:

- An `Npc3D` whose character has no bespoke 3D art needs **no special handling**: it reuses the shared `data/sprites/npc_frames.tres` atlas (no `sprite_frames` override) and its portrait resolves via the Yarn speaker name to `FALLBACK_PORTRAIT_INDEX` when the name is absent from `NPC_PORTRAIT_INDEX`. Quen is the first such NPC; Maris/Dex/Sable were authored before this was explicit. Bespoke art (sprite atlas + portrait index) is a separate follow-up, not part of a room migration.
- A room with three doors (one far + two near) is just the cantina's four-door layout minus the north doorframe — no new rule; the far wall gets `doorframe.tscn` (yaw 90° on a Z-running wall) and each near side gets a 4-unit parapet gap with **no** doorframe.

Do **not** add a line to `docs/index.md` — that index catalogs design/story/world docs, and neither this README nor `docs/plans/` entries are listed there.

**Step 2: Verify**

Read the edited section back and confirm the placeholder-art bullet states a rule the next migration would otherwise have to rediscover, and the three-door bullet does not restate what `cantina.tscn` already demonstrates.

**Step 3: Commit**

```powershell
git add scenes/poc3d/README.md
git commit -m "docs: record the placeholder-art Npc3D convention (README)"
```

---

### Task 7: Full-suite verification and stale-reference sweep (AC3)

**Files:**
- Modify: whatever the sweep turns up (expected: nothing)

**Depends on:** Task 4, Task 5 — the sweep asserts the final state of the tree.
**Parallelizable with:** none — it greps the whole tree for `security_post` and must run last.

**Step 1: Write the content**

Run the full suite in the form that surfaces parse errors the "All tests passed" banner swallows, and record the counts:

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit 2>&1 |
  Select-String -Pattern "SCRIPT ERROR|Failing Tests|Passing Tests|Scripts "
```

Then sweep for references to the deleted 2D security post across code, scenes, and tests:

```powershell
Get-ChildItem -Recurse -Include *.gd,*.tscn,*.cs,*.tres -Path scripts,scenes,tests,data |
  Select-String -Pattern "areas/security_post"
```

And confirm every surviving `security_post` mention is intentional:

```powershell
Get-ChildItem -Recurse -Include *.gd,*.tscn -Path scripts,scenes,tests |
  Select-String -Pattern "security_post" -CaseSensitive:$false
```

**Step 2: Verify**

- The suite reports **zero failures** and **zero `SCRIPT ERROR` lines**.
- The `Scripts` count equals the pre-#132 total **plus 2** (`test_security_post3d.gd`, `test_security_post_registry.gd`). A count that did not rise by 2 means a test file failed to parse and was silently skipped — investigate before proceeding, do not trust the banner.
- The `areas/security_post` sweep returns **no output**.
- Every hit in the broad sweep is one of: `scripts/areas3d/security_post.gd`, `scenes/areas3d/security_post.tscn`, the neighbour rooms' `go_to_area("security_post")` calls, `cantina.tscn`'s / `trade_dock.tscn`'s `SecurityPostExit`/`EntryFromSecurityPost`, `med_bay.gd`/`med_bay.tscn`'s `SecurityPostDoor`, the legacy `data/maps/trade_dock.tmx`, `tools/generate_rooms.gd`'s `med_bay` `SecurityPostDoor` key, and the new and existing tests. Anything else is a real stale reference; fix it and re-run.

**Step 3: Commit**

Only if the sweep required a fix:
```powershell
git add -A
git commit -m "fix: clear stale references to the deleted 2D security post"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 3

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 6 | README edit |
| B (sequential) | Task 7 | Full-suite + sweep must run after every other task; asserts final tree state |

### Smoketest Checkpoint 3 — full acceptance pass

**Step 1: Fetch and merge latest master**
```powershell
git fetch origin; git merge origin/master
```

**Step 2: Run all GUT tests**
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit 2>&1 |
  Select-String -Pattern "SCRIPT ERROR|Failing Tests|Passing Tests|Scripts "
```
Expected: zero failures, zero `SCRIPT ERROR` lines, `Scripts` count = pre-#132 total + 2.

**Step 3: Build and launch the game**
```powershell
dotnet build "Outpost Nova.csproj"
./tools/godot.ps1 --path .
```

**Step 4: Confirm with user**

Walk the whole acceptance list end to end in one session:

- **AC1** — all three doors transition both ways with correct spawn positions, fade covering each swap (cantina and trade_dock 3D↔3D; med_bay 2D↔3D).
- **AC2** — Quen dialogue runs through real YarnSpinner with its (fallback) portrait, and conversation end commits 30 minutes exactly once.
- **AC3** — GUT green with the `Scripts` count checked (not the banner); no remaining references to the deleted 2D security post files.

Then take the branch through `finishing-a-development-branch`.
