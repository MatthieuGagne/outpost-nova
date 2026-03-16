# Outpost Nova (Evolved) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

> **Note:** This plan supersedes `2026-03-15-mvp-implementation.md`. Task 1 (project setup, GUT, autoloads) from that plan is already complete. Everything else is replaced by this plan.

**Goal:** Build a playable vertical slice — top-down movement through a space station, flag-driven dialogue with emotional registers and inner voices, a roguelite Derelict Section, and a 7-day story arc with a real ending.

**Architecture:** Four autoload singletons (GameState, CraftingSystem, DayManager, DialogueManager) handle all global state. Player moves freely through walkable Area scenes. The Derelict is a separate roguelite mode. All pure logic is TDD with GUT; visual/scene tasks use manual testing.

**Tech Stack:** Godot 4.6.1 (GDScript), GUT v9.6.0 (unit tests), Mobile renderer, 16-bit pixel art (placeholder colored rects for MVP).

---

## Status

| Task | Status |
|------|--------|
| Task 1: Project Setup + Autoload stubs | ✅ Done |
| Task 2: GameState (extended) | ⬜ Todo |
| Task 3: DayManager Autoload | ⬜ Todo |
| Task 4: DialogueManager Autoload | ⬜ Todo |
| Task 5: CraftingSystem (extended) | ⬜ Todo |
| Task 6: PlayerCharacter Scene & Movement | ⬜ Todo |
| Task 7: NPC Base Scene & Wander | ⬜ Todo |
| Task 8: Area Scenes (Cantina, Engineering, Quarters) | ⬜ Todo |
| Task 9: Character Creation UI | ⬜ Todo |
| Task 10: DialogueBox UI | ⬜ Todo |
| Task 11: Character Dialogue Scripts (Maris, Dex, Sable) | ⬜ Todo |
| Task 12: Derelict Run (Room Generator + Basic Combat) | ⬜ Todo |
| Task 13: Enemy Base + Drone Enemy | ⬜ Todo |
| Task 14: Survivor Encounter System | ⬜ Todo |
| Task 15: Main Story Beats (7-day arc) | ⬜ Todo |
| Task 16: HUD + Day Summary UI | ⬜ Todo |
| Task 17: Main Scene — Wire Everything Together | ⬜ Todo |

---

## Project Structure

```
outpost-nova/
├── project.godot
├── addons/gut/
├── scenes/
│   ├── main.tscn                    # Entry after character creation
│   ├── character_creation.tscn      # First scene on launch
│   ├── areas/
│   │   ├── cantina.tscn
│   │   ├── engineering.tscn
│   │   ├── quarters.tscn
│   │   └── derelict_entrance.tscn
│   ├── characters/
│   │   ├── player.tscn
│   │   └── npc_base.tscn
│   ├── derelict/
│   │   ├── run.tscn
│   │   └── rooms/                   # Hand-crafted room templates
│   └── ui/
│       ├── hud.tscn
│       ├── dialogue_box.tscn
│       ├── crafting_panel.tscn
│       └── day_summary.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_state.gd
│   │   ├── crafting_system.gd
│   │   ├── day_manager.gd
│   │   └── dialogue_manager.gd
│   ├── areas/
│   │   ├── cantina.gd
│   │   ├── engineering.gd
│   │   ├── quarters.gd
│   │   └── derelict_entrance.gd
│   ├── characters/
│   │   ├── player.gd
│   │   ├── npc_base.gd
│   │   ├── maris.gd
│   │   ├── dex.gd
│   │   └── sable.gd
│   ├── derelict/
│   │   ├── run.gd
│   │   ├── room_generator.gd
│   │   └── enemy_base.gd
│   └── ui/
│       ├── hud.gd
│       ├── dialogue_box.gd
│       ├── crafting_panel.gd
│       └── day_summary.gd
└── tests/
    ├── test_game_state.gd
    ├── test_day_manager.gd
    ├── test_dialogue_manager.gd
    └── test_crafting_system.gd
```

---

## Task 2: GameState (Extended)

**Files:**
- Modify: `scripts/autoload/game_state.gd`
- Create: `tests/test_game_state.gd`

GameState tracks resources, flags, AND player identity. Player background affects inner voice in dialogues. All prior resource/flag API is preserved.

**Step 1: Write the failing tests**

```gdscript
# tests/test_game_state.gd
extends GutTest

func test_resources_start_at_zero():
    GameState.reset()
    assert_eq(GameState.get_resource("rations"), 0)
    assert_eq(GameState.get_resource("parts"), 0)
    assert_eq(GameState.get_resource("energy_cells"), 0)

func test_add_resource():
    GameState.reset()
    GameState.add_resource("rations", 3)
    assert_eq(GameState.get_resource("rations"), 3)

func test_spend_resource_succeeds():
    GameState.reset()
    GameState.add_resource("parts", 5)
    var ok = GameState.spend_resource("parts", 3)
    assert_true(ok)
    assert_eq(GameState.get_resource("parts"), 2)

func test_spend_resource_fails_if_insufficient():
    GameState.reset()
    GameState.add_resource("parts", 1)
    var ok = GameState.spend_resource("parts", 3)
    assert_false(ok)
    assert_eq(GameState.get_resource("parts"), 1)

func test_flags_default_false():
    GameState.reset()
    assert_false(GameState.get_flag("workshop_unlocked"))

func test_set_flag():
    GameState.reset()
    GameState.set_flag("workshop_unlocked", true)
    assert_true(GameState.get_flag("workshop_unlocked"))

func test_player_background_defaults_empty():
    GameState.reset()
    assert_eq(GameState.player_background, "")

func test_set_player_identity():
    GameState.reset()
    GameState.set_player_identity("Kael", "engineer", 0)
    assert_eq(GameState.player_name, "Kael")
    assert_eq(GameState.player_background, "engineer")
    assert_eq(GameState.player_appearance, 0)

func test_engineer_background_starts_with_parts():
    GameState.reset()
    GameState.apply_background_bonus("engineer")
    assert_eq(GameState.get_resource("parts"), 3)

func test_medic_background_starts_with_rations():
    GameState.reset()
    GameState.apply_background_bonus("medic")
    assert_eq(GameState.get_resource("rations"), 3)

func test_drifter_background_starts_with_energy_cells():
    GameState.reset()
    GameState.apply_background_bonus("drifter")
    assert_eq(GameState.get_resource("energy_cells"), 3)

func test_npc_flag_history():
    GameState.reset()
    GameState.record_npc_choice("maris", "was_honest")
    assert_true(GameState.has_npc_flag("maris", "was_honest"))
    assert_false(GameState.has_npc_flag("maris", "helped_her"))
```

**Step 2: Run tests to verify they fail**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_game_state.gd
```

Expected: errors (new methods don't exist yet).

**Step 3: Implement extended GameState**

```gdscript
# scripts/autoload/game_state.gd
extends Node

signal resource_changed(resource_id: String, new_amount: int)
signal flag_changed(flag_id: String, value: bool)

var player_name: String = ""
var player_background: String = ""  # "engineer", "medic", "drifter"
var player_appearance: int = 0

var _resources: Dictionary = {}
var _flags: Dictionary = {}
var _npc_flags: Dictionary = {}  # { npc_id: [flag1, flag2, ...] }

const BACKGROUND_BONUSES = {
    "engineer": { "parts": 3 },
    "medic": { "rations": 3 },
    "drifter": { "energy_cells": 3 }
}

func reset() -> void:
    player_name = ""
    player_background = ""
    player_appearance = 0
    _resources = { "rations": 0, "parts": 0, "energy_cells": 0, "scrap": 0 }
    _flags = {}
    _npc_flags = {}

func _ready() -> void:
    reset()

func set_player_identity(name: String, background: String, appearance: int) -> void:
    player_name = name
    player_background = background
    player_appearance = appearance

func apply_background_bonus(background: String) -> void:
    if not BACKGROUND_BONUSES.has(background):
        return
    for resource_id in BACKGROUND_BONUSES[background]:
        add_resource(resource_id, BACKGROUND_BONUSES[background][resource_id])

func get_resource(id: String) -> int:
    return _resources.get(id, 0)

func add_resource(id: String, amount: int) -> void:
    _resources[id] = _resources.get(id, 0) + amount
    resource_changed.emit(id, _resources[id])

func spend_resource(id: String, amount: int) -> bool:
    if _resources.get(id, 0) < amount:
        return false
    _resources[id] -= amount
    resource_changed.emit(id, _resources[id])
    return true

func get_flag(id: String) -> bool:
    return _flags.get(id, false)

func set_flag(id: String, value: bool) -> void:
    _flags[id] = value
    flag_changed.emit(id, value)

func record_npc_choice(npc_id: String, flag: String) -> void:
    if not _npc_flags.has(npc_id):
        _npc_flags[npc_id] = []
    if not _npc_flags[npc_id].has(flag):
        _npc_flags[npc_id].append(flag)

func has_npc_flag(npc_id: String, flag: String) -> bool:
    return _npc_flags.get(npc_id, []).has(flag)
```

**Step 4: Run tests to verify they pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_game_state.gd
```

Expected: all green.

**Step 5: Register GameState in project.godot** (if not already done in Task 1)

Project → Project Settings → Autoload → verify `scripts/autoload/game_state.gd` is registered as `GameState`.

**Step 6: Commit**

```bash
git add scripts/autoload/game_state.gd tests/test_game_state.gd
git commit -m "feat: extend GameState with player identity, backgrounds, and NPC flag history"
```

---

## Task 3: DayManager Autoload

**Files:**
- Create: `scripts/autoload/day_manager.gd`
- Create: `tests/test_day_manager.gd`

DayManager tracks which story beats are available today, which are completed, and when the day ends. Beat definitions are data-driven (a dict per day). The arc is 7 days for the MVP.

**Step 1: Write the failing tests**

```gdscript
# tests/test_day_manager.gd
extends GutTest

func before_each():
    GameState.reset()
    DayManager.reset()

func test_starts_on_day_one():
    assert_eq(DayManager.current_day, 1)

func test_beats_empty_on_reset():
    assert_eq(DayManager.get_todays_beats().size(), 0)

func test_complete_beat():
    DayManager.reset()
    DayManager._override_beats_for_test([{ "id": "meet_maris", "required": true }])
    DayManager.complete_beat("meet_maris")
    assert_true(DayManager.is_beat_complete("meet_maris"))

func test_day_not_complete_if_required_beats_remain():
    DayManager.reset()
    DayManager._override_beats_for_test([
        { "id": "beat_a", "required": true },
        { "id": "beat_b", "required": true }
    ])
    DayManager.complete_beat("beat_a")
    assert_false(DayManager.is_day_complete())

func test_day_complete_when_all_required_beats_done():
    DayManager.reset()
    DayManager._override_beats_for_test([
        { "id": "beat_a", "required": true },
        { "id": "beat_b", "required": false }
    ])
    DayManager.complete_beat("beat_a")
    assert_true(DayManager.is_day_complete())

func test_advance_day_increments_counter():
    DayManager.reset()
    DayManager._override_beats_for_test([])
    DayManager.advance_day()
    assert_eq(DayManager.current_day, 2)

func test_advance_day_clears_completed_beats():
    DayManager.reset()
    DayManager._override_beats_for_test([{ "id": "beat_a", "required": true }])
    DayManager.complete_beat("beat_a")
    DayManager.advance_day()
    assert_false(DayManager.is_beat_complete("beat_a"))
```

**Step 2: Run tests to verify they fail**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_day_manager.gd
```

**Step 3: Implement DayManager**

```gdscript
# scripts/autoload/day_manager.gd
extends Node

signal day_ended(day_number: int)
signal beat_completed(beat_id: String)
signal all_beats_done()

var current_day: int = 1
var _completed_beats: Array = []
var _todays_beats: Array = []

# Arc beat definitions: array of { id, required, npc, flag_to_set }
# Each entry in ARC_BEATS is the beat list for that day (1-indexed).
const ARC_BEATS: Dictionary = {
    1: [
        { "id": "meet_maris", "required": true, "npc": "maris", "flag_to_set": "met_maris" },
        { "id": "check_engineering", "required": true, "npc": "dex", "flag_to_set": "met_dex" },
    ],
    2: [
        { "id": "sable_arrives", "required": true, "npc": "sable", "flag_to_set": "met_sable" },
        { "id": "power_flicker", "required": true, "npc": "dex", "flag_to_set": "power_flicker_noticed" },
    ],
    3: [
        { "id": "maris_food_trouble", "required": true, "npc": "maris", "flag_to_set": "maris_confided" },
        { "id": "sable_offer", "required": false, "npc": "sable", "flag_to_set": "sable_offered_help" },
    ],
    4: [
        { "id": "derelict_door", "required": true, "npc": "dex", "flag_to_set": "derelict_mentioned" },
        { "id": "maris_asks_favour", "required": true, "npc": "maris", "flag_to_set": "maris_favour_asked" },
    ],
    5: [
        { "id": "first_derelict_run", "required": true, "npc": "", "flag_to_set": "derelict_entered" },
        { "id": "sable_past", "required": false, "npc": "sable", "flag_to_set": "sable_past_revealed" },
    ],
    6: [
        { "id": "survivor_found", "required": true, "npc": "", "flag_to_set": "first_survivor_found" },
        { "id": "dex_secret", "required": true, "npc": "dex", "flag_to_set": "dex_secret_known" },
    ],
    7: [
        { "id": "the_choice", "required": true, "npc": "", "flag_to_set": "final_choice_made" },
    ],
}

func reset() -> void:
    current_day = 1
    _completed_beats = []
    _todays_beats = ARC_BEATS.get(current_day, []).duplicate(true)

func _ready() -> void:
    reset()

func _override_beats_for_test(beats: Array) -> void:
    _todays_beats = beats.duplicate(true)
    _completed_beats = []

func get_todays_beats() -> Array:
    return _todays_beats

func complete_beat(beat_id: String) -> void:
    if not _completed_beats.has(beat_id):
        _completed_beats.append(beat_id)
        beat_completed.emit(beat_id)
        # Set the flag on GameState
        for beat in _todays_beats:
            if beat["id"] == beat_id and beat.get("flag_to_set", "") != "":
                GameState.set_flag(beat["flag_to_set"], true)
        if is_day_complete():
            all_beats_done.emit()

func is_beat_complete(beat_id: String) -> bool:
    return _completed_beats.has(beat_id)

func is_day_complete() -> bool:
    for beat in _todays_beats:
        if beat.get("required", false) and not _completed_beats.has(beat["id"]):
            return false
    return true

func advance_day() -> void:
    var finished_day = current_day
    current_day += 1
    _completed_beats = []
    _todays_beats = ARC_BEATS.get(current_day, []).duplicate(true)
    day_ended.emit(finished_day)
```

**Step 4: Register DayManager as autoload**

Project → Project Settings → Autoload → add `scripts/autoload/day_manager.gd` as `DayManager`.

**Step 5: Run tests**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_day_manager.gd
```

Expected: all green.

**Step 6: Commit**

```bash
git add scripts/autoload/day_manager.gd tests/test_day_manager.gd
git commit -m "feat: add DayManager with 7-day arc beat definitions"
```

---

## Task 4: DialogueManager Autoload

**Files:**
- Create: `scripts/autoload/dialogue_manager.gd`
- Create: `tests/test_dialogue_manager.gd`

DialogueManager drives all NPC conversations. Dialogue is defined as a tree of nodes (plain GDScript dicts). Each node has text, speaker, choices (with emotional tags). If a choice matches the player's background inner voice, it gets flagged as an inner voice option. Completing a beat node fires `story_beat_triggered`.

**Step 1: Write the failing tests**

```gdscript
# tests/test_dialogue_manager.gd
extends GutTest

# Minimal test tree
const TEST_TREE = {
    "start": {
        "speaker": "Maris",
        "text": "Hey, you must be new.",
        "choices": [
            { "text": "Just arrived.", "register": "detached", "next": "end" },
            { "text": "Yeah, glad to be here.", "register": "hopeful", "next": "end" },
        ]
    },
    "end": {
        "speaker": "Maris",
        "text": "Well, welcome.",
        "choices": []
    }
}

const BEAT_TREE = {
    "start": {
        "speaker": "Maris",
        "text": "I need to tell you something.",
        "beat": "maris_confided",
        "choices": [
            { "text": "I'm listening.", "register": "warm", "next": "end" }
        ]
    },
    "end": {
        "speaker": "Maris",
        "text": "Thanks.",
        "choices": []
    }
}

func before_each():
    GameState.reset()
    DayManager.reset()
    DialogueManager.reset()

func test_start_conversation_sets_current_node():
    DialogueManager.start_conversation(TEST_TREE)
    assert_eq(DialogueManager.get_current_node()["speaker"], "Maris")

func test_make_choice_advances_node():
    DialogueManager.start_conversation(TEST_TREE)
    DialogueManager.make_choice(0)
    assert_eq(DialogueManager.get_current_node()["text"], "Well, welcome.")

func test_conversation_ends_on_empty_choices():
    DialogueManager.start_conversation(TEST_TREE)
    DialogueManager.make_choice(0)
    assert_true(DialogueManager.is_conversation_over())

func test_inner_voice_flagged_for_matching_background():
    GameState.set_player_identity("Test", "medic", 0)
    DialogueManager.start_conversation(TEST_TREE)
    var node = DialogueManager.get_current_node()
    # "warm" and "hopeful" are Heart registers for medic
    var flags = DialogueManager.get_inner_voice_flags()
    # hopeful maps to medic inner voice
    assert_true(flags.has(1))  # index 1 is "hopeful"

func test_beat_completion_fires_on_beat_node():
    DayManager._override_beats_for_test([
        { "id": "maris_confided", "required": true, "npc": "maris", "flag_to_set": "maris_confided" }
    ])
    var beat_fired = false
    DialogueManager.story_beat_triggered.connect(func(id): beat_fired = true)
    DialogueManager.start_conversation(BEAT_TREE)
    DialogueManager.make_choice(0)
    assert_true(beat_fired)

func test_register_history_recorded():
    DialogueManager.start_conversation(TEST_TREE)
    DialogueManager.make_choice(1)  # hopeful
    assert_true(DialogueManager.register_history.has("hopeful"))
```

**Step 2: Run tests to verify they fail**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_dialogue_manager.gd
```

**Step 3: Implement DialogueManager**

```gdscript
# scripts/autoload/dialogue_manager.gd
extends Node

signal story_beat_triggered(beat_id: String)
signal conversation_ended()

# Inner voice registers per background
const INNER_VOICE_REGISTERS = {
    "engineer": ["logical", "curious", "sharp"],
    "medic": ["warm", "hopeful", "empathetic"],
    "drifter": ["detached", "cynical", "instinct"]
}

var register_history: Dictionary = {}  # { register: count }
var _current_tree: Dictionary = {}
var _current_node_id: String = ""

func reset() -> void:
    register_history = {}
    _current_tree = {}
    _current_node_id = ""

func _ready() -> void:
    reset()

func start_conversation(tree: Dictionary) -> void:
    _current_tree = tree
    _current_node_id = "start"
    _check_for_beat()

func get_current_node() -> Dictionary:
    return _current_tree.get(_current_node_id, {})

func is_conversation_over() -> bool:
    var node = get_current_node()
    return node.is_empty() or node.get("choices", []).is_empty()

func make_choice(choice_index: int) -> void:
    var node = get_current_node()
    var choices = node.get("choices", [])
    if choice_index >= choices.size():
        return
    var choice = choices[choice_index]
    var register = choice.get("register", "")
    if register != "":
        register_history[register] = register_history.get(register, 0) + 1
    _current_node_id = choice.get("next", "")
    if _current_node_id == "":
        conversation_ended.emit()
        return
    _check_for_beat()
    if is_conversation_over():
        conversation_ended.emit()

func _check_for_beat() -> void:
    var node = get_current_node()
    var beat_id = node.get("beat", "")
    if beat_id != "":
        DayManager.complete_beat(beat_id)
        story_beat_triggered.emit(beat_id)

# Returns a Set (Dictionary used as set) of choice indices that match
# the player's background inner voice registers.
func get_inner_voice_flags() -> Dictionary:
    var result = {}
    var bg = GameState.player_background
    var voice_registers = INNER_VOICE_REGISTERS.get(bg, [])
    var node = get_current_node()
    var choices = node.get("choices", [])
    for i in range(choices.size()):
        if voice_registers.has(choices[i].get("register", "")):
            result[i] = true
    return result
```

**Step 4: Register DialogueManager as autoload**

Project → Project Settings → Autoload → add `scripts/autoload/dialogue_manager.gd` as `DialogueManager`.

**Step 5: Run tests**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_dialogue_manager.gd
```

Expected: all green.

**Step 6: Commit**

```bash
git add scripts/autoload/dialogue_manager.gd tests/test_dialogue_manager.gd
git commit -m "feat: add DialogueManager with emotional registers and inner voice flagging"
```

---

## Task 5: CraftingSystem (Extended)

**Files:**
- Create: `scripts/autoload/crafting_system.gd`
- Create: `tests/test_crafting_system.gd`

Identical to the original plan, but recipes now include a `requires_resource_type` field for Derelict-only materials (`scrap`). GameState already tracks `scrap` as a resource.

**Step 1: Write the failing tests**

```gdscript
# tests/test_crafting_system.gd
extends GutTest

func before_each():
    GameState.reset()

func test_can_craft_when_resources_sufficient():
    GameState.add_resource("rations", 2)
    assert_true(CraftingSystem.can_craft("hot_meal"))

func test_cannot_craft_when_insufficient():
    assert_false(CraftingSystem.can_craft("hot_meal"))

func test_craft_consumes_resources():
    GameState.add_resource("rations", 2)
    CraftingSystem.craft("hot_meal")
    assert_eq(GameState.get_resource("rations"), 0)

func test_craft_returns_false_if_cannot_afford():
    assert_false(CraftingSystem.craft("hot_meal"))

func test_workshop_recipe_locked_by_default():
    assert_false(CraftingSystem.is_recipe_available("power_relay"))

func test_workshop_recipe_available_after_unlock():
    GameState.set_flag("workshop_unlocked", true)
    assert_true(CraftingSystem.is_recipe_available("power_relay"))

func test_derelict_recipe_requires_scrap():
    GameState.add_resource("scrap", 2)
    GameState.add_resource("parts", 1)
    assert_true(CraftingSystem.can_craft("jury_rig"))

func test_derelict_recipe_unavailable_without_scrap():
    GameState.add_resource("parts", 1)
    assert_false(CraftingSystem.can_craft("jury_rig"))
```

**Step 2: Run to verify failure**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_crafting_system.gd
```

**Step 3: Implement CraftingSystem**

```gdscript
# scripts/autoload/crafting_system.gd
extends Node

signal item_crafted(item_id: String)

const RECIPES: Dictionary = {
    "hot_meal": {
        "inputs": [{ "id": "rations", "qty": 2 }],
        "requires_flag": ""
    },
    "decent_drink": {
        "inputs": [{ "id": "rations", "qty": 1 }, { "id": "energy_cells", "qty": 1 }],
        "requires_flag": ""
    },
    "patch_kit": {
        "inputs": [{ "id": "parts", "qty": 2 }],
        "requires_flag": ""
    },
    "power_relay": {
        "inputs": [{ "id": "parts", "qty": 1 }, { "id": "energy_cells", "qty": 2 }],
        "requires_flag": "workshop_unlocked"
    },
    "station_light": {
        "inputs": [{ "id": "parts", "qty": 1 }, { "id": "rations", "qty": 1 }],
        "requires_flag": ""
    },
    "jury_rig": {
        "inputs": [{ "id": "scrap", "qty": 2 }, { "id": "parts", "qty": 1 }],
        "requires_flag": ""
    }
}

func get_all_recipes() -> Dictionary:
    return RECIPES

func is_recipe_available(recipe_id: String) -> bool:
    if not RECIPES.has(recipe_id):
        return false
    var flag = RECIPES[recipe_id]["requires_flag"]
    if flag != "":
        return GameState.get_flag(flag)
    return true

func can_craft(recipe_id: String) -> bool:
    if not is_recipe_available(recipe_id):
        return false
    for input in RECIPES[recipe_id]["inputs"]:
        if GameState.get_resource(input["id"]) < input["qty"]:
            return false
    return true

func craft(recipe_id: String) -> bool:
    if not can_craft(recipe_id):
        return false
    for input in RECIPES[recipe_id]["inputs"]:
        GameState.spend_resource(input["id"], input["qty"])
    item_crafted.emit(recipe_id)
    return true
```

**Step 4: Register as autoload, run tests, confirm green**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_crafting_system.gd
```

**Step 5: Commit**

```bash
git add scripts/autoload/crafting_system.gd tests/test_crafting_system.gd
git commit -m "feat: add CraftingSystem with Derelict scrap recipes"
```

---

## Task 6: PlayerCharacter Scene & Movement

**Files:**
- Create: `scenes/characters/player.tscn`
- Create: `scripts/characters/player.gd`

The player is a top-down sprite with 8-directional movement (CharacterBody2D). An Area2D child (InteractionZone) detects nearby interactables. Pressing the interact key (E) triggers the nearest interactable.

**Step 1: Create the scene in Godot**

New Scene → root node `CharacterBody2D`, rename to `Player`.
Add children:
- `Sprite2D` (placeholder: blue colored rect, 16×16)
- `CollisionShape2D` (RectangleShape2D, 12×12)
- `Area2D` named `InteractionZone`
  - `CollisionShape2D` (CircleShape2D, radius 24)

Save as `scenes/characters/player.tscn`.
Attach `scripts/characters/player.gd`.

**Step 2: Write the player script**

```gdscript
# scripts/characters/player.gd
extends CharacterBody2D

const SPEED = 80.0

@onready var interaction_zone: Area2D = $InteractionZone

func _physics_process(_delta: float) -> void:
    var direction = Vector2(
        Input.get_axis("ui_left", "ui_right"),
        Input.get_axis("ui_up", "ui_down")
    ).normalized()
    velocity = direction * SPEED
    move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        _try_interact()

func _try_interact() -> void:
    var bodies = interaction_zone.get_overlapping_bodies()
    var areas = interaction_zone.get_overlapping_areas()
    # Prefer NPCs, then resource nodes
    for area in areas:
        if area.is_in_group("interactable"):
            area.interact()
            return
    for body in bodies:
        if body.is_in_group("interactable"):
            body.interact()
            return
```

**Step 3: Add "interact" input action**

Project → Project Settings → Input Map → add action `interact`, assign key `E`.

**Step 4: Manual test**

Create a temporary test scene. Place Player. Run. Verify WASD/arrows move the character and collisions work.

**Step 5: Commit**

```bash
git add scenes/characters/player.tscn scripts/characters/player.gd
git commit -m "feat: add top-down PlayerCharacter with movement and interaction zone"
```

---

## Task 7: NPC Base Scene & Wander Behavior

**Files:**
- Create: `scenes/characters/npc_base.tscn`
- Create: `scripts/characters/npc_base.gd`

NPCs wander within a defined rectangular bounds. When the player interacts, the NPC stops wandering and a conversation begins via DialogueManager.

**Step 1: Create the scene**

New Scene → root `CharacterBody2D`, rename `NPC`.
Children:
- `Sprite2D` (placeholder colored rect, 16×16 — different color per NPC)
- `CollisionShape2D` (RectangleShape2D)
- `Area2D` named `InteractionArea` (in group `interactable`)
  - `CollisionShape2D` (CircleShape2D, radius 20)
- `Timer` named `WanderTimer`

Save as `scenes/characters/npc_base.tscn`.
Attach `scripts/characters/npc_base.gd`.

**Step 2: Write NPC base script**

```gdscript
# scripts/characters/npc_base.gd
extends CharacterBody2D

@export var npc_id: String = "unknown"
@export var display_name: String = "NPC"
@export var wander_bounds: Rect2 = Rect2(-50, -50, 100, 100)  # Local space

const WANDER_SPEED = 30.0

@onready var wander_timer: Timer = $WanderTimer
@onready var interaction_area: Area2D = $InteractionArea

var _wander_target: Vector2 = Vector2.ZERO
var _is_talking: bool = false

func _ready() -> void:
    add_to_group("npcs")
    interaction_area.add_to_group("interactable")
    interaction_area.interact = interact  # Expose interact to player
    wander_timer.timeout.connect(_pick_wander_target)
    wander_timer.wait_time = randf_range(2.0, 5.0)
    wander_timer.start()
    _pick_wander_target()

func _physics_process(_delta: float) -> void:
    if _is_talking:
        velocity = Vector2.ZERO
        move_and_slide()
        return
    var diff = _wander_target - position
    if diff.length() > 4.0:
        velocity = diff.normalized() * WANDER_SPEED
    else:
        velocity = Vector2.ZERO
    move_and_slide()

func _pick_wander_target() -> void:
    var origin = get_parent().position if get_parent() else Vector2.ZERO
    _wander_target = Vector2(
        randf_range(wander_bounds.position.x, wander_bounds.end.x),
        randf_range(wander_bounds.position.y, wander_bounds.end.y)
    ) + origin
    wander_timer.wait_time = randf_range(2.0, 5.0)
    wander_timer.start()

func interact() -> void:
    _is_talking = true
    var tree = get_dialogue_tree()
    DialogueManager.conversation_ended.connect(_on_conversation_ended, CONNECT_ONE_SHOT)
    DialogueManager.start_conversation(tree)

func _on_conversation_ended() -> void:
    _is_talking = false

func get_dialogue_tree() -> Dictionary:
    return {
        "start": {
            "speaker": display_name,
            "text": "...",
            "choices": []
        }
    }
```

**Step 3: Manual test**

Place an NPC in a test scene. Verify it wanders. Walk the player into range, press E, verify DialogueManager.start_conversation is called (print statement is fine).

**Step 4: Commit**

```bash
git add scenes/characters/npc_base.tscn scripts/characters/npc_base.gd
git commit -m "feat: add NPC base scene with wander behavior and interaction"
```

---

## Task 8: Area Scenes

**Files:**
- Create: `scenes/areas/cantina.tscn` + `scripts/areas/cantina.gd`
- Create: `scenes/areas/engineering.tscn` + `scripts/areas/engineering.gd`
- Create: `scenes/areas/quarters.tscn` + `scripts/areas/quarters.gd`
- Create: `scenes/resource_node.tscn` + `scripts/resource_node.gd`

Each area is a walkable Node2D with collision walls, resource nodes, door triggers, and NPC spawn points. Door triggers (Area2D) call `SceneManager.go_to_area(area_id)` — a helper on Main.

**Step 1: Create ResourceNode scene**

New Scene → root `Area2D`, rename `ResourceNode`. Add to group `interactable`.
Children:
- `Sprite2D` (colored rect — green for rations, grey for parts, yellow for energy)
- `CollisionShape2D` (RectangleShape2D)
- `Timer`

Attach `scripts/resource_node.gd`:

```gdscript
# scripts/resource_node.gd
extends Area2D

@export var resource_id: String = "rations"
@export var amount: int = 1
@export var cooldown: float = 8.0

@onready var timer: Timer = $Timer

var _ready_to_collect: bool = true

func _ready() -> void:
    add_to_group("interactable")
    timer.wait_time = cooldown
    timer.one_shot = true
    timer.timeout.connect(func(): _ready_to_collect = true; modulate = Color.WHITE)

func interact() -> void:
    if not _ready_to_collect:
        return
    _ready_to_collect = false
    GameState.add_resource(resource_id, amount)
    modulate = Color(0.5, 0.5, 0.5)
    timer.start()
```

**Step 2: Create Cantina scene**

New Scene → root `Node2D`, rename `Cantina`.
Add:
- `TileMapLayer` or `StaticBody2D` with `CollisionPolygon2D` for walls (simple rectangle room for MVP)
- `Sprite2D` background (plain colored rect, dark blue)
- 1× ResourceNode (`resource_id = "rations"`)
- NPC spawn markers (Node2D named `MarisSpawn`, `SableSpawn`)
- `Area2D` named `EngineeringDoor` (collision near right wall edge)

`scripts/areas/cantina.gd`:

```gdscript
# scripts/areas/cantina.gd
extends Node2D

@onready var engineering_door: Area2D = $EngineeringDoor

func _ready() -> void:
    engineering_door.body_entered.connect(func(body):
        if body.is_in_group("player"):
            get_tree().get_root().get_node("Main").go_to_area("engineering")
    )
```

Save as `scenes/areas/cantina.tscn`.

**Step 3: Create Engineering scene**

Same structure. Add:
- 1× ResourceNode (`resource_id = "parts"`)
- 1× ResourceNode (`resource_id = "energy_cells"`)
- `StaticBody2D` named `Workbench` (group `interactable`) — interact opens crafting panel
- NPC spawn marker (`DexSpawn`)
- `Area2D` doors: `CantinaDoor`, `QuartersDoor`

`scripts/areas/engineering.gd`:

```gdscript
# scripts/areas/engineering.gd
extends Node2D

@onready var cantina_door: Area2D = $CantinaDoor
@onready var quarters_door: Area2D = $QuartersDoor
@onready var workbench: StaticBody2D = $Workbench

func _ready() -> void:
    workbench.add_to_group("interactable")
    workbench.set_meta("interact_fn", func(): get_tree().get_root().get_node("Main").open_crafting())

    cantina_door.body_entered.connect(func(body):
        if body.is_in_group("player"):
            get_tree().get_root().get_node("Main").go_to_area("cantina")
    )
    quarters_door.body_entered.connect(func(body):
        if body.is_in_group("player"):
            get_tree().get_root().get_node("Main").go_to_area("quarters")
    )
```

**Step 4: Create Quarters scene**

Add:
- `StaticBody2D` named `PlayerBunk` (group `interactable`) — interact triggers sleep/day advance if `DayManager.is_day_complete()`
- Door back to Engineering

`scripts/areas/quarters.gd`:

```gdscript
# scripts/areas/quarters.gd
extends Node2D

@onready var bunk: StaticBody2D = $PlayerBunk
@onready var engineering_door: Area2D = $EngineeringDoor

func _ready() -> void:
    bunk.add_to_group("interactable")

    engineering_door.body_entered.connect(func(body):
        if body.is_in_group("player"):
            get_tree().get_root().get_node("Main").go_to_area("engineering")
    )

func interact_bunk() -> void:
    var main = get_tree().get_root().get_node("Main")
    if DayManager.is_day_complete():
        main.advance_day()
    else:
        main.show_hud_message("You're not ready to rest yet.")
```

**Step 5: Manual test**

Place Player in Cantina scene. Walk to door trigger. Verify door area fires. (Full navigation tested in Task 17.)

**Step 6: Commit**

```bash
git add scenes/areas/ scripts/areas/ scenes/resource_node.tscn scripts/resource_node.gd
git commit -m "feat: add area scenes (Cantina, Engineering, Quarters) with doors and resource nodes"
```

---

## Task 9: Character Creation UI

**Files:**
- Create: `scenes/character_creation.tscn`
- Create: `scripts/ui/character_creation.gd`

The first scene the player sees. Sets `GameState` player identity, then loads `scenes/main.tscn`.

**Step 1: Create the scene**

New Scene → root `Control` (full-screen), rename `CharacterCreation`.
Layout:
- `VBoxContainer` centered:
  - `Label` ("Outpost Nova")
  - `LineEdit` named `NameInput` (placeholder "Your name...")
  - `HBoxContainer` named `AppearancePicker` (3 `TextureButton`s or colored `Button`s)
  - `VBoxContainer` named `BackgroundPicker`:
    - 3 `Button`s: "Engineer (starts with Parts)", "Medic (starts with Rations)", "Drifter (starts with Energy Cells)"
  - `Button` named `StartBtn` ("Begin")

Save as `scenes/character_creation.tscn`.
Set as project main scene: Project Settings → Application → Run → Main Scene.

**Step 2: Write the script**

```gdscript
# scripts/ui/character_creation.gd
extends Control

@onready var name_input: LineEdit = $VBoxContainer/NameInput
@onready var start_btn: Button = $VBoxContainer/StartBtn
@onready var appearance_picker: HBoxContainer = $VBoxContainer/AppearancePicker
@onready var background_picker: VBoxContainer = $VBoxContainer/BackgroundPicker

const BACKGROUNDS = ["engineer", "medic", "drifter"]

var _selected_appearance: int = 0
var _selected_background: String = "drifter"

func _ready() -> void:
    start_btn.pressed.connect(_on_start)
    for i in appearance_picker.get_child_count():
        var btn = appearance_picker.get_child(i)
        btn.pressed.connect(func(): _selected_appearance = i)
    for i in background_picker.get_child_count():
        var btn = background_picker.get_child(i)
        btn.pressed.connect(func(): _selected_background = BACKGROUNDS[i])

func _on_start() -> void:
    var name_val = name_input.text.strip_edges()
    if name_val == "":
        name_val = "Crew"
    GameState.set_player_identity(name_val, _selected_background, _selected_appearance)
    GameState.apply_background_bonus(_selected_background)
    get_tree().change_scene_to_file("res://scenes/main.tscn")
```

**Step 3: Manual test**

Run the project. Fill in the form. Click Begin. Verify `GameState.player_name` and `player_background` are set (print in main.gd `_ready`). Verify starting resources match the background.

**Step 4: Commit**

```bash
git add scenes/character_creation.tscn scripts/ui/character_creation.gd
git commit -m "feat: add character creation UI with name, appearance, and background selection"
```

---

## Task 10: DialogueBox UI

**Files:**
- Create: `scenes/ui/dialogue_box.tscn`
- Create: `scripts/ui/dialogue_box.gd`

DialogueBox reads from `DialogueManager`. Displays the current node's text and renders choice buttons. Inner voice choices get a distinct style (italic label prefix + different color). Story beat choices show a subtle indicator.

**Step 1: Create the scene**

New Scene → root `CanvasLayer`, add:
- `PanelContainer` (anchored bottom, full width, ~200px tall)
  - `VBoxContainer`
    - `Label` named `SpeakerLabel`
    - `RichTextLabel` named `DialogueText`
    - `VBoxContainer` named `ChoicesContainer`

Save as `scenes/ui/dialogue_box.tscn`.

**Step 2: Write the script**

```gdscript
# scripts/ui/dialogue_box.gd
extends CanvasLayer

@onready var speaker_label: Label = $PanelContainer/VBoxContainer/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $PanelContainer/VBoxContainer/DialogueText
@onready var choices_container: VBoxContainer = $PanelContainer/VBoxContainer/ChoicesContainer

func _ready() -> void:
    hide()
    DialogueManager.conversation_ended.connect(hide)
    # When a conversation starts, show the current node
    # The NPC calls DialogueManager.start_conversation — we listen for state changes
    # by polling is_conversation_over or via a signal from Main

func show_current_node() -> void:
    var node = DialogueManager.get_current_node()
    if node.is_empty():
        hide()
        return
    speaker_label.text = node.get("speaker", "")
    dialogue_text.text = node.get("text", "")
    _build_choices(node.get("choices", []))
    show()

func _build_choices(choices: Array) -> void:
    for child in choices_container.get_children():
        child.queue_free()

    if choices.is_empty():
        # Auto-advance after a short pause or on click
        var btn = Button.new()
        btn.text = "..."
        btn.pressed.connect(func():
            DialogueManager.make_choice(0) if false else hide()
        )
        choices_container.add_child(btn)
        return

    var inner_voice_flags = DialogueManager.get_inner_voice_flags()

    for i in range(choices.size()):
        var choice = choices[i]
        var btn = Button.new()
        var label = choice.get("text", "")
        var register = choice.get("register", "")

        if inner_voice_flags.has(i):
            btn.text = "[%s] %s" % [GameState.player_background.capitalize(), label]
            btn.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
        else:
            btn.text = label

        btn.pressed.connect(func(): _on_choice(i))
        choices_container.add_child(btn)

func _on_choice(index: int) -> void:
    DialogueManager.make_choice(index)
    if not DialogueManager.is_conversation_over():
        show_current_node()
```

**Step 3: Wire to NPC interaction**

In `npc_base.gd`, after `DialogueManager.start_conversation(tree)`, get the dialogue box and call `show_current_node()`:

```gdscript
func interact() -> void:
    _is_talking = true
    var tree = get_dialogue_tree()
    DialogueManager.conversation_ended.connect(_on_conversation_ended, CONNECT_ONE_SHOT)
    DialogueManager.start_conversation(tree)
    get_tree().get_root().get_node("Main/DialogueBox").show_current_node()
```

**Step 4: Manual test**

Walk up to an NPC, press E. Verify dialogue box appears with speaker name, text, and choice buttons. Make a choice. Verify it advances. Verify box hides when conversation ends.

**Step 5: Commit**

```bash
git add scenes/ui/dialogue_box.tscn scripts/ui/dialogue_box.gd
git commit -m "feat: add DialogueBox UI with inner voice highlighting"
```

---

## Task 11: Character Dialogue Scripts (Maris, Dex, Sable)

**Files:**
- Create: `scripts/characters/maris.gd`
- Create: `scripts/characters/dex.gd`
- Create: `scripts/characters/sable.gd`

Each extends `npc_base.gd` and overrides `get_dialogue_tree()`. Dialogue trees are plain GDScript dicts. Each character has 3 states: before meeting, after meeting, post-arc event. Story beat nodes are embedded where appropriate.

**Step 1: Write Maris**

```gdscript
# scripts/characters/maris.gd
extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
    super()
    npc_id = "maris"
    display_name = "Maris"

func get_dialogue_tree() -> Dictionary:
    if not GameState.get_flag("met_maris"):
        return _tree_first_meeting()
    elif GameState.get_flag("maris_confided") and not GameState.get_flag("maris_favour_done"):
        return _tree_favour_pending()
    elif GameState.get_flag("maris_favour_done"):
        return _tree_post_favour()
    else:
        return _tree_casual()

func _tree_first_meeting() -> Dictionary:
    return {
        "start": {
            "speaker": "Maris",
            "text": "Oh — you're the new one. I'm Maris. I run the food printer, for what that's worth.",
            "beat": "meet_maris",
            "choices": [
                { "text": "Nice to meet you. I'm %s." % GameState.player_name, "register": "warm", "next": "warm_reply" },
                { "text": "What's wrong with the food printer?", "register": "curious", "next": "printer_reply" },
                { "text": "Right.", "register": "detached", "next": "detached_reply" },
            ]
        },
        "warm_reply": {
            "speaker": "Maris",
            "text": "Well. It's nice to have someone introduce themselves properly for once.",
            "choices": []
        },
        "printer_reply": {
            "speaker": "Maris",
            "text": "Nothing you'd want to know about. Eat the output, don't ask questions.",
            "choices": []
        },
        "detached_reply": {
            "speaker": "Maris",
            "text": "Sure. The food's over there when you want it.",
            "choices": []
        }
    }

func _tree_casual() -> Dictionary:
    return {
        "start": {
            "speaker": "Maris",
            "text": "The printer's running. That's about as good as it gets today.",
            "choices": [
                { "text": "How are you holding up?", "register": "warm", "next": "holding_up" },
                { "text": "Good to know.", "register": "detached", "next": "end" },
            ]
        },
        "holding_up": {
            "speaker": "Maris",
            "text": "Honestly? I've had better weeks. But I'm here.",
            "choices": []
        },
        "end": {
            "speaker": "Maris",
            "text": "Yeah.",
            "choices": []
        }
    }

func _tree_favour_pending() -> Dictionary:
    return {
        "start": {
            "speaker": "Maris",
            "text": "Hey — did you get a chance to look at what I asked? The ration stores are lower than I reported.",
            "beat": "maris_asks_favour",
            "choices": [
                { "text": "I'll handle it.", "register": "hopeful", "next": "handle_it" },
                { "text": "Why didn't you tell the others?", "register": "curious", "next": "why_not_tell" },
                { "text": "That's not really my problem.", "register": "cynical", "next": "not_my_problem" },
            ]
        },
        "handle_it": {
            "speaker": "Maris",
            "text": "Thank you. I mean it.",
            "choices": []
        },
        "why_not_tell": {
            "speaker": "Maris",
            "text": "Because Dex would spiral and Sable would leave. I need someone who can be calm about it.",
            "choices": []
        },
        "not_my_problem": {
            "speaker": "Maris",
            "text": "...Right. Sorry to bother you.",
            "choices": []
        }
    }

func _tree_post_favour() -> Dictionary:
    return {
        "start": {
            "speaker": "Maris",
            "text": "You came through. I won't forget that.",
            "choices": [
                { "text": "Anyone would have done the same.", "register": "warm", "next": "end" },
                { "text": "Don't mention it.", "register": "detached", "next": "end" },
            ]
        },
        "end": {
            "speaker": "Maris",
            "text": "Still. It matters.",
            "choices": []
        }
    }
```

**Step 2: Write Dex**

```gdscript
# scripts/characters/dex.gd
extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
    super()
    npc_id = "dex"
    display_name = "Dex"

func get_dialogue_tree() -> Dictionary:
    if not GameState.get_flag("met_dex"):
        return _tree_first_meeting()
    elif GameState.get_flag("power_flicker_noticed") and not GameState.get_flag("dex_secret_known"):
        return _tree_power_concern()
    elif GameState.get_flag("dex_secret_known"):
        return _tree_post_secret()
    else:
        return _tree_casual()

func _tree_first_meeting() -> Dictionary:
    return {
        "start": {
            "speaker": "Dex",
            "text": "You're the new one. Dex. I keep the lights on — literally. Don't touch anything in Engineering without asking.",
            "beat": "check_engineering",
            "choices": [
                { "text": "Understood. What should I know?", "register": "curious", "next": "what_to_know" },
                { "text": "Fair enough.", "register": "detached", "next": "fair_enough" },
                { "text": "I'll try not to break anything.", "register": "sharp", "next": "sharp_reply" },
            ]
        },
        "what_to_know": {
            "speaker": "Dex",
            "text": "Power's stable. For now. The lower decks draw from the same grid. Whatever's down there — it's pulling more than it should.",
            "choices": []
        },
        "fair_enough": {
            "speaker": "Dex",
            "text": "Good. We understand each other.",
            "choices": []
        },
        "sharp_reply": {
            "speaker": "Dex",
            "text": "See that you don't. This station runs on experience, not good intentions.",
            "choices": []
        }
    }

func _tree_casual() -> Dictionary:
    return {
        "start": {
            "speaker": "Dex",
            "text": "Systems are nominal. Don't quote me on that.",
            "choices": [
                { "text": "The lower decks — you ever been down there?", "register": "curious", "next": "lower_decks" },
                { "text": "Good to hear.", "register": "hopeful", "next": "end" },
            ]
        },
        "lower_decks": {
            "speaker": "Dex",
            "text": "Once. Before the seal. I don't talk about it.",
            "choices": []
        },
        "end": {
            "speaker": "Dex",
            "text": "Keep it that way.",
            "choices": []
        }
    }

func _tree_power_concern() -> Dictionary:
    return {
        "start": {
            "speaker": "Dex",
            "text": "The flicker last night — that wasn't random. Something in the lower decks is drawing power on a cycle. It's been doing it for months.",
            "beat": "power_flicker",
            "choices": [
                { "text": "We should open the door and find out.", "register": "instinct", "next": "open_door" },
                { "text": "What's the risk if we leave it?", "register": "logical", "next": "risk_if_left" },
                { "text": "Why didn't you report this?", "register": "sharp", "next": "why_not_report" },
            ]
        },
        "open_door": {
            "speaker": "Dex",
            "text": "...Yeah. I think so too. I'll start the unlock sequence. It'll take until tomorrow.",
            "choices": []
        },
        "risk_if_left": {
            "speaker": "Dex",
            "text": "Grid failure in 2-3 weeks, best case. We'd lose life support.",
            "choices": []
        },
        "why_not_report": {
            "speaker": "Dex",
            "text": "Because I knew whoever was down there sealed that door for a reason.",
            "choices": []
        }
    }

func _tree_post_secret() -> Dictionary:
    return {
        "start": {
            "speaker": "Dex",
            "text": "Now you know. I'm sorry I didn't tell you sooner.",
            "choices": [
                { "text": "What do we do now?", "register": "hopeful", "next": "what_now" },
                { "text": "We deal with what's in front of us.", "register": "logical", "next": "deal_with_it" },
            ]
        },
        "what_now": {
            "speaker": "Dex",
            "text": "We fix it. Or we don't. But at least we know.",
            "choices": []
        },
        "deal_with_it": {
            "speaker": "Dex",
            "text": "Yeah. That's all we can do.",
            "choices": []
        }
    }
```

**Step 3: Write Sable**

```gdscript
# scripts/characters/sable.gd
extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
    super()
    npc_id = "sable"
    display_name = "Sable"

func get_dialogue_tree() -> Dictionary:
    if not GameState.get_flag("met_sable"):
        return _tree_first_meeting()
    elif GameState.get_flag("sable_past_revealed"):
        return _tree_post_revelation()
    elif GameState.get_flag("met_sable"):
        return _tree_guarded()

    return _tree_guarded()

func _tree_first_meeting() -> Dictionary:
    return {
        "start": {
            "speaker": "Sable",
            "text": "You're new. I'm Sable. I'm just passing through.",
            "beat": "sable_arrives",
            "choices": [
                { "text": "Where are you headed?", "register": "curious", "next": "where_headed" },
                { "text": "We're glad you're here.", "register": "warm", "next": "glad_here" },
                { "text": "Same.", "register": "detached", "next": "end" },
            ]
        },
        "where_headed": {
            "speaker": "Sable",
            "text": "Somewhere that isn't here. No offence.",
            "choices": []
        },
        "glad_here": {
            "speaker": "Sable",
            "text": "Don't be. I might be gone by morning.",
            "choices": []
        },
        "end": {
            "speaker": "Sable",
            "text": "Right.",
            "choices": []
        }
    }

func _tree_guarded() -> Dictionary:
    return {
        "start": {
            "speaker": "Sable",
            "text": "Still here, apparently.",
            "choices": [
                { "text": "What's keeping you?", "register": "curious", "next": "keeping_here" },
                { "text": "Glad you stayed.", "register": "warm", "next": "glad_stayed" },
                { "text": "Hm.", "register": "detached", "next": "end" },
            ]
        },
        "keeping_here": {
            "speaker": "Sable",
            "text": "Honestly? I don't know. Something about this place feels unfinished.",
            "choices": []
        },
        "glad_stayed": {
            "speaker": "Sable",
            "text": "Don't read into it.",
            "choices": []
        },
        "end": {
            "speaker": "Sable",
            "text": "...",
            "choices": []
        }
    }

func _tree_post_revelation() -> Dictionary:
    return {
        "start": {
            "speaker": "Sable",
            "text": "I didn't think I'd tell anyone that. About the lower decks. About what I saw before the seal.",
            "choices": [
                { "text": "You can trust us.", "register": "warm", "next": "trust_us" },
                { "text": "What exactly did you see?", "register": "curious", "next": "what_saw" },
            ]
        },
        "trust_us": {
            "speaker": "Sable",
            "text": "Maybe. I'm still deciding.",
            "choices": []
        },
        "what_saw": {
            "speaker": "Sable",
            "text": "Something that was still alive. And it recognised me.",
            "choices": []
        }
    }
```

**Step 4: Attach scripts to NPC instances**

In Cantina scene: instance `npc_base.tscn` twice, attach `maris.gd` and `sable.gd`.
In Engineering scene: instance once, attach `dex.gd`.
Set `wander_bounds` export to fit each room.

**Step 5: Manual test**

Run the game past character creation. Walk to Maris. Press E. Verify dialogue tree loads, inner voice choice appears for your background, story beat fires on beat node. Check `DayManager.is_beat_complete("meet_maris")`.

**Step 6: Commit**

```bash
git add scripts/characters/maris.gd scripts/characters/dex.gd scripts/characters/sable.gd
git commit -m "feat: add flag-driven dialogue trees for Maris, Dex, and Sable"
```

---

## Task 12: Derelict Run (Room Generator + Basic Combat)

**Files:**
- Create: `scenes/derelict/run.tscn` + `scripts/derelict/run.gd`
- Create: `scripts/derelict/room_generator.gd`
- Create: `scenes/derelict/rooms/room_a.tscn` (template)
- Create: `scenes/derelict/rooms/room_b.tscn` (template)
- Create: `scenes/derelict/rooms/room_exit.tscn`

The Derelict Run is entered from the Derelict Entrance area. It generates a sequence of rooms. Player navigates room to room. Reaching the exit door of each room loads the next. Reaching `room_exit` returns to the station with gathered loot.

**Step 1: Create room templates**

Each room template is a `Node2D` with:
- Background `Sprite2D` (dark corridor aesthetic — placeholder black rect)
- Wall `StaticBody2D` collision
- Enemy spawn points (`Marker2D` named `EnemySpawn1`, etc.)
- Loot spawn point (`Marker2D` named `LootSpawn`)
- `Area2D` named `ExitDoor` (right wall)

Create two hand-crafted variants (`room_a.tscn`, `room_b.tscn`) that differ only in layout.

**Step 2: Write RoomGenerator**

```gdscript
# scripts/derelict/room_generator.gd
extends Node

const ROOM_POOL = [
    "res://scenes/derelict/rooms/room_a.tscn",
    "res://scenes/derelict/rooms/room_b.tscn",
]
const EXIT_ROOM = "res://scenes/derelict/rooms/room_exit.tscn"
const ROOMS_PER_RUN = 4

func generate_sequence() -> Array:
    var sequence = []
    for i in range(ROOMS_PER_RUN - 1):
        sequence.append(ROOM_POOL[randi() % ROOM_POOL.size()])
    sequence.append(EXIT_ROOM)
    return sequence
```

**Step 3: Write Run script**

```gdscript
# scripts/derelict/run.gd
extends Node2D

var _room_sequence: Array = []
var _current_room_index: int = 0
var _current_room: Node = null
var _gathered_loot: Dictionary = {}

@onready var player: CharacterBody2D = $Player

func _ready() -> void:
    _room_sequence = RoomGenerator.generate_sequence()
    _load_room(0)

func _load_room(index: int) -> void:
    if _current_room:
        _current_room.queue_free()
    var scene = load(_room_sequence[index])
    _current_room = scene.instantiate()
    add_child(_current_room)
    # Place player at room entry point
    var entry = _current_room.get_node_or_null("EntryPoint")
    if entry:
        player.position = entry.position
    # Connect exit door
    var exit_door = _current_room.get_node_or_null("ExitDoor")
    if exit_door:
        exit_door.body_entered.connect(func(body):
            if body.is_in_group("player"):
                _on_exit_reached()
        )
    # Spawn enemies
    _spawn_enemies()

func _spawn_enemies() -> void:
    var spawns = _current_room.get_children().filter(func(n): return n.name.begins_with("EnemySpawn"))
    for spawn in spawns:
        var drone = load("res://scenes/derelict/enemies/drone.tscn").instantiate()
        drone.position = spawn.position
        _current_room.add_child(drone)

func _on_exit_reached() -> void:
    _current_room_index += 1
    if _current_room_index >= _room_sequence.size():
        _exit_run(true)
    else:
        _load_room(_current_room_index)

func add_loot(resource_id: String, amount: int) -> void:
    _gathered_loot[resource_id] = _gathered_loot.get(resource_id, 0) + amount

func _exit_run(survived: bool) -> void:
    if survived:
        for resource_id in _gathered_loot:
            GameState.add_resource(resource_id, _gathered_loot[resource_id])
    get_tree().change_scene_to_file("res://scenes/main.tscn")
```

**Step 4: Add RoomGenerator as autoload**

Project Settings → Autoload → add `scripts/derelict/room_generator.gd` as `RoomGenerator`.

**Step 5: Manual test**

Enter via Derelict Entrance (hardcode scene change for now). Verify rooms load in sequence. Verify exit door advances to next room. Verify final exit returns to main.

**Step 6: Commit**

```bash
git add scenes/derelict/ scripts/derelict/run.gd scripts/derelict/room_generator.gd
git commit -m "feat: add Derelict roguelite run with room sequence and loot tracking"
```

---

## Task 13: Enemy Base + Drone Enemy

**Files:**
- Create: `scenes/derelict/enemies/drone.tscn`
- Create: `scripts/derelict/enemy_base.gd`
- Create: `scripts/derelict/drone.gd`

Simple patrol/chase AI. The drone patrols between two points until the player enters its detect radius, then chases. Contact with player deals damage (tracked as a `GameState` flag for MVP — `player_hurt`). On death: drops scrap.

**Step 1: Create enemy scene**

New Scene → root `CharacterBody2D`, rename `Drone`.
Children:
- `Sprite2D` (red placeholder rect, 12×12)
- `CollisionShape2D`
- `Area2D` named `DetectZone` (CircleShape2D, radius 60)
- `Area2D` named `HitZone` (CircleShape2D, radius 10)

Save as `scenes/derelict/enemies/drone.tscn`.

**Step 2: Write EnemyBase**

```gdscript
# scripts/derelict/enemy_base.gd
extends CharacterBody2D

@export var max_hp: int = 3
@export var move_speed: float = 40.0
@export var loot_resource: String = "scrap"
@export var loot_amount: int = 1

var _hp: int = 0

func _ready() -> void:
    _hp = max_hp

func take_damage(amount: int) -> void:
    _hp -= amount
    if _hp <= 0:
        _die()

func _die() -> void:
    var run = get_tree().get_root().find_child("DerelictRun", true, false)
    if run:
        run.add_loot(loot_resource, loot_amount)
    queue_free()
```

**Step 3: Write Drone (extends EnemyBase)**

```gdscript
# scripts/derelict/drone.gd
extends "res://scripts/derelict/enemy_base.gd"

@onready var detect_zone: Area2D = $DetectZone
@onready var hit_zone: Area2D = $HitZone

var _player: CharacterBody2D = null
var _patrol_points: Array = []
var _patrol_index: int = 0

func _ready() -> void:
    super()
    detect_zone.body_entered.connect(func(body):
        if body.is_in_group("player"):
            _player = body
    )
    detect_zone.body_exited.connect(func(body):
        if body.is_in_group("player"):
            _player = null
    )
    hit_zone.body_entered.connect(func(body):
        if body.is_in_group("player"):
            GameState.set_flag("player_hurt", true)
    )
    # Set simple patrol points relative to spawn
    _patrol_points = [position + Vector2(-40, 0), position + Vector2(40, 0)]

func _physics_process(_delta: float) -> void:
    if _player:
        var dir = (_player.position - position).normalized()
        velocity = dir * move_speed
    else:
        var target = _patrol_points[_patrol_index]
        var diff = target - position
        if diff.length() < 4.0:
            _patrol_index = (_patrol_index + 1) % _patrol_points.size()
        velocity = diff.normalized() * (move_speed * 0.5)
    move_and_slide()
```

**Step 4: Add player attack**

In `player.gd`, add a basic swing — on action `attack` (key F), create a short-lived `Area2D` hitbox that damages enemies:

```gdscript
# Add to player.gd
@export var attack_damage: int = 1

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        _try_interact()
    if event.is_action_pressed("attack"):
        _do_attack()

func _do_attack() -> void:
    var hitbox = Area2D.new()
    var shape = CollisionShape2D.new()
    shape.shape = CircleShape2D.new()
    shape.shape.radius = 20.0
    hitbox.add_child(shape)
    hitbox.position = position + Vector2(16, 0)  # In front of player
    get_parent().add_child(hitbox)
    await get_tree().create_timer(0.1).timeout
    for body in hitbox.get_overlapping_bodies():
        if body.has_method("take_damage"):
            body.take_damage(attack_damage)
    hitbox.queue_free()
```

Add `attack` input action in Project Settings → Input Map → assign key `F`.

**Step 5: Manual test**

Enter the Derelict. Verify drone patrols. Walk near it — verify it chases. Press F near it — verify it dies and drops scrap (check GameState). Take contact damage — verify `player_hurt` flag set.

**Step 6: Commit**

```bash
git add scenes/derelict/enemies/ scripts/derelict/enemy_base.gd scripts/derelict/drone.gd
git commit -m "feat: add Drone enemy with patrol/chase AI and player attack"
```

---

## Task 14: Survivor Encounter System

**Files:**
- Create: `scenes/derelict/rooms/room_survivor.tscn`
- Create: `scripts/derelict/survivor.gd`

A special room type that contains a survivor NPC. Brief dialogue + choice. On success, survivor joins the station. A few have full story arcs; others become background crew.

**Step 1: Create survivor room**

Duplicate `room_a.tscn` → `room_survivor.tscn`. Add a `CharacterBody2D` named `Survivor` with a different sprite (orange rect).

**Step 2: Write Survivor script**

```gdscript
# scripts/derelict/survivor.gd
extends CharacterBody2D

@export var survivor_id: String = "survivor_01"
@export var survivor_name: String = "Stranger"
@export var is_story_character: bool = false

@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
    add_to_group("interactable")
    interaction_area.add_to_group("interactable")
    interaction_area.interact = interact

func interact() -> void:
    var tree = _get_dialogue_tree()
    DialogueManager.conversation_ended.connect(_on_conversation_ended, CONNECT_ONE_SHOT)
    DialogueManager.start_conversation(tree)
    get_tree().get_root().get_node("Main/DialogueBox").show_current_node()

func _get_dialogue_tree() -> Dictionary:
    return {
        "start": {
            "speaker": survivor_name,
            "text": "I've been down here since the seal. I thought everyone forgot about this place.",
            "choices": [
                { "text": "Come with me. There's room on the station.", "register": "warm", "next": "come_yes" },
                { "text": "I can't guarantee your safety up there.", "register": "logical", "next": "come_cautious" },
                { "text": "What do you know about what happened here?", "register": "curious", "next": "what_happened" },
            ]
        },
        "come_yes": {
            "speaker": survivor_name,
            "text": "...Alright. Lead the way.",
            "choices": []
        },
        "come_cautious": {
            "speaker": survivor_name,
            "text": "Nowhere's safe. But up beats down.",
            "choices": []
        },
        "what_happened": {
            "speaker": survivor_name,
            "text": "Something was left running. Something that wasn't supposed to survive the purge.",
            "choices": []
        }
    }

func _on_conversation_ended() -> void:
    GameState.set_flag("survivor_%s_recruited" % survivor_id, true)
    GameState.record_npc_choice("station", "recruited_%s" % survivor_id)
    queue_free()
```

**Step 3: Add survivor room to room pool**

In `room_generator.gd`, add `room_survivor.tscn` to the pool and ensure it appears at a random depth (not always the first room):

```gdscript
const ROOM_POOL = [
    "res://scenes/derelict/rooms/room_a.tscn",
    "res://scenes/derelict/rooms/room_b.tscn",
    "res://scenes/derelict/rooms/room_survivor.tscn",
]
```

**Step 4: Manual test**

Run multiple Derelict runs until the survivor room appears. Interact with the survivor. Verify `GameState.get_flag("survivor_survivor_01_recruited")` is true after conversation.

**Step 5: Commit**

```bash
git add scenes/derelict/rooms/room_survivor.tscn scripts/derelict/survivor.gd
git commit -m "feat: add survivor encounter room and recruitment system"
```

---

## Task 15: Main Story Beats (7-Day Arc)

**Files:**
- Modify: `scripts/characters/maris.gd`, `dex.gd`, `sable.gd` (beat dialogue already embedded)
- Create: `scripts/derelict/arc_events.gd` (handles non-NPC beats like "first_derelict_run" and "the_choice")
- Modify: `scripts/areas/derelict_entrance.gd` (fires beat on first entry)

The 7-day beat schedule is already in `DayManager.ARC_BEATS`. This task wires the non-NPC beats and implements the final choice.

**Step 1: Create Derelict Entrance area**

New Scene → root `Node2D`, rename `DerelictEntrance`.
Children:
- Background `Sprite2D`
- A large sealed door `Sprite2D` (red while locked, green when `GameState.get_flag("derelict_mentioned")`)
- `Area2D` named `DoorTrigger` (overlaps door)

`scripts/areas/derelict_entrance.gd`:

```gdscript
# scripts/areas/derelict_entrance.gd
extends Node2D

@onready var door_trigger: Area2D = $DoorTrigger
@onready var door_sprite: Sprite2D = $DoorSprite

func _ready() -> void:
    _refresh_door()
    GameState.flag_changed.connect(func(flag, _val):
        if flag == "derelict_mentioned": _refresh_door()
    )
    door_trigger.body_entered.connect(func(body):
        if body.is_in_group("player") and GameState.get_flag("derelict_mentioned"):
            _enter_derelict()
    )

func _refresh_door() -> void:
    door_sprite.modulate = Color.GREEN if GameState.get_flag("derelict_mentioned") else Color.RED

func _enter_derelict() -> void:
    if not DayManager.is_beat_complete("first_derelict_run"):
        DayManager.complete_beat("first_derelict_run")
    get_tree().change_scene_to_file("res://scenes/derelict/run.tscn")
```

**Step 2: Implement "the_choice" beat**

Day 7's `the_choice` beat is a special scene — a full-screen dialogue moment. Create it as a `CanvasLayer` overlay triggered by `DayManager.beat_completed` signal when the day is 7.

`scripts/derelict/arc_events.gd`:

```gdscript
# scripts/derelict/arc_events.gd
extends Node

# Called from Main after day 6 ends (day 7 starts)
func trigger_final_choice() -> void:
    var overlay = _build_choice_overlay()
    get_tree().root.add_child(overlay)

func _build_choice_overlay() -> CanvasLayer:
    var layer = CanvasLayer.new()
    var panel = PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var vbox = VBoxContainer.new()
    var label = RichTextLabel.new()
    label.text = """[center]You know what's in the lower decks now.

The thing that survived the purge is still alive.
Dex wants to shut it down. Maris says it might be salvageable.
Sable says it knows something — about all of you.[/center]"""
    vbox.add_child(label)

    var choices = [
        { "text": "Shut it down. The station comes first.", "flag": "ending_pragmatic" },
        { "text": "Try to communicate. There might be a way.", "flag": "ending_hopeful" },
        { "text": "Let Sable decide. She's the one it recognises.", "flag": "ending_deferred" },
    ]
    for choice in choices:
        var btn = Button.new()
        btn.text = choice["text"]
        var flag = choice["flag"]
        btn.pressed.connect(func():
            GameState.set_flag(flag, true)
            DayManager.complete_beat("the_choice")
            layer.queue_free()
        )
        vbox.add_child(btn)

    panel.add_child(vbox)
    layer.add_child(panel)
    return layer
```

**Step 3: Add ending scenes**

Create three minimal ending screens (`scenes/ui/ending_pragmatic.tscn`, `ending_hopeful.tscn`, `ending_deferred.tscn`) — each is a full-screen label with an ending paragraph and a "Credits" button.

Ending text examples:

- **Pragmatic:** "The station survived. The thing in the lower decks didn't. Dex said it was the right call. You're not sure you believe him."
- **Hopeful:** "You opened a channel. It spoke. It knew things about the station's history that the logs had erased. Whether that changes anything — that's still being decided."
- **Deferred:** "Sable went in alone. She was down there for three hours. When she came back, she didn't say what happened. But she's still here."

**Step 4: Wire endings from Main**

In `main.gd`, connect to `DayManager.day_ended` and check if day 7 ended + `the_choice` complete:

```gdscript
func _on_day_ended(day: int) -> void:
    if day == 7:
        _show_ending()

func _show_ending() -> void:
    if GameState.get_flag("ending_pragmatic"):
        get_tree().change_scene_to_file("res://scenes/ui/ending_pragmatic.tscn")
    elif GameState.get_flag("ending_hopeful"):
        get_tree().change_scene_to_file("res://scenes/ui/ending_hopeful.tscn")
    else:
        get_tree().change_scene_to_file("res://scenes/ui/ending_deferred.tscn")
```

**Step 5: Commit**

```bash
git add scripts/areas/derelict_entrance.gd scripts/derelict/arc_events.gd scenes/ui/ending_*.tscn
git commit -m "feat: wire 7-day story arc with final choice and three endings"
```

---

## Task 16: HUD + Day Summary UI

**Files:**
- Create: `scenes/ui/hud.tscn` + `scripts/ui/hud.gd`
- Create: `scenes/ui/day_summary.tscn` + `scripts/ui/day_summary.gd`

**Step 1: Create HUD**

New Scene → root `CanvasLayer`.
Add `HBoxContainer` anchored top-left:
- `Label` named `RationsLabel`
- `Label` named `PartsLabel`
- `Label` named `EnergyLabel`
- `Label` named `ScrapLabel`
- `Label` named `DayLabel` (right side)
- `Label` named `BeatsLabel` ("Story beats remaining: N")

`scripts/ui/hud.gd`:

```gdscript
extends CanvasLayer

@onready var rations_lbl: Label = $HBoxContainer/RationsLabel
@onready var parts_lbl: Label = $HBoxContainer/PartsLabel
@onready var energy_lbl: Label = $HBoxContainer/EnergyLabel
@onready var scrap_lbl: Label = $HBoxContainer/ScrapLabel
@onready var day_lbl: Label = $HBoxContainer/DayLabel
@onready var beats_lbl: Label = $HBoxContainer/BeatsLabel
@onready var message_lbl: Label = $MessageLabel  # Centered, fades out

func _ready() -> void:
    GameState.resource_changed.connect(_refresh_resources)
    DayManager.beat_completed.connect(_refresh_beats)
    DayManager.day_ended.connect(_on_day_ended)
    _refresh_resources("", 0)
    _refresh_beats("")

func _refresh_resources(_id, _amt) -> void:
    rations_lbl.text = "Rations: %d" % GameState.get_resource("rations")
    parts_lbl.text = "Parts: %d" % GameState.get_resource("parts")
    energy_lbl.text = "Energy: %d" % GameState.get_resource("energy_cells")
    scrap_lbl.text = "Scrap: %d" % GameState.get_resource("scrap")
    day_lbl.text = "Day %d" % DayManager.current_day

func _refresh_beats(_beat_id) -> void:
    var remaining = 0
    for beat in DayManager.get_todays_beats():
        if beat.get("required", false) and not DayManager.is_beat_complete(beat["id"]):
            remaining += 1
    beats_lbl.text = "" if remaining == 0 else "Story beats: %d remaining" % remaining
    if DayManager.is_day_complete():
        beats_lbl.text = "Rest when ready (bunk in Quarters)"

func _on_day_ended(_day) -> void:
    day_lbl.text = "Day %d" % DayManager.current_day

func show_message(text: String) -> void:
    message_lbl.text = text
    message_lbl.show()
    await get_tree().create_timer(3.0).timeout
    message_lbl.hide()
```

**Step 2: Create Day Summary**

New Scene → `CanvasLayer` with full-screen `PanelContainer`.
Shows: day number, what beats were completed (labels), a "Rest" button.

`scripts/ui/day_summary.gd`:

```gdscript
extends CanvasLayer

@onready var day_lbl: Label = $Panel/VBox/DayLabel
@onready var events_container: VBoxContainer = $Panel/VBox/EventsContainer
@onready var rest_btn: Button = $Panel/VBox/RestButton

func _ready() -> void:
    hide()
    rest_btn.pressed.connect(_on_rest)

func show_summary() -> void:
    day_lbl.text = "End of Day %d" % DayManager.current_day
    for child in events_container.get_children():
        child.queue_free()
    for beat in DayManager.get_todays_beats():
        if DayManager.is_beat_complete(beat["id"]):
            var lbl = Label.new()
            lbl.text = "✓ %s" % beat["id"].replace("_", " ").capitalize()
            events_container.add_child(lbl)
    show()

func _on_rest() -> void:
    hide()
    DayManager.advance_day()
```

**Step 3: Commit**

```bash
git add scenes/ui/hud.tscn scripts/ui/hud.gd scenes/ui/day_summary.tscn scripts/ui/day_summary.gd
git commit -m "feat: add HUD resource display and Day Summary screen"
```

---

## Task 17: Main Scene — Wire Everything Together

**Files:**
- Create: `scenes/main.tscn`
- Create: `scripts/main.gd`

Main is the hub scene. It holds the player, the current area, all persistent UI layers (HUD, DialogueBox, CraftingPanel, DaySummary), and handles area transitions.

**Step 1: Create Main scene**

New Scene → root `Node2D`, rename `Main`.
Add:
- `Node2D` named `AreaContainer` (swapped area scenes go here)
- Instance `scenes/characters/player.tscn` as `Player` — add to group `player`
- Instance `scenes/ui/hud.tscn` as `HUD`
- Instance `scenes/ui/dialogue_box.tscn` as `DialogueBox`
- Instance `scenes/ui/crafting_panel.tscn` as `CraftingPanel`
- Instance `scenes/ui/day_summary.tscn` as `DaySummary`

Save as `scenes/main.tscn`.

**Step 2: Write Main script**

```gdscript
# scripts/main.gd
extends Node2D

const AREA_SCENES = {
    "cantina": "res://scenes/areas/cantina.tscn",
    "engineering": "res://scenes/areas/engineering.tscn",
    "quarters": "res://scenes/areas/quarters.tscn",
    "derelict_entrance": "res://scenes/areas/derelict_entrance.tscn",
}

const NPC_SPAWN_AREAS = {
    "maris": "cantina",
    "sable": "cantina",
    "dex": "engineering",
}

@onready var area_container: Node2D = $AreaContainer
@onready var player: CharacterBody2D = $Player
@onready var hud = $HUD
@onready var day_summary = $DaySummary
@onready var crafting_panel = $CraftingPanel

var _current_area_id: String = ""
var _npc_instances: Dictionary = {}

func _ready() -> void:
    DayManager.day_ended.connect(_on_day_ended)
    DayManager.all_beats_done.connect(_on_all_beats_done)
    go_to_area("cantina")
    _spawn_npcs()

func go_to_area(area_id: String) -> void:
    if _current_area_id == area_id:
        return
    for child in area_container.get_children():
        child.queue_free()
    var scene = load(AREA_SCENES[area_id])
    var area = scene.instantiate()
    area_container.add_child(area)
    _current_area_id = area_id
    # Move NPCs that belong in this area
    for npc_id in _npc_instances:
        var npc = _npc_instances[npc_id]
        var spawn_area = NPC_SPAWN_AREAS.get(npc_id, "cantina")
        npc.visible = (spawn_area == area_id)
        if spawn_area == area_id:
            var spawn = area.get_node_or_null("%sSpawn" % npc_id.capitalize())
            if spawn:
                npc.position = spawn.global_position

func _spawn_npcs() -> void:
    var npc_scripts = {
        "maris": "res://scripts/characters/maris.gd",
        "sable": "res://scripts/characters/sable.gd",
        "dex": "res://scripts/characters/dex.gd",
    }
    for npc_id in npc_scripts:
        var base = load("res://scenes/characters/npc_base.tscn").instantiate()
        base.set_script(load(npc_scripts[npc_id]))
        add_child(base)
        _npc_instances[npc_id] = base

func open_crafting() -> void:
    crafting_panel.open()

func advance_day() -> void:
    day_summary.show_summary()

func show_hud_message(text: String) -> void:
    hud.show_message(text)

func _on_day_ended(day: int) -> void:
    if day == 7:
        _show_ending()

func _on_all_beats_done() -> void:
    show_hud_message("All story beats complete. Rest at your bunk in Quarters.")

func _show_ending() -> void:
    if GameState.get_flag("ending_pragmatic"):
        get_tree().change_scene_to_file("res://scenes/ui/ending_pragmatic.tscn")
    elif GameState.get_flag("ending_hopeful"):
        get_tree().change_scene_to_file("res://scenes/ui/ending_hopeful.tscn")
    else:
        get_tree().change_scene_to_file("res://scenes/ui/ending_deferred.tscn")
```

**Step 3: Full playthrough test**

Play through the full loop:
1. Character creation → choose background, verify starting resources
2. Day 1 — meet Maris and Dex (both required beats), verify HUD shows "0 remaining", bunk available
3. Day 2 — meet Sable, trigger power flicker beat with Dex
4. Day 3 — Maris confides, Sable optional beat
5. Day 4 — Derelict mentioned (door turns green), Maris favour
6. Day 5 — Enter Derelict, fight a drone, collect scrap, exit
7. Day 6 — Find survivor, trigger Dex secret
8. Day 7 — Final choice overlay appears, select an option, verify correct ending loads

**Step 4: Final commit**

```bash
git add scenes/main.tscn scripts/main.gd
git commit -m "feat: wire main scene — Outpost Nova evolved MVP playable"
```

---

## Done

The vertical slice is complete when you play through the 7-day arc and reach one of three endings.

**What this validates:**
- Top-down movement through a space station feels natural
- Dialogue emotional registers + inner voice add character without complexity
- Day cycle with story beats creates Citizen Sleeper-style weight
- Derelict roguelite loop provides tension and resource pressure
- Recruitment makes the station feel alive over time
- Three distinct endings shaped by accumulated choices

**Not in scope (DLC foundation):**
- Second arc / episodic content
- Art pass (replace placeholder colored rects)
- Sound and music
- Save system
- Additional recruitable survivors with full story arcs
- More enemy types in the Derelict
- Workshop room (existing plan referenced it — can be a Day 8+ unlock in DLC 1)
