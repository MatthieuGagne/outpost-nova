# Hybrid 3D Area Runner & trade_dock Pilot — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Productionize the proven 3D POC (epic #100) into the live game as a permanent hybrid 2D/3D area runner, and make `trade_dock` the first live 3D room — the game boots into 3D from day one.

**Architecture:** `main.tscn` gains a full-rect `World3D` `SubViewportContainer` (480×270 `SubViewport`, `render_target_update_mode = 4`) holding an `Area3D` spatial container with a persistent `Player3D` + the current 3D room, beside the existing 2D `AreaContainer`. `main.gd`'s `AREA_SCENES` becomes `{area_id: {scene, presentation}}`; `go_to_area()` branches on presentation and hard-swaps process-mode/visibility/velocity between the two players. 3D rooms author `Marker3D` spawns (`EntryFrom<Area>`/`DefaultSpawn`); 2D rooms keep `AREA_ENTRY_POSITIONS`. `Npc3D` becomes a wandering `CharacterBody3D` with real `DialogueRunner` dialogue and a one-shot 30-minute clock commit. `scripts/poc3d/` moves to `scripts/world3d/`; the 2D `trade_dock` is deleted and recreated in 3D from the kit.

**Tech Stack:** Godot 4.7.1 (mono), GDScript, Mobile renderer, GUT, YarnSpinner, kit meshes.

## Open questions (must resolve before starting)

None — the design question in the issue (`sable_arrived` gating, not writer) is resolved: gating is verified in both states; no writer ships.

## Commands (project convention)

```powershell
# Full GUT suite (read Scripts/Tests COUNT, never the banner)
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit 2>&1 |
  Select-String -Pattern "SCRIPT ERROR|Failing Tests|Passing Tests|Scripts "

# Single test script
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_X.gd" -gexit

# Rebuild class cache (after moving/adding class_name scripts)
./tools/godot.ps1 -Console --headless --path . --editor --quit

# Launch game / run POC
./tools/godot.ps1 --path .
./tools/godot.ps1 --path . "res://scenes/poc3d/poc_entry.tscn"
```

---

## Batch 1 — Foundation (move + pure helper)

### Task 1: Move `scripts/poc3d/` → `scripts/world3d/` and rename POC tests

**Files:**
- Move: `scripts/poc3d/*.gd` (14 files + `.uid` sidecars) → `scripts/world3d/`
- Modify (rewrite 14 `path=` refs in 8 files): `scenes/poc3d/poc_entry.tscn`, `player3d.tscn`, `npc3d.tscn`, `console.tscn`, `exit_door.tscn`, `room_camera.tscn`, `rooms/test_room.tscn`, `rooms/workshop.tscn`
- Rename: `tests/test_poc3d_*.gd` (10 files + `.uid`) → `tests/test_world3d_*.gd`

**Depends on:** none
**Parallelizable with:** none — every subsequent task references the new `scripts/world3d/` paths, so this is the foundation everything else builds on.

**Step 1: Run the move**

```powershell
git mv scripts/poc3d scripts/world3d

foreach ($f in Get-ChildItem tests -Filter 'test_poc3d_*') {
  $new = $f.Name -replace '^test_poc3d_', 'test_world3d_'
  git mv $f.FullName "tests/$new"
}

sd 'res://scripts/poc3d/' 'res://scripts/world3d/' `
  scenes/poc3d/poc_entry.tscn scenes/poc3d/player3d.tscn scenes/poc3d/npc3d.tscn `
  scenes/poc3d/console.tscn scenes/poc3d/exit_door.tscn scenes/poc3d/room_camera.tscn `
  scenes/poc3d/rooms/test_room.tscn scenes/poc3d/rooms/workshop.tscn
```

**Step 2: Rebuild class cache** — `./tools/godot.ps1 -Console --headless --path . --editor --quit`

**Step 3: Verify**

Run the full GUT suite. Expected: **zero failures, and the Scripts/Tests count is unchanged** from before the move (the rename must not silently drop files — see the stale-class-cache gotcha in CLAUDE.md). Then run the POC (`"res://scenes/poc3d/poc_entry.tscn"`) and confirm the test room still renders and walks.

**Step 4: Commit**

```powershell
git add -A
git commit -m "refactor: move poc3d scripts to world3d and rename tests"
```

---

### Task 2: Add `SpriteFacing.from_world` (pure inverse of `input_to_world`)

**Files:**
- Modify: `scripts/world3d/sprite_facing.gd`
- Test: `tests/test_world3d_sprite_facing.gd`

**Depends on:** Task 1
**Parallelizable with:** none — edits the file Task 1 moved.

**Step 1: Write the failing GUT test** (append to `tests/test_world3d_sprite_facing.gd`)

```gdscript
func test_from_world_maps_world_velocity_back_to_facing():
	# contract yaw 45°: screen-up walks (-sin45, 0, -cos45) = (-√½, 0, -√½)
	assert_eq(SpriteFacing.from_world(Vector3(-0.707, 0.0, -0.707), 45.0), "up")
	# screen-right walks (√½, 0, -√½)
	assert_eq(SpriteFacing.from_world(Vector3(0.707, 0.0, -0.707), 45.0), "right")
	# y is ignored — facing is XZ-only
	assert_eq(SpriteFacing.from_world(Vector3(-0.707, 99.0, -0.707), 45.0), "up")
	# zero velocity → no facing
	assert_eq(SpriteFacing.from_world(Vector3.ZERO, 45.0), SpriteFacing.NO_FACING)
```

**Step 2: Run to verify it fails** — `"-gtest=res://tests/test_world3d_sprite_facing.gd"` → FAIL (method not declared).

**Step 3: Implement** (in `sprite_facing.gd`, after `input_to_world`)

```gdscript
## Inverts input_to_world: rotates a world-space XZ velocity back into camera
## space, then resolves facing. For NPCs, whose velocity is already world-space.
static func from_world(world: Vector3, yaw_degrees: float) -> String:
	if world.length_squared() < 0.0001:
		return NO_FACING
	var yaw := deg_to_rad(yaw_degrees)
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	return from_input(Vector2(world.dot(right), -world.dot(forward)))
```

**Step 4: Run to verify it passes.**

**Step 5: Refactor checkpoint** — does `from_world` handle any yaw, or is it hard-coded to 45°? It takes `yaw_degrees` as a parameter (generalized). Proceed.

**Step 6: Commit** — `git commit -m "feat: add SpriteFacing.from_world for world-space NPC facing"`

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 1 → Task 2 | Task 2 edits the file Task 1 moved |

### Smoketest Checkpoint 1 — POC still boots, suite green

**Step 1:** `git fetch origin && git merge origin/master`
**Step 2:** Full GUT suite — all pass, Scripts/Tests count unchanged.
**Step 3:** Run the POC (`./tools/godot.ps1 --path . "res://scenes/poc3d/poc_entry.tscn"`) — test room renders, player walks camera-relative, NPC idle.
**Step 4:** Confirm with user, then proceed.

---

## Batch 2 — Components (parallelizable)

### Task 3: Productionize `Npc3D` (R6)

**Files:**
- Modify: `scripts/world3d/npc3d.gd`, `scenes/poc3d/npc3d.tscn`, `scenes/poc3d/rooms/test_room.tscn`
- Test: `tests/test_world3d_npc3d.gd` (rewrite), `tests/test_world3d_interaction.gd` (Npc3D sections)
- Create test helpers: `tests/helpers/dialogue_runner_stub.gd`, `tests/helpers/dialogue_box_stub.gd`

**Depends on:** Task 2 (`from_world`)
**Parallelizable with:** Task 4 — different output files, no shared state.

**Step 1: Write the failing GUT tests**

`tests/helpers/dialogue_runner_stub.gd`:
```gdscript
extends Node
var started_node := ""
func StartDialogueForget(node: String) -> void:
	started_node = node
```

`tests/helpers/dialogue_box_stub.gd`:
```gdscript
extends Node
signal conversation_ended
```

`tests/test_world3d_npc3d.gd` (full rewrite):
```gdscript
extends GutTest

const NPC_SCENE := "res://scenes/poc3d/npc3d.tscn"
const RUNNER_STUB := "res://tests/helpers/dialogue_runner_stub.gd"
const BOX_STUB := "res://tests/helpers/dialogue_box_stub.gd"

func test_wander_speed_matches_2d_npc():
	assert_eq(Npc3D.WANDER_SPEED, 30.0 / WorldScale.PIXELS_PER_UNIT)

func test_npc3d_is_a_character_body():
	var npc := load(NPC_SCENE).instantiate()
	add_child_autofree(npc)
	assert_true(npc is CharacterBody3D)

func test_wander_stays_on_xz_and_faces_velocity():
	var npc := load(NPC_SCENE).instantiate()
	add_child_autofree(npc)
	npc._wander_target = npc.position + Vector3(5.0, 0.0, 0.0)
	npc._physics_process(0.016)
	assert_eq(npc.velocity.y, 0.0)
	assert_almost_eq(npc.velocity.length(), Npc3D.WANDER_SPEED, 0.001)
	# walking +X at the 45° contract yaw resolves to "right"
	assert_eq(npc._facing, "right")

func test_near_target_idles_and_repicks():
	var npc := load(NPC_SCENE).instantiate()
	add_child_autofree(npc)
	npc._wander_target = npc.position + Vector3(0.05, 0.0, 0.0)
	npc._physics_process(0.016)
	assert_eq(npc.velocity, Vector3.ZERO)

func test_set_present_toggles_sprite_and_interact_target():
	var npc := load(NPC_SCENE).instantiate()
	add_child_autofree(npc)
	npc.set_present(false)
	assert_false(npc.visible)
	assert_false(npc.get_node("InteractTarget").visible)

func test_interact_starts_dialogue_and_guards_reentry():
	var runner := load(RUNNER_STUB).new()
	runner.add_to_group("dialogue_runner")
	add_child_autofree(runner)
	var box := load(BOX_STUB).new()
	box.add_to_group("dialogue_box")
	add_child_autofree(box)
	var npc := load(NPC_SCENE).instantiate()
	npc.dialogue_node = "Sable"
	add_child_autofree(npc)
	npc.interact()
	assert_true(npc._is_talking)
	assert_eq(runner.started_node, "Sable")
	runner.started_node = ""
	npc.interact()
	assert_eq(runner.started_node, "", "second interact must be a no-op while talking")

func test_conversation_end_commits_30_minutes_once():
	ClockManager.reset()
	var box := load(BOX_STUB).new()
	box.add_to_group("dialogue_box")
	add_child_autofree(box)
	var runner := load(RUNNER_STUB).new()
	runner.add_to_group("dialogue_runner")
	add_child_autofree(runner)
	var npc := load(NPC_SCENE).instantiate()
	npc.dialogue_node = "Sable"
	add_child_autofree(npc)
	npc.interact()
	var before := ClockManager.current_time
	box.conversation_ended.emit()
	box.conversation_ended.emit()
	assert_eq(ClockManager.current_time, before + 30, "one-shot connect must fire once")
	assert_false(npc._is_talking)
```

**Step 2: Run to verify failures** — `"-gtest=res://tests/test_world3d_npc3d.gd"` → FAIL.

**Step 3: Implement `npc3d.gd`** (full replacement)

```gdscript
@tool
class_name Npc3D
extends CharacterBody3D

## Production 3D NPC (issue #129 R6). Wander on XZ, real Yarn dialogue via
## DialogueRunner, facing derived from world velocity.

const DEFAULT_FACING := "down"

## Matches the 2D npc_base WANDER_SPEED (30 px/s) scaled to world units.
const WANDER_SPEED_PIXELS := 30.0
const WANDER_SPEED := WANDER_SPEED_PIXELS / WorldScale.PIXELS_PER_UNIT

const BODY_RADIUS_PIXELS := 5.0
const BODY_HEIGHT_PIXELS := 16.0
const BODY_RADIUS := BODY_RADIUS_PIXELS / WorldScale.PIXELS_PER_UNIT
const BODY_HEIGHT := BODY_HEIGHT_PIXELS / WorldScale.PIXELS_PER_UNIT

const DIALOGUE_RUNNER_GROUP := "dialogue_runner"
const DIALOGUE_BOX_GROUP := "dialogue_box"
const ARRIVE_RADIUS := 0.25
const CONVERSATION_COST_MINUTES := 30

@export var facing := DEFAULT_FACING:
	set(value):
		facing = value
		_apply_facing()

## Yarn node title to start on interact. Empty means silent.
@export var dialogue_node := ""

## Half-extents (XZ) the NPC wanders within, around its spawn position.
@export var wander_half_extents := Vector2(3.0, 2.0)

@onready var sprite: PixelSprite3D = $PixelSprite3D
@onready var _shape: CollisionShape3D = $CollisionShape3D

var _wander_target := Vector3.ZERO
var _spawn_position := Vector3.ZERO
var _is_talking := false
var _facing := DEFAULT_FACING


func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_facing()
		return
	_spawn_position = position
	add_to_group("npcs")
	_apply_body_shape()
	_apply_facing()
	_pick_wander_target()


func _physics_process(_delta: float) -> void:
	if _is_talking:
		velocity = Vector3.ZERO
		move_and_slide()
		sprite.play("idle_" + _facing)
		return
	var to_target := _wander_target - position
	to_target.y = 0.0
	if to_target.length() > ARRIVE_RADIUS:
		var direction := to_target.normalized()
		velocity = Vector3(direction.x, 0.0, direction.z) * WANDER_SPEED
		_facing = SpriteFacing.from_world(velocity, WorldScale.camera_yaw_degrees(get_viewport()))
		sprite.play("walk_" + _facing)
	else:
		velocity = Vector3.ZERO
		sprite.play("idle_" + _facing)
		_pick_wander_target()
	move_and_slide()


func _pick_wander_target() -> void:
	var offset := Vector2(
		randf_range(-wander_half_extents.x, wander_half_extents.x),
		randf_range(-wander_half_extents.y, wander_half_extents.y))
	_wander_target = _spawn_position + Vector3(offset.x, 0.0, offset.y)


func interact() -> void:
	if _is_talking or dialogue_node.is_empty():
		return
	var runners := get_tree().get_nodes_in_group(DIALOGUE_RUNNER_GROUP)
	if runners.is_empty():
		push_error("Npc3D: no node in group '%s'" % DIALOGUE_RUNNER_GROUP)
		return
	var boxes := get_tree().get_nodes_in_group(DIALOGUE_BOX_GROUP)
	if not boxes.is_empty():
		var box := boxes[0]
		if not box.conversation_ended.is_connected(_on_conversation_ended):
			box.conversation_ended.connect(_on_conversation_ended, CONNECT_ONE_SHOT)
	_is_talking = true
	runners[0].StartDialogueForget(dialogue_node)


func _on_conversation_ended() -> void:
	_is_talking = false
	ClockManager.commit_action(CONVERSATION_COST_MINUTES)


## Present/absent toggle. Node3D.visible only affects rendering — the child
## InteractTarget's own `visible` (which InteractScan gates on) is independent,
## so both must be set together to fully hide the NPC from interaction.
func set_present(present: bool) -> void:
	visible = present
	var target := get_node_or_null("InteractTarget") as Node3D
	if target != null:
		target.visible = present


func _apply_body_shape() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	_shape.shape = capsule
	_shape.position = Vector3(0.0, BODY_HEIGHT * 0.5, 0.0)


func _apply_facing() -> void:
	if sprite == null:
		return
	var resolved := facing if SpriteFacing.is_valid(facing) else DEFAULT_FACING
	_facing = resolved
	sprite.play("idle_" + resolved)
```

**Step 3b: Update `npc3d.tscn`** — change root type `Node3D` → `CharacterBody3D` and add an empty `CollisionShape3D` (stamped at runtime):

```
[node name="Npc3D" type="CharacterBody3D"]
script = ExtResource("1")

[node name="PixelSprite3D" type="AnimatedSprite3D" parent="."]  # unchanged
[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
[node name="InteractTarget" type="Area3D" parent="."]             # unchanged
```

**Step 3c: Update `test_room.tscn`'s NPC3D node** — remove the now-invalid `speaker_name`/`dialogue_line` properties; keep `facing="right"` and set `dialogue_node = ""` (the standalone POC has no `DialogueRunner`, so the demo NPC is silent). This prevents "invalid property" parse errors.

**Step 3d: Update `test_world3d_interaction.gd`** — remove the Npc3D tests that drove it through `speaker_name`/`dialogue_line`/`PocDialogueLine`; **keep** the standalone `PocDialogueLine.build()` → `LocalizedLine.from_dictionary()` round-trip test (that class still exists and is still valid). The Npc3D dialogue behaviour is now covered by `test_world3d_npc3d.gd` above.

**Step 4: Run full suite** — all pass.

**Step 5: Refactor checkpoint** — does wander generalize (any `wander_half_extents`/`dialogue_node`), or is it hard-coded to Sable? It's parameterized via exports. Proceed.

**Step 6: Commit** — `git commit -m "feat: productionize Npc3D (wander, Yarn dialogue, clock commit)"`

### Task 4: Add `AreaEntry` marker-name helper (R4)

**Files:**
- Create: `scripts/world3d/area_entry.gd`
- Test: `tests/test_world3d_area_entry.gd`

**Depends on:** Task 1
**Parallelizable with:** Task 3 — different output files.

**Step 1: Write the failing test**

```gdscript
extends GutTest

func test_marker_name_pascal_cases_prev_area():
	assert_eq(AreaEntry.marker_name("cantina"), "EntryFromCantina")
	assert_eq(AreaEntry.marker_name("security_post"), "EntryFromSecurityPost")
	assert_eq(AreaEntry.marker_name("derelict_entrance"), "EntryFromDerelictEntrance")
	assert_eq(AreaEntry.marker_name(""), "EntryFrom")
```

**Step 2: Run → FAIL.**

**Step 3: Implement**

```gdscript
class_name AreaEntry
extends RefCounted

## Resolves the Marker3D name a 3D room authors for a given previous area
## (issue #129 R4). The runner finds "EntryFrom<PrevArea>" in PascalCase.

static func marker_name(prev_area_id: String) -> String:
	return "EntryFrom" + snake_to_pascal(prev_area_id)

static func snake_to_pascal(s: String) -> String:
	var out := ""
	for part in s.split("_"):
		if part.is_empty():
			continue
		out += part[0].to_upper() + part.substr(1)
	return out
```

**Step 4: Run → PASS.**

**Step 5: Refactor checkpoint** — generalized for any snake_case area id. Proceed.

**Step 6: Commit** — `git commit -m "feat: add AreaEntry marker-name helper"`

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 3, Task 4 | Different files, no shared state |
| B (sequential) | — | Both independent; no ordering constraint |

### Smoketest Checkpoint 2 — Npc3D wanders, suite green

**Step 1:** `git fetch origin && git merge origin/master`
**Step 2:** Full GUT suite — all pass.
**Step 3:** Run the POC — the test-room NPC now wanders on the XZ plane (silent in the POC since no `DialogueRunner`).
**Step 4:** Confirm with user, proceed.

---

## Batch 3 — Hybrid hub (R1, R2, R3, R4, R5)

> This batch wires the hybrid structure but **does not flip any room** — all seven areas remain 2D until Batch 4. Its checkpoint is therefore *no-regression*: the game boots into the 2D `trade_dock` exactly as today, with the `World3D` branch present but hidden and inert.

### Task 5: Add the `World3D` branch to `main.tscn` (R1)

**Files:** Modify `scenes/main.tscn`

**Depends on:** Task 1 (player3d.tscn's script refs are now `scripts/world3d/`)
**Parallelizable with:** none — Task 6's `main.gd` `@onready` paths depend on the node names authored here.

**Step 1: Edit the scene.** Add one `ext_resource` and bump `load_steps` 15 → 16, then add these nodes as siblings of `AreaContainer` (order vs `AreaContainer` does not matter — visibility is swapped at runtime):

```
[ext_resource type="PackedScene" path="res://scenes/poc3d/player3d.tscn" id="12"]

[node name="World3D" type="SubViewportContainer" parent="."]
visible = false
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
stretch = true

[node name="SubViewport" type="SubViewport" parent="World3D"]
handle_input_locally = false
transparent_bg = false
render_target_update_mode = 4

[node name="Area3D" type="Node3D" parent="World3D/SubViewport"]

[node name="Player3D" parent="World3D/SubViewport/Area3D" instance=ExtResource("12")]
process_mode = 4
```

Notes for the editor: `Area3D` is a plain **`Node3D` spatial container** (the 3D analogue of `AreaContainer`), not an `Area3D` physics node — the issue names it `Area3D` to parallel `AreaContainer`. `process_mode = 4` (`PROCESS_MODE_DISABLED`) keeps the persistent `Player3D` inert until a 3D area is entered.

**Step 2: Verify** — open the editor, confirm the tree parses and no missing-node warnings; the game still boots into the 2D `trade_dock` (World3D hidden).

**Step 3: Commit** — `git commit -m "feat: add hybrid World3D branch to main scene"`

### Task 6: Registry dispatch, presentation switch, entry resolution in `main.gd` (R2, R3, R4)

**Files:**
- Modify: `scripts/main.gd`
- Test: none directly (`main.gd` is the composition root; verified by structural tests in Task 10 + smoke)

**Depends on:** Task 4 (`AreaEntry`), Task 5 (`$World3D/...` node names)
**Parallelizable with:** none — Task 7 edits the same file.

**Step 1: Change the registry format** (all seven still `"2d"`):

```gdscript
const AREA_SCENES = {
	"trade_dock":        {"scene": "res://scenes/areas/trade_dock.tscn", "presentation": "2d"},
	"cantina":           {"scene": "res://scenes/areas/cantina.tscn", "presentation": "2d"},
	"workshop":          {"scene": "res://scenes/areas/workshop.tscn", "presentation": "2d"},
	"quarters":          {"scene": "res://scenes/areas/quarters.tscn", "presentation": "2d"},
	"security_post":     {"scene": "res://scenes/areas/security_post.tscn", "presentation": "2d"},
	"med_bay":           {"scene": "res://scenes/areas/med_bay.tscn", "presentation": "2d"},
	"derelict_entrance": {"scene": "res://scenes/areas/derelict_entrance.tscn", "presentation": "2d"},
}
```

**Step 2: Add the new `@onready` refs:**

```gdscript
@onready var world3d: SubViewportContainer = $World3D
@onready var area3d: Node3D = $World3D/SubViewport/Area3D
@onready var player3d: CharacterBody3D = $World3D/SubViewport/Area3D/Player3D
```

**Step 3: Split `go_to_area()` on presentation** (replace the body after the fade-out/free):

```gdscript
	var entry: Dictionary = AREA_SCENES[area_id]
	if entry["presentation"] == "3d":
		_enter_3d(area_id, prev)
	else:
		_enter_2d(area_id, prev)
	_current_area_id = area_id
```

**Step 4: Add `_enter_2d`, `_enter_3d`, `_set_presentation`, `_find_3d_entry_marker`** (extract the existing 2D room-instantiation + NPC loop verbatim into `_enter_2d`):

```gdscript
func _enter_2d(area_id: String, prev: String) -> void:
	_set_presentation("2d")
	var positions = AREA_ENTRY_POSITIONS.get(area_id, {})
	player.position = positions.get(prev, positions.get("default", Vector2(240, 128)))
	var scene = load(AREA_SCENES[area_id]["scene"])
	_current_area = scene.instantiate()
	area_container.add_child(_current_area)
	area_container.move_child(_current_area, 0)
	for npc_id in _npc_instances:
		var npc = _npc_instances[npc_id]
		var spawn_area = NPC_SPAWN_AREAS.get(npc_id, "cantina")
		var in_area = (spawn_area == area_id)
		if npc_id == "sable":
			npc.visible = in_area and GameState.get_flag("sable_arrived")
		else:
			npc.visible = in_area
		if npc.visible:
			var spawn = _current_area.find_child("%sSpawn" % npc_id.capitalize(), true, false)
			if spawn:
				npc.position = spawn.global_position
			if npc.has_method("_pick_wander_target"):
				npc._pick_wander_target()


func _enter_3d(area_id: String, prev: String) -> void:
	_set_presentation("3d")
	var scene = load(AREA_SCENES[area_id]["scene"])
	_current_area = scene.instantiate()
	area3d.add_child(_current_area)
	var marker := _find_3d_entry_marker(_current_area, prev, area_id)
	if marker != null:
		player3d.global_position = marker.global_position


func _find_3d_entry_marker(room: Node, prev: String, area_id: String) -> Node3D:
	var marker := room.find_child(AreaEntry.marker_name(prev), false, false)
	if marker == null:
		marker = room.find_child("DefaultSpawn", false, false)
	if marker == null:
		push_error("main: 3D room '%s' has no '%s' or 'DefaultSpawn' marker" % [area_id, AreaEntry.marker_name(prev)])
	return marker


func _set_presentation(presentation: String) -> void:
	if presentation == "3d":
		area_container.visible = false
		world3d.visible = true
		player.velocity = Vector2.ZERO
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.get_node("Camera2D").enabled = false
		player3d.velocity = Vector3.ZERO
		player3d.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		area_container.visible = true
		world3d.visible = false
		player3d.velocity = Vector3.ZERO
		player3d.process_mode = Node.PROCESS_MODE_DISABLED
		player.velocity = Vector2.ZERO
		player.process_mode = Node.PROCESS_MODE_INHERIT
		player.get_node("Camera2D").enabled = true
```

> R3 note (validated): `PROCESS_MODE_DISABLED` stops the 2D player's `_input`/`_physics_process` (no movement, no `ui_accept`). `Camera2D.enabled = false` is separately required — a `Camera2D`'s "current" status is governed by its own `enabled`, not by the parent's process mode. Zeroing both velocities kills the stale-velocity lurch on re-entry.

**Step 4b: Verify** — run full GUT suite (no regressions), launch the game: boots into 2D `trade_dock`, walk between rooms, 2D behaviour unchanged.

**Step 5: Commit** — `git commit -m "feat: hybrid area dispatch with 2D/3D presentation switch"`

### Task 7: Register Yarn commands once; remove `npc_base` hack (R5)

**Files:**
- Modify: `scripts/main.gd`, `scripts/characters/npc_base.gd`

**Depends on:** Task 6
**Parallelizable with:** none — edits `main.gd` (same file as Task 6) and `npc_base.gd`.

**Step 1: Register the three command handlers in `_setup_dialogue_runner()`** (append after `yarn_functions.Register(runners[0])`):

```gdscript
	# Yarn commands, registered once at boot (#129 R5) — not lazily per-NPC.
	runners[0].AddCommandHandlerCallable("register", Callable(GameState, "record_register"))
	runners[0].AddCommandHandlerCallable("log_action", Callable(ClockManager, "log_action"))
	runners[0].AddCommandHandlerCallable("flag", Callable(GameState, "set_flag_on"))
```

**Step 2: Remove the hack from `npc_base.gd`** — delete `static var _commands_registered: bool = false` and the `if not _commands_registered:` block inside `interact()`. The resulting `interact()`:

```gdscript
func interact() -> void:
	if _is_talking:
		return
	var runners := get_tree().get_nodes_in_group("dialogue_runner")
	if runners.is_empty():
		push_error("npc_base: no node in group 'dialogue_runner'")
		return
	var runner := runners[0]
	var boxes := get_tree().get_nodes_in_group("dialogue_box")
	if not boxes.is_empty():
		var box := boxes[0]
		if not box.conversation_ended.is_connected(_on_conversation_ended):
			box.conversation_ended.connect(_on_conversation_ended, CONNECT_ONE_SHOT)
	_is_talking = true
	runner.StartDialogueForget(get_dialogue_node())
```

**Step 3: Verify** — full GUT suite (incl. `test_dialogue_wiring.gd` still green). Smoke: talk to a 2D NPC (e.g. Maris in cantina) — choices with `#register` tags still record registers (proves handlers now fire from boot registration).

**Step 4: Commit** — `git commit -m "refactor: register Yarn command handlers once at boot"`

#### Parallel Execution Groups — Smoketest Checkpoint 3

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 5 → Task 6 → Task 7 | Task 6 depends on Task 5's node names; Task 7 edits `main.gd` after Task 6 |

### Smoketest Checkpoint 3 — no regression; 2D game unchanged

**Step 1:** `git fetch origin && git merge origin/master`
**Step 2:** Full GUT suite — all pass, Scripts/Tests count unchanged.
**Step 3:** Launch the game — boots into the 2D `trade_dock`; walk to cantina/security_post/derelict_entrance and back; talk to Maris and confirm `#register` choices still work.
**Step 4:** Confirm with user, proceed.

---

## Batch 4 — trade_dock 3D pilot (R7, R8)

### Task 8: Build the 3D `trade_dock` room (R7)

**Files:**
- Create: `scenes/areas3d/trade_dock.tscn`, `scripts/areas3d/trade_dock.gd`

**Depends on:** Task 1 (moved scripts), Task 3 (productionized `Npc3D` for Sable)
**Parallelizable with:** none — Task 9 flips the registry to this room.

**Step 1: Create `scripts/areas3d/trade_dock.gd`**

```gdscript
extends Node3D

## The first live 3D room (issue #129 R7). Sable's presence is gated by the
## sable_arrived flag, read room-side. Exits report through ExitDoor.triggered.

@onready var sable: Npc3D = $Sable

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_refresh_sable()
	GameState.flag_changed.connect(_on_flag_changed)
	for door in [$CantinaExit, $SecurityPostExit]:
		door.triggered.connect(_on_exit_triggered)

func _on_flag_changed(flag_id: String, _value: bool) -> void:
	if flag_id == "sable_arrived":
		_refresh_sable()

func _refresh_sable() -> void:
	sable.set_present(GameState.get_flag("sable_arrived"))

func _on_exit_triggered(destination_id: String) -> void:
	get_tree().get_root().get_node("Main").go_to_area(destination_id)
```

**Step 2: Create `scenes/areas3d/trade_dock.tscn`** — assemble from the kit (copy `scenes/poc3d/rooms/workshop.tscn` as the structural template). Required node tree and contracts:

```
TradeDock (Node3D, script above)
├── Floor            TileFloor (tiles = Vector2i(14,10), tile_col = 5, tile_row = 0)
├── Walls (Node3D)
│   ├── WestWall     kit/wall_segment × N — the berth face (back −X wall)
│   ├── NorthWall    kit/wall_segment + TWO kit/doorframe — the two arc exits (−Z wall)
│   ├── EastParapet / SouthParapet — low parapets toward the camera (+X/+Z)
├── Props (Node3D)   Sable's post (kit/table) + berth dressing (kit/crate, kit/pipe)
├── Collision        TileCollision (blocked = [], border_for_floor = Vector2i(14,10))
├── Sun              DirectionalLight3D (the ONLY DirectionalLight3D)
├── Env              WorldEnvironment (ambient, like the kit rooms)
├── RoomCamera       instance room_camera.tscn (contract: FOV 40 / pitch −35 / yaw 45)
├── Sable            instance npc3d.tscn — dialogue_node = "Sable", position at Sable's post
├── CantinaExit      instance exit_door.tscn — destination_id = "cantina"
├── SecurityPostExit instance exit_door.tscn — destination_id = "security_post"
├── EntryFromCantina          (Marker3D)
├── EntryFromSecurityPost     (Marker3D)
├── EntryFromDerelictEntrance (Marker3D)
└── DefaultSpawn              (Marker3D)
```

Contract checks: ≤1 `DirectionalLight3D` + a few omnis (or none); no SSAO/SSIL/SSR/SDFGI/volumetric fog (Mobile); kit textures already have `detect_3d/compress_to=0`.

**Step 3: Author positions** (initial placement; adjust visually — markers must sit just inside the matching doorway, exits at the thresholds):

| Node | Position (X, Y, Z) |
|------|--------------------|
| `RoomCamera` | (9, 9, 9) |
| `DefaultSpawn` | (0, 0, 0) |
| `EntryFromCantina` | (−5.5, 0, 0) |
| `EntryFromSecurityPost` | (5.5, 0, 0) |
| `EntryFromDerelictEntrance` | (0, 0, 4.5) |
| `CantinaExit` (ExitDoor) | (−5.5, 1, 0) |
| `SecurityPostExit` (ExitDoor) | (5.5, 1, 0) |
| `Sable` | (−2, 0, −2) |

**Step 4: Verify** — open `scenes/areas3d/trade_dock.tscn` in the editor (F6): greybox renders at the contract angle; the `Area3D`/camera/light/markers all present; no script errors.

**Step 5: Commit** — `git commit -m "feat: add 3D trade_dock room"`

### Task 9: Flip the registry, delete 2D trade_dock, prune dead refs (R8)

**Files:**
- Modify: `scripts/main.gd`, `tools/generate_rooms.gd`
- Delete: `scenes/areas/trade_dock.tscn`, `scripts/areas/trade_dock.gd` (+ `.uid` sidecars)

**Depends on:** Task 6 (`main.gd` registry), Task 8 (room exists)
**Parallelizable with:** none — edits `main.gd` and performs the deletions.

**Step 1: Flip the registry entry** in `AREA_SCENES`:

```gdscript
	"trade_dock":        {"scene": "res://scenes/areas3d/trade_dock.tscn", "presentation": "3d"},
```

**Step 2: Prune 2D trade_dock state in `main.gd`:**
- Delete the whole `"trade_dock": { ... }` block from `AREA_ENTRY_POSITIONS` (the 3D room authors its own markers). Keep `"trade_dock"` keys inside `cantina`/`security_post`/`derelict_entrance` — those are the 3D→2D entry positions.
- Remove `"sable": "trade_dock"` from `NPC_SPAWN_AREAS` and `"sable": "res://scripts/characters/sable.gd"` from `_spawn_npcs`' `npc_scripts` (Sable is now a 3D `Npc3D`).
- In `_enter_2d`, replace the `if npc_id == "sable": ... else: ...` with the single line `npc.visible = (spawn_area == area_id)`.

**Step 3: Remove the stale `trade_dock` entry from `tools/generate_rooms.gd`** (the `_process_area("res://scenes/areas/trade_dock.tscn", ...)` block — it regenerates 2D rooms and would otherwise leave a reference to the deleted scene).

**Step 4: Delete the files** (run from the repo root, not inside the dir):

```powershell
git rm scenes/areas/trade_dock.tscn scenes/areas/trade_dock.tscn.uid scripts/areas/trade_dock.gd scripts/areas/trade_dock.gd.uid
```

**Step 5: Verify (AC7)** — grep must find **zero** references to the deleted paths (`res://scenes/areas/trade_dock.tscn` and `res://scripts/areas/trade_dock.gd`) across `scripts/ scenes/ tests/ tools/`. Then run the full GUT suite — all pass.

**Step 6: Commit** — `git commit -m "feat: boot into 3D trade_dock; delete 2D room"`

#### Parallel Execution Groups — Smoketest Checkpoint 4

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 8 → Task 9 | Task 9 flips to the room Task 8 builds |

### Smoketest Checkpoint 4 — the pilot (AC1, AC2, AC3, AC4, AC5, AC8)

**Step 1:** `git fetch origin && git merge origin/master`
**Step 2:** Full GUT suite — all pass.
**Step 3:** Launch the game. Verify with the user:
- **AC1** — boots into a 3D `trade_dock` at 480×270, nearest-upscaled; HUD and dialogue box full-resolution above it.
- **AC2** — walk `trade_dock` → cantina → back: fade covers the swap, spawn positions correct both ways, no camera-offset artifact on return.
- **AC3** — `Player3D` moves camera-relative with correct facing; `ui_accept` interaction works through the hybrid tree.
- **AC4** — Sable hidden (flag unset). Temporarily set `sable_arrived` via a debug flag (e.g. a throwaway `-s` script or GUT test), confirm Sable appears and real Yarn dialogue is reachable; conversation end advances the clock exactly 30 minutes once.
- **AC5** — while in 3D, the 2D player neither moves nor consumes `ui_accept`; area swaps never produce a velocity lurch.
- **AC8** — 2D→3D transition derelict_entrance → trade_dock works.
**Step 4:** Confirm with user, proceed.

---

## Batch 5 — Structural tests (R10)

### Task 10: Structural GUT tests

**Files:** Create `tests/test_hybrid_structure.gd`

**Depends on:** Task 9 (final state)
**Parallelizable with:** none — verifies the final assembled state.

**Step 1: Write the test** (mirrors the `SceneState` technique of `test_dialogue_wiring.gd` — no instantiation of `main.tscn`):

```gdscript
extends GutTest

## Guards the hybrid invariants (issue #129 R10).

const MAIN_SCENE := "res://scenes/main.tscn"
const TRADE_DOCK_3D := "res://scenes/areas3d/trade_dock.tscn"

func _state() -> SceneState:
	return (load(MAIN_SCENE) as PackedScene).get_state()

func _node_paths() -> Array:
	var state := _state()
	var paths := []
	for i in state.get_node_count():
		paths.append(str(state.get_node_path(i)))
	return paths

func test_hud_and_dialogue_stay_outside_the_subviewport():
	var paths := _node_paths()
	assert_true(paths.has("HUD"), "main.tscn must keep HUD as a root sibling")
	assert_true(paths.has("DialogueBox"), "main.tscn must keep DialogueBox as a root sibling")
	for p in paths:
		assert_false(p.begins_with("World3D/SubViewport/HUD"), "HUD must not live under the SubViewport")
		assert_false(p.begins_with("World3D/SubViewport/DialogueBox"), "DialogueBox must not live under the SubViewport")

func test_world3d_branch_hosts_the_3d_player():
	var paths := _node_paths()
	assert_true(paths.has("World3D/SubViewport/Area3D/Player3D"),
		"the World3D branch must hold a persistent Player3D")

func test_2d_trade_dock_files_are_gone():
	assert_false(ResourceLoader.exists("res://scenes/areas/trade_dock.tscn"), "2D trade_dock scene must be deleted")
	assert_false(ResourceLoader.exists("res://scripts/areas/trade_dock.gd"), "2D trade_dock script must be deleted")

func test_trade_dock_authors_entry_markers_for_every_2d_neighbour():
	var room := load(TRADE_DOCK_3D).instantiate()
	add_child_autofree(room)
	for marker in ["EntryFromCantina", "EntryFromSecurityPost", "EntryFromDerelictEntrance", "DefaultSpawn"]:
		assert_not_null(room.find_child(marker, false, false), "3D trade_dock missing marker '%s'" % marker)

func test_2d_neighbours_keep_entry_positions_keyed_by_trade_dock():
	var main_script := load("res://scripts/main.gd")
	for area in ["cantina", "security_post"]:
		assert_true(main_script.AREA_ENTRY_POSITIONS[area].has("trade_dock"),
			"2D area '%s' lost its trade_dock entry position" % area)
```

**Step 2: Run to verify it fails** (it should fail before Task 9 is complete; by this task it passes).

**Step 3: Run full suite** — all pass; record the Scripts/Tests count.

**Step 4: Commit** — `git commit -m "test: hybrid structure invariants"`

#### Parallel Execution Groups — Smoketest Checkpoint 5

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 10 | Single task; verifies final state |

### Smoketest Checkpoint 5 — final full pass

**Step 1:** `git fetch origin && git merge origin/master`
**Step 2:** Full GUT suite — all pass; Scripts/Tests count checked, not just the banner (AC6).
**Step 3:** Final launch — repeat Checkpoint 4's AC1–AC8 walkthrough once more on clean state.
**Step 4:** Confirm with user.

---

## Plan self-review checklist — result

| # | Check | Result |
|---|---|---|
| 1 | No hardcoded values | PASS — speeds/radii derive from `WorldScale.PIXELS_PER_UNIT`; `from_world`/`AreaEntry` parameterized; scene positions are authoring data, not magic code values |
| 2 | Explicit test criteria | PASS — every task states command + expected output |
| 3 | Parallel annotations justified | PASS — every `none` carries a one-sentence justification (same-file edit or hard dependency) |
| 4 | Parallel Execution Groups tables | PASS — present before each checkpoint |
| 5 | No brainstorming leakage | PASS — plan is task/file oriented; no design narrative |
| 6 | Removal tasks grepped first | PASS — grepped `trade_dock` before writing: `main.gd` (registry, `AREA_ENTRY_POSITIONS`, `NPC_SPAWN_AREAS`, `_spawn_npcs`, `_ready` boot), `cantina.gd`/`security_post.gd`/`derelict_entrance.gd` (2D→3D triggers — kept), `trade_dock.tscn`/`.gd` (deleted), `tools/generate_rooms.gd` (stale ref removed) |
| 7 | UI control intent | N/A — no new button/panel/label; the hybrid structure adds a `SubViewportContainer`, not a user-facing control |

**Out-of-scope leftovers flagged:**
- `scripts/characters/sable.gd` becomes dead after Task 9 (Sable is now a 3D `Npc3D`). Not in the issue's delete list; left in place.
- `data/maps/trade_dock.tmx` (+ `.import`) becomes orphaned after deleting the 2D room. Not in the issue's delete list; flagged for a follow-up.
