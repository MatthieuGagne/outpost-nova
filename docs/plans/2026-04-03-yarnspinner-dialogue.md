# RPG-Style Dialogue System (YarnSpinner) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the custom dict-tree dialogue system with YarnSpinner-powered RPG dialogue — bottom-anchored panel, character portraits, typewriter effect, keyboard navigation, and Yarn-driven NPC scripts.

**Architecture:** `DialogueRunner` (C# YarnSpinner node) lives in `main.tscn` and drives `dialogue_box.gd`, which implements the YarnSpinner GDScript view protocol (`run_line_async`, `run_options_async`, `on_dialogue_complete_async`). NPCs call `runner.StartDialogueForget("NodeTitle")` via `npc_base.gd`. Yarn custom commands (`<<register>>`, `<<beat>>`) are registered once per scene via a static guard in `npc_base`.

**Tech Stack:** Godot 4.6.1 Mono, YarnSpinner-Godot v0.3.12 (already installed), GDScript, GUT.

## Open questions

- None — all resolved in grill-me session.

---

## Batch 1 — Foundation cleanup

### Task 1: Enable C# and YarnSpinner plugin (interactive)

**Files:** `project.godot` (auto-modified by editor)

**Depends on:** none
**Parallelizable with:** none — all subsequent tasks require the C# project to exist.

**Step 1: Open the Godot editor**

```bash
godot
```

The editor will detect the `.mono` binary and generate `outpost-nova.csproj` and `outpost-nova.sln` at the project root. Wait until the editor finishes loading (bottom bar shows no import activity).

**Step 2: Enable the plugin**

Go to `Project → Project Settings → Plugins`. Find `YarnSpinner-Godot` and set its status to **Enabled**. Click Close.

**Step 3: Verify**

A `DialogueRunner` node type should now appear when you search "Add Node". If you see a C# build error, check the Output panel — the most common cause is a missing .NET SDK. Run `dotnet --version` to confirm .NET 8+ is installed.

**Step 4: Close editor, confirm files exist**

```bash
ls outpost-nova.csproj outpost-nova.sln
```

Expected: both files present.

**Step 5: Commit**

```bash
git add outpost-nova.csproj outpost-nova.sln .godot/mono/ *.props 2>/dev/null; git add -u
git commit -m "chore: generate C# project and enable YarnSpinner plugin"
```

---

### Task 2: Add `GameState.record_register()` with GUT tests

**Files:**
- Modify: `scripts/autoload/game_state.gd`
- Modify: `tests/test_game_state.gd`

**Depends on:** none
**Parallelizable with:** Task 3, Task 4 — different files, no shared state.

**Step 1: Write the failing GUT test**

Add to `tests/test_game_state.gd`, inside the existing class (after any existing test functions):

```gdscript
func test_record_register_increments_count():
	GameState.record_register("warm")
	GameState.record_register("warm")
	GameState.record_register("curious")
	var history = GameState.get_register_history()
	assert_eq(history.get("warm", 0), 2)
	assert_eq(history.get("curious", 0), 1)

func test_record_register_cleared_on_reset():
	GameState.record_register("warm")
	GameState.reset()
	assert_eq(GameState.get_register_history().is_empty(), true)
```

**Step 2: Run test to verify it fails**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_game_state.gd
```

Expected: FAIL — `record_register` is not defined.

**Step 3: Write minimal implementation**

Add to `scripts/autoload/game_state.gd`:

In the variables block (near the other private vars):
```gdscript
var _register_history: Dictionary = {}
```

In `reset()`, add after the existing resets:
```gdscript
_register_history = {}
```

New public methods (add anywhere after `reset()`):
```gdscript
func record_register(register: String) -> void:
	_register_history[register] = _register_history.get(register, 0) + 1

func get_register_history() -> Dictionary:
	return _register_history.duplicate()
```

**Step 4: Run tests to verify they pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_game_state.gd
```

Expected: PASS (all existing tests + 2 new ones).

**Step 5: Refactor checkpoint**

`record_register` takes a bare string — no validation. If an unrecognized register name is passed (e.g., a typo in a `.yarn` file), it silently adds a new key. This is acceptable for the stub phase; if it becomes a problem, open a follow-up issue to add a validation set.

**Step 6: Commit**

```bash
git add scripts/autoload/game_state.gd tests/test_game_state.gd
git commit -m "feat: add GameState.record_register() and get_register_history()"
```

---

### Task 3: Remove `DialogueManager` autoload and delete its script

**Files:**
- Modify: `project.godot`
- Delete: `scripts/autoload/dialogue_manager.gd`

**Depends on:** none
**Parallelizable with:** Task 2 — different output files, no shared state. Not Task 4: Task 4 depends on Task 3 completing first.

**Step 1: Remove the autoload entry**

In `project.godot`, find the `[autoload]` section and remove this line:

```
DialogueManager="*res://scripts/autoload/dialogue_manager.gd"
```

Leave all other autoloads intact.

**Step 2: Delete the script**

```bash
rm scripts/autoload/dialogue_manager.gd
```

**Step 3: Verify no remaining references**

```bash
grep -rn "DialogueManager" --include="*.gd" --include="*.tscn" .
```

Expected: zero matches. If matches remain, remove them — but check first whether they're in dead-code files that Task 4 will delete anyway.

**Step 4: Commit**

```bash
git add project.godot
git rm scripts/autoload/dialogue_manager.gd
git commit -m "refactor: remove DialogueManager autoload"
```

---

### Task 4: Delete dead-code files

**Files deleted:**
- `tests/test_dialogue_manager.gd`
- `scripts/characters/cook.gd`
- `scripts/characters/engineer.gd`
- `scripts/characters/drifter.gd`

**Depends on:** Task 3 (so the deleted test doesn't reference a just-removed autoload and confuse the deletion rationale)
**Parallelizable with:** none — depends on Task 3. Justification: cook/engineer/drifter reference `DialogueManager` through `character.gd`; deleting before Task 3 would leave orphan references visible in grep output.

**Step 1: Delete files**

```bash
git rm tests/test_dialogue_manager.gd \
       scripts/characters/cook.gd \
       scripts/characters/engineer.gd \
       scripts/characters/drifter.gd
```

**Step 2: Verify no scene references**

```bash
grep -rn "cook.gd\|engineer.gd\|drifter.gd" --include="*.tscn" --include="*.gd" .
```

Expected: zero matches (these scripts are not instantiated in any scene).

**Step 3: Commit**

```bash
git commit -m "refactor: delete DialogueManager test and legacy character scripts"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 2, Task 3 | Different output files, no shared state |
| B (sequential) | Task 4 | Depends on Task 3 (dialogue_manager.gd must be gone before clean grep check) |

### Smoketest Checkpoint 1 — Game launches, all GUT tests pass

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass. `test_dialogue_manager.gd` is gone so those tests no longer run. `test_game_state.gd` gains 2 new passing tests.

**Step 3: Launch game and verify visually**
```bash
godot
```

**Step 4: Confirm with user**
Confirm the game launches without errors in the Output panel, and that the existing gameplay (movement, crafting, HUD) still works. Interacting with an NPC will crash or do nothing — that is expected at this stage.

---

## Batch 2 — Yarn content and project wiring

### Task 5: Add portrait sprite sheet

**Files:**
- Create: `assets/portraits/portraits.png`

**Depends on:** none
**Parallelizable with:** Task 6, Task 7.

**Step 1: Copy the source image**

```bash
cp art/placeholder/portraits/IMG_5371.png assets/portraits/portraits.png
```

The sheet is 320×128 px, 10 portraits, each 32×128. Portrait index to character mapping used by `dialogue_box.gd`:

| Index | Character |
|-------|-----------|
| 0 | Maris |
| 1 | Dex |
| 2 | Sable |
| 3–8 | Reserved for future NPCs |
| 9 | Player (all backgrounds) |

Atlas region formula: `Rect2(index * 32, 0, 32, 128)`

**Step 2: Verify**

Open Godot editor and confirm `assets/portraits/portraits.png` appears in the FileSystem panel and imports without error.

**Step 3: Commit**

```bash
git add assets/portraits/portraits.png
git commit -m "feat: add placeholder portrait sprite sheet"
```

---

### Task 6: Create stub Yarn dialogue files

**Files:**
- Create: `data/dialogue/maris.yarn`
- Create: `data/dialogue/dex.yarn`
- Create: `data/dialogue/sable.yarn`

**Depends on:** none
**Parallelizable with:** Task 5, Task 7.

Each file contains a router node and a first-meeting node only. The `#register:` hashtag on choices is a placeholder that `dialogue_box.gd` reads to track inner-voice type (to be redesigned in a future issue).

**Step 1: Create `data/dialogue/maris.yarn`**

```yarn
title: Maris
---
<<jump Maris_FirstMeeting>>
===

title: Maris_FirstMeeting
---
Maris: Hey, you must be new. I'm Maris — I run the food printer.
Maris: Don't let the name fool you, it actually makes real food. Mostly.
-> Good to meet you. #register:warm
    <<register warm>>
    Maris: Likewise. Come find me if you need anything — or if you're hungry.
-> What's the yield rate on something like that? #register:curious
    <<register curious>>
    Maris: Ha. An engineer question. Fifty percent on a good day. Better with decent inputs.
-> ...right. #register:detached
    <<register detached>>
    Maris: ...okay then.
<<beat meet_maris>>
===
```

**Step 2: Create `data/dialogue/dex.yarn`**

```yarn
title: Dex
---
<<jump Dex_FirstMeeting>>
===

title: Dex_FirstMeeting
---
Dex: You're the new face. Good timing — station needs an extra set of eyes.
Dex: I'm Dex. I keep the systems from eating themselves. So far, so good.
-> What should I know about this place? #register:curious
    <<register curious>>
    Dex: Where to start. The power grid's held together by habits and stubbornness. Watch the lower decks.
-> Fair enough. #register:detached
    <<register detached>>
    Dex: Fair enough is about the best you can hope for out here.
-> You sound like you've been here a while. #register:sharp
    <<register sharp>>
    Dex: Long enough to know where the bodies are buried. Metaphorically. Probably.
<<beat check_engineering>>
===
```

**Step 3: Create `data/dialogue/sable.yarn`**

```yarn
title: Sable
---
<<jump Sable_FirstMeeting>>
===

title: Sable_FirstMeeting
---
Sable: Don't mind me. Just passing through.
Sable: ...you're going to ask, aren't you.
-> What brings you to the station? #register:curious
    <<register curious>>
    Sable: Needed a place to be quiet for a while. This seemed quiet enough.
-> We could use more people willing to stick around. #register:warm
    <<register warm>>
    Sable: I said passing through. I didn't say how fast.
-> Sure. #register:detached
    <<register detached>>
    Sable: ...hm. Maybe you're alright.
<<beat sable_arrives>>
===
```

**Step 4: Verify syntax**

Open the Godot editor after the `.yarnproject` exists (Task 7) — the files will be imported and any syntax errors will appear in the Output panel. At this stage, just confirm the files are saved correctly.

**Step 5: Commit**

```bash
git add data/dialogue/
git commit -m "feat: add stub Yarn dialogue files for Maris, Dex, Sable"
```

---

### Task 7: Create the YarnProject file

**Files:**
- Create: `data/dialogue/outpost-nova.yarnproject`

**Depends on:** Task 6 (yarn files must exist before the project file references them)
**Parallelizable with:** none — depends on Task 6. Justification: The importer resolves `*.yarn` relative to the `.yarnproject` file; if yarn files don't exist, the import will fail with a source-not-found error.

**Step 1: Create the project file**

```json
{
  "projectFileVersion": 2,
  "sourceFiles": [
    "*.yarn"
  ],
  "excludeFiles": [],
  "baseLanguage": "en",
  "localisation": {},
  "definitions": null
}
```

Save as `data/dialogue/outpost-nova.yarnproject`.

**Step 2: Trigger Godot reimport**

Open (or focus) the Godot editor. The file watcher will detect the new `.yarnproject` and reimport it. Check the Output panel for any errors. A successful import produces no errors and the `.yarnproject` file gets a `.import` sidecar.

**Step 3: Verify**

In the Godot FileSystem panel, right-click `outpost-nova.yarnproject` → "Reimport". Confirm no errors.

**Step 4: Commit**

```bash
git add data/dialogue/outpost-nova.yarnproject
git commit -m "feat: add YarnProject file for dialogue system"
```

---

### Task 8: Add `DialogueRunner` to `main.tscn` (interactive)

**Files:**
- Modify: `scenes/main.tscn`

**Depends on:** Task 7 (YarnProject must be imported before it can be assigned in the inspector)
**Parallelizable with:** none — depends on Task 7. Justification: assigning an unimported resource in the DialogueRunner inspector will fail or reset on next open.

**Step 1: Open `main.tscn` in the Godot editor**

In the Scene panel, click the root node to ensure you're at the top level.

**Step 2: Add `DialogueRunner` node**

Click "Add Child Node" (Ctrl+A), search for `DialogueRunner`, add it as a child of the scene root. Name it `DialogueRunner`.

**Step 3: Configure in Inspector**

With `DialogueRunner` selected:
- **Yarn Project:** click the field, browse to `data/dialogue/outpost-nova.yarnproject`, assign it.
- **Auto Start:** leave unchecked.
- **Groups:** In the Node panel → Groups tab, add the group `dialogue_runner`.
- **Process Mode:** set to `Always` (so it runs while the tree is paused).

**Step 4: Add `DialogueBox` as a Dialogue View**

With `DialogueRunner` selected, find the **Dialogue Presenters** (or **Dialogue Views**) array in the Inspector. Click the array, add one entry, and drag the existing `DialogueBox` node from the Scene panel into that slot.

**Step 5: Save the scene**

Ctrl+S.

**Step 6: Commit**

```bash
git add scenes/main.tscn
git commit -m "feat: add DialogueRunner node to main.tscn"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 5, Task 6 | Different output files, no shared state |
| B (sequential) | Task 7 | Depends on Task 6 — .yarnproject glob must resolve |
| C (sequential) | Task 8 | Depends on Task 7 — requires imported YarnProject resource |

### Smoketest Checkpoint 2 — Yarn files imported, game launches

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass.

**Step 3: Launch game and verify visually**
```bash
godot
```

**Step 4: Confirm with user**
Confirm: (a) no Yarn import errors in the Output panel, (b) game launches and `DialogueRunner` is visible in the remote scene tree (Scene → Remote tab while game is running), (c) interacting with an NPC still does nothing/crashes gracefully — expected, NPC scripts not yet updated.

---

## Batch 3 — DialogueBox rebuild

### Task 9: Rebuild `dialogue_box.tscn`

**Files:**
- Modify: `scenes/ui/dialogue_box.tscn`

**Depends on:** none
**Parallelizable with:** Task 10 — scene structure and script are separate files; the script references node paths, so if working in parallel be aware node names must match what Task 10 expects.

**Step 1: Open `dialogue_box.tscn` in the Godot editor**

Delete all existing child nodes of the root `DialogueBox` (CanvasLayer) — they will be replaced.

**Step 2: Build the new scene tree**

Create the following hierarchy (all created via the "Add Child Node" flow):

```
DialogueBox (CanvasLayer)            ← existing root, keep it
  process_mode = Always
  layer = 10

  └── PanelContainer                 ← add new
        layout_mode = 1 (anchors)
        anchor_left = 0
        anchor_top = 1
        anchor_right = 1
        anchor_bottom = 1
        offset_top = -110
        offset_bottom = 0
        [StyleBoxFlat override: bg_color = Color(0.06, 0.06, 0.10, 0.95),
         border_color = Color(0.3, 0.3, 0.5), border_width_all = 1]

        └── MarginContainer
              theme_override_constants/margin_left   = 8
              theme_override_constants/margin_right  = 8
              theme_override_constants/margin_top    = 6
              theme_override_constants/margin_bottom = 6

              └── HBoxContainer
                    theme_override_constants/separation = 8

                    ├── PortraitContainer (VBoxContainer)
                    │     custom_minimum_size = Vector2(32, 0)
                    │
                    │     ├── NPCPortrait (TextureRect)
                    │     │     custom_minimum_size = Vector2(32, 64)
                    │     │     expand_mode = EXPAND_FIT_HEIGHT_PROPORTIONAL
                    │     │     stretch_mode = KEEP_ASPECT_CENTERED
                    │     │
                    │     └── PlayerPortrait (TextureRect)
                    │           custom_minimum_size = Vector2(32, 32)
                    │           expand_mode = EXPAND_FIT_HEIGHT_PROPORTIONAL
                    │           stretch_mode = KEEP_ASPECT_CENTERED
                    │
                    └── ContentContainer (VBoxContainer)
                          size_flags_horizontal = FILL+EXPAND
                          theme_override_constants/separation = 2

                          ├── SpeakerLabel (Label)
                          │     theme_override_fonts/font = res://data/fonts/m5x7.tres
                          │     theme_override_font_sizes/font_size = 16
                          │     [modulate = Color(0.8, 0.8, 1.0)]
                          │
                          ├── DialogueText (RichTextLabel)
                          │     bbcode_enabled = true
                          │     scroll_active = false
                          │     fit_content = true
                          │     theme_override_fonts/normal_font = res://data/fonts/m5x7.tres
                          │     theme_override_font_sizes/normal_font_size = 14
                          │
                          └── ChoicesContainer (VBoxContainer)
                                visible = false
                                theme_override_constants/separation = 2
```

**Step 3: Set DialogueBox hidden by default**

Select the root `DialogueBox` node and set `visible = false`.

**Step 4: Save scene**

Ctrl+S.

**Step 5: Verify**

Run the game briefly and confirm the panel does not appear on startup (it's hidden). No script errors expected at this stage.

**Step 6: Commit**

```bash
git add scenes/ui/dialogue_box.tscn
git commit -m "feat: rebuild dialogue_box scene with RPG panel layout"
```

---

### Task 10: Rewrite `dialogue_box.gd` as YarnSpinner GDScript view

**Files:**
- Modify: `scripts/ui/dialogue_box.gd`

**Depends on:** Task 9 (node paths must exist)
**Parallelizable with:** none — depends on Task 9. Justification: this script references `$PanelContainer/MarginContainer/HBoxContainer/...` node paths that only exist after Task 9 builds the scene.

**Step 1: Write the failing GUT test**

There is no headless GUT test for this file — `DialogueViewBase` UI logic is not headlessly testable (it requires a running scene tree with signal-driven awaits). Skip to Step 3.

**Step 2: (no test to run)**

**Step 3: Write the implementation**

Replace the entire contents of `scripts/ui/dialogue_box.gd`:

```gdscript
extends CanvasLayer

signal conversation_ended

const PORTRAIT_SHEET := preload("res://assets/portraits/portraits.png")
const PORTRAIT_WIDTH := 32
const PORTRAIT_HEIGHT := 128

const NPC_PORTRAIT_INDEX: Dictionary = {
	"Maris": 0,
	"Dex": 1,
	"Sable": 2,
}
const PLAYER_PORTRAIT_INDEX := 9
const FALLBACK_PORTRAIT_INDEX := 3

const TYPEWRITER_CHARS_PER_SECOND := 30.0

enum _State { IDLE, TYPEWRITING, COMPLETE, CHOOSING }

var _state: _State = _State.IDLE
var _line_advance_signal := Signal(self, "_line_advance_requested")
var _option_chosen_signal := Signal(self, "_option_chosen")

signal _line_advance_requested
signal _option_chosen

@onready var _npc_portrait: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/PortraitContainer/NPCPortrait
@onready var _player_portrait: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/PortraitContainer/PlayerPortrait
@onready var _speaker_label: Label = $PanelContainer/MarginContainer/HBoxContainer/ContentContainer/SpeakerLabel
@onready var _dialogue_text: RichTextLabel = $PanelContainer/MarginContainer/HBoxContainer/ContentContainer/DialogueText
@onready var _choices_container: VBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/ContentContainer/ChoicesContainer

var _typewriter_timer: float = 0.0
var _typewriter_target: int = 0
var _full_text: String = ""

func _ready() -> void:
	add_to_group("dialogue_box")
	_player_portrait.texture = _make_atlas(PLAYER_PORTRAIT_INDEX)
	hide()

func _process(delta: float) -> void:
	if _state != _State.TYPEWRITING:
		return
	_typewriter_timer += delta
	var chars_to_show := int(_typewriter_timer * TYPEWRITER_CHARS_PER_SECOND)
	_dialogue_text.visible_characters = min(chars_to_show, _typewriter_target)
	if _dialogue_text.visible_characters >= _typewriter_target:
		_state = _State.COMPLETE

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		match _state:
			_State.TYPEWRITING:
				_dialogue_text.visible_characters = -1
				_typewriter_timer = 9999.0
				_state = _State.COMPLETE
			_State.COMPLETE:
				_state = _State.IDLE
				_line_advance_requested.emit()
		get_viewport().set_input_as_handled()
	if _state == _State.CHOOSING:
		var buttons := _choices_container.get_children()
		if event.is_action_pressed("ui_up"):
			_move_selection(buttons, -1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			_move_selection(buttons, 1)
			get_viewport().set_input_as_handled()
		else:
			for i in range(min(4, buttons.size())):
				if event.is_action_pressed("ui_text_completion_replace") or \
				   (event is InputEventKey and event.pressed and \
				    event.keycode == KEY_1 + i):
					_select_choice(buttons[i])
					get_viewport().set_input_as_handled()

# ── YarnSpinner GDScript view protocol ───────────────────────────────────────

func on_dialogue_start_async() -> void:
	show()
	get_tree().paused = true

func run_line_async(line: Dictionary) -> void:
	_choices_container.visible = false
	var localized_line := YarnSpinner.LocalizedLine.from_dictionary(line)
	_speaker_label.text = localized_line.character_name
	_update_portrait(localized_line.character_name)
	_start_typewriter(localized_line.text_without_character_name.text)
	await _line_advance_requested

func run_options_async(options: Array, on_option_selected: Callable) -> void:
	_build_choices(options, on_option_selected)
	_choices_container.visible = true
	await _option_chosen

func on_dialogue_complete_async() -> void:
	_choices_container.visible = false
	_state = _State.IDLE
	hide()
	get_tree().paused = false
	conversation_ended.emit()

# ── Internal helpers ──────────────────────────────────────────────────────────

func _start_typewriter(text: String) -> void:
	_full_text = text
	_dialogue_text.text = text
	_dialogue_text.visible_characters = 0
	_typewriter_timer = 0.0
	_typewriter_target = len(text)
	_state = _State.TYPEWRITING

func _update_portrait(speaker: String) -> void:
	var idx: int = NPC_PORTRAIT_INDEX.get(speaker, FALLBACK_PORTRAIT_INDEX)
	_npc_portrait.texture = _make_atlas(idx)

func _make_atlas(index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = PORTRAIT_SHEET
	atlas.region = Rect2(index * PORTRAIT_WIDTH, 0, PORTRAIT_WIDTH, PORTRAIT_HEIGHT)
	return atlas

func _build_choices(options: Array, on_option_selected: Callable) -> void:
	for child in _choices_container.get_children():
		child.queue_free()
	for i in range(options.size()):
		var option := YarnSpinner.DialogueOption.from_dictionary(options[i])
		var btn := Button.new()
		btn.text = "[%d] %s" % [i + 1, option.line.text_without_character_name.text]
		btn.theme_override_fonts["font"] = load("res://data/fonts/m5x7.tres")
		btn.theme_override_font_sizes["font_size"] = 13
		btn.disabled = not option.is_available
		btn.pressed.connect(_on_choice_pressed.bind(option.dialogue_option_id, on_option_selected))
		_choices_container.add_child(btn)
	# Focus the first available button
	for child in _choices_container.get_children():
		if not child.disabled:
			child.grab_focus()
			break

func _on_choice_pressed(option_id: int, on_option_selected: Callable) -> void:
	_state = _State.IDLE
	_choices_container.visible = false
	on_option_selected.call(option_id)
	_option_chosen.emit()

func _move_selection(buttons: Array, direction: int) -> void:
	var focused := _choices_container.get_viewport().gui_get_focus_owner()
	var current_idx := buttons.find(focused)
	if current_idx == -1:
		current_idx = 0
	var next_idx := wrapi(current_idx + direction, 0, buttons.size())
	buttons[next_idx].grab_focus()

func _select_choice(btn: Button) -> void:
	if not btn.disabled:
		btn.emit_signal("pressed")
```

**Step 4: Run tests to verify no regressions**

```bash
godot --headless -s addons/gut/gut_cmdln.gd
```

Expected: All tests still pass (no tests cover this file headlessly).

**Step 5: Refactor checkpoint**

`_make_atlas` creates a new `AtlasTexture` on every call. For 11 possible portraits over a short session this is harmless. If profiling ever flags it, cache in a dictionary — open a follow-up issue then.

**Step 6: Commit**

```bash
git add scripts/ui/dialogue_box.gd
git commit -m "feat: rewrite dialogue_box as YarnSpinner GDScript view with typewriter and portraits"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 3

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 9, then Task 10 | Task 10 reads node paths Task 9 creates |

### Smoketest Checkpoint 3 — Dialogue box appears without crashing

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass.

**Step 3: Launch game and verify visually**
```bash
godot
```

**Step 4: Confirm with user**
Confirm: (a) game launches without errors, (b) the dialogue panel is not visible on startup (hidden by default), (c) no script errors about missing node paths in the Output panel. Interacting with an NPC may still crash — expected, NPC scripts not yet updated.

---

## Batch 4 — NPC integration

### Task 11: Update `npc_base.gd` to use `DialogueRunner`

**Files:**
- Modify: `scripts/characters/npc_base.gd`

**Depends on:** none
**Parallelizable with:** Task 12 — different files; both write to character scripts but not the same file.

**Step 1: Write the failing GUT test**

There is no headless GUT test for `npc_base` interaction flow — it requires a running scene. Skip to Step 3.

**Step 2: (no test to run)**

**Step 3: Write minimal implementation**

In `scripts/characters/npc_base.gd`, replace the `interact()` method and add the following changes:

Add near the top of the class (after `var _is_talking`):
```gdscript
static var _commands_registered: bool = false
```

Replace `interact()`:
```gdscript
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
		runner.AddCommandHandlerCallable("beat", Callable(DayManager, "complete_beat"))
		_commands_registered = true
	var boxes := get_tree().get_nodes_in_group("dialogue_box")
	if not boxes.is_empty():
		var box := boxes[0]
		if not box.conversation_ended.is_connected(_on_conversation_ended):
			box.conversation_ended.connect(_on_conversation_ended)
	_is_talking = true
	runner.StartDialogueForget(get_dialogue_node())
```

Replace `_on_conversation_ended()` (keep the same method, just make sure it exists):
```gdscript
func _on_conversation_ended() -> void:
	_is_talking = false
```

Add abstract method (at bottom of the file, after existing methods):
```gdscript
## Override in subclass to return the Yarn node title for this NPC.
func get_dialogue_node() -> String:
	return display_name
```

Remove (or gut) `get_dialogue_tree()` — it is no longer called anywhere. If it exists as an abstract method, delete it. If subclasses override it, those overrides will be removed in Task 12.

**Step 4: Run tests to verify no regressions**

```bash
godot --headless -s addons/gut/gut_cmdln.gd
```

Expected: All tests pass.

**Step 5: Refactor checkpoint**

`_commands_registered` is a `static var` — shared across all `npc_base` instances. The first NPC to call `interact()` registers the commands; all subsequent NPCs skip it. This is the intended behavior. If a future NPC subclass needs different commands, open a follow-up issue.

**Step 6: Commit**

```bash
git add scripts/characters/npc_base.gd
git commit -m "feat: update npc_base to start dialogue via DialogueRunner"
```

---

### Task 12: Update `maris.gd`, `dex.gd`, `sable.gd`

**Files:**
- Modify: `scripts/characters/maris.gd`
- Modify: `scripts/characters/dex.gd`
- Modify: `scripts/characters/sable.gd`

**Depends on:** Task 11 (npc_base must define `get_dialogue_node()` before subclasses override it)
**Parallelizable with:** none — depends on Task 11. Justification: subclasses override `get_dialogue_node()` which Task 11 adds to npc_base; without it, the override has no base definition.

**Step 1: Update each file**

In each file, make two changes:
1. Remove the `get_dialogue_tree()` override entirely.
2. Add a `get_dialogue_node()` override returning the matching Yarn node title.

**`scripts/characters/maris.gd`** — add:
```gdscript
func get_dialogue_node() -> String:
	return "Maris"
```

**`scripts/characters/dex.gd`** — add:
```gdscript
func get_dialogue_node() -> String:
	return "Dex"
```

**`scripts/characters/sable.gd`** — add:
```gdscript
func get_dialogue_node() -> String:
	return "Sable"
```

**Step 2: Verify no remaining `get_dialogue_tree` calls**

```bash
grep -rn "get_dialogue_tree\|start_conversation\|DialogueManager" --include="*.gd" .
```

Expected: zero matches.

**Step 3: Run tests**

```bash
godot --headless -s addons/gut/gut_cmdln.gd
```

Expected: All tests pass.

**Step 4: Commit**

```bash
git add scripts/characters/maris.gd scripts/characters/dex.gd scripts/characters/sable.gd
git commit -m "feat: update NPC scripts to use YarnSpinner via get_dialogue_node()"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 4

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 11, then Task 12 | Task 12 overrides a method Task 11 defines |

### Smoketest Checkpoint 4 — Full dialogue flow end-to-end

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass.

**Step 3: Launch game and verify visually**
```bash
godot
```

**Step 4: Confirm with user — verify all acceptance criteria**

Walk the user through each AC:

- **AC1:** Walk up to an NPC → interact → panel appears at screen bottom with NPC portrait.
- **AC2:** Text appears character-by-character. First Enter skips to full text; second Enter advances.
- **AC3:** Choice buttons appear; Up/Down arrow moves the highlight; Enter confirms; keys 1–3 jump directly.
- **AC4:** Mouse click on a choice button works.
- **AC5:** Player movement stops while dialogue is open; world is frozen.
- **AC6:** NPC portrait shown during NPC lines. Player portrait shown during player-voiced lines (if any).
- **AC7:** After choosing a `#register:warm` option, `GameState.get_register_history()["warm"]` increments (verify in GUT or debugger).
- **AC8:** Completing a first-meeting dialogue triggers the correct story beat (check `DayManager.is_beat_complete("meet_maris")` etc.).
- **AC9:** (N/A for stub-only yarn files with no `<<if get_flag()>>` conditions — deferred to multi-state implementation.)
- **AC10:** All GUT tests pass headlessly. ✓ (already verified in Step 2)
