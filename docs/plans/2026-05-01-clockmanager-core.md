# Plan A — ClockManager Core Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the beat-based `DayManager` autoload with a clock-based `ClockManager`, wire up the HUD clock display and End Day button, update the day summary to show an action log, and migrate all Yarn `<<beat>>` commands to `<<log_action>>`.

**Architecture:** `ClockManager` is an autoload Node tracking `current_time` (minutes; 360=06:00, 960=22:00), `current_day`, and `_actions_log: Array[String]`. All UI connects to `time_advanced` and `day_ended` signals — never polls. `DayManager` is deleted once all references are migrated in Batch 3.

**Tech Stack:** GDScript, GUT (headless test runner at `addons/gut/gut_cmdln.gd`), YarnSpinner Godot (dialogue commands)

## Open questions

None — all resolved in grill-me.

## Session notes (2026-05-01)

**Batch 1 complete.** Tasks 1–3 done and committed. Smoketest 1 passed — 50/50 GUT tests, game launches, dialogue works.

**Run skill fixed (two corrections this session):**
- The `.import` file must NOT be deleted before headless import. It contains `importer="yarnproject"` which tells Godot to invoke the C# YarnSpinner importer. Deleting it causes headless to use a generic loader that omits `CompiledYarnProgramBase64`, silently breaking all dialogue. Fix: delete only the compiled `.tres`, keep the `.import`.
- The main repo's compiled `.tres` was stale (old "commander" text). Recompiled fresh on main repo.

**Next session:** Start at Batch 2 — Tasks 4 (npc_base.gd) and 5 (Yarn files), which are parallel.

---

## Batch 1 — ClockManager TDD ✅

### Task 1: Write failing test_clock_manager.gd

**Files:**
- Create: `tests/test_clock_manager.gd`

**Depends on:** none
**Parallelizable with:** none — TDD gate; Task 2 must see these fail first

**Step 1: Write the failing GUT test**

```gdscript
# tests/test_clock_manager.gd
extends GutTest

func before_each():
	ClockManager.reset()

func test_initial_time_is_0600():
	assert_eq(ClockManager.current_time, 360)

func test_initial_day_is_1():
	assert_eq(ClockManager.current_day, 1)

func test_get_time_string_at_start():
	assert_eq(ClockManager.get_time_string(), "06:00")

func test_commit_action_advances_time():
	ClockManager.commit_action(30)
	assert_eq(ClockManager.current_time, 390)
	assert_eq(ClockManager.get_time_string(), "06:30")

func test_can_act_true_when_time_available():
	assert_true(ClockManager.can_act(30))

func test_can_act_false_when_cost_exceeds_end_time():
	ClockManager.current_time = 940
	assert_false(ClockManager.can_act(30))

func test_can_act_true_at_exact_boundary():
	ClockManager.current_time = 930
	assert_true(ClockManager.can_act(30))  # 930+30=960 exactly

func test_commit_action_emits_time_advanced():
	var emitted := [false]
	var cb := func(_t: int): emitted[0] = true
	ClockManager.time_advanced.connect(cb)
	ClockManager.commit_action(30)
	ClockManager.time_advanced.disconnect(cb)
	assert_true(emitted[0])

func test_overflow_emits_day_ended():
	ClockManager.current_time = 940
	var day_num := [0]
	var cb := func(d: int): day_num[0] = d
	ClockManager.day_ended.connect(cb)
	ClockManager.commit_action(30)  # 940+30=970 > 960
	ClockManager.day_ended.disconnect(cb)
	assert_eq(day_num[0], 1)

func test_overflow_does_not_error():
	ClockManager.current_time = 950
	ClockManager.commit_action(30)  # 950+30=980 > 960
	assert_eq(ClockManager.current_time, 980)

func test_end_day_manually_emits_day_ended():
	var day_num := [0]
	var cb := func(d: int): day_num[0] = d
	ClockManager.day_ended.connect(cb)
	ClockManager.end_day_manually()
	ClockManager.day_ended.disconnect(cb)
	assert_eq(day_num[0], 1)

func test_advance_day_increments_day():
	ClockManager.advance_day()
	assert_eq(ClockManager.current_day, 2)

func test_advance_day_resets_time():
	ClockManager.commit_action(60)
	ClockManager.advance_day()
	assert_eq(ClockManager.current_time, 360)

func test_advance_day_emits_time_advanced_360():
	var new_time := [0]
	var cb := func(t: int): new_time[0] = t
	ClockManager.time_advanced.connect(cb)
	ClockManager.advance_day()
	ClockManager.time_advanced.disconnect(cb)
	assert_eq(new_time[0], 360)

func test_advance_day_clears_actions_log():
	ClockManager.log_action("Did something")
	ClockManager.advance_day()
	assert_eq(ClockManager._actions_log.size(), 0)

func test_log_action_appends():
	ClockManager.log_action("Met Maris")
	assert_eq(ClockManager._actions_log.size(), 1)
	assert_eq(ClockManager._actions_log[0], "Met Maris")

func test_reset_clears_log():
	ClockManager.log_action("Something")
	ClockManager.reset()
	assert_eq(ClockManager._actions_log.size(), 0)
```

**Step 2: Run test to verify it fails**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_clock_manager.gd
```
Expected: FAIL — `ClockManager` is not yet registered as an autoload.

**Step 3: Commit**

```bash
git add tests/test_clock_manager.gd
git commit -m "test: add failing ClockManager GUT tests"
```

---

### Task 2: Write clock_manager.gd

**Files:**
- Create: `scripts/autoload/clock_manager.gd`

**Depends on:** Task 1
**Parallelizable with:** none — TDD gate requires Task 1 first

**Step 1: Write the implementation**

```gdscript
# scripts/autoload/clock_manager.gd
extends Node

signal time_advanced(new_time: int)
signal day_ended(day_number: int)

const START_TIME: int = 360  # 06:00
const END_TIME: int = 960    # 22:00

var current_time: int = START_TIME
var current_day: int = 1
var _actions_log: Array[String] = []

func _ready() -> void:
	reset()

func reset() -> void:
	current_time = START_TIME
	current_day = 1
	_actions_log.clear()

func commit_action(cost_minutes: int) -> void:
	current_time += cost_minutes
	time_advanced.emit(current_time)
	if current_time >= END_TIME:
		day_ended.emit(current_day)

func can_act(cost_minutes: int) -> bool:
	return current_time + cost_minutes <= END_TIME

func get_time_string() -> String:
	var hours: int = current_time / 60
	var minutes: int = current_time % 60
	return "%02d:%02d" % [hours, minutes]

func log_action(message: String) -> void:
	_actions_log.append(message)

func end_day_manually() -> void:
	day_ended.emit(current_day)

func advance_day() -> void:
	current_day += 1
	current_time = START_TIME
	_actions_log.clear()
	time_advanced.emit(current_time)
```

**Step 2: Run test to verify it still fails** (not yet registered as autoload)

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_clock_manager.gd
```
Expected: FAIL — autoload not registered yet.

**Step 3: Commit**

```bash
git add scripts/autoload/clock_manager.gd
git commit -m "feat: add ClockManager autoload (unregistered)"
```

---

### Task 3: Register ClockManager in project.godot

**Files:**
- Modify: `project.godot`

**Depends on:** Task 2
**Parallelizable with:** none — `clock_manager.gd` must exist before Godot can register it

**Step 1: Add ClockManager autoload entry**

In `project.godot`, find the `[autoload]` section:

```ini
[autoload]

GameState="*res://scripts/autoload/game_state.gd"
CraftingSystem="*res://scripts/autoload/crafting_system.gd"
DayManager="*res://scripts/autoload/day_manager.gd"
```

Add `ClockManager` after `CraftingSystem` (keep `DayManager` for now — it will be removed in Task 9):

```ini
[autoload]

GameState="*res://scripts/autoload/game_state.gd"
CraftingSystem="*res://scripts/autoload/crafting_system.gd"
ClockManager="*res://scripts/autoload/clock_manager.gd"
DayManager="*res://scripts/autoload/day_manager.gd"
```

**Step 2: Run tests to verify they pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_clock_manager.gd
```
Expected: All tests PASS.

**Step 3: Run full test suite to confirm nothing broke**

```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All existing tests still PASS (DayManager is still registered).

**Step 4: Refactor checkpoint**

`ClockManager.can_act` uses `<=` so 960 exactly is allowed (boundary test covers this). `commit_action` always succeeds regardless of `can_act` — overflow is intentional per spec.

**Step 5: Commit**

```bash
git add project.godot
git commit -m "feat: register ClockManager autoload in project.godot"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 1, Task 2, Task 3 | TDD gate: failing tests → impl → registration |

### Smoketest Checkpoint 1 — ClockManager GUT tests pass

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass, zero failures.

**Step 3: Launch game and verify visually**

Use the `/run` skill to launch the game.

**Step 4: Confirm with user**

At this point `ClockManager` exists but nothing in the game uses it yet — verify the game launches and existing DayManager-driven behaviour still works (story beats still function). Confirm before proceeding.

---

## Batch 2 — NPC and Yarn Migration

### Task 4: Update npc_base.gd

**Files:**
- Modify: `scripts/characters/npc_base.gd`

**Depends on:** Task 2 (ClockManager must exist; `Callable(ClockManager, "log_action")` and `ClockManager.commit_action` are referenced)
**Parallelizable with:** Task 5 — different output files, no shared state

**Step 1: Write the full updated file**

```gdscript
# scripts/characters/npc_base.gd
extends CharacterBody2D

@export var npc_id: String = "unknown"
@export var display_name: String = "NPC"
@export var wander_bounds: Rect2 = Rect2(-50, -50, 100, 100)

const WANDER_SPEED = 30.0

@onready var wander_timer: Timer = $WanderTimer
@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _wander_target: Vector2 = Vector2.ZERO
var _is_talking: bool = false
var _facing: String = "down"

static var _commands_registered: bool = false

func _ready() -> void:
	add_to_group("npcs")
	add_to_group("interactable")
	wander_timer.timeout.connect(_pick_wander_target)
	wander_timer.wait_time = randf_range(2.0, 5.0)
	wander_timer.start()
	_pick_wander_target()

func _physics_process(_delta: float) -> void:
	if _is_talking:
		velocity = Vector2.ZERO
		move_and_slide()
		sprite.play("idle_" + _facing)
		return
	var diff = _wander_target - position
	if diff.length() > 4.0:
		velocity = diff.normalized() * WANDER_SPEED
		_facing = _get_facing(velocity)
		sprite.play("walk_" + _facing)
	else:
		velocity = Vector2.ZERO
		sprite.play("idle_" + _facing)
	move_and_slide()

func _get_facing(direction: Vector2) -> String:
	if abs(direction.x) >= abs(direction.y):
		return "right" if direction.x > 0 else "left"
	return "down" if direction.y > 0 else "up"

func _pick_wander_target() -> void:
	_wander_target = position + Vector2(
		randf_range(wander_bounds.position.x, wander_bounds.end.x),
		randf_range(wander_bounds.position.y, wander_bounds.end.y)
	)
	wander_timer.wait_time = randf_range(2.0, 5.0)
	wander_timer.start()

func interact() -> void:
	if _is_talking:
		return
	var runners := get_tree().get_nodes_in_group("dialogue_runner")
	if runners.is_empty():
		push_error("npc_base: no node in group 'dialogue_runner'")
		return
	var runner := runners[0]
	if not _commands_registered:
		runner.AddCommandHandlerCallable("register", Callable(GameState, "record_register"))
		runner.AddCommandHandlerCallable("log_action", Callable(ClockManager, "log_action"))
		runner.AddCommandHandlerCallable("flag", Callable(GameState, "set_flag_on"))
		_commands_registered = true
	var boxes := get_tree().get_nodes_in_group("dialogue_box")
	if not boxes.is_empty():
		var box := boxes[0]
		if not box.conversation_ended.is_connected(_on_conversation_ended):
			box.conversation_ended.connect(_on_conversation_ended)
	_is_talking = true
	runner.StartDialogueForget(get_dialogue_node())

func _on_conversation_ended() -> void:
	_is_talking = false
	ClockManager.commit_action(30)

## Override in subclass to return the Yarn node title for this NPC.
func get_dialogue_node() -> String:
	return display_name
```

Key changes vs original:
- Removed `runner.AddCommandHandlerCallable("beat", Callable(DayManager, "complete_beat"))`
- Added `runner.AddCommandHandlerCallable("log_action", Callable(ClockManager, "log_action"))`
- Added `ClockManager.commit_action(30)` in `_on_conversation_ended`

**Step 2: Verify**

Run the game, talk to any NPC. Confirm: dialogue completes without errors; clock should advance 30 min (visible once HUD is wired in Task 6).

**Step 3: Commit**

```bash
git add scripts/characters/npc_base.gd
git commit -m "feat: migrate npc_base from beat command to log_action + commit_action(30)"
```

---

### Task 5: Update all Yarn files

**Files:**
- Modify: `data/dialogue/maris.yarn`
- Modify: `data/dialogue/dex.yarn`
- Modify: `data/dialogue/velreth.yarn`
- Modify: `data/dialogue/quen.yarn`
- Modify: `data/dialogue/sable.yarn`

**Depends on:** none — pure text substitution, no GDScript dependency
**Parallelizable with:** Task 4 — different output files, no shared state

**Important:** Only `<<beat ...>>` *commands* (double-angle brackets) are replaced. Inline `[beat]` text inside dialogue lines (e.g., `Velreth: [beat] Most superintendents...`) is **not** changed — it is YarnSpinner markup for a pause, not a command.

**Step 1: Apply the following exact replacements**

`data/dialogue/maris.yarn` — replace line 23:
```
<<beat meet_maris>>
```
with:
```
<<log_action "Met Maris">>
```

`data/dialogue/dex.yarn` — replace line 23:
```
<<beat check_workshop>>
```
with:
```
<<log_action "Checked in with Dex">>
```

`data/dialogue/velreth.yarn` — replace line 22:
```
<<beat met_velreth>>
```
with:
```
<<log_action "Met Velreth">>
```

`data/dialogue/quen.yarn` — replace line 24:
```
<<beat quen_arrives>>
```
with:
```
<<log_action "Spoke with Quen">>
```

`data/dialogue/sable.yarn` — replace the `<<beat sable_arrives>>` line:
```
<<beat sable_arrives>>
```
with:
```
<<log_action "Met Sable">>
```

**Step 2: Verify no `<<beat` commands remain**

```bash
grep -rn "<<beat" data/dialogue/
```
Expected: no output (zero matches).

**Step 3: Verify `[beat]` inline markup is untouched**

```bash
grep -n "\[beat\]" data/dialogue/velreth.yarn data/dialogue/quen.yarn
```
Expected: lines with `[beat]` still present inside dialogue text.

**Step 4: Commit**

```bash
git add data/dialogue/
git commit -m "feat: replace <<beat>> commands with <<log_action>> in all Yarn scripts"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 4, Task 5 | Different output files, no shared state |

### Smoketest Checkpoint 2 — NPC dialogue works, no beat errors

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass, zero failures.

**Step 3: Launch game and verify visually**

Use the `/run` skill to launch the game.

**Step 4: Confirm with user**

Talk to Maris (or any NPC). Confirm:
- Dialogue completes without errors in the Output panel
- No `<<beat>>` command-not-found warnings
- `<<log_action>>` fires silently (ClockManager._actions_log is updated, though HUD clock won't show the change until Task 6)

Confirm before proceeding to Batch 3.

---

## Batch 3 — UI Wiring + DayManager Removal

### Task 6: Update hud.tscn + hud.gd

**Files:**
- Modify: `scenes/ui/hud.tscn`
- Modify: `scripts/ui/hud.gd`

**Depends on:** Task 2 (ClockManager must exist for signal connections)
**Parallelizable with:** Tasks 7, 8 — different output files, no shared state

**Step 1: Update hud.tscn**

Replace the `BeatsLabel` node with `ClockLabel` and `EndDayButton`. The current node:

```
[node name="BeatsLabel" type="Label" parent="HBoxContainer"]
theme_override_fonts/font = ExtResource("2")
theme_override_font_sizes/font_size = 16
text = ""
```

Replace with these two nodes (add both after `DayLabel`):

```
[node name="ClockLabel" type="Label" parent="HBoxContainer"]
theme_override_fonts/font = ExtResource("2")
theme_override_font_sizes/font_size = 16
text = "06:00"

[node name="EndDayButton" type="Button" parent="HBoxContainer"]
theme_override_fonts/font = ExtResource("2")
theme_override_font_sizes/font_size = 16
text = "End Day"
```

**Step 2: Rewrite hud.gd**

```gdscript
# scripts/ui/hud.gd
extends CanvasLayer

@onready var rations_lbl: Label = $HBoxContainer/RationsLabel
@onready var parts_lbl: Label = $HBoxContainer/PartsLabel
@onready var energy_lbl: Label = $HBoxContainer/EnergyLabel
@onready var scrap_lbl: Label = $HBoxContainer/ScrapLabel
@onready var day_lbl: Label = $HBoxContainer/DayLabel
@onready var clock_lbl: Label = $HBoxContainer/ClockLabel
@onready var end_day_btn: Button = $HBoxContainer/EndDayButton
@onready var message_lbl: Label = $MessageLabel

func _ready() -> void:
	GameState.resource_changed.connect(_refresh_resources)
	ClockManager.time_advanced.connect(_on_time_advanced)
	end_day_btn.pressed.connect(ClockManager.end_day_manually)
	message_lbl.hide()
	_refresh_resources("", 0)
	_on_time_advanced(ClockManager.current_time)

func _refresh_resources(_id, _amt) -> void:
	rations_lbl.text = "Rations: %d" % GameState.get_resource("rations")
	parts_lbl.text = "Parts: %d" % GameState.get_resource("parts")
	energy_lbl.text = "Energy: %d" % GameState.get_resource("energy_cells")
	scrap_lbl.text = "Scrap: %d" % GameState.get_resource("scrap")

func _on_time_advanced(_new_time: int) -> void:
	clock_lbl.text = ClockManager.get_time_string()
	day_lbl.text = "Day %d" % ClockManager.current_day

func show_message(text: String) -> void:
	message_lbl.text = text
	message_lbl.show()
	await get_tree().create_timer(3.0).timeout
	message_lbl.hide()
```

Key changes vs original:
- Removed `beats_lbl` onready, `_refresh_beats()`, `_on_day_ended()`
- Added `clock_lbl`, `end_day_btn` onready
- Removed `DayManager.beat_completed` and `DayManager.day_ended` connections
- Added `ClockManager.time_advanced` connection and `end_day_btn` connection
- `_on_time_advanced` refreshes both clock and day labels

**Step 3: Verify**

Open `scenes/ui/hud.tscn` in the Godot editor — confirm `ClockLabel` and `EndDayButton` nodes are present under `HBoxContainer`, and `BeatsLabel` is gone.

**Step 4: Commit**

```bash
git add scenes/ui/hud.tscn scripts/ui/hud.gd
git commit -m "feat: wire HUD to ClockManager — add ClockLabel and EndDayButton, remove BeatsLabel"
```

---

### Task 7: Update day_summary.gd

**Files:**
- Modify: `scripts/ui/day_summary.gd`

**Depends on:** Task 2 (ClockManager must exist)
**Parallelizable with:** Tasks 6, 8 — different output files, no shared state

**Step 1: Rewrite day_summary.gd**

```gdscript
# scripts/ui/day_summary.gd
extends CanvasLayer

@onready var day_lbl: Label = $Panel/VBox/DayLabel
@onready var events_container: VBoxContainer = $Panel/VBox/EventsContainer
@onready var rest_btn: Button = $Panel/VBox/RestButton

func _ready() -> void:
	hide()
	rest_btn.pressed.connect(_on_rest)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_on_rest()
		get_viewport().set_input_as_handled()

func show_summary() -> void:
	day_lbl.text = "End of Day %d" % ClockManager.current_day
	for child in events_container.get_children():
		child.queue_free()
	var font = load("res://data/fonts/m5x7.tres")
	for entry in ClockManager._actions_log:
		var lbl := Label.new()
		lbl.text = "• %s" % entry
		lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", 13)
		events_container.add_child(lbl)
	var sep := Label.new()
	sep.text = "—"
	sep.add_theme_font_override("font", font)
	sep.add_theme_font_size_override("font_size", 13)
	events_container.add_child(sep)
	for res_id in ["rations", "parts", "energy_cells"]:
		var lbl := Label.new()
		lbl.text = "%s: %d" % [res_id.replace("_", " ").capitalize(), GameState.get_resource(res_id)]
		lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", 13)
		events_container.add_child(lbl)
	show()
	rest_btn.grab_focus()

func _on_rest() -> void:
	hide()
	ClockManager.advance_day()
```

Key changes vs original:
- `show_summary()` reads `ClockManager._actions_log` instead of `DayManager.get_todays_beats()`
- Adds a `—` separator then current resource stocks (rations, parts, energy_cells)
- `_on_rest()` calls `ClockManager.advance_day()` instead of `DayManager.advance_day()`

**Step 2: Verify**

No scene changes needed — `EventsContainer` VBoxContainer is already present in `day_summary.tscn` and is reused for both action log entries and resource stock labels.

**Step 3: Commit**

```bash
git add scripts/ui/day_summary.gd
git commit -m "feat: update day_summary to show ClockManager action log and resource stocks"
```

---

### Task 8: Update main.gd

**Files:**
- Modify: `scripts/main.gd`

**Depends on:** Task 2 (ClockManager must exist for signal connection)
**Parallelizable with:** Tasks 6, 7 — different output files, no shared state

**Step 1: Apply the following changes to main.gd**

Remove the `arc_events` onready line:
```gdscript
# DELETE this line:
@onready var arc_events = $ArcEvents
```

In `_ready()`, replace:
```gdscript
DayManager.day_ended.connect(_on_day_ended)
DayManager.all_beats_done.connect(_on_all_beats_done)
```
with:
```gdscript
ClockManager.day_ended.connect(_on_day_ended)
```

Replace the entire `_on_day_ended` method:
```gdscript
# OLD:
func _on_day_ended(day: int) -> void:
	if day == 7:
		_show_ending()
	else:
		if DayManager.current_day == 7:
			arc_events.trigger_final_choice()
		else:
			show_hud_message("Day %d begins." % DayManager.current_day)

# NEW:
func _on_day_ended(_day: int) -> void:
	day_summary.show_summary()
```

Delete the entire `_on_all_beats_done` method:
```gdscript
# DELETE this entire method:
func _on_all_beats_done() -> void:
	show_hud_message("All story beats complete. Rest at your bunk in Quarters.")
```

Delete the entire `_show_ending` method:
```gdscript
# DELETE this entire method:
func _show_ending() -> void:
	if GameState.get_flag("ending_pragmatic"):
		get_tree().change_scene_to_file("res://scenes/ui/ending_pragmatic.tscn")
	elif GameState.get_flag("ending_hopeful"):
		get_tree().change_scene_to_file("res://scenes/ui/ending_hopeful.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/ending_deferred.tscn")
```

**Step 2: Verify**

Run a grep to confirm no `DayManager` references remain in main.gd:
```bash
grep "DayManager" scripts/main.gd
```
Expected: no output.

**Step 3: Commit**

```bash
git add scripts/main.gd
git commit -m "feat: simplify main.gd — wire day_ended to ClockManager, remove arc logic"
```

---

### Task 9: Delete DayManager + clean up tests

**Files:**
- Delete: `scripts/autoload/day_manager.gd`
- Delete: `tests/test_day_manager.gd`
- Modify: `project.godot` (remove DayManager entry)
- Modify: `tests/test_game_state.gd` (add `before_each`)

**Depends on:** Tasks 6, 7, 8 — all DayManager references in hud.gd, day_summary.gd, and main.gd must be removed first
**Parallelizable with:** none — writes project.godot and deletes files that Tasks 6–8 depended on

**Step 1: Verify no remaining DayManager references**

```bash
grep -rn "DayManager" scripts/ tests/ data/
```
Expected: no output. If any appear, fix them before proceeding.

**Step 2: Delete DayManager files**

```bash
git rm scripts/autoload/day_manager.gd
git rm tests/test_day_manager.gd
```

**Step 3: Remove DayManager from project.godot**

In `project.godot`, find the `[autoload]` section and remove the `DayManager` line:

```ini
# DELETE this line:
DayManager="*res://scripts/autoload/day_manager.gd"
```

Result should be:
```ini
[autoload]

GameState="*res://scripts/autoload/game_state.gd"
CraftingSystem="*res://scripts/autoload/crafting_system.gd"
ClockManager="*res://scripts/autoload/clock_manager.gd"
```

**Step 4: Add before_each to test_game_state.gd**

In `tests/test_game_state.gd`, add a `before_each` function at the top of the class body (after `extends GutTest`):

```gdscript
func before_each():
	GameState.reset()
```

The existing inline `GameState.reset()` calls in individual tests remain (double-reset is harmless).

**Step 5: Run all GUT tests**

```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass. `test_day_manager.gd` is gone; `test_clock_manager.gd` is the new suite.

**Step 6: Commit**

```bash
git add project.godot tests/test_game_state.gd
git commit -m "feat: delete DayManager, remove from project.godot, clean up test suite"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 3

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 6, Task 7, Task 8 | Different output files (hud.tscn, hud.gd, day_summary.gd, main.gd) |
| B (sequential) | Task 9 | Depends on Group A — all DayManager refs removed before deletion |

### Smoketest Checkpoint 3 — Full ClockManager feature

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass, zero failures.

**Step 3: Launch game and verify visually**

Use the `/run` skill to launch the game.

**Step 4: Confirm with user**

Verify each acceptance criterion:

- [ ] HUD shows `06:00` at game start
- [ ] Talk to any NPC — clock advances to `06:30` after dialogue ends
- [ ] `End Day` button in HUD triggers the day summary
- [ ] Day summary shows action log entries (e.g., "• Met Maris") and current resource stocks below the `—` separator
- [ ] `Rest and begin next day` button advances to Day 2 — clock resets to `06:00`, day label shows `Day 2`
- [ ] Running past `22:00` via consecutive talks auto-triggers the day summary

Confirm all pass before handing off for PR.
