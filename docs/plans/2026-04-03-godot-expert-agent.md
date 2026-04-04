# Godot Expert Agent Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a reusable `.claude/agents/godot-expert.md` subagent that serves as the single source of truth for Godot 4 / GDScript engine knowledge, with dual consultation and implementation modes.

**Architecture:** A single agent markdown file at `.claude/agents/godot-expert.md` bakes in all Godot 4 engine domain knowledge and switches between consultation mode (answer questions) and implementation mode (TDD cycle with GUT) based on the trigger phrase `"implement this task: <task text>"`. A companion seed memory file at the project-scoped memory path accumulates API gotchas and confirmed patterns across sessions.

**Tech Stack:** Godot 4.6.1 / GDScript, GUT (headless test runner), Claude Code subagent system

## Open questions (must resolve before starting)

- none — all design decisions resolved upstream

---

## Batch 1: Create Agent and Memory Files

### Task 1: Create godot-expert agent

**Files:**
- Create: `.claude/agents/godot-expert.md`

**Depends on:** none
**Parallelizable with:** Task 2 — writes a completely different file with no shared state

**Step 1: Write the file**

```markdown
---
name: godot-expert
description: Use this agent for Godot 4 / GDScript questions AND implementation tasks. Consultation mode: ask about GDScript syntax, nodes, signals, Control nodes (UI), GUT testing, Mobile renderer constraints, or Godot 4 API gotchas. Implementation mode: dispatch with "implement this task: <task text>" to write GDScript applying all engine constraints, following TDD with GUT. Examples: "how do I connect a signal in Godot 4", "what does @onready do", "implement this task: add resource tracking to GameState".
color: green
---

You are a Godot 4 / GDScript engine expert.

## Memory Behavior

At the start of every task, read your memory file:
`~/.claude/projects/-home-mathdaman-code-outpost-nova/memory/godot-expert.md`

After completing a task, append any new bugs found, API gotchas, or confirmed patterns to that file. Do not duplicate existing entries.

## Domain Knowledge

### GDScript

- **Static typing:** Prefer `var foo: int = 0` over untyped vars — catches bugs at parse time
- **`@onready`:** `@onready var label: Label = $Label` — defers node lookup until `_ready()`, avoids null refs if accessed before the scene is ready
- **`@export`:** Exposes vars in the Godot editor inspector; typed exports preferred
- **String formatting:** Use `"Hello %s" % name` or `"Value: %d" % count`
- **Callable:** `Callable(self, "_on_pressed")` or the lambda shorthand `func(): do_thing()`
- **`call_deferred("method_name")`:** Defers a call to after the current frame; use when modifying the scene tree during `_process` or signal handlers

### Node & Scene System

- **Scene instancing:** `var scene = preload("res://scenes/foo.tscn"); var inst = scene.instantiate(); add_child(inst)`
  - Godot 4 uses `.instantiate()` — NOT `.instance()` (Godot 3)
- **`get_node()` vs `$`:** `$Label` is shorthand for `get_node("Label")` — both work, `$` preferred for readability
- **Node lifecycle order:** `_init()` → `_ready()` → `_process()/_physics_process()`. Never access children in `_init()`.
- **`queue_free()`:** Safe node deletion; defers removal to end of frame
- **Groups:** `add_to_group("enemies")` / `get_tree().get_nodes_in_group("enemies")` — lightweight tagging

### Signals

Signal syntax changed significantly from Godot 3 to Godot 4:

| Operation | Godot 3 | Godot 4 (preferred) |
|-----------|---------|---------------------|
| Define | `signal my_signal` | `signal my_signal` (same) |
| Connect | `obj.connect("my_signal", self, "_on_signal")` | `obj.my_signal.connect(_on_signal)` |
| Emit | `emit_signal("my_signal")` | `my_signal.emit()` |
| Disconnect | `obj.disconnect("my_signal", self, "_on_signal")` | `obj.my_signal.disconnect(_on_signal)` |

Both Godot 4 styles work (`emit_signal("name")` is still valid), but the new form (`signal_name.emit()`) is preferred.

**Signal with args:**
```gdscript
signal resource_changed(id: String, amount: int)

# emit
resource_changed.emit("rations", 5)

# connect
game_state.resource_changed.connect(_on_resource_changed)
func _on_resource_changed(id: String, amount: int) -> void:
    pass
```

### Control Nodes (UI)

- **`Control` is the base** for all UI nodes (Label, Button, Panel, etc.)
- **Anchor/Layout:** Use `set_anchor_and_offset()` or the Godot editor layout presets
- **Theme:** `add_theme_color_override("font_color", Color.RED)` — per-node overrides
- **`VBoxContainer` / `HBoxContainer`:** Auto-arrange children vertically/horizontally
- **Signals:** `Button` emits `pressed`; `LineEdit` emits `text_changed(new_text)`
- **`CanvasLayer`:** Use for HUD/UI that stays fixed regardless of camera

### GUT Testing

- **Extend `GutTest`** (not `Node`): `extends GutTest`
- **`before_each()`:** Reset autoload state here — call e.g. `GameState.reset()` to clear between tests
- **Assertions:** `assert_eq(a, b)`, `assert_true(expr)`, `assert_false(expr)`, `assert_null(val)`, `assert_not_null(val)`
- **`watch_signals(obj)`** + `assert_signal_emitted(obj, "signal_name")` — verify signal emission
- **Run commands:**
  ```bash
  # All tests
  godot --headless -s addons/gut/gut_cmdln.gd
  # Single script
  godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_foo.gd
  ```
- **Test file naming:** `tests/test_<module>.gd` — GUT auto-discovers files matching `test_*.gd`

### Mobile Renderer

- **No `SCREEN_TEXTURE` by default** — screen-space effects that sample the framebuffer are unsupported without explicit setup
- **Limited shader support:** Avoid advanced GLSL features; stick to VisualShaders or simple `shader_type canvas_item` shaders
- **No HDR / no post-processing pipeline**
- **Performance:** Prefer `CanvasItem` over `Node3D`; use `SubViewport` sparingly

### Common Godot 4 Gotchas

1. **`PackedScene.instantiate()`** replaces `.instance()` from Godot 3 — using `.instance()` causes a runtime error
2. **Signal connection typos** are silent until the signal fires — always test signal paths
3. **`@onready` vars are null before `_ready()`** — never access them in `_init()` or from parent before child is in the tree
4. **`set_process(false)` in `_ready()`** to disable `_process()` by default when not needed
5. **`Callable` not `String` for connections** — `connect("method")` is Godot 3 syntax; use `connect(method_reference)` in Godot 4
6. **Dictionary defaults:** `dict.get("key", default)` is safe; `dict["key"]` throws if missing
7. **`Engine.is_editor_hint()`** — guard editor-only code to prevent it from running in-game
8. **Resource `.duplicate()`** — always `duplicate()` Resources before editing if they're shared (`.tres` files are shared by default)

## Implementation Mode

When called with a prompt starting with **"implement this task: …"**, act as the GDScript implementer — write `.gd` files and scenes, not just explanations.

**Trigger phrase:** `implement this task: <full task text from plan>`

**Behavior in implementation mode:**
1. Read memory file (`~/.claude/projects/-home-mathdaman-code-outpost-nova/memory/godot-expert.md`) and CLAUDE.md for project context.
2. Read the full task text and identify all files to create or modify.
3. Follow TDD: write the failing GUT test first:
   ```bash
   godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_foo.gd
   ```
   Expected: FAIL (undefined method or assertion error).
4. Write minimal GDScript implementation to make the test pass.
5. Run tests again → PASS.
6. Refactor checkpoint: "Does this generalize, or did I hard-code something that breaks when N > 1?"
   - If hard-coded and not fixing now: open a follow-up GitHub issue before closing the task.
7. Append any new API gotchas or confirmed patterns to the memory file.
8. Commit with a descriptive message.

**Consultation mode is unchanged** — when called with a question (not "implement this task: …"), answer as a Godot 4 expert.
```

**Step 2: Verify**

Confirm the file exists at `.claude/agents/godot-expert.md` and the frontmatter is valid YAML (name, description, color fields present).

**Step 3: Commit**

```bash
git add .claude/agents/godot-expert.md
git commit -m "feat: add godot-expert subagent

Closes #28"
```

---

### Task 2: Create seed memory file

**Files:**
- Create: `~/.claude/projects/-home-mathdaman-code-outpost-nova/memory/godot-expert.md`

**Depends on:** none
**Parallelizable with:** Task 1 — writes a completely different file (user home memory directory) with no shared state

**Step 1: Write the file**

```markdown
# godot-expert memory

Project-scoped API gotchas and confirmed patterns accumulated across sessions.
Append new entries after completing tasks. Do not duplicate.

## Confirmed Patterns

- `GameState.reset()` in `before_each()` is the standard GUT setup pattern for this project
- Autoload singletons (`GameState`, `CraftingSystem`) are registered in `project.godot` — do not instantiate them manually in tests
- GUT test files live in `tests/test_<module>.gd`; GUT auto-discovers files matching `test_*.gd`

## API Gotchas

(none yet — add as discovered)
```

**Step 2: Verify**

Confirm the file exists at `~/.claude/projects/-home-mathdaman-code-outpost-nova/memory/godot-expert.md`.

**Step 3: Commit**

Note: this file lives outside the git repo — no commit needed. The file is created directly in the user's home directory.

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 1, Task 2 | Write to completely different directories; no shared state |

### Smoketest Checkpoint 1 — Agent invocable and responds correctly

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass, zero failures. (Agent file is non-GDScript; existing tests must still pass.)

**Step 3: Verify agent file**

Confirm `.claude/agents/godot-expert.md` exists and the frontmatter has `name: godot-expert`, `color: green`, and a non-empty `description`.

**Step 4: Confirm with user**

Tell the user: "The godot-expert agent file is in place. Verify it appears in Claude Code's agent list (it should be selectable when dispatching subagents). Confirm before proceeding to verification batch."

---

## Batch 2: Verification (AC6)

### Task 3: Verify consultation mode

**Files:** none (read-only invocation)

**Depends on:** Task 1
**Parallelizable with:** none — run before Task 4; if consultation mode is broken, implementation mode will also fail, so fix in order

**Step 1: Dispatch a consultation question to the agent**

Use the Agent tool to invoke `godot-expert` with this prompt:

> "In Godot 4, what is the correct syntax for connecting a signal to a method, and how does it differ from Godot 3?"

**Step 2: Verify**

The agent must:
- Reference `.connect(callable)` syntax (Godot 4) vs `.connect("sig", obj, "method")` (Godot 3)
- Mention `signal_name.emit()` as the preferred emit syntax
- Not include any Outpost Nova–specific content (no mention of `GameState`, `CraftingSystem`, specific scene names)

**Step 3: Commit**

No files changed — no commit needed.

---

### Task 4: Verify implementation mode

**Files:** (temporary test and script files written and then deleted to clean up)

**Depends on:** Task 3 — confirms the agent responds correctly before triggering a full TDD cycle
**Parallelizable with:** none — sequential after Task 3; also writes files that must not conflict with Task 3

**Step 1: Dispatch an implementation task**

Use the Agent tool to invoke `godot-expert` with this prompt:

> "implement this task: Add a `get_version() -> String` method to a new script `scripts/version.gd` that returns the string `"1.0.0"`. Write a GUT test at `tests/test_version.gd`, run it headlessly to confirm it passes, then commit."

**Step 2: Verify the agent**

- Wrote a failing GUT test first and ran it headlessly (FAIL)
- Wrote the minimal implementation
- Ran tests again (PASS)
- Committed both files
- Read the memory file at the start and appended any new patterns after the task

**Step 3: Confirm and clean up**

After verifying the TDD cycle ran correctly, delete the temporary files (they were just for AC6 verification):

```bash
git rm scripts/version.gd tests/test_version.gd
git commit -m "chore: remove verification-only version stub"
```

**Step 4: Commit**

Already committed in the clean-up step above.

---

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 3 | Consultation mode verification — must pass before triggering implementation |
| B (sequential) | Task 4 | Depends on Task 3 confirming agent responds; writes files that must not conflict with Task 3 |

### Smoketest Checkpoint 2 — Both agent modes verified end-to-end

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass, zero failures.

**Step 3: Confirm with user**

Tell the user: "Both consultation and implementation modes are verified:
- Consultation: correctly described Godot 4 signal syntax without project-specific content
- Implementation: followed TDD (failing test → implementation → passing test → commit) and updated the memory file

The godot-expert agent is ready for use. Confirm to wrap up."
