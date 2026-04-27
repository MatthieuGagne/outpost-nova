# ResourcePlot & Layout — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rewrite `resource_node.gd` as a `ResourcePlot` state machine (EMPTY→GROWING), build a dismissable `ActionMenu` popup wired to `ClockManager`, move Quen to the Security Post, and add a ResourcePlot to the Cantina (issue #73, part of #65).

**Architecture:** `resource_node.gd` becomes a state machine; `interact()` delegates to `ActionMenu` via group lookup. `ActionMenu` is a CanvasLayer added to `main.tscn` and found via group `"action_menu"`. NPC_SPAWN_AREAS in `main.gd` is updated to move Quen; scene files get the matching spawn node change.

**Tech Stack:** Godot 4.6 / GDScript, GUT test framework.

**Prerequisite:** Plan A (#71) must be merged first — `ClockManager.can_act()` and `ClockManager.commit_action()` must exist.

## Open questions (must resolve before starting)

- none

---

### Task 1: Write failing GUT tests for ResourcePlot

**Files:**
- Create: `tests/test_resource_plot.gd`

**Depends on:** none
**Parallelizable with:** none — must fail before Task 2 implements the code.

**Step 1: Write the failing GUT test**

Create `tests/test_resource_plot.gd`:

```gdscript
# tests/test_resource_plot.gd
extends GutTest

var _plot: Node = null

func before_each():
	_plot = load("res://scenes/resource_node.tscn").instantiate()
	add_child_autofree(_plot)

func test_starts_in_empty_state():
	assert_eq(_plot.get_plot_state(), _plot.PlotState.EMPTY)

func test_start_plot_transitions_to_growing():
	_plot.start_plot()
	assert_eq(_plot.get_plot_state(), _plot.PlotState.GROWING)

func test_start_plot_emits_plot_state_changed():
	watch_signals(_plot)
	_plot.start_plot()
	assert_signal_emitted(_plot, "plot_state_changed")

func test_start_plot_when_growing_is_idempotent():
	_plot.start_plot()
	_plot.start_plot()
	assert_eq(_plot.get_plot_state(), _plot.PlotState.GROWING)

func test_interact_when_growing_does_not_change_state():
	_plot.start_plot()
	_plot.interact()
	assert_eq(_plot.get_plot_state(), _plot.PlotState.GROWING)
```

**Step 2: Run test to verify it fails**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_resource_plot.gd
```

Expected: FAIL — `PlotState`, `get_plot_state`, `start_plot`, and `plot_state_changed` do not exist yet.

**Step 3: Commit**

```bash
git add tests/test_resource_plot.gd
git commit -m "test: add failing ResourcePlot state machine tests"
```

---

### Task 2: Rewrite resource_node.gd as ResourcePlot state machine

**Files:**
- Modify: `scripts/resource_node.gd`

**Depends on:** Task 1
**Parallelizable with:** Task 3 — Task 3 modifies the scene file; they share no GDScript state.

**Step 1: Replace resource_node.gd entirely**

```gdscript
# scripts/resource_node.gd
extends Area2D

enum PlotState { EMPTY, GROWING }

signal plot_state_changed(new_state: PlotState)

@export var resource_id: String = "rations"
@export var yield_amount: int = 1

var _state: PlotState = PlotState.EMPTY

func _ready() -> void:
	add_to_group("interactable")

func interact() -> void:
	if _state == PlotState.GROWING:
		return
	var menus := get_tree().get_nodes_in_group("action_menu")
	if menus.is_empty():
		return
	menus[0].show_for_plot(self)

func start_plot() -> void:
	if _state != PlotState.EMPTY:
		return
	_state = PlotState.GROWING
	plot_state_changed.emit(_state)

func get_plot_state() -> PlotState:
	return _state
```

**Step 2: Run tests to verify they pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_resource_plot.gd
```

Expected: All ResourcePlot tests PASS.

Run full suite:

```bash
godot --headless -s addons/gut/gut_cmdln.gd
```

Expected: All tests pass. Zero failures.

**Step 3: Refactor checkpoint**

`start_plot()` guards on `_state != PlotState.EMPTY` — correct, idempotent when called twice. State machine will extend to PAUSED/COLLECTING in a future plan; enum and signal are already the right shape.

**Step 4: Commit**

```bash
git add scripts/resource_node.gd
git commit -m "feat: rewrite resource_node.gd as ResourcePlot state machine (EMPTY, GROWING)"
```

---

### Task 3: Remove Timer node from resource_node.tscn

**Files:**
- Modify: `scenes/resource_node.tscn`

**Depends on:** none
**Parallelizable with:** Task 2 — different output file; the scene change is independent of the script.

**Step 1: Update resource_node.tscn**

Replace the entire contents of `scenes/resource_node.tscn`. Remove the `Timer` node — the new state machine does not use a cooldown timer:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resource_node.gd" id="1"]

[sub_resource type="RectangleShape2D" id="1"]
size = Vector2(16, 16)

[node name="ResourceNode" type="Area2D"]
script = ExtResource("1")

[node name="Sprite2D" type="Sprite2D" parent="."]
modulate = Color(0.2, 0.9, 0.3, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("1")
```

**Step 2: Verify**

Open Godot editor: `godot`. Confirm `scenes/resource_node.tscn` opens without errors and has no Timer node.

**Step 3: Commit**

```bash
git add scenes/resource_node.tscn
git commit -m "chore: remove unused Timer node from resource_node scene"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 1 → Task 2 | Task 2 implements what Task 1 tests |
| B (parallel with A) | Task 3 | Different output file (tscn vs gd); no dependency on Tasks 1 or 2 |

---

### Smoketest Checkpoint 1 — ResourcePlot tests pass, scene updated

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass including new `test_resource_plot.gd`. Zero failures.

**Step 3: Launch game and verify visually**
```bash
godot
```
Expected: Game launches. The Cantina ResourceNode (green sprite) is visible and no longer has a cooldown timer. Interacting with it does nothing visible yet (no ActionMenu exists). Game does not crash.

**Step 4: Confirm with user**
Confirm tests pass and game launches before proceeding to Batch 2.

---

### Task 4: Create ActionMenu script and scene

**Files:**
- Create: `scripts/ui/action_menu.gd`
- Create: `scenes/ui/action_menu.tscn`

**Depends on:** Smoketest Checkpoint 1
**Parallelizable with:** none — Task 5 (main.tscn) depends on the scene existing.

**Step 1: Create action_menu.gd**

Create `scripts/ui/action_menu.gd`:

```gdscript
# scripts/ui/action_menu.gd
extends CanvasLayer

@onready var _preview_lbl: Label = $PanelContainer/VBoxContainer/PreviewLabel
@onready var _start_btn: Button = $PanelContainer/VBoxContainer/StartButton

const START_COST_MINUTES: int = 90

var _current_plot: Node = null

func _ready() -> void:
	add_to_group("action_menu")
	_start_btn.pressed.connect(_on_start_pressed)
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		hide()
		_current_plot = null
		get_viewport().set_input_as_handled()

func show_for_plot(plot: Node) -> void:
	_current_plot = plot
	var can_start := ClockManager.can_act(START_COST_MINUTES)
	_preview_lbl.text = "Yield: %d %s\nTime: 1.5 hr%s" % [
		plot.yield_amount,
		plot.resource_id,
		"" if can_start else "\nNot enough time today."
	]
	_start_btn.disabled = not can_start
	show()
	_start_btn.grab_focus()

func _on_start_pressed() -> void:
	if _current_plot == null:
		return
	_current_plot.start_plot()
	ClockManager.commit_action(START_COST_MINUTES)
	ClockManager._actions_log.append("Started %s plot" % _current_plot.resource_id)
	hide()
	_current_plot = null
```

**Step 2: Create action_menu.tscn**

Create `scenes/ui/action_menu.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/action_menu.gd" id="1"]

[node name="ActionMenu" type="CanvasLayer"]
process_mode = 3
script = ExtResource("1")

[node name="PanelContainer" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -100.0
offset_top = -60.0
offset_right = 100.0
offset_bottom = 60.0

[node name="VBoxContainer" type="VBoxContainer" parent="PanelContainer"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="PreviewLabel" type="Label" parent="PanelContainer/VBoxContainer"]
text = "Yield: ? rations\nTime: 1.5 hr"
horizontal_alignment = 1

[node name="StartButton" type="Button" parent="PanelContainer/VBoxContainer"]
text = "Start (1.5 hr)"
```

**Step 3: Verify**

Open `scenes/ui/action_menu.tscn` in the Godot editor. Confirm it shows a PanelContainer with PreviewLabel and StartButton. No errors in the scene.

**Step 4: Commit**

```bash
git add scripts/ui/action_menu.gd scenes/ui/action_menu.tscn
git commit -m "feat: add ActionMenu scene and script"
```

---

### Task 5: Add ActionMenu to main.tscn

**Files:**
- Modify: `scenes/main.tscn`

**Depends on:** Task 4
**Parallelizable with:** none — requires Task 4's scene file to exist.

**Step 1: Add ActionMenu instance to main.tscn**

In `scenes/main.tscn`, add a new `ext_resource` entry for the ActionMenu scene and a node instance.

Find the `[ext_resource ... path="res://scenes/ui/day_summary.tscn" id="6"]` line and add immediately after it:

```
[ext_resource type="PackedScene" path="res://scenes/ui/action_menu.tscn" id="10"]
```

Then find the line:

```
[node name="DaySummary" parent="." instance=ExtResource("6")]
```

And add immediately after it:

```
[node name="ActionMenu" parent="." instance=ExtResource("10")]
```

**Step 2: Verify**

```bash
godot
```

Open the Godot editor. Confirm `scenes/main.tscn` has an `ActionMenu` node in the scene tree. No errors.

**Step 3: Commit**

```bash
git add scenes/main.tscn
git commit -m "feat: add ActionMenu instance to main scene"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 4 → Task 5 | Task 5 instances the scene Task 4 creates |

---

### Smoketest Checkpoint 2 — Action menu opens on Cantina plot interact

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass. Zero failures.

**Step 3: Launch game and verify visually**
```bash
godot
```

**Step 4: Confirm with user**
Verify all of the following:
- Go to Cantina and interact with the green ResourceNode sprite
- An action menu popup appears showing: `"Yield: 1 rations"` (yield_amount=1 until Task 6 sets it to 2) and `"Start (1.5 hr)"` button
- Clicking Start advances the clock by 90 min and closes the menu
- Pressing Escape dismisses the menu without any action
- When clock time + 90 min > 22:00 (960), the Start button is greyed out

---

### Task 6: Update cantina.tscn — yield_amount=2, remove QuenSpawn

**Files:**
- Modify: `scenes/areas/cantina.tscn`

**Depends on:** Smoketest Checkpoint 2
**Parallelizable with:** Task 7, Task 8 — different output files, no shared state.

**Step 1: Remove QuenSpawn and set yield_amount**

In `scenes/areas/cantina.tscn`, make these two changes:

**Change 1 — Set yield_amount on the ResourceNode instance.** Find:

```
[node name="ResourceNode" type="Area2D" parent="RationsNode" unique_id=240848598 instance=ExtResource("2")]
script = ExtResource("4_gv2i0")
```

Add `yield_amount = 2` as a property:

```
[node name="ResourceNode" type="Area2D" parent="RationsNode" unique_id=240848598 instance=ExtResource("2")]
script = ExtResource("4_gv2i0")
yield_amount = 2
```

**Change 2 — Remove QuenSpawn node.** Delete the following two lines entirely:

```
[node name="QuenSpawn" type="Node2D" parent="." unique_id=-1120141237]
position = Vector2(360, 128)
```

**Step 2: Verify**

Open Cantina area in the Godot editor. Confirm:
- `QuenSpawn` node no longer exists in the scene tree
- `ResourceNode` shows `yield_amount = 2` in the Inspector

**Step 3: Commit**

```bash
git add scenes/areas/cantina.tscn
git commit -m "feat: set Cantina ResourcePlot yield=2, remove QuenSpawn"
```

---

### Task 7: Add QuenSpawn to security_post.tscn

**Files:**
- Modify: `scenes/areas/security_post.tscn`

**Depends on:** Smoketest Checkpoint 2
**Parallelizable with:** Task 6, Task 8 — different output files, no shared state.

**Step 1: Add QuenSpawn node**

In `scenes/areas/security_post.tscn`, add a `QuenSpawn` node after the `TileMapLayer` node and before `CantinaDoor`. Insert after line 20 (after the `tile_set = ExtResource("1_ts")` line):

```
[node name="QuenSpawn" type="Node2D" parent="."]
position = Vector2(240, 128)
```

**Step 2: Verify**

Open the SecurityPost scene in the Godot editor. Confirm `QuenSpawn` node appears at position (240, 128) in the center of the room.

**Step 3: Commit**

```bash
git add scenes/areas/security_post.tscn
git commit -m "feat: add QuenSpawn to SecurityPost scene"
```

---

### Task 8: Update NPC_SPAWN_AREAS in main.gd

**Files:**
- Modify: `scripts/main.gd`

**Depends on:** Smoketest Checkpoint 2
**Parallelizable with:** Task 6, Task 7 — different output file, no shared state.

**Step 1: Update NPC_SPAWN_AREAS**

In `scripts/main.gd`, find:

```gdscript
const NPC_SPAWN_AREAS = {
	"maris":   "cantina",
	"quen":    "cantina",
	"dex":     "workshop",
	"velreth": "med_bay",
	"sable":   "trade_dock",
}
```

Change `"quen": "cantina"` to `"quen": "security_post"`:

```gdscript
const NPC_SPAWN_AREAS = {
	"maris":   "cantina",
	"quen":    "security_post",
	"dex":     "workshop",
	"velreth": "med_bay",
	"sable":   "trade_dock",
}
```

**Step 2: Verify**

No GUT test required. Verified at Smoketest Checkpoint 3.

**Step 3: Commit**

```bash
git add scripts/main.gd
git commit -m "feat: move Quen spawn area from cantina to security_post"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 3

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 6, Task 7, Task 8 | Different output files; cantina, security_post, and main.gd are fully independent |

---

### Smoketest Checkpoint 3 — Quen in Security Post, Cantina plot shows yield=2

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass. Zero failures.

**Step 3: Launch game and verify visually**
```bash
godot
```

**Step 4: Confirm with user**
Verify all of the following:
- Go to Cantina: Quen is NOT present. Maris is present. ResourceNode (green sprite) is visible.
- Interact with the ResourceNode: menu shows `"Yield: 2 rations"` (not 1)
- Confirm Start: clock advances 90 min, day summary shows `"Started rations plot"` in action log
- Go to Security Post: Quen IS present in the center of the room
- Talk to Quen: dialogue works, clock advances 30 min after conversation ends
- The ResourceNode in Cantina now shows a GROWING state after Start — interacting with it again does nothing (no Tend yet — that's a future plan)
- Sable is NOT visible anywhere on Day 1
