# Greybox POC Room, Interaction & NPC Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Finish the epic #100 proof-of-concept room so every system that could break in the 2D→3D move — movement, occlusion, interaction, dialogue, resource signals, door triggers — is exercised in one playable scene, ending at the go/no-go gate.

**Architecture:** `scenes/poc3d/rooms/test_room.tscn` is evolved in place (it is all one POC — there is no second room). Walls, a console and a crate are added on the existing 1-unit tile grid; `BlockA` and `BlockC` are deleted and replaced by the two props issue #103 actually names, while `BlockB` stays because PRD 1's `ReferenceSprite` occlusion demo intersects it. All new interaction logic is authored as **node-free static functions** (`InteractScan`, `PocDialogueLine`) so it is testable headlessly, exactly the pattern `SpriteFacing` established in PRD 2 — the node scripts are thin wiring around them. `dialogue_box.tscn`/`.gd` and `hud.tscn`/`.gd` are instanced completely unmodified; the composition root `poc_entry.gd` is where the room's door is connected to the HUD.

**Tech Stack:** Godot 4.7.1 (mono), GDScript, Mobile renderer, GUT for headless tests. `YarnSpinner` here is the pure-GDScript helper class in `addons/YarnSpinner-Godot/Runtime/Views/GDScriptHelper.gd` — **not** C#, and **not** `DialogueRunner`, which this plan never touches.

## Open questions (must resolve before starting)

None. All nine design decisions were settled in the grilling session that preceded this plan.

---

## Context the implementer needs before Task 1

You are working in a Godot project on Windows. Read this section once; it explains the vocabulary the tasks assume.

### Commands

**Never** invoke `godot` or `godot_console` from PATH — those are WinGet shims and Godot crashes with `.NET: Assemblies not found`. Always use the wrapper:

```powershell
# Run every test headlessly (quote any res:// argument — PowerShell splits on the colon)
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit

# Run one test script
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit

# Launch the POC room (this is what you smoketest)
./tools/godot.ps1 --path . "res://scenes/poc3d/poc_entry.tscn"

# Launch the 2D game (this must keep working — AC7)
./tools/godot.ps1 --path .
```

Do not read `$LASTEXITCODE` after a piped command — the pipe masks it. Run the command bare and read the exit code on the next line.

### The tile grid

`TileFloor` renders a floor of 1-world-unit tiles centred on the origin. `TileCollision` turns a list of blocked tiles into a `StaticBody3D` of `BoxShape3D` children at `_ready()`. **Tile `(i, j)` covers world X in `[i, i+1)` and Z in `[j, j+1)`.** The floor is `Vector2i(12, 12)`, so it spans world X and Z from `-6` to `+6`.

`border_for_floor = Vector2i(12, 12)` generates the collision ring *just outside* the floor: tile columns `x = -7` and `x = 6`, tile rows `z = -7` and `z = 6`. **That ring is already generated and already solid — none of the walls this plan adds require any collision change.** The walls are purely visual meshes dropped onto footprints that are already blocked.

### The camera, and why two walls are short

`RoomCamera` sits at `(9, 9, 9)` with the contract angle (FOV 40°, pitch −35°, yaw 45°), looking down at the origin from the **+X / +Z** corner. The `−X` and `−Z` walls are therefore *far* walls and are built 3 units tall. The `+X` and `+Z` walls are *between the camera and the room* and are built as **0.5-unit parapets** so they do not occlude the interior. All four footprints exist and are collidable; only the mesh height differs. This is the classic diorama read the epic is chasing, and it leaves PRD 4 a real grid-snapped footprint to drop kit pieces into on all four sides.

### The interaction contract being preserved

`scripts/characters/player.gd._try_interact()` is the 2D original this plan mirrors in 3D:

1. Scan `interaction_zone.get_overlapping_bodies()` first, then `get_overlapping_areas()`.
2. A candidate qualifies if it `is_in_group("interactable")` **and** `.visible`.
3. Call the duck-typed `interact()` on the first match and stop.

The 3D version adds one stricter filter — the candidate must also `has_method("interact")`. This differs from 2D only in the case where 2D currently crashes, and it was explicitly approved.

### Files that must not be touched (AC6)

`scenes/main.tscn`, `scripts/main.gd`, anything under `scenes/areas/`, `scenes/ui/hud.tscn`, `scripts/ui/hud.gd`, `scenes/ui/dialogue_box.tscn`, `scripts/ui/dialogue_box.gd`, `project.godot`. If a task seems to need one of these, stop and ask — it does not.

---

## Batch 1 — The interaction scan and a working console

### Task 1: `InteractScan` — the pure interaction-scan rule

**Files:**
- Create: `scripts/poc3d/interact_scan.gd`
- Test: `tests/test_poc3d_interaction.gd`

**Depends on:** none
**Parallelizable with:** none — Tasks 2 and 3 both reference the constants this task defines, and Task 4 instances the scene Task 2 builds, so this is the batch's root.

**Step 1: Write the failing GUT test**

Create `tests/test_poc3d_interaction.gd`:

```gdscript
# tests/test_poc3d_interaction.gd
# Headless coverage for PRD 3 (#103) AC9: the interaction contract, the console's
# resource grant, the door latch, and the hardcoded dialogue line.
#
# The point of testing InteractScan rather than Player3D is that a real Area3D overlap
# needs physics frames to register. Keeping the RULE node-free — the pattern SpriteFacing
# established in PRD 2 — makes it assertable with stub nodes and no frame waits.
extends GutTest


func _stub(in_group: bool, is_visible: bool, has_interact: bool) -> Node3D:
	var node := Node3D.new()
	if has_interact:
		node.set_script(load("res://tests/helpers/interactable_stub.gd"))
	if in_group:
		node.add_to_group(InteractScan.INTERACTABLE_GROUP)
	node.visible = is_visible
	add_child_autofree(node)
	return node


func test_a_qualifying_body_is_returned():
	var body := _stub(true, true, true)
	assert_eq(InteractScan.first_interactable([body], []), body)


func test_a_qualifying_area_is_returned_when_there_are_no_bodies():
	var area := _stub(true, true, true)
	assert_eq(InteractScan.first_interactable([], [area]), area)


func test_bodies_are_scanned_before_areas():
	# Byte-identical ordering to scripts/characters/player.gd._try_interact().
	var body := _stub(true, true, true)
	var area := _stub(true, true, true)
	assert_eq(InteractScan.first_interactable([body], [area]), body)


func test_the_first_match_wins_within_a_list():
	var first := _stub(true, true, true)
	var second := _stub(true, true, true)
	assert_eq(InteractScan.first_interactable([first, second], []), first)


func test_a_node_outside_the_group_is_skipped():
	var outsider := _stub(false, true, true)
	assert_null(InteractScan.first_interactable([outsider], []))


func test_an_invisible_node_is_skipped():
	var hidden := _stub(true, false, true)
	assert_null(InteractScan.first_interactable([hidden], []))


func test_a_node_without_interact_is_skipped_rather_than_crashing():
	# The one place this is stricter than the 2D original, which duck-types blindly.
	var malformed := _stub(true, true, false)
	assert_null(InteractScan.first_interactable([malformed], []))


func test_nothing_in_reach_returns_null():
	assert_null(InteractScan.first_interactable([], []))


func test_a_skipped_candidate_does_not_hide_a_later_valid_one():
	var hidden := _stub(true, false, true)
	var valid := _stub(true, true, true)
	assert_eq(InteractScan.first_interactable([hidden, valid], []), valid)
```

Create the stub helper `tests/helpers/interactable_stub.gd` (create the `tests/helpers/` directory):

```gdscript
# tests/helpers/interactable_stub.gd
# A minimal interactable for InteractScan tests. Records that it was called so a test can
# assert the duck-typed contract without a real prop scene.
extends Node3D

var interact_count := 0


func interact() -> void:
	interact_count += 1
```

> GUT collects test scripts from `-gdir=res://tests`. A helper under `tests/helpers/` that does not `extends GutTest` is not collected as a test, so no exclusion is needed.

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit
```
Expected: FAIL — `Identifier "InteractScan" not declared in the current scope` on every test.

**Step 3: Write minimal implementation**

```gdscript
# scripts/poc3d/interact_scan.gd
class_name InteractScan
extends RefCounted

## The interaction-scan rule, lifted out of any node so it can be asserted headlessly.
##
## PRD 3 (#103) R4/AC9. scripts/characters/player.gd._try_interact() is the 2D original:
## bodies before areas, first match wins, a candidate qualifies on group membership plus
## visibility. This adds one stricter filter — has_method("interact") — so a malformed
## prop is skipped instead of erroring. That differs from 2D only where 2D crashes.
##
## Not an autoload and not a node: a class_name is globally reachable and costs nothing.

## The group both the console and the NPC's interact target join. Named here so no
## call site types the string.
const INTERACTABLE_GROUP := "interactable"

## The duck-typed method the contract is built on.
const INTERACT_METHOD := "interact"


## The node the player would interact with, or null when nothing in reach qualifies.
## `bodies` is scanned before `areas`, matching the 2D contract exactly.
static func first_interactable(bodies: Array, areas: Array) -> Node:
	var found := _first_in(bodies)
	if found != null:
		return found
	return _first_in(areas)


## Whether one overlap candidate qualifies. Public so a prop can self-check in a test.
static func is_interactable(candidate: Variant) -> bool:
	if not (candidate is Node):
		return false
	var node: Node = candidate
	if not node.is_in_group(INTERACTABLE_GROUP):
		return false
	if not node.has_method(INTERACT_METHOD):
		return false
	# `visible` lives on Node3D/CanvasItem, not on Node. A qualifying prop that is
	# neither cannot be hidden, so it counts as visible.
	if node is Node3D:
		return (node as Node3D).visible
	if node is CanvasItem:
		return (node as CanvasItem).visible
	return true


static func _first_in(candidates: Array) -> Node:
	for candidate in candidates:
		if is_interactable(candidate):
			return candidate
	return null
```

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit
```
Expected: PASS — 9 passing, 0 failures.

> If `InteractScan` is reported as undeclared even after the file exists, the class cache has not picked up the new `class_name`. Open the editor once (`./tools/godot.ps1`) and close it, then re-run.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" The scan takes arbitrary arrays and names no prop type, so a third and fourth interactable cost nothing. Proceed.

**Step 6: Commit**

```bash
git add scripts/poc3d/interact_scan.gd tests/test_poc3d_interaction.gd tests/helpers/interactable_stub.gd
git commit -m "feat: add the node-free interaction scan rule (#103)"
```

---

### Task 2: The console prop

**Files:**
- Create: `scripts/poc3d/console.gd`, `scenes/poc3d/console.tscn`
- Test: `tests/test_poc3d_interaction.gd` (append)

**Depends on:** Task 1 — uses `InteractScan.INTERACTABLE_GROUP`.
**Parallelizable with:** none — Task 3 appends to the same `tests/test_poc3d_interaction.gd` and instantiates this task's `console.tscn`, so the two must be sequential.

**Step 1: Write the failing GUT test**

Append to `tests/test_poc3d_interaction.gd`:

```gdscript
# ── Console (R5 / AC2) ────────────────────────────────────────────────────────

const CONSOLE_SCENE := "res://scenes/poc3d/console.tscn"


func _console() -> PocConsole:
	var node: PocConsole = load(CONSOLE_SCENE).instantiate()
	add_child_autofree(node)
	return node


func test_the_console_joins_the_interactable_group():
	assert_true(_console().is_in_group(InteractScan.INTERACTABLE_GROUP))


func test_the_console_satisfies_the_scan_contract():
	# Guards the whole chain at once: group, visibility and the duck-typed method.
	var console := _console()
	assert_true(InteractScan.is_interactable(console))


func test_interacting_grants_the_console_yield():
	GameState.reset()
	var before := GameState.get_resource(PocConsole.RESOURCE_ID)
	_console().interact()
	assert_eq(GameState.get_resource(PocConsole.RESOURCE_ID), before + PocConsole.CONSOLE_YIELD)


func test_the_console_is_repeatable():
	# Deliberately has no one-shot latch: the gate play-session hammers this prop.
	GameState.reset()
	var console := _console()
	console.interact()
	console.interact()
	console.interact()
	assert_eq(GameState.get_resource(PocConsole.RESOURCE_ID), PocConsole.CONSOLE_YIELD * 3)


func test_interacting_emits_dispensed():
	GameState.reset()
	var console := _console()
	watch_signals(console)
	console.interact()
	assert_signal_emitted_with_parameters(
		console, "dispensed", [PocConsole.RESOURCE_ID, PocConsole.CONSOLE_YIELD])
```

Also append the AC2 signal-discipline test — the one that proves the HUD is driven by the signal rather than polling:

```gdscript
# ── AC2: the HUD updates from the signal, not from polling ───────────────────

const HUD_SCENE := "res://scenes/ui/hud.tscn"


func test_the_hud_reflects_a_console_grant_through_the_resource_changed_signal():
	# AC2. hud.gd connects GameState.resource_changed in _ready() and never polls; this
	# asserts the connection itself, so deleting it fails here even if a later _process
	# happened to refresh the same label.
	GameState.reset()
	var hud := load(HUD_SCENE).instantiate()
	add_child_autofree(hud)
	await wait_frames(1)
	assert_true(GameState.resource_changed.is_connected(hud._refresh_resources),
		"hud.gd must stay connected to GameState.resource_changed — AC2 is signal discipline")
	_console().interact()
	await wait_frames(1)
	var label: Label = hud.get_node("HBoxContainer/PartsLabel")
	assert_eq(label.text, "Parts: %d" % GameState.get_resource(PocConsole.RESOURCE_ID))
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit
```
Expected: FAIL — `console.tscn` does not exist / `PocConsole` undeclared.

**Step 3: Write minimal implementation**

```gdscript
# scripts/poc3d/console.gd
class_name PocConsole
extends Area3D

## The room's interactable console. PRD 3 (#103) R5.
##
## An Area3D rather than a body: the player's InteractionZone scans overlapping areas as
## well as bodies, and the console's *solidity* is authored separately as a blocked tile
## in TileCollision. Keeping the two apart is R3 — PRD 4 swaps the visual mesh and must
## not be able to disturb either the collision or the interaction volume.

## Which resource the console dispenses. All four GameState ids appear on the HUD, so any
## would prove AC2; `parts` is the one this room grants.
const RESOURCE_ID := "parts"

## How much per interact. Named so no call site carries a bare literal.
const CONSOLE_YIELD := 1

## Emitted after the grant, so a room or a test can observe the interaction without
## reaching into GameState. Nothing in this PRD consumes it; it exists for the test.
signal dispensed(resource_id: String, amount: int)


func _ready() -> void:
	add_to_group(InteractScan.INTERACTABLE_GROUP)


## Duck-typed entry point. The player never knows this type — see InteractScan.
func interact() -> void:
	GameState.add_resource(RESOURCE_ID, CONSOLE_YIELD)
	dispensed.emit(RESOURCE_ID, CONSOLE_YIELD)
```

Create `scenes/poc3d/console.tscn`. The `Area3D` covers exactly the console's 1×2 tile footprint (world X `[-6,-5]`, Z `[-1,1]` once placed in Task 4), authored here in local space around the origin so the scene stays position-independent:

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/poc3d/console.gd" id="1"]

[sub_resource type="BoxShape3D" id="1"]
size = Vector3(1, 1, 2)

[node name="Console" type="Area3D"]
script = ExtResource("1")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("1")
```

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit
```
Expected: PASS — all Task 1 and Task 2 tests green.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" A second console is one more instance with no shared state; the resource id and yield are consts on the type, which is correct for a POC with one console. If a second prop needs a different yield, promote them to `@export`s then — not now (YAGNI). Proceed.

**Step 6: Commit**

```bash
git add scripts/poc3d/console.gd scenes/poc3d/console.tscn tests/test_poc3d_interaction.gd
git commit -m "feat: add the interactable console prop (#103)"
```

---

### Task 3: Wire `Player3D`'s interaction zone

**Files:**
- Modify: `scripts/poc3d/player3d.gd`

**Depends on:** Task 1 (calls `InteractScan.first_interactable()`) and Task 2 (its reach tests instantiate `console.tscn`).
**Parallelizable with:** none — it appends to `tests/test_poc3d_interaction.gd`, which Task 2 also writes.

**Step 1: Write the failing GUT test**

The scan *rule* is already covered by Task 1 with no physics involved. What is left untested is the one thing only a real overlap can prove: that `INTERACT_RADIUS` actually **reaches** a prop standing where props stand. That is worth a physics-frame test — it is the constant most likely to be silently wrong.

Append to `tests/test_poc3d_interaction.gd`:

```gdscript
# ── Player3D reach (R4) ──────────────────────────────────────────────────────

const PLAYER_SCENE := "res://scenes/poc3d/player3d.tscn"

## Just inside INTERACT_RADIUS (20 px / 16 = 1.25 units), and just outside it.
const WITHIN_REACH := 1.0
const BEYOND_REACH := 3.0


func _player_and_console_at(separation: float) -> Node3D:
	# The console's own 1x2 box is centred on it, so `separation` is measured between
	# origins; anything under INTERACT_RADIUS plus half the box depth overlaps.
	var player: Player3D = load(PLAYER_SCENE).instantiate()
	var console: PocConsole = load(CONSOLE_SCENE).instantiate()
	add_child_autofree(player)
	add_child_autofree(console)
	console.global_position = Vector3(separation, 0.0, 0.0)
	# Overlaps are resolved by the physics server, not on add_child.
	await wait_physics_frames(2)
	return player


func test_the_player_reaches_a_console_standing_next_to_it():
	GameState.reset()
	var player = await _player_and_console_at(WITHIN_REACH)
	player._try_interact()
	assert_eq(GameState.get_resource(PocConsole.RESOURCE_ID), PocConsole.CONSOLE_YIELD,
		"INTERACT_RADIUS does not reach a prop the player is standing against")


func test_the_player_does_not_reach_a_distant_console():
	GameState.reset()
	var player = await _player_and_console_at(BEYOND_REACH)
	player._try_interact()
	assert_eq(GameState.get_resource(PocConsole.RESOURCE_ID), 0,
		"the interaction zone is reaching further than INTERACT_RADIUS allows")


func test_interacting_with_nothing_in_reach_is_a_no_op():
	GameState.reset()
	var player: Player3D = load(PLAYER_SCENE).instantiate()
	add_child_autofree(player)
	await wait_physics_frames(2)
	player._try_interact()
	pass_test("an empty interaction zone must not error")
```

> These tests reuse `CONSOLE_SCENE` and `PocConsole` from Task 2, which is why Task 3 runs after it rather than alongside it.

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit
```
Expected: FAIL — `Invalid call. Nonexistent function '_try_interact' in base 'Player3D'`.

**Step 3: Write minimal implementation**

In `scripts/poc3d/player3d.gd`, add the action constant next to the existing interaction constants:

```gdscript
## The action that fires an interaction, matching scripts/characters/player.gd.
const INTERACT_ACTION := "ui_accept"
```

Add the zone to the existing `@onready` block:

```gdscript
@onready var _interaction_zone: Area3D = $InteractionZone
```

And append these two functions at the end of the file:

```gdscript
## _unhandled_input rather than _input: the dialogue box runs at PROCESS_MODE_ALWAYS and
## pauses the tree while a line is up, so a paused Player3D stops receiving input and the
## box gets ui_accept to itself. No explicit "is dialogue open" guard is needed.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(INTERACT_ACTION):
		return
	_try_interact()
	get_viewport().set_input_as_handled()


## Mirrors scripts/characters/player.gd._try_interact(): bodies before areas, first match
## wins, duck-typed call. The rule itself lives in InteractScan so it can be tested.
func _try_interact() -> void:
	var target := InteractScan.first_interactable(
		_interaction_zone.get_overlapping_bodies(),
		_interaction_zone.get_overlapping_areas())
	if target == null:
		return
	target.interact()
```

Update the doc comment on `INTERACT_RADIUS_PIXELS` — it currently says "Reach of the (unwired) interaction zone… PRD 3 (#103) wires it up." Drop the parenthetical and the trailing sentence, since this task is that wiring:

```gdscript
## Reach of the interaction zone: 20 px, matching the 2D player's InteractionZone circle
## in scenes/characters/player.tscn.
```

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_player3d.gd" -gexit
```
Expected: PASS for both — the new reach tests, and the existing Player3D suite, which is unchanged and must stay green.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" `_try_interact()` names no prop type and stops at the first match; a second, third and fourth interactable in reach all resolve through the same rule. Proceed.

**Step 6: Commit**

```bash
git add scripts/poc3d/player3d.gd
git commit -m "feat: wire the 3D player's interaction zone to the scan (#103)"
```

---

### Task 4: Replace `BlockA`/`BlockC` with the console and crate

**Files:**
- Modify: `scenes/poc3d/rooms/test_room.tscn`

**Depends on:** Task 2 — instances `console.tscn`.
**Parallelizable with:** none — it is the only task in the batch that writes `test_room.tscn`, and it needs Task 2's scene to exist.

**Step 1: Write the content**

Three edits to `scenes/poc3d/rooms/test_room.tscn`.

**(a) Delete `BlockA` and `BlockC`** and their now-unused sub-resources. `BlockA` used `BoxMesh id="1"` + `StandardMaterial3D id="2"`; `BlockC` used `BoxMesh id="5"` + `StandardMaterial3D id="6"`. **Keep `BlockB` and its `id="3"`/`id="4"` sub-resources untouched** — `scenes/poc3d/README.md` documents `ReferenceSprite` intersecting `BlockB` as PRD 1's deliberate partial-occlusion demo, and moving or removing it regresses that.

**(b) Add the two props.** Add an `ext_resource` for the console scene and these nodes under `Blocks`:

```
[ext_resource type="PackedScene" path="res://scenes/poc3d/console.tscn" id="8"]

[sub_resource type="BoxMesh" id="8"]
size = Vector3(1, 1, 2)

[sub_resource type="StandardMaterial3D" id="9"]
albedo_color = Color(0.239, 0.435, 0.494, 1)
texture_filter = 0

[sub_resource type="BoxMesh" id="10"]
size = Vector3(1, 1, 1)

[sub_resource type="StandardMaterial3D" id="11"]
albedo_color = Color(0.545, 0.447, 0.298, 1)
texture_filter = 0
```

```
[node name="Console" type="MeshInstance3D" parent="Blocks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -5.5, 0.5, 0)
mesh = SubResource("8")
material_override = SubResource("9")

[node name="Console" parent="Blocks/Console" instance=ExtResource("8")]

[node name="Crate" type="MeshInstance3D" parent="Blocks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.5, 0.5, 1.5)
mesh = SubResource("10")
material_override = SubResource("11")
```

> Godot rejects two siblings with the same name but a child may share its parent's name; if the editor renames the instanced child to `Console2`, rename it to `Interact` instead and keep going — nothing looks it up by name.

Geometry check (AC5 — every coordinate is a whole or half unit):

| Prop | Mesh size | Position | World footprint | Tiles |
|---|---|---|---|---|
| `Console` | `1 × 1 × 2` | `(-5.5, 0.5, 0)` | X `[-6,-5]`, Z `[-1,1]` | `(-6,-1)`, `(-6,0)` |
| `Crate` | `1 × 1 × 1` | `(1.5, 0.5, 1.5)` | X `[1,2]`, Z `[1,2]` | `(1,1)` |

`texture_filter = 0` is `TEXTURE_FILTER_NEAREST`. These materials carry no texture, so it changes nothing visually — it is set so the rule from the epic's finding #2 ("`default_texture_filter` is 2D-only, every 3D material sets nearest explicitly") is visible in the scene rather than remembered.

**(c) Update `TileCollision.blocked`.** `BlockA` claimed `(-4,1) (-4,2) (-3,1) (-3,2)`; `BlockC` claimed `(0,3) (1,3) (2,3)`; both are freed. `BlockB`'s `(2,-1)` stays. The console and crate claim three tiles. The `Collision` node's `blocked` property becomes exactly:

```
blocked = Array[Vector2i]([Vector2i(2, -1), Vector2i(-6, -1), Vector2i(-6, 0), Vector2i(1, 1)])
```

Leave `border_for_floor = Vector2i(12, 12)` alone.

**Step 2: Verify**

```powershell
./tools/godot.ps1 --path . "res://scenes/poc3d/poc_entry.tscn"
```

Confirm: the two old grey blocks are gone; a teal console sits against the far `−X` edge of the floor and a brown crate sits in the open floor; the tall `BlockB` and the `ReferenceSprite` in front of it are unchanged. Walk the player into the console and the crate — both stop you. Walk into the space `BlockA` and `BlockC` used to occupy — you now pass freely.

**Step 3: Commit**

```bash
git add scenes/poc3d/rooms/test_room.tscn
git commit -m "feat: replace the anonymous blocks with the console and crate (#103)"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 1 | Defines `InteractScan`, which Tasks 2 and 3 both reference |
| B (sequential) | Task 2 | Depends on Group A. Writes `console.gd`/`console.tscn` and appends to the test file |
| C (sequential) | Task 3 | Depends on Task 2 — its reach tests instantiate `console.tscn`, and it appends to the same test file |
| D (sequential) | Task 4 | Depends on Task 2 — instances `console.tscn`; sole writer of `test_room.tscn` |

**This batch has no parallel group.** Every task after the first either appends to `tests/test_poc3d_interaction.gd` or consumes `console.tscn`, and two agents appending to one file conflict. Tasks 3 and 4 have no dependency on each other, but both depend on Task 2 and both would be run by an agent that must first see Task 2's output; if the executor can guarantee Task 3 (test file + `player3d.gd`) and Task 4 (`test_room.tscn`) never touch the same file — they do not — they may be run in parallel *after* Task 2 lands.

### Smoketest Checkpoint 1 — the console grants a resource and the HUD reacts

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: All tests pass, zero failures.

**Step 3: Launch the POC and verify visually**
```powershell
./tools/godot.ps1 --path . "res://scenes/poc3d/poc_entry.tscn"
```

**Step 4: Confirm with user**

Ask the user to verify:
- The teal console and brown crate are present and grid-aligned; the old `BlockA`/`BlockC` are gone; `BlockB` and its reference sprite are unchanged.
- Walking into the console or the crate stops the player.
- Standing next to the console and pressing **Enter** ticks `Parts:` up by 1 on the HUD, every press, with no delay.
- Pressing Enter in open floor does nothing and does not error.

Wait for confirmation before starting Batch 2.

---

## Batch 2 — Walls and the exit door

### Task 5: The four wall meshes

**Files:**
- Modify: `scenes/poc3d/rooms/test_room.tscn`

**Depends on:** Task 4 — same file, and it must land after the block deletion so the sub-resource ids do not collide.
**Parallelizable with:** Task 6 — Task 6 writes only new files (`exit_door.gd`, `exit_door.tscn`, the test file); this writes only `test_room.tscn`.

**Step 1: Write the content**

Add a `Walls` node as a sibling of `Blocks` in `scenes/poc3d/rooms/test_room.tscn`, with five mesh children. **No collision change** — every footprint below already sits on the ring `border_for_floor` generates.

Sub-resources:

```
[sub_resource type="StandardMaterial3D" id="12"]
albedo_color = Color(0.349, 0.369, 0.400, 1)
texture_filter = 0

[sub_resource type="StandardMaterial3D" id="13"]
albedo_color = Color(0.298, 0.318, 0.349, 1)
texture_filter = 0

[sub_resource type="BoxMesh" id="14"]
size = Vector3(1, 3, 14)

[sub_resource type="BoxMesh" id="15"]
size = Vector3(5, 3, 1)

[sub_resource type="BoxMesh" id="16"]
size = Vector3(2, 0.5, 1)

[sub_resource type="BoxMesh" id="17"]
size = Vector3(1, 0.5, 14)

[sub_resource type="BoxMesh" id="18"]
size = Vector3(12, 0.5, 1)
```

Nodes:

```
[node name="Walls" type="Node3D" parent="."]

[node name="WestWall" type="MeshInstance3D" parent="Walls"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -6.5, 1.5, 0)
mesh = SubResource("14")
material_override = SubResource("12")

[node name="NorthWallLeft" type="MeshInstance3D" parent="Walls"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -3.5, 1.5, -6.5)
mesh = SubResource("15")
material_override = SubResource("12")

[node name="NorthWallRight" type="MeshInstance3D" parent="Walls"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 3.5, 1.5, -6.5)
mesh = SubResource("15")
material_override = SubResource("12")

[node name="NorthWallLintel" type="MeshInstance3D" parent="Walls"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.75, -6.5)
mesh = SubResource("16")
material_override = SubResource("12")

[node name="EastParapet" type="MeshInstance3D" parent="Walls"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 6.5, 0.25, 0)
mesh = SubResource("17")
material_override = SubResource("13")

[node name="SouthParapet" type="MeshInstance3D" parent="Walls"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.25, 6.5)
mesh = SubResource("18")
material_override = SubResource("13")
```

Geometry check — every value below is a whole or half unit (AC5); the lintel's `2.75` centre is `2.5 + 0.5/2`, derived from the opening height, and its footprint edges land on `2.5` and `3.0`:

| Node | Size | Position | World span | On ring tiles |
|---|---|---|---|---|
| `WestWall` | `1 × 3 × 14` | `(-6.5, 1.5, 0)` | X `[-7,-6]`, Y `[0,3]`, Z `[-7,7]` | column `x = -7` |
| `NorthWallLeft` | `5 × 3 × 1` | `(-3.5, 1.5, -6.5)` | X `[-6,-1]`, Y `[0,3]`, Z `[-7,-6]` | row `z = -7` |
| `NorthWallRight` | `5 × 3 × 1` | `(3.5, 1.5, -6.5)` | X `[1,6]`, Y `[0,3]`, Z `[-7,-6]` | row `z = -7` |
| `NorthWallLintel` | `2 × 0.5 × 1` | `(0, 2.75, -6.5)` | X `[-1,1]`, Y `[2.5,3]`, Z `[-7,-6]` | row `z = -7` |
| `EastParapet` | `1 × 0.5 × 14` | `(6.5, 0.25, 0)` | X `[6,7]`, Y `[0,0.5]`, Z `[-7,7]` | column `x = 6` |
| `SouthParapet` | `12 × 0.5 × 1` | `(0, 0.25, 6.5)` | X `[-6,6]`, Y `[0,0.5]`, Z `[6,7]` | row `z = 6` |

**The door opening** is what the three `NorthWall*` pieces leave behind: X `[-1,1]` (2 units wide) and Y `[0,2.5]` (2.5 units tall), exactly R2. The two side pieces stop at X `±1` and the lintel bridges above `2.5`.

The `WestWall` and `EastParapet` run the full Z span `[-7,7]` and so own the corners; the north and south pieces stop at X `±6` and do not overlap them.

**Step 2: Verify**

```powershell
./tools/godot.ps1 --path . "res://scenes/poc3d/poc_entry.tscn"
```

Confirm: the room reads as an enclosed box from the fixed camera; the two far walls are full height with a clear doorway gap in the `−Z` wall; the two camera-side walls are ankle-height parapets that do not block the view; the player is stopped on all four sides, including across the doorway.

**Step 3: Commit**

```bash
git add scenes/poc3d/rooms/test_room.tscn
git commit -m "feat: enclose the POC room with far walls and near parapets (#103)"
```

---

### Task 6: The exit door trigger

**Files:**
- Create: `scripts/poc3d/exit_door.gd`, `scenes/poc3d/exit_door.tscn`
- Test: `tests/test_poc3d_interaction.gd` (append)

**Depends on:** none
**Parallelizable with:** Task 5 — Task 5 writes only `test_room.tscn`; this writes only new files plus an append to the test file.

**Step 1: Write the failing GUT test**

Append to `tests/test_poc3d_interaction.gd`:

```gdscript
# ── Exit door (R8 / AC4) ──────────────────────────────────────────────────────

const DOOR_SCENE := "res://scenes/poc3d/exit_door.tscn"


func _door() -> ExitDoor:
	var node: ExitDoor = load(DOOR_SCENE).instantiate()
	add_child_autofree(node)
	return node


func _player_body() -> Node3D:
	# A stand-in for Player3D: the door filters on the group, not the type.
	var body := Node3D.new()
	body.add_to_group(ExitDoor.PLAYER_GROUP)
	add_child_autofree(body)
	return body


func test_entering_fires_the_trigger_once():
	var door := _door()
	watch_signals(door)
	door._on_body_entered(_player_body())
	assert_signal_emit_count(door, "triggered", 1)


func test_the_trigger_reports_the_destination_id():
	var door := _door()
	door.destination_id = "cantina"
	watch_signals(door)
	door._on_body_entered(_player_body())
	assert_signal_emitted_with_parameters(door, "triggered", ["cantina"])


func test_jitter_inside_the_zone_does_not_refire():
	# AC4: "exactly once per entry". Physics can re-emit body_entered while the player is
	# pressed against the wall inside the trigger; the latch is what makes AC4 true.
	var door := _door()
	var body := _player_body()
	watch_signals(door)
	door._on_body_entered(body)
	door._on_body_entered(body)
	door._on_body_entered(body)
	assert_signal_emit_count(door, "triggered", 1)


func test_leaving_and_re_entering_fires_again():
	var door := _door()
	var body := _player_body()
	watch_signals(door)
	door._on_body_entered(body)
	door._on_body_exited(body)
	door._on_body_entered(body)
	assert_signal_emit_count(door, "triggered", 2)


func test_a_non_player_body_is_ignored():
	var door := _door()
	var crate := Node3D.new()
	add_child_autofree(crate)
	watch_signals(door)
	door._on_body_entered(crate)
	assert_signal_emit_count(door, "triggered", 0)


func test_a_non_player_leaving_does_not_clear_the_latch():
	var door := _door()
	var body := _player_body()
	var crate := Node3D.new()
	add_child_autofree(crate)
	watch_signals(door)
	door._on_body_entered(body)
	door._on_body_exited(crate)
	door._on_body_entered(body)
	assert_signal_emit_count(door, "triggered", 1)
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit
```
Expected: FAIL — `ExitDoor` undeclared, `exit_door.tscn` missing.

**Step 3: Write minimal implementation**

```gdscript
# scripts/poc3d/exit_door.gd
class_name ExitDoor
extends Area3D

## The doorway trigger. PRD 3 (#103) R8/AC4.
##
## It REPORTS and nothing more — real area-to-area transitions are PRD 6. The collision
## ring stays solid across the doorway, so the player is stopped at the threshold and this
## zone covers the floor tiles immediately in front of the opening.
##
## The door does not reach for the HUD itself: the HUD lives outside the SubViewport, in
## poc_entry.tscn, and a NodePath across that boundary would hard-wire the room to its
## host. poc_entry.gd connects `triggered` to HUD.show_message() at the composition root.

## Group the player joins in Player3D._ready(). Anything else entering is ignored.
const PLAYER_GROUP := "player"

## Console line format. The HUD message uses the same text.
const MESSAGE_FORMAT := "Exit door: %s"

## Fired once per entry. `destination_id` is passed through so PRD 6 has the hook already
## named when real transitions arrive.
signal triggered(destination_id: String)

## Where this door would lead. Nothing consumes it yet — that is the point of R8.
@export var destination_id := "unwired"

## The latch that makes AC4's "exactly once per entry" true. Physics can re-emit
## body_entered while the player is pressed against the wall inside the zone.
var _occupied := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if _occupied or not body.is_in_group(PLAYER_GROUP):
		return
	_occupied = true
	print(MESSAGE_FORMAT % destination_id)
	triggered.emit(destination_id)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group(PLAYER_GROUP):
		_occupied = false
```

Create `scenes/poc3d/exit_door.tscn`. The shape covers the two floor tiles in front of the opening — world X `[-1,1]`, Z `[-6,-5]` once placed in Task 7 — authored around the local origin:

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/poc3d/exit_door.gd" id="1"]

[sub_resource type="BoxShape3D" id="1"]
size = Vector3(2, 3, 1)

[node name="ExitDoor" type="Area3D"]
script = ExtResource("1")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("1")
```

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit
```
Expected: PASS.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" `destination_id` is exported, so a second and third door in the same room each report their own id and each carry their own latch. Proceed.

**Step 6: Commit**

```bash
git add scripts/poc3d/exit_door.gd scenes/poc3d/exit_door.tscn tests/test_poc3d_interaction.gd
git commit -m "feat: add the reporting exit-door trigger (#103)"
```

---

### Task 7: Place the door and connect it to the HUD

**Files:**
- Modify: `scenes/poc3d/rooms/test_room.tscn`, `scripts/poc3d/poc_entry.gd`

**Depends on:** Task 5 (same file, and the doorway must exist), Task 6 (instances `exit_door.tscn`).
**Parallelizable with:** none — it is the join point of Tasks 5 and 6 and writes a file Task 5 also writes.

**Step 1: Write the content**

**(a)** In `scenes/poc3d/rooms/test_room.tscn`, add the ext_resource and instance the door as a child of the scene root:

```
[ext_resource type="PackedScene" path="res://scenes/poc3d/exit_door.tscn" id="9"]
```

```
[node name="ExitDoor" parent="." instance=ExtResource("9")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, -5.5)
destination_id = "corridor"
```

Footprint check: the `2 × 3 × 1` shape centred at `(0, 1.5, -5.5)` covers world X `[-1,1]`, Y `[0,3]`, Z `[-6,-5]` — the two floor tiles `(-1,-6)` and `(0,-6)`, directly in front of the doorway opening Task 5 left at X `[-1,1]`. All whole or half units (AC5).

**(b)** In `scripts/poc3d/poc_entry.gd`, connect the room's door to the HUD. Add the constants and `@onready`s next to the existing `_viewport`:

```gdscript
## The door reports through the HUD's existing message banner rather than a fade: this
## PRD does no transitions, and hud.gd.show_message() already exists and auto-hides.
const DOOR_NODE_PATH := "SubViewportContainer/SubViewport/TestRoom/ExitDoor"
const HUD_NODE_PATH := "HUD"

@onready var _door: ExitDoor = get_node(DOOR_NODE_PATH)
@onready var _hud: CanvasLayer = get_node(HUD_NODE_PATH)
```

and extend `_ready()` — keeping the existing editor-hint early return and the render-target warning exactly as they are — by appending one line after the warning block:

```gdscript
	_door.triggered.connect(_on_door_triggered)
```

then add:

```gdscript
## Wiring the room to its host lives HERE, at the composition root, not inside the room:
## the HUD is deliberately outside the SubViewport, and a NodePath reaching across that
## boundary from inside the room would couple the room to whatever hosts it.
func _on_door_triggered(destination_id: String) -> void:
	_hud.show_message(ExitDoor.MESSAGE_FORMAT % destination_id)
```

Extend the tree diagram in that file's header comment to show `ExitDoor` under `TestRoom`.

**Step 2: Verify**

```powershell
./tools/godot.ps1 -Console --path . "res://scenes/poc3d/poc_entry.tscn"
```

Confirm: walking into the doorway prints `Exit door: corridor` on the console **once** and shows the same text in the HUD's message banner; backing out and walking in again fires it again; standing still inside the doorway does not spam it.

**Step 3: Commit**

```bash
git add scenes/poc3d/rooms/test_room.tscn scripts/poc3d/poc_entry.gd
git commit -m "feat: place the exit door and report through the HUD banner (#103)"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 5, Task 6 | Task 5 writes only `test_room.tscn`; Task 6 writes only new files plus a test append. No shared symbols. |
| B (sequential) | Task 7 | Depends on Group A — must run after both complete; needs Task 5's doorway and Task 6's scene, and writes `test_room.tscn` again |

### Smoketest Checkpoint 2 — enclosed room, working door trigger

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: All tests pass, zero failures.

**Step 3: Launch the POC and verify visually**
```powershell
./tools/godot.ps1 -Console --path . "res://scenes/poc3d/poc_entry.tscn"
```

**Step 4: Confirm with user**

Ask the user to verify (**AC1** and **AC4**):
- The room reads as enclosed from the fixed camera; the near walls do not occlude the interior.
- A clear 2-wide doorway gap sits in the far `−Z` wall with a lintel above it.
- The player is stopped by all four sides, including across the doorway.
- Walking behind the console and behind the crate occludes the sprite correctly — the sprite disappears behind the geometry rather than drawing through it or being hidden entirely.
- Entering the doorway shows `Exit door: corridor` in the HUD banner and prints it once on the console; leaving and re-entering fires again; loitering in the doorway does not repeat it.

Wait for confirmation before starting Batch 3.

---

## Batch 3 — Maris and the dialogue box

### Task 8: `PocDialogueLine` — the hand-built Yarn line

**Files:**
- Create: `scripts/poc3d/poc_dialogue_line.gd`
- Test: `tests/test_poc3d_interaction.gd` (append)

**Depends on:** none
**Parallelizable with:** none — Task 9 appends to the same `tests/test_poc3d_interaction.gd`, so the two must be sequential despite having no symbol dependency.

**Background the implementer needs.** `dialogue_box.run_line_async()` takes a plain `Dictionary` and feeds it to `YarnSpinner.LocalizedLine.from_dictionary()`. `YarnSpinner` is the **pure GDScript** helper in `addons/YarnSpinner-Godot/Runtime/Views/GDScriptHelper.gd` — there is no C# and no `DialogueRunner` involved, which is why this works headlessly and why `dialogue_box.gd` needs no modification. The speaker name is read from a markup attribute named `character` covering the `"Speaker: "` prefix; `text_without_character_name` deletes that range, leaving the body.

**Step 1: Write the failing GUT test**

Append to `tests/test_poc3d_interaction.gd`:

```gdscript
# ── Hardcoded dialogue line (R7 / AC3) ───────────────────────────────────────

const SPEAKER := "Maris"
const BODY := "The recycler's coughing again. Third time this week."


func _localized() -> YarnSpinner.LocalizedLine:
	return YarnSpinner.LocalizedLine.from_dictionary(PocDialogueLine.build(SPEAKER, BODY))


func test_the_line_round_trips_into_a_localized_line():
	assert_not_null(_localized(),
		"from_dictionary() returns null and push_errors when a required key is missing")


func test_the_speaker_is_recoverable_as_the_character_name():
	# This is what drives dialogue_box's SpeakerLabel and its portrait lookup.
	assert_eq(_localized().character_name, SPEAKER)


func test_the_body_survives_with_the_speaker_prefix_stripped():
	assert_eq(_localized().text_without_character_name.text, BODY)


func test_the_raw_text_keeps_the_full_line():
	assert_eq(_localized().raw_text, SPEAKER + PocDialogueLine.SPEAKER_SEPARATOR + BODY)


func test_the_speaker_maps_to_a_real_portrait_index():
	# dialogue_box falls back to FALLBACK_PORTRAIT_INDEX for an unknown speaker; AC3 wants
	# Maris's actual portrait, so the name must match NPC_PORTRAIT_INDEX exactly.
	var box := load("res://scenes/ui/dialogue_box.tscn").instantiate()
	add_child_autofree(box)
	assert_true(box.NPC_PORTRAIT_INDEX.has(SPEAKER),
		"'%s' is not a key of dialogue_box.NPC_PORTRAIT_INDEX" % SPEAKER)
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit
```
Expected: FAIL — `PocDialogueLine` undeclared.

**Step 3: Write minimal implementation**

```gdscript
# scripts/poc3d/poc_dialogue_line.gd
class_name PocDialogueLine
extends RefCounted

## Builds the Dictionary that dialogue_box.run_line_async() expects, without YarnSpinner's
## DialogueRunner. PRD 3 (#103) R7.
##
## Why this exists: DialogueRunner is set up in main.gd._setup_dialogue_runner(), which
## this PRD deliberately does not touch, and re-doing that Yarn wiring would prove nothing
## about the 3D move. The question worth answering is whether the dialogue UI LAYERS
## correctly over the low-res SubViewport — a hardcoded line answers that far cheaper.
##
## The shape below is exactly what YarnSpinner.LocalizedLine.from_dictionary() and
## MarkupParseResult.from_dictionary() read (see
## addons/YarnSpinner-Godot/Runtime/Views/GDScriptHelper.gd). Both push_error and return
## null on a missing key, so a drift in that addon fails loudly in this file's tests
## rather than silently on screen.

## The markup attribute name YarnSpinner reserves for the speaker.
const CHARACTER_ATTRIBUTE := "character"

## What separates the speaker from the body in the flattened text. The `character`
## attribute covers the speaker plus this separator, and delete_range() removes exactly
## that span to recover the body.
const SPEAKER_SEPARATOR := ": "

## Line ids are Yarn's localisation handle. Nothing localises a POC line, but the key must
## be present and distinguishable in a log.
const LINE_ID_PREFIX := "line:poc-"


static func build(speaker: String, body: String) -> Dictionary:
	var prefix := speaker + SPEAKER_SEPARATOR
	var full_text := prefix + body
	return {
		"text": {
			"text": full_text,
			"attributes": [{
				"name": CHARACTER_ATTRIBUTE,
				"position": 0,
				"length": prefix.length(),
				"properties": {"name": speaker},
			}],
		},
		"text_id": LINE_ID_PREFIX + speaker.to_lower(),
		"raw_text": full_text,
		"substitutions": [],
		"metadata": [],
	}
```

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit
```
Expected: PASS.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" `build()` takes both the speaker and the body as parameters and derives the attribute length from the prefix, so a second speaker with a different name length works unchanged. Proceed.

**Step 6: Commit**

```bash
git add scripts/poc3d/poc_dialogue_line.gd tests/test_poc3d_interaction.gd
git commit -m "feat: build a Yarn line dictionary without the DialogueRunner (#103)"
```

---

### Task 9: `InteractTarget` — the NPC's interaction volume

**Files:**
- Create: `scripts/poc3d/interact_target.gd`
- Modify: `scenes/poc3d/npc3d.tscn`
- Test: `tests/test_poc3d_interaction.gd` (append)

**Depends on:** Task 1 (uses `InteractScan.INTERACTABLE_GROUP` and `INTERACT_METHOD`) and Task 8 (same test file).
**Parallelizable with:** none — it appends to `tests/test_poc3d_interaction.gd`, which Task 8 also writes.

**Background.** `Npc3D` is a plain `Node3D`, and `tests/test_poc3d_npc3d.gd` asserts it is **not** a `CharacterBody3D`. A `Node3D` is invisible to the player's `Area3D` scan, so the NPC needs a child `Area3D`. Forwarding through a tiny generic node — rather than re-typing `Npc3D`'s root — keeps every PRD 2 test green and gives the NPC the *same* interactable shape as the console.

**Step 1: Write the failing GUT test**

Append to `tests/test_poc3d_interaction.gd`:

```gdscript
# ── The NPC's interact target (R7) ───────────────────────────────────────────

const NPC_SCENE := "res://scenes/poc3d/npc3d.tscn"
const INTERACT_TARGET_NODE := "InteractTarget"


func test_the_npc_carries_an_interact_target_in_the_group():
	var npc = load(NPC_SCENE).instantiate()
	add_child_autofree(npc)
	await wait_frames(1)
	var target := npc.get_node_or_null(INTERACT_TARGET_NODE)
	assert_not_null(target, "npc3d.tscn must carry an %s Area3D" % INTERACT_TARGET_NODE)
	assert_true(InteractScan.is_interactable(target),
		"the NPC's interact target must satisfy the same contract as the console")


func test_the_interact_target_forwards_to_its_parent():
	var parent := Node3D.new()
	parent.set_script(load("res://tests/helpers/interactable_stub.gd"))
	var target := InteractTarget.new()
	parent.add_child(target)
	add_child_autofree(parent)
	await wait_frames(1)
	target.interact()
	assert_eq(parent.interact_count, 1)


func test_the_interact_target_ignores_a_parent_that_cannot_interact():
	var parent := Node3D.new()
	var target := InteractTarget.new()
	parent.add_child(target)
	add_child_autofree(parent)
	await wait_frames(1)
	target.interact()
	pass_test("forwarding to a parent without interact() must not error")
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit
```
Expected: FAIL — `InteractTarget` undeclared, and `npc3d.tscn` has no such child.

**Step 3: Write minimal implementation**

```gdscript
# scripts/poc3d/interact_target.gd
class_name InteractTarget
extends Area3D

## An interaction volume that forwards to the node that owns the behaviour.
##
## PRD 3 (#103) R7. Npc3D is a plain Node3D — tests/test_poc3d_npc3d.gd asserts it is not
## a physics body — so it is invisible to the player's Area3D scan. Rather than re-typing
## Npc3D's root and mixing "is a character" with "is an interaction volume", the volume is
## a child that hands the call back up. That gives the NPC the same interactable shape as
## the console: one contract, not two.


func _ready() -> void:
	add_to_group(InteractScan.INTERACTABLE_GROUP)


func interact() -> void:
	var owner_node := get_parent()
	if owner_node == null or not owner_node.has_method(InteractScan.INTERACT_METHOD):
		return
	owner_node.interact()
```

Add to `scenes/poc3d/npc3d.tscn` — a 1×2×1 box, one tile wide and sprite-tall, centred on the NPC's body:

```
[ext_resource type="Script" path="res://scripts/poc3d/interact_target.gd" id="4"]

[sub_resource type="BoxShape3D" id="1"]
size = Vector3(1, 2, 1)

[node name="InteractTarget" type="Area3D" parent="."]
script = ExtResource("4")

[node name="CollisionShape3D" type="CollisionShape3D" parent="InteractTarget"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)
shape = SubResource("1")
```

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: PASS — run the whole suite here, since `npc3d.tscn` changed and `tests/test_poc3d_npc3d.gd` asserts against it.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" `InteractTarget` names no parent type and calls through `has_method`, so it forwards for a second NPC, a workbench, or anything else that grows an `interact()`. Proceed.

**Step 6: Commit**

```bash
git add scripts/poc3d/interact_target.gd scenes/poc3d/npc3d.tscn tests/test_poc3d_interaction.gd
git commit -m "feat: give the 3D NPC an interaction volume (#103)"
```

---

### Task 10: `Npc3D` speaks a line

**Files:**
- Modify: `scripts/poc3d/npc3d.gd`
- Test: `tests/test_poc3d_interaction.gd` (append)

**Depends on:** Task 8 (`PocDialogueLine`), Task 9 (`InteractTarget` forwards to this).
**Parallelizable with:** none — it is the join point of Tasks 8 and 9.

**Step 1: Write the failing GUT test**

Append to `tests/test_poc3d_interaction.gd`:

```gdscript
# ── Npc3D dialogue wiring (R7) ───────────────────────────────────────────────

func _npc_with_line() -> Node3D:
	var npc = load(NPC_SCENE).instantiate()
	npc.speaker_name = SPEAKER
	npc.dialogue_line = BODY
	add_child_autofree(npc)
	await wait_frames(1)
	return npc


func test_an_npc_without_a_line_does_not_open_the_dialogue_box():
	var box := load("res://scenes/ui/dialogue_box.tscn").instantiate()
	add_child_autofree(box)
	var npc = load(NPC_SCENE).instantiate()
	add_child_autofree(npc)
	await wait_frames(1)
	npc.interact()
	await wait_frames(1)
	assert_false(box.visible, "an NPC with no authored line must stay silent")
	get_tree().paused = false


func test_interacting_shows_the_line_in_the_real_dialogue_box():
	var box := load("res://scenes/ui/dialogue_box.tscn").instantiate()
	add_child_autofree(box)
	var npc = await _npc_with_line()
	npc.interact()
	await wait_frames(2)
	assert_true(box.visible, "dialogue_box.tscn must be shown by the NPC's interact()")
	var speaker: Label = box.get_node(
		"PanelContainer/MarginContainer/HBoxContainer/ContentContainer/SpeakerLabel")
	var text: RichTextLabel = box.get_node(
		"PanelContainer/MarginContainer/HBoxContainer/ContentContainer/DialogueText")
	assert_eq(speaker.text, SPEAKER)
	assert_eq(text.text, BODY)
	# on_dialogue_start_async() pauses the tree; leave it clean for the next test.
	box.on_dialogue_complete_async()
	await wait_frames(1)
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit
```
Expected: FAIL — `Invalid assignment of property 'speaker_name'` / `Npc3D` has no `interact()`.

**Step 3: Write minimal implementation**

In `scripts/poc3d/npc3d.gd`, add the constant and the two exports below the existing `facing` export:

```gdscript
## The group dialogue_box.gd joins in its own _ready(). Looked up rather than hard-pathed:
## the box lives in poc_entry.tscn, outside the SubViewport this NPC renders into, and a
## NodePath across that boundary would couple the room to its host.
const DIALOGUE_BOX_GROUP := "dialogue_box"

## Who is speaking. Must match a key of dialogue_box.NPC_PORTRAIT_INDEX to get a portrait
## rather than the fallback. Empty means this NPC is silent.
@export var speaker_name := ""

## The single hardcoded line. R7: no YarnSpinner, no DialogueRunner, no yarnproject —
## what this PRD needs to prove is that the dialogue UI layers over the low-res
## SubViewport legibly, and one line answers that.
@export_multiline var dialogue_line := ""
```

and append:

```gdscript
## Duck-typed entry point, reached via the child InteractTarget. Drives the REAL
## dialogue box through its real view protocol — typewriter, portrait, tree pause and
## ui_accept advance all included — so what AC3 is judged on is the production UI.
func interact() -> void:
	if speaker_name.is_empty() or dialogue_line.is_empty():
		return
	var boxes := get_tree().get_nodes_in_group(DIALOGUE_BOX_GROUP)
	if boxes.is_empty():
		push_warning("Npc3D: no node in the '%s' group — is dialogue_box.tscn instanced?"
			% DIALOGUE_BOX_GROUP)
		return
	var box: Node = boxes[0]
	box.on_dialogue_start_async()
	await box.run_line_async(PocDialogueLine.build(speaker_name, dialogue_line))
	box.on_dialogue_complete_async()
```

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: PASS — whole suite, since `npc3d.gd` is covered by `tests/test_poc3d_npc3d.gd` too.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" Both the speaker and the line are exported per instance, and the box is found by group, so a second and third NPC each speak their own line with no code change. Proceed.

**Step 6: Commit**

```bash
git add scripts/poc3d/npc3d.gd tests/test_poc3d_interaction.gd
git commit -m "feat: let the 3D NPC speak a hardcoded line (#103)"
```

---

### Task 11: Instance the dialogue box and cast Maris

**Files:**
- Modify: `scenes/poc3d/poc_entry.tscn`, `scenes/poc3d/rooms/test_room.tscn`
- Test: `tests/test_poc3d_interaction.gd` (append)

**Depends on:** Task 10 — sets the exports it defines.
**Parallelizable with:** none — sole writer of `poc_entry.tscn` in this batch, and it depends on Task 10.

**Step 1: Write the failing GUT test**

Append to `tests/test_poc3d_interaction.gd` — the structural half of AC3, which the manual smoketest cannot regression-guard:

```gdscript
# ── AC3 structure: the dialogue box is NOT inside the low-res target ──────────

const ENTRY_SCENE := "res://scenes/poc3d/poc_entry.tscn"


func test_the_dialogue_box_draws_above_the_low_res_viewport():
	# AC3. Parented under the SubViewport it would render at 480x270 and upscale with the
	# world, turning the text to mush — the same invariant the HUD has in
	# tests/test_poc3d_pipeline.gd, and the reason the box is a SIBLING.
	var entry := load(ENTRY_SCENE).instantiate()
	add_child_autofree(entry)
	await wait_frames(2)
	var box := entry.find_child("DialogueBox", true, false)
	assert_not_null(box, "poc_entry.tscn no longer instances dialogue_box.tscn")
	var viewport: SubViewport = entry.get_node("SubViewportContainer/SubViewport")
	assert_false(viewport.is_ancestor_of(box),
		"the dialogue box has been reparented under the SubViewport — it must stay a sibling")
	assert_true(box is CanvasLayer)


func test_the_room_casts_maris_with_a_line():
	var entry := load(ENTRY_SCENE).instantiate()
	add_child_autofree(entry)
	await wait_frames(2)
	var npc := entry.find_child("NPC3D", true, false)
	assert_not_null(npc, "the test room no longer has an NPC3D")
	assert_eq(npc.speaker_name, SPEAKER)
	assert_false(npc.dialogue_line.is_empty(), "Maris must have an authored line")
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_interaction.gd" -gexit
```
Expected: FAIL — no `DialogueBox` in `poc_entry.tscn`, `speaker_name` empty.

**Step 3: Write the implementation**

**(a)** In `scenes/poc3d/poc_entry.tscn`, add the ext_resource and instance the box as a **sibling** of `SubViewportContainer`, after `HUD`:

```
[ext_resource type="PackedScene" path="res://scenes/ui/dialogue_box.tscn" id="4"]
```

```
[node name="DialogueBox" parent="." instance=ExtResource("4")]
```

`dialogue_box.tscn` is a `CanvasLayer` at `layer = 10` (the HUD is `layer = 1`), so as a sibling it draws above both the upscaled world and the HUD at full window resolution. **Instance it unmodified — set no properties on it.**

**(b)** In `scenes/poc3d/rooms/test_room.tscn`, set the exports on the existing `NPC3D` instance, leaving its transform and `facing` alone:

```
[node name="NPC3D" parent="." instance=ExtResource("7")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.5, 0, 1.5)
facing = "right"
speaker_name = "Maris"
dialogue_line = "The recycler's coughing again. Third time this week. Dex says it's fine. Dex says a lot of things."
```

**(c)** Extend the tree diagram in `scripts/poc3d/poc_entry.gd`'s header comment to show `DialogueBox` as a sibling, with a one-line note that it draws above the HUD on layer 10.

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: PASS — whole suite, including `tests/test_poc3d_pipeline.gd`, whose "exactly one light" and "HUD not inside the viewport" assertions must survive this change.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" One dialogue box serves every NPC — the group lookup in Task 10 takes the first, and there is deliberately only ever one. Proceed.

**Step 6: Commit**

```bash
git add scenes/poc3d/poc_entry.tscn scenes/poc3d/rooms/test_room.tscn scripts/poc3d/poc_entry.gd tests/test_poc3d_interaction.gd
git commit -m "feat: layer the dialogue box over the POC and cast Maris (#103)"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 3

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 8 | Writes `poc_dialogue_line.gd` and appends to the test file |
| B (sequential) | Task 9 | Depends on Task 8 — appends to the same test file |
| C (sequential) | Task 10 | Depends on Tasks 8 and 9 — uses `PocDialogueLine`, and `InteractTarget` forwards into it |
| D (sequential) | Task 11 | Depends on Task 10 — sets the exports it defines |

**This batch has no parallel group.** Tasks 8, 9, 10 and 11 all append to `tests/test_poc3d_interaction.gd`, and Tasks 10 and 11 additionally have real symbol dependencies. Serialising them is the shared-file constraint, not a missed opportunity.

### Smoketest Checkpoint 3 — Maris talks, legibly, above the low-res world

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: All tests pass, zero failures.

**Step 3: Launch the POC and verify visually**
```powershell
./tools/godot.ps1 -Console --path . "res://scenes/poc3d/poc_entry.tscn"
```

**Step 4: Confirm with user**

Ask the user to verify (**AC3** — this is the one the go/no-go gate turns on most):
- Walking up to Maris and pressing **Enter** opens the dialogue box.
- The text is **crisp** — full window resolution, not upscaled with the 480×270 world. If it looks like the pixel-art world, the box has been parented wrongly.
- The box sits **above** everything: the world, the HUD.
- Maris's portrait appears (not the fallback), the speaker label reads `Maris`, and the typewriter runs.
- The player cannot move while the line is up, and **Enter** dismisses it and returns control.
- Walking away and interacting again replays it.

Wait for confirmation before starting Batch 4.

---

## Batch 4 — Documentation and the acceptance sweep

### Task 12: Document the room in the POC README

**Files:**
- Modify: `scenes/poc3d/README.md`

**Depends on:** Task 11 — documents the finished room.
**Parallelizable with:** Task 13 — Task 13 writes no files at all; this writes only the README.

**Step 1: Write the content**

Add a `## Greybox room, interaction & NPC (PRD 3, #103)` section after the existing PRD 2 section, and correct the two places the existing text is now stale.

Corrections to existing text:
- The **Shape** table's `rooms/test_room.tscn` row currently reads "Greybox geometry, one directional light, the camera". Extend it to mention the walls, the console, the crate and the door.
- The **Collision is authored in 2D** section documents `blocked` as "eight explicitly authored tiles covering `BlockA`, `BlockB`, and `BlockC`". Rewrite that sentence for the four tiles now authored — `(2,-1)` for `BlockB`, `(-6,-1)`/`(-6,0)` for the console, `(1,1)` for the crate — and note that `BlockA` and `BlockC` were removed in #103. **Keep the paragraph explaining why `BlockB` and `ReferenceSprite` sit where they do** — it is still load-bearing.

The new section must cover, in prose matching the file's existing voice:

- **Room shape.** The 12×12 floor, the collision ring from `border_for_floor`, and the fact that the walls added in #103 are **purely visual** — every footprint was already blocked, so no collision changed.
- **Why two walls are short.** The camera looks from the +X/+Z corner, so the `−X`/`−Z` walls are 3 units and the `+X`/`+Z` walls are 0.5-unit parapets. All four footprints are real and grid-snapped so PRD 4 has somewhere to drop kit pieces on every side.
- **The door does not open.** The ring stays solid across the doorway; the player is stopped at the threshold and the `Area3D` covering the two tiles in front reports through `triggered` → `poc_entry.gd` → `HUD.show_message()`. Real transitions are PRD 6. The `_occupied` latch is what makes "exactly once per entry" true against physics jitter.
- **The interaction contract.** `InteractScan` is node-free on purpose (the `SpriteFacing` pattern); it mirrors `scripts/characters/player.gd._try_interact()` — bodies before areas, group plus visibility — and adds `has_method("interact")`, which differs from 2D only where 2D crashes. Both the console and the NPC reach it through an `Area3D` in the `interactable` group; the NPC's is a forwarding `InteractTarget` child because `Npc3D` is a plain `Node3D`.
- **Dialogue without YarnSpinner.** `PocDialogueLine.build()` hand-builds the dictionary `dialogue_box.run_line_async()` wants. `YarnSpinner` is the pure-GDScript helper in `addons/YarnSpinner-Godot/Runtime/Views/GDScriptHelper.gd`, so no C#, no `DialogueRunner`, no yarnproject — and `dialogue_box.gd`/`.tscn` are **completely unmodified**. Note that `speaker_name` must match a key of `dialogue_box.NPC_PORTRAIT_INDEX` or the portrait silently falls back.
- **The dialogue box is a sibling.** Same invariant as the HUD, for the same reason, and it is `layer = 10` so it draws above the HUD's `layer = 1`.
- **The go/no-go gate.** State plainly that this room is where the epic's decision is made, and that PRD 4 must not start before it is answered.

**Step 2: Verify**

Read the file top to bottom. Confirm no stale claim survives: no reference to `BlockA` or `BlockC` as present, and the `blocked` tile list matches `test_room.tscn` exactly.

**Step 3: Commit**

```bash
git add scenes/poc3d/README.md
git commit -m "docs: describe the greybox room, interaction and NPC (#103)"
```

---

### Task 13: The acceptance sweep

**Files:** none — this task only runs and reports.

**Depends on:** Task 11 — needs the feature complete.
**Parallelizable with:** Task 12 — Task 12 writes only the README; this writes nothing.

**Step 1: Verify AC6 — nothing protected was touched**

```powershell
git diff --name-only origin/master...HEAD
```

Expected: the list contains **none** of `scenes/main.tscn`, `scripts/main.gd`, anything under `scenes/areas/`, `scenes/ui/hud.tscn`, `scripts/ui/hud.gd`, `scenes/ui/dialogue_box.tscn`, `scripts/ui/dialogue_box.gd`, `project.godot`.

If any appears, stop and report — do not "fix" it by reverting silently.

**Step 2: Verify AC8 — the full suite is green**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: zero failures, zero errors. Record the pass count in the report.

**Step 3: Verify AC7 — the 2D game still plays**

```powershell
./tools/godot.ps1 --path .
```

Expected: character creation, then the trade dock. Walk around, talk to an NPC, open the crafting panel. Confirm no regression, then quit.

**Step 4: Report**

Post a short summary against each acceptance criterion — AC1 through AC9 — saying which are confirmed and by what evidence (test name, or "confirmed by the user at Checkpoint N"). AC1 and AC3 are manual by nature; cite the checkpoint at which the user confirmed them.

**Step 5: Commit**

Nothing to commit. If any step above required a fix, that fix is its own commit with its own re-verification.

---

#### Parallel Execution Groups — Smoketest Checkpoint 4

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 12, Task 13 | Task 12 writes only `README.md`; Task 13 writes nothing. No shared state. |

### Smoketest Checkpoint 4 — the go/no-go gate

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: All tests pass, zero failures.

**Step 3: Launch the POC and verify visually**
```powershell
./tools/godot.ps1 -Console --path . "res://scenes/poc3d/poc_entry.tscn"
```

**Step 4: Confirm with user**

Walk the whole room once more and confirm AC1–AC9 end to end.

Then put **the gate** to the user, plainly, as its own question — this is the entire purpose of the epic and it is not the implementer's call:

> **Does sprite-in-3D look and feel right for Outpost Nova?**
>
> A "no" costs three small PRDs and leaves the 2D game exactly as it was. PRD 4 (#104) must not start before this is answered.

Record the answer as a comment on issue #103. Do not open, unblock or start #104 under any circumstances without an explicit "go".

---

## Deliberate deviations from the issue text

Recorded here so a reviewer does not read them as misses. All were settled with the user before this plan was written.

| Issue text | What this plan does | Why |
|---|---|---|
| "new `scenes/poc3d/poc_room.tscn`" | Evolves `scenes/poc3d/rooms/test_room.tscn` in place | It is all one POC; a second room would fork the pipeline tests and the documented `ReferenceSprite` framing |
| R1: flat-coloured floor | Keeps the existing textured `TileFloor` | `tests/test_poc3d_pipeline.gd` pins that node's nearest-filtering material, and the texel density is what PRD 1 exists to show. Walls, console and crate **are** flat-coloured per R1 |
| R2: wall height is 3 units | Far walls 3 units; camera-side walls 0.5-unit parapets | Full-height near walls occlude the entire interior from the fixed camera. All four footprints are real, grid-snapped and collidable |
| "new `scripts/poc3d/poc_room.gd` for door and console wiring" | No room script — the door is self-contained and `poc_entry.gd` connects it to the HUD | DRY: a room script whose only job is forwarding one signal is a layer with no content |
| R4: "preserving today's 2D contract shape" | Adds a `has_method("interact")` filter | Differs from 2D only where 2D currently crashes |
