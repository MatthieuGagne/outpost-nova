# Social Web — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a PairState relationship system to `GameState`, wire the 30-minute talk cost via `ClockManager`, parse `#pair:` tags in dialogue option buttons, and tag all Day 1 NPC Yarn scripts (issue #72, part of #65).

**Architecture:** `GameState` gains a `PairState` enum and a `_pair_states` dict with authored defaults. `npc_base.gd` calls `ClockManager.commit_action(30)` after `conversation_ended`. `dialogue_box.gd` reads `option.line.metadata` from YarnSpinner to detect `#pair:X` tags and appends the human-readable pair state to each button. Yarn scripts gain at least one `#pair:`-tagged option per NPC. All logic is GUT-tested before UI wiring.

**Tech Stack:** Godot 4.6 / GDScript, GUT test framework, YarnSpinner GDScript addon.

**Prerequisite:** Plan A (#71) must be merged first — `ClockManager.commit_action()` must exist and be registered in `project.godot`.

## Open questions (must resolve before starting)

- none

---

### Task 1: Write failing GUT tests for PairState

**Files:**
- Modify: `tests/test_game_state.gd`

**Depends on:** none
**Parallelizable with:** none — must fail before Task 2 implements the code.

**Step 1: Append the failing PairState tests to test_game_state.gd**

Add the following test functions to the bottom of `tests/test_game_state.gd` (after the existing `test_set_flag_on_cleared_on_reset` test):

```gdscript
# --- PairState tests ---

func test_pair_state_defaults_neutral_for_unknown_pair():
	GameState.reset()
	assert_eq(GameState.get_pair_state("no_such_pair"), GameState.PairState.NEUTRAL)

func test_set_pair_state_stores_value():
	GameState.reset()
	GameState.set_pair_state("maris_dex", GameState.PairState.COLLEGIAL)
	assert_eq(GameState.get_pair_state("maris_dex"), GameState.PairState.COLLEGIAL)

func test_set_pair_state_emits_signal():
	GameState.reset()
	watch_signals(GameState)
	GameState.set_pair_state("maris_dex", GameState.PairState.COLLEGIAL)
	assert_signal_emitted(GameState, "pair_state_changed")

func test_authored_default_maris_velreth_is_collegial():
	GameState.reset()
	assert_eq(GameState.get_pair_state("maris_velreth"), GameState.PairState.COLLEGIAL)

func test_authored_default_dex_velreth_is_collegial():
	GameState.reset()
	assert_eq(GameState.get_pair_state("dex_velreth"), GameState.PairState.COLLEGIAL)

func test_authored_default_maris_dex_is_neutral():
	GameState.reset()
	assert_eq(GameState.get_pair_state("maris_dex"), GameState.PairState.NEUTRAL)

func test_reset_restores_authored_defaults():
	GameState.reset()
	GameState.set_pair_state("maris_velreth", GameState.PairState.TENSION)
	GameState.reset()
	assert_eq(GameState.get_pair_state("maris_velreth"), GameState.PairState.COLLEGIAL)

func test_get_pairs_for_npc_returns_only_pairs_involving_npc():
	GameState.reset()
	var pairs := GameState.get_pairs_for_npc("maris")
	assert_true(pairs.has("maris_velreth"))
	assert_true(pairs.has("maris_dex"))
	assert_false(pairs.has("dex_velreth"))

func test_get_pair_state_label_neutral():
	assert_eq(GameState.get_pair_state_label(GameState.PairState.NEUTRAL), "Neutral")

func test_get_pair_state_label_collegial():
	assert_eq(GameState.get_pair_state_label(GameState.PairState.COLLEGIAL), "Collegial")

func test_get_pair_state_label_tension():
	assert_eq(GameState.get_pair_state_label(GameState.PairState.TENSION), "Tension")

func test_get_pair_state_label_bonded():
	assert_eq(GameState.get_pair_state_label(GameState.PairState.BONDED), "Bonded")
```

**Step 2: Run test to verify it fails**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_game_state.gd
```

Expected: FAIL — `PairState` and `get_pair_state` do not exist yet.

**Step 3: Commit**

```bash
git add tests/test_game_state.gd
git commit -m "test: add failing PairState tests to test_game_state"
```

---

### Task 2: Implement PairState in game_state.gd

**Files:**
- Modify: `scripts/autoload/game_state.gd`

**Depends on:** Task 1
**Parallelizable with:** none — tests must fail first.

**Step 1: Add PairState to game_state.gd**

Add the following to `scripts/autoload/game_state.gd` after the existing `signal flag_changed` line:

```gdscript
signal pair_state_changed(pair_id: String, new_state: int)

enum PairState { TENSION = 0, NEUTRAL = 1, COLLEGIAL = 2, BONDED = 3 }

const _PAIR_STATE_LABELS: Dictionary = {
	PairState.TENSION:   "Tension",
	PairState.NEUTRAL:   "Neutral",
	PairState.COLLEGIAL: "Collegial",
	PairState.BONDED:    "Bonded",
}

const DEFAULT_PAIR_STATES: Dictionary = {
	"maris_velreth": PairState.COLLEGIAL,
	"dex_velreth":   PairState.COLLEGIAL,
	"maris_dex":     PairState.NEUTRAL,
	"maris_quen":    PairState.NEUTRAL,
	"dex_quen":      PairState.NEUTRAL,
	"velreth_quen":  PairState.NEUTRAL,
}

var _pair_states: Dictionary = {}
```

Update `reset()` to include:

```gdscript
func reset() -> void:
	player_name = ""
	player_background = ""
	player_appearance = 0
	_resources = { "rations": 0, "parts": 0, "energy_cells": 0, "scrap": 0 }
	_flags = {}
	_npc_flags = {}
	_register_history = {}
	_pair_states = DEFAULT_PAIR_STATES.duplicate()
```

Add the new methods at the bottom of the file:

```gdscript
func get_pair_state(pair_id: String) -> PairState:
	return _pair_states.get(pair_id, PairState.NEUTRAL)

func set_pair_state(pair_id: String, state: PairState) -> void:
	_pair_states[pair_id] = state
	pair_state_changed.emit(pair_id, state)

func get_pairs_for_npc(npc_id: String) -> Dictionary:
	var result: Dictionary = {}
	for pair_id in _pair_states:
		var parts := pair_id.split("_")
		if parts.has(npc_id):
			result[pair_id] = _pair_states[pair_id]
	return result

func get_pair_state_label(state: PairState) -> String:
	return _PAIR_STATE_LABELS.get(state, "Unknown")
```

**Step 2: Run tests to verify they pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_game_state.gd
```

Expected: All tests PASS including new PairState tests.

Also confirm the full suite still passes:

```bash
godot --headless -s addons/gut/gut_cmdln.gd
```

Expected: All tests pass. Zero failures.

**Step 3: Refactor checkpoint**

Does `get_pairs_for_npc` generalize? It splits the pair_id on `"_"` and checks if the npc_id is in the parts. This assumes pair IDs use `npc1_npc2` format, which is correct. But NPC IDs like `energy_cells` would break — however, NPC IDs in this game are single words (maris, dex, velreth, quen), so this is safe for the current data set. Document the assumption or open a follow-up issue if multi-word NPC IDs are ever added.

**Step 4: Commit**

```bash
git add scripts/autoload/game_state.gd
git commit -m "feat: add PairState enum, pair state dict, and pair methods to GameState"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 1 → Task 2 | Task 2 implements what Task 1 tests; must run in order |

---

### Smoketest Checkpoint 1 — PairState tests pass

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass including new PairState tests. Zero failures.

**Step 3: Launch game and verify visually**
```bash
godot
```
Expected: Game launches normally. No visible changes yet — PairState exists but isn't wired to UI.

**Step 4: Confirm with user**
Confirm all tests pass and game launches before proceeding to Batch 2.

---

### Task 3: Wire talk cost in npc_base.gd

**Files:**
- Modify: `scripts/characters/npc_base.gd`

**Depends on:** Smoketest Checkpoint 1
**Parallelizable with:** Task 4 — different output files, no shared state.

**Step 1: Update _on_conversation_ended in npc_base.gd**

In `scripts/characters/npc_base.gd`, replace:

```gdscript
func _on_conversation_ended() -> void:
	_is_talking = false
```

With:

```gdscript
func _on_conversation_ended() -> void:
	_is_talking = false
	ClockManager.commit_action(30)
```

**Step 2: Verify**

No GUT test required — this is a timing side-effect wired to a signal. Verified visually at Smoketest Checkpoint 2: clock advances 30 min after each conversation ends.

**Step 3: Commit**

```bash
git add scripts/characters/npc_base.gd
git commit -m "feat: commit 30-min talk cost to ClockManager after each conversation"
```

---

### Task 4: Parse #pair: tags in dialogue_box.gd

**Files:**
- Modify: `scripts/ui/dialogue_box.gd`

**Depends on:** Smoketest Checkpoint 1
**Parallelizable with:** Task 3 — different output files, no shared state.

**Step 1: Update _build_choices in dialogue_box.gd**

In `scripts/ui/dialogue_box.gd`, find the `_build_choices` method. Locate the line that sets `btn.text`:

```gdscript
btn.text = "[%d] %s" % [i + 1, option.line.text_without_character_name.text]
```

Replace with:

```gdscript
var btn_text := "[%d] %s" % [i + 1, option.line.text_without_character_name.text]
for tag in option.line.metadata:
    if tag.begins_with("pair:"):
        var pair_id := tag.substr(5)  # strip "pair:" prefix (5 chars)
        var state := GameState.get_pair_state(pair_id)
        btn_text += " [%s]" % GameState.get_pair_state_label(state)
        break
btn.text = btn_text
```

**Note:** `option.line.metadata` is a `PackedStringArray` of the hashtag strings on the Yarn option line (without the leading `#`). For `#pair:maris_dex`, the metadata entry is `"pair:maris_dex"`. The `#register:warm` tag also appears in metadata but starts with `"register:"` — the `begins_with("pair:")` guard ensures we only process pair tags.

**Step 2: Verify**

No GUT test required — YarnSpinner dialogue rendering is not unit-testable in isolation. Verified visually at Smoketest Checkpoint 2.

**Step 3: Commit**

```bash
git add scripts/ui/dialogue_box.gd
git commit -m "feat: parse #pair: tags on dialogue options to show pair state label"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 3, Task 4 | Different output files; talk cost and tag parsing are independent |

---

### Smoketest Checkpoint 2 — Talk cost fires, pair state labels appear on buttons

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
Verify all of the following before proceeding:
- Talk to Maris — after conversation ends, clock shows `06:30` (30-min cost applied)
- Talk to Dex — clock shows `07:00`
- Confirm the talk cost fires after conversation ends (not when dialogue starts)
- Yarn dialogue still loads — no errors about unregistered commands
- Note: Yarn files don't yet have `#pair:` tagged options, so no pair labels appear yet — that's expected

---

### Task 5: Add #pair: tags to Yarn dialogue files

**Files:**
- Modify: `data/dialogue/maris.yarn`
- Modify: `data/dialogue/dex.yarn`
- Modify: `data/dialogue/velreth.yarn`
- Modify: `data/dialogue/quen.yarn`

**Depends on:** Smoketest Checkpoint 2
**Parallelizable with:** none — single task touching 4 files; all 4 must be done together so the smoketest covers them all.

**Pair ID reference** (use these exact strings as tag values):
| Pair | ID | Default State |
|------|----|---------------|
| Maris ↔ Velreth | `maris_velreth` | Collegial |
| Dex ↔ Velreth | `dex_velreth` | Collegial |
| Maris ↔ Dex | `maris_dex` | Neutral |
| Maris ↔ Quen | `maris_quen` | Neutral |
| Dex ↔ Quen | `dex_quen` | Neutral |
| Velreth ↔ Quen | `velreth_quen` | Neutral |

**Step 1: Update maris.yarn**

In the `Maris_Casual` node, add a new option referencing Velreth (a pair tagged option):

```yarn
title: Maris_Casual
---
Maris: The printer's running. That's about as good as it gets today.
-> How are you holding up? #register:warm
    <<register warm>>
    Maris: Honestly? I've had better weeks. But I'm here.
-> Good to know. #register:detached
    <<register detached>>
    Maris: Yeah.
-> How's Velreth settling in? #pair:maris_velreth
    Maris: Velreth? They keep to themselves. I respect that.
===
```

**Step 2: Update dex.yarn**

In the `Dex_Casual` node, add an option referencing Velreth:

```yarn
title: Dex_Casual
---
Dex: Back again. Nothing's exploded since you left, if that's what you're checking.
-> Have you spoken with Velreth? #pair:dex_velreth
    Dex: Once or twice. Quiet. Knows their stuff, which counts for something out here.
===
```

**Step 3: Update velreth.yarn**

In the `Velreth_Casual` node, add an option referencing Maris:

```yarn
title: Velreth_Casual
---
Velreth: The presenting problem today is the same as yesterday. [beat] Not yours — the station's.
-> How are you holding up? #register:warm
    <<register warm>>
    Velreth: I am making the same choice I made yesterday. That is, I think, the honest answer.
-> Noted. #register:detached
    <<register detached>>
    Velreth: [beat] Yes.
-> Have you met Maris properly? #pair:maris_velreth
    Velreth: We have spoken. She appears to manage her frustrations constructively. I find that admirable.
===
```

**Step 4: Update quen.yarn**

In the `Quen_Casual` node, add an option referencing Dex:

```yarn
title: Quen_Casual
---
Quen: The corridors remain as I left them.
-> What do you think of Dex? #pair:dex_quen
    Quen: The engineer. Competent. Cautious. Whether that caution is wisdom or fear, I have not yet determined.
===
```

**Step 5: Verify (manual)**

Open each `.yarn` file and confirm no `[beat]` inline markup was accidentally changed. Search for any remaining `<<beat>>` commands (should be zero after Plan A):

```bash
grep -n "<<beat" data/dialogue/
```

Expected: (empty after Plan A merges).

**Step 6: Commit**

```bash
git add data/dialogue/
git commit -m "feat: add #pair: tagged dialogue options to all Day 1 NPCs"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 3

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 5 | Single task; 4 files but all in one logical step |

---

### Smoketest Checkpoint 3 — Pair state labels appear on dialogue option buttons

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
- Talk to Maris — in `Maris_Casual` dialogue, the option `"How's Velreth settling in?"` shows `[Collegial]` appended: `"[3] How's Velreth settling in? [Collegial]"`
- Talk to Dex — `"Have you spoken with Velreth?"` shows `[Collegial]`
- Talk to Velreth — `"Have you met Maris properly?"` shows `[Collegial]`
- Talk to Quen — `"What do you think of Dex?"` shows `[Neutral]`
- Clock advances 30 min after each conversation (talk cost still firing)
- No errors in Godot output log
