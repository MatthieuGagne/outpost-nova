# ResourcePlot & Layout — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rewrite `resource_node.gd` as a `ResourcePlot` state machine (EMPTY→GROWING), build a dismissable `ActionMenu` popup wired to `ClockManager`, move Quen to the Security Post, and add a visible ResourcePlot to the Cantina (issue #73, part of #65).

**Architecture:** `resource_node.gd` becomes a state machine with a `ColorRect` visual that changes color on state transition (green = EMPTY, amber = GROWING). `interact()` delegates to `ActionMenu` via group lookup. `ActionMenu` is a CanvasLayer added to `main.tscn` and found via group `"action_menu"`. `start_plot()` owns the clock commit and action log — `ActionMenu` only calls `start_plot()` and hides. `NPC_SPAWN_AREAS` in `main.gd` updated to move Quen; scene files get matching spawn node changes.

**Tech Stack:** Godot 4.6 / GDScript, GUT test framework.

**Prerequisite:** Plan A (#71) merged — `ClockManager.can_act()` and `ClockManager.commit_action()` already exist ✓.

## Open questions (must resolve before starting)

- none

---

### Task 1: Write failing GUT tests for ResourcePlot

**Files:**
- Create: `tests/test_resource_plot.gd`

**Depends on:** none
**Parallelizable with:** Task 3 — Task 3 updates the scene file; different output files, no shared state.

**Step 1: Write the failing GUT test**

Create `tests/test_resource_plot.gd`:

```gdscript
# tests/test_resource_plot.gd
extends GutTest

var _plot: Node = null

func before_each():
	ClockManager.reset()
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

func test_start_plot_advances_clock_90_minutes():
	_plot.start_plot()
	assert_eq(ClockManager.current_time, 360 + 90)

func test_start_plot_logs_action():
	_plot.start_plot()
	assert_eq(ClockManager._actions_log.size(), 1)
	assert_eq(ClockManager._actions_log[0], "Started rations plot")
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

**Depends on:** Task 1 and Task 3 — Task 3 must add the `ColorRect` node to the scene before `@onready` resolves.
**Parallelizable with:** none — depends on both Task 1 (tests) and Task 3 (scene structure).

**Step 1: Replace resource_node.gd entirely**

```gdscript
# scripts/resource_node.gd
extends Area2D

enum PlotState { EMPTY, GROWING }

signal plot_state_changed(new_state: PlotState)

@export var resource_id: String = "rations"
@export var yield_amount: int = 1

@onready var _visual: ColorRect = $ColorRect

var _state: PlotState = PlotState.EMPTY

const COLOR_EMPTY: Color = Color(0.2, 0.7, 0.2)
const COLOR_GROWING: Color = Color(0.8, 0.6, 0.1)

func _ready() -> void:
	add_to_group("interactable")
	_visual.color = COLOR_EMPTY

func interact() -> void:
	if _state == PlotState.GROWING:
		var main := get_tree().get_root().get_node_or_null("Main")
		if main:
			main.show_hud_message("Plot is already growing.")
		return
	var menus := get_tree().get_nodes_in_group("action_menu")
	if menus.is_empty():
		return
	menus[0].show_for_plot(self)

func start_plot() -> void:
	if _state != PlotState.EMPTY:
		return
	_state = PlotState.GROWING
	_visual.color = COLOR_GROWING
	ClockManager.commit_action(90)
	ClockManager.log_action("Started %s plot" % resource_id)
	plot_state_changed.emit(_state)

func get_plot_state() -> PlotState:
	return _state
```

**Step 2: Run tests to verify they pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_resource_plot.gd
```

Expected: All ResourcePlot tests PASS.

Then full suite:

```bash
godot --headless -s addons/gut/gut_cmdln.gd
```

Expected: All tests pass. Zero failures.

**Step 3: Refactor checkpoint**

`start_plot()` owns the clock commit and log — `ActionMenu` just calls it and hides, no duplication. Guard on `_state != PlotState.EMPTY` ensures idempotency. State machine will extend to PAUSED/COLLECTING in a future plan; enum and signal are already the right shape.

**Step 4: Commit**

```bash
git add scripts/resource_node.gd
git commit -m "feat: rewrite resource_node.gd as ResourcePlot state machine (EMPTY, GROWING)"
```

---

### Task 3: Update resource_node.tscn — ColorRect visual, remove Timer

**Files:**
- Modify: `scenes/resource_node.tscn`

**Depends on:** none
**Parallelizable with:** Task 1 — different output file; tests can be written before the scene is updated.

**Step 1: Replace resource_node.tscn entirely**

The existing scene has a `Sprite2D` with no texture (invisible at runtime) and an unused `Timer`. Replace with a `ColorRect` (always visible, no texture needed) sized to one tile (16×16):

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resource_node.gd" id="1"]

[sub_resource type="RectangleShape2D" id="1"]
size = Vector2(16, 16)

[node name="ResourceNode" type="Area2D"]
script = ExtResource("1")

[node name="ColorRect" type="ColorRect" parent="."]
offset_left = -8.0
offset_top = -8.0
offset_right = 8.0
offset_bottom = 8.0
color = Color(0.2, 0.7, 0.2, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("1")
```

**Step 2: Verify**

Open Godot editor. Confirm `scenes/resource_node.tscn` shows a green `ColorRect` square with no Timer node. No errors.

**Step 3: Commit**

```bash
git add scenes/resource_node.tscn
git commit -m "feat: replace resource_node Sprite2D with visible ColorRect, remove Timer"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 1, Task 3 | Task 1 writes tests; Task 3 updates scene — different output files, no shared state |
| B (sequential) | Task 2 | Depends on Group A — script needs tests to exist and scene to have ColorRect |

### Smoketest Checkpoint 1 — ResourcePlot tests pass, green square visible in Cantina

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass including `test_resource_plot.gd`. Zero failures.

**Step 3: Launch game and verify visually**

Use the `/run` skill to launch the game. Go to Cantina — a green square (16×16) is visible at position (80, 80). Interacting with it does nothing visible yet (no ActionMenu in main.tscn yet). Game does not crash.

**Step 4: Confirm with user before proceeding.**

---

### Task 4: Create ActionMenu script and scene

**Files:**
- Create: `scripts/ui/action_menu.gd`
- Create: `scenes/ui/action_menu.tscn`

**Depends on:** Smoketest Checkpoint 1
**Parallelizable with:** none — Task 5 (main.tscn) depends on the scene existing.

**Step 1: Create action_menu.gd**

```gdscript
# scripts/ui/action_menu.gd
extends CanvasLayer

@onready var _preview_lbl: Label = $PanelContainer/VBoxContainer/PreviewLabel
@onready var _start_btn: Button = $PanelContainer/VBoxContainer/StartButton

const START_COST_MINUTES: int = 90

var _current_plot: Node = null

func _ready() -> void:
	add_to_group("action_menu")
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	hide()
	_current_plot = null
```

**Step 2: Create action_menu.tscn**

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

Open `scenes/ui/action_menu.tscn` in the Godot editor. Confirm PanelContainer with PreviewLabel and StartButton. No errors.

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

In `scenes/main.tscn`, find the `ext_resource` line for `day_summary.tscn` and add immediately after:

```
[ext_resource type="PackedScene" path="res://scenes/ui/action_menu.tscn" id="10"]
```

Then find the `[node name="DaySummary" ...]` line and add immediately after:

```
[node name="ActionMenu" parent="." instance=ExtResource("10")]
```

**Step 2: Verify**

Open Godot editor. Confirm `scenes/main.tscn` has an `ActionMenu` node in the scene tree. No errors.

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

**Step 3: Launch game with `/run` skill and verify:**
- Go to Cantina, interact with the green square
- ActionMenu appears: `"Yield: 1 rations"` and `"Start (1.5 hr)"` button
- Clicking Start: clock advances 90 min, green square turns amber/yellow, menu closes
- Interacting again: HUD shows `"Plot is already growing."`
- Pressing Escape dismisses without action
- With clock at 21:00+, Start button is greyed out with "Not enough time today."

**Step 4: Confirm with user before proceeding.**

---

### Task 6: Update cantina.tscn — yield_amount=2, remove QuenSpawn

**Files:**
- Modify: `scenes/areas/cantina.tscn`

**Depends on:** Smoketest Checkpoint 2
**Parallelizable with:** Task 7, Task 8 — different output files, no shared state.

**Step 1: Set yield_amount and remove QuenSpawn**

In `scenes/areas/cantina.tscn`:

**Change 1 — yield_amount.** Find:

```
[node name="ResourceNode" type="Area2D" parent="RationsNode" unique_id=240848598 instance=ExtResource("2")]
script = ExtResource("4_gv2i0")
```

Add `yield_amount = 2`:

```
[node name="ResourceNode" type="Area2D" parent="RationsNode" unique_id=240848598 instance=ExtResource("2")]
script = ExtResource("4_gv2i0")
yield_amount = 2
```

**Change 2 — Remove QuenSpawn.** Delete these two lines entirely:

```
[node name="QuenSpawn" type="Node2D" parent="." unique_id=-1120141237]
position = Vector2(360, 128)
```

**Step 2: Verify**

Open Cantina in the Godot editor. Confirm `QuenSpawn` is gone and `ResourceNode` shows `yield_amount = 2` in the Inspector.

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

In `scenes/areas/security_post.tscn`, insert after the `tile_set = ExtResource("1_ts")` line:

```
[node name="QuenSpawn" type="Node2D" parent="."]
position = Vector2(240, 128)
```

**Step 2: Verify**

Open SecurityPost in the Godot editor. Confirm `QuenSpawn` node at (240, 128).

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

**Step 1: Change quen spawn area**

In `scripts/main.gd`, change `"quen": "cantina"` to `"quen": "security_post"`:

```gdscript
const NPC_SPAWN_AREAS = {
	"maris":   "cantina",
	"quen":    "security_post",
	"dex":     "workshop",
	"velreth": "med_bay",
	"sable":   "trade_dock",
}
```

**Step 2: Commit**

```bash
git add scripts/main.gd
git commit -m "feat: move Quen spawn area from cantina to security_post"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 3

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 6, Task 7, Task 8 | Cantina tscn, security_post tscn, and main.gd are fully independent |

### Smoketest Checkpoint 3 — Quen in Security Post, Cantina plot yield=2 and color-changing

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass. Zero failures.

**Step 3: Launch game with `/run` skill and verify:**
- Cantina: Quen NOT present. Maris present. Green square visible.
- Interact with square → menu shows `"Yield: 2 rations"` (not 1)
- Confirm Start → clock +90 min, square turns amber/yellow, day summary shows `"Started rations plot"`
- Interact again → HUD message `"Plot is already growing."`
- Security Post: Quen IS present at center. Talking to Quen → dialogue works, clock +30 min after
- Sable NOT visible on Day 1
