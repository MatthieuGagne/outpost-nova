# YarnSpinner Dialogue — Completion Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the broken choice system, correct the portrait sprite sheet, expose `get_flag()` to Yarn via a C# bridge, and remove dead dialogue tree code from NPC scripts.

**Architecture:** Three targeted fixes + one new C# file. The YarnSpinner setup, `DialogueRunner`, `dialogue_box.gd`, and stub `.yarn` files are already in place. This plan completes what's broken or missing.

**Tech Stack:** Godot 4.6.1 Mono, YarnSpinner-Godot v0.3.12 (C#), GDScript, GUT, Python 3 (portrait generation).

## Open questions

- None — all resolved in grill-me session.

---

## Batch 1 — Fix choices + portraits

### Task 1: Fix `_build_choices` crash in `dialogue_box.gd`

**Files:**
- Modify: `scripts/ui/dialogue_box.gd`

**Depends on:** none
**Parallelizable with:** Task 2 — different files, no shared state.

**Step 1: Apply the fix**

In `scripts/ui/dialogue_box.gd`, replace lines 145–146 (inside `_build_choices`):

```gdscript
# BEFORE (crashes on nodes outside the scene tree)
btn.theme_override_fonts["font"] = load("res://data/fonts/m5x7.tres")
btn.theme_override_font_sizes["font_size"] = 13

# AFTER
btn.add_theme_font_override("font", load("res://data/fonts/m5x7.tres"))
btn.add_theme_font_size_override("font_size", 13)
```

**Step 2: Verify**

Open the Godot editor and run the game. Walk up to an NPC and press E. Confirm that choice buttons appear in the dialogue panel and are clickable / keyboard-navigable.

**Step 3: Commit**

```bash
git add scripts/ui/dialogue_box.gd
git commit -m "fix: use add_theme_font_override in _build_choices — dict-style crashes outside scene tree"
```

---

### Task 2: Regenerate `portraits.png` as 704×64 and update constants

**Files:**
- Modify: `assets/portraits/portraits.png`
- Modify: `scripts/ui/dialogue_box.gd`

**Depends on:** none
**Parallelizable with:** Task 1 — different files, no shared state.

**Step 1: Generate the new sprite sheet**

Run this Python script from the project root:

```python
# Run as: python3 generate_portraits.py
import struct, zlib

WIDTH_PER = 64
HEIGHT = 64
COUNT = 11

# Index → (R, G, B, A): matches NPC_PORTRAIT_INDEX and PLAYER_PORTRAIT_INDEX
COLORS = [
    (255, 160, 160, 255),  # 0 — Maris (warm pink)
    (160, 200, 255, 255),  # 1 — Dex (cool blue)
    (160, 255, 160, 255),  # 2 — Sable (green)
    (180, 180, 180, 255),  # 3 — Fallback (grey)
    (255, 200, 100, 255),  # 4 — reserved NPC
    (200, 160, 255, 255),  # 5 — reserved NPC
    (255, 255, 140, 255),  # 6 — reserved NPC
    (100, 220, 200, 255),  # 7 — reserved NPC
    (150, 220, 255, 255),  # 8 — reserved player bg
    (240, 240, 200, 255),  # 9 — Player (PLAYER_PORTRAIT_INDEX)
    (255, 220, 150, 255),  # 10 — reserved player bg
]

W = WIDTH_PER * COUNT

def make_png(width, height, colors_per_col):
    def chunk(name, data):
        c = name + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    
    # IHDR
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    
    # Raw pixel rows
    raw_rows = []
    for y in range(height):
        row = b'\x00'  # filter type None
        for x in range(width):
            col_idx = x // WIDTH_PER
            r, g, b, a = colors_per_col[col_idx]
            row += bytes([r, g, b])
        raw_rows.append(row)
    
    idat = zlib.compress(b''.join(raw_rows), 9)
    
    return (b'\x89PNG\r\n\x1a\n'
            + chunk(b'IHDR', ihdr)
            + chunk(b'IDAT', idat)
            + chunk(b'IEND', b''))

data = make_png(W, HEIGHT, COLORS)
with open('assets/portraits/portraits.png', 'wb') as f:
    f.write(data)
print(f"Written: {W}x{HEIGHT} PNG ({COUNT} portraits at {WIDTH_PER}x{HEIGHT} each)")
```

Expected output: `Written: 704x64 PNG (11 portraits at 64x64 each)`

**Step 2: Update constants in `dialogue_box.gd`**

```gdscript
# BEFORE
const PORTRAIT_WIDTH := 32
const PORTRAIT_HEIGHT := 128

# AFTER
const PORTRAIT_WIDTH := 64
const PORTRAIT_HEIGHT := 64
```

**Step 3: Delete the stale Godot import cache for the PNG**

```bash
rm -f .godot/imported/portraits.png-*.ctex .godot/imported/portraits.png-*.md5
```

Godot will re-import the PNG on next launch.

**Step 4: Verify**

Open the Godot editor and run the game. Walk up to an NPC and press E. Confirm that NPC and player portrait slots show a solid-color square (not a sliver or blank).

**Step 5: Commit**

```bash
git add assets/portraits/portraits.png scripts/ui/dialogue_box.gd
git commit -m "fix: regenerate portraits.png as 704x64 (11×64px); update PORTRAIT_WIDTH/HEIGHT constants"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 1, Task 2 | Different output files; no shared state |

### Smoketest Checkpoint 1 — choices appear, portraits are correct

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
```bash
godot
```

**Step 4: Confirm with user**

Ask the user to:
1. Walk up to any NPC and press E
2. Confirm dialogue panel opens at the bottom
3. Confirm NPC portrait (colored square) is visible
4. Confirm choice buttons appear with text (e.g. `[1] Good to meet you.`)
5. Confirm Up/Down arrows move highlight, Enter confirms, keys 1–3 select directly
6. Confirm player portrait (light yellow square, index 9) is visible on the right

Wait for confirmation before proceeding to Batch 2.

---

## Batch 2 — C# bridge + Yarn branching

### Task 3: Add `GameState.set_flag_on()` + GUT test

**Files:**
- Modify: `scripts/autoload/game_state.gd`
- Modify: `tests/test_game_state.gd`

**Depends on:** none
**Parallelizable with:** Task 4 — different files, no shared state.

**Step 1: Write the failing GUT test**

Append to `tests/test_game_state.gd`:

```gdscript
func test_set_flag_on():
    GameState.reset()
    GameState.set_flag_on("met_maris")
    assert_true(GameState.get_flag("met_maris"))

func test_set_flag_on_cleared_on_reset():
    GameState.set_flag_on("met_maris")
    GameState.reset()
    assert_false(GameState.get_flag("met_maris"))
```

**Step 2: Run test to verify it fails**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_game_state.gd
```
Expected: FAIL (undefined method `set_flag_on`)

**Step 3: Write minimal implementation**

Append to `scripts/autoload/game_state.gd`:

```gdscript
func set_flag_on(flag_id: String) -> void:
    set_flag(flag_id, true)
```

**Step 4: Run tests to verify they pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_game_state.gd
```
Expected: All tests PASS.

**Step 5: Refactor checkpoint**

`set_flag_on` is a single-line wrapper — no generalization needed.

**Step 6: Commit**

```bash
git add scripts/autoload/game_state.gd tests/test_game_state.gd
git commit -m "feat: add GameState.set_flag_on() for Yarn <<flag>> command"
```

---

### Task 4: Write `scripts/YarnGameState.cs` — C# Yarn function bridge

**Files:**
- Create: `scripts/YarnGameState.cs`

**Depends on:** none
**Parallelizable with:** Task 3 — different files, no shared state.

**Step 1: Write the file**

```csharp
// scripts/YarnGameState.cs
using Godot;
using YarnSpinnerGodot;

namespace OutpostNova;

/// <summary>
/// Exposes GameState query methods as Yarn functions.
/// Auto-registered by the YarnSpinner source generator — no manual registration needed.
/// </summary>
public static class YarnGameState
{
    /// <summary>
    /// Returns the value of a GameState flag. 
    /// Usage in Yarn: <<if get_flag("workshop_unlocked")>>
    /// </summary>
    [YarnFunction("get_flag")]
    public static bool GetFlag(string flagId)
    {
        var gameState = Engine.GetSingleton("GameState");
        return gameState.Call("get_flag", flagId).AsBool();
    }
}
```

**Step 2: Verify the C# build**

```bash
godot --headless --build-solutions
```
Expected: Build succeeds with zero errors. If the source generator emits a warning about missing return type registration, ignore it — it's informational.

**Step 3: Verify**

No automated test for C# ↔ Yarn interop (can't run headlessly). AC9 is verified at Smoketest Checkpoint 2 (talk to Maris twice).

**Step 4: Commit**

```bash
git add scripts/YarnGameState.cs
git commit -m "feat: add YarnGameState.cs — exposes get_flag() to Yarn via [YarnFunction]"
```

---

### Task 5: Register `<<flag>>` command + update `maris.yarn`

**Files:**
- Modify: `scripts/characters/npc_base.gd`
- Modify: `data/dialogue/maris.yarn`

**Depends on:** Task 3 (needs `GameState.set_flag_on()`), Task 4 (needs `get_flag` registered before branching)
**Parallelizable with:** none — depends on Tasks 3 and 4.

**Step 1: Register `<<flag>>` command in `npc_base.gd`**

In `npc_base.gd`, inside the `if not _commands_registered:` block (line 66), add:

```gdscript
runner.AddCommandHandlerCallable("flag", Callable(GameState, "set_flag_on"))
```

The block should now read:

```gdscript
if not _commands_registered:
    runner.AddCommandHandlerCallable("register", Callable(GameState, "record_register"))
    runner.AddCommandHandlerCallable("beat", Callable(DayManager, "complete_beat"))
    runner.AddCommandHandlerCallable("flag", Callable(GameState, "set_flag_on"))
    _commands_registered = true
```

**Step 2: Update `maris.yarn` to branch on `get_flag("met_maris")`**

Replace the entire contents of `data/dialogue/maris.yarn`:

```yarn
title: Maris
---
<<if get_flag("met_maris")>>
    <<jump Maris_Casual>>
<<else>>
    <<jump Maris_FirstMeeting>>
<<endif>>
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
<<flag met_maris>>
===

title: Maris_Casual
---
Maris: The printer's running. That's about as good as it gets today.
-> How are you holding up? #register:warm
    <<register warm>>
    Maris: Honestly? I've had better weeks. But I'm here.
-> Good to know. #register:detached
    <<register detached>>
    Maris: Yeah.
===
```

**Step 3: Recompile the Yarn project**

Open the Godot editor. The `.yarn` file change triggers an automatic YarnProject recompile. Confirm in the Output panel that there are no Yarn parse errors.

**Step 4: Commit**

```bash
git add scripts/characters/npc_base.gd data/dialogue/maris.yarn
git commit -m "feat: register <<flag>> command; Maris branches on get_flag(met_maris)"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 3, Task 4 | Different output files; no shared state |
| B (sequential) | Task 5 | Depends on Group A — needs `set_flag_on` (Task 3) and `get_flag` registered (Task 4) |

### Smoketest Checkpoint 2 — Maris branches correctly on repeat visit

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
```bash
godot
```

**Step 4: Confirm with user**

Ask the user to:
1. Walk up to Maris and press E — should see `Maris_FirstMeeting` dialogue with 3 choices
2. Complete the conversation
3. Walk up to Maris again and press E — should see `Maris_Casual` dialogue with 2 choices (different from the first visit)
4. Confirm both conversations end cleanly and the game unpauses

Wait for confirmation before proceeding to Batch 3.

---

## Batch 3 — Cleanup

### Task 6: Remove dead `_tree_*()` methods from NPC scripts

**Files:**
- Modify: `scripts/characters/maris.gd`
- Modify: `scripts/characters/dex.gd`
- Modify: `scripts/characters/sable.gd`

**Depends on:** none — the old methods are unreferenced; removing them is safe at any point.
**Parallelizable with:** Task 7 — different files, no shared state.

**Step 1: Strip dead code from each file**

`scripts/characters/maris.gd` — delete everything from `func _tree_first_meeting()` to the end of the file (lines 13–109). Keep only:

```gdscript
# scripts/characters/maris.gd
extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
    super()
    npc_id = "maris"
    display_name = "Maris"
    $AnimatedSprite2D.modulate = Color(1.0, 0.7, 0.7)

func get_dialogue_node() -> String:
    return "Maris"
```

`scripts/characters/dex.gd` — same: delete `_tree_first_meeting`, `_tree_casual`, `_tree_power_concern`, `_tree_post_secret`. Keep only `_ready()` and `get_dialogue_node()`.

`scripts/characters/sable.gd` — same: delete `_tree_first_meeting`, `_tree_guarded`, `_tree_post_revelation`. Keep only `_ready()` and `get_dialogue_node()`.

**Step 2: Verify**

Open the Godot editor and confirm no script errors appear in the Scene panel for the three NPC instances. Run the game and talk to each NPC once to confirm they still open dialogue normally.

**Step 3: Commit**

```bash
git add scripts/characters/maris.gd scripts/characters/dex.gd scripts/characters/sable.gd
git commit -m "chore: remove dead _tree_*() dialogue methods from NPC scripts"
```

---

### Task 7: Delete `scripts/Temp.cs`

**Files:**
- Delete: `scripts/Temp.cs`

**Depends on:** none
**Parallelizable with:** Task 6 — different files, no shared state.

**Step 1: Delete the file**

```bash
git rm scripts/Temp.cs
```

**Step 2: Verify**

```bash
godot --headless --build-solutions
```
Expected: Build succeeds with zero errors.

**Step 3: Commit**

```bash
git commit -m "chore: delete empty Temp.cs placeholder"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 3

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 6, Task 7 | Different output files; no shared state |

### Smoketest Checkpoint 3 — clean codebase, all tests green

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
```bash
godot
```

**Step 4: Confirm with user**

Ask the user to:
1. Talk to all three NPCs (Maris, Dex, Sable) — confirm dialogue opens for each
2. Confirm Maris shows different dialogue on second visit
3. Confirm no errors in the Godot Output panel

Once confirmed, this branch is ready for PR via the `finishing-a-development-branch` skill.
