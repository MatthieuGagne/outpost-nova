# DialogueRunner Line Provider Wiring Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Stop `TextLineProvider` from pushing `YarnProject is not set` on the first NPC conversation, by wiring an explicit line provider into `scenes/main.tscn` so YarnSpinner never runs its lazy-construction path. (GitHub issue #98)

**Architecture:** `DialogueRunner.LineProvider`'s getter constructs a `TextLineProvider`, calls `AddChild` on it — which fires `_Ready()` synchronously — and only *then* assigns `YarnProject`. The provider therefore always sees a null project at `_Ready`, no matter how or when the runner's own project is assigned. The fix is to give the runner a scene-declared `TextLineProvider` child whose `YarnProject` is already set before it enters the tree, so the lazy branch is never taken. `scripts/main.gd` is not modified.

**Tech Stack:** Godot 4.7.1 (mono), GDScript, YarnSpinner-Godot addon (C#), GUT for tests.

## Open questions (must resolve before starting)

- None. All decisions resolved in the grilling session on 2026-08-25 (see "Decisions" below).

## Decisions

| Decision | Choice |
|---|---|
| Fix approach | Explicit `TextLineProvider` child node declared in `scenes/main.tscn` |
| `scripts/main.gd` | **Unchanged** — the runtime `SetProject()` call stays as a no-op safeguard |
| Verification | Manual smoketest **plus** a GUT test inspecting `PackedScene.get_state()` |
| Scene edit method | Hand-edit the `.tscn` text (not the Godot editor inspector) |
| Smoketest acceptance | Capture full Godot output to a log file and grep it — zero hits required |
| Task ordering | Test first (observed failing), then the scene fix |

## Verified facts (do not re-derive)

These were confirmed empirically against Godot 4.7.1 on 2026-08-25 by loading the C# scripts and dumping `get_script_property_list()`. **Use these exact names — do not guess or snake_case them.**

`DialogueRunner.cs` exported properties:

```
yarnProject | Object (YarnProject)
variableStorage | Object (Node)
PrintProjectErrors | bool
lineProvider | Object (Node)
dialoguePresenters | Array[Node]
autoStart | bool
startNode | String
runSelectedOptionAsLine | bool
```

`TextLineProvider.cs` exported properties:

```
textLanguageCode | String
YarnProject | Object (YarnProject)
```

Two consequences:

1. `lineProvider` is a **Node** reference, so in a `.tscn` it must be declared through the node's `node_paths=PackedStringArray(...)` list, exactly like the existing `dialoguePresenters`.
2. The existing line `auto_start = false` in `scenes/main.tscn` is **not a real property** — the C# export is `autoStart`. Godot silently discards it on load. It is harmless (`autoStart` defaults to `false`), but Task 2 corrects it to `autoStart = false` since we are editing that exact node block anyway.

**Scope check:** `grep -rln "DialogueRunner" scenes/ scripts/` returns only `scenes/main.tscn` and `scripts/YarnGameState.cs`. There is exactly one `DialogueRunner` in the project, so this is a single-scene fix.

**Known behavior change:** with `yarnProject` assigned in the scene, `DialogueRunner._Ready()` now runs `CheckCompilationErrors()`, which it previously never did (the project was null at `_ready`). If the Yarn project has compile errors, that error will now appear at startup. That is a real problem being surfaced, not new noise — but do not be surprised by it during the smoketest.

---

## Batch 1 — Wire the line provider

### Task 1: Failing GUT test for DialogueRunner scene wiring

**Files:**
- Create: `tests/test_dialogue_wiring.gd`

**Depends on:** none
**Parallelizable with:** none — Task 2 must not run until this test has been *observed failing*, which is the entire point of the ordering decision. This test uses `PackedScene.get_state()`, an API this repo has never used; if it is subtly wrong (wrong property name, wrong node lookup) it would pass vacuously against the fixed scene and guard nothing.

**Step 1: Write the failing GUT test**

Create `tests/test_dialogue_wiring.gd` with exactly this content:

```gdscript
# tests/test_dialogue_wiring.gd
# Guards the DialogueRunner <-> TextLineProvider wiring in main.tscn (issue #98).
# YarnSpinner's DialogueRunner.LineProvider getter calls AddChild() before it
# assigns YarnProject, so a lazily-created provider always errors in _Ready().
# The scene must therefore declare the provider explicitly.
extends GutTest

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const RUNNER_NODE_NAME := "DialogueRunner"
const PROVIDER_NODE_NAME := "TextLineProvider"
const PROVIDER_NODE_PATH := "DialogueRunner/TextLineProvider"
const YARN_PROJECT_PATH := "res://data/dialogue/outpost-nova.yarnproject"

var _state: SceneState

func before_each():
	var packed: PackedScene = load(MAIN_SCENE_PATH)
	_state = packed.get_state()

func _find_node_index(node_name: String) -> int:
	for i in _state.get_node_count():
		if _state.get_node_name(i) == node_name:
			return i
	return -1

func _get_property(node_index: int, property_name: String) -> Variant:
	for p in _state.get_node_property_count(node_index):
		if _state.get_node_property_name(node_index, p) == property_name:
			return _state.get_node_property_value(node_index, p)
	return null

func test_dialogue_runner_exists_in_scene():
	assert_ne(_find_node_index(RUNNER_NODE_NAME), -1,
		"main.tscn must contain a %s node" % RUNNER_NODE_NAME)

func test_dialogue_runner_has_yarn_project_assigned():
	var idx := _find_node_index(RUNNER_NODE_NAME)
	var project = _get_property(idx, "yarnProject")
	assert_not_null(project,
		"DialogueRunner.yarnProject must be assigned in the scene, not only at runtime")
	assert_eq(project.resource_path, YARN_PROJECT_PATH)

func test_dialogue_runner_line_provider_points_at_provider_node():
	var idx := _find_node_index(RUNNER_NODE_NAME)
	var path = _get_property(idx, "lineProvider")
	assert_not_null(path,
		"DialogueRunner.lineProvider must be wired, or YarnSpinner lazily builds a broken one")
	assert_eq(str(path), PROVIDER_NODE_NAME)

func test_text_line_provider_node_exists_under_runner():
	var idx := _find_node_index(PROVIDER_NODE_NAME)
	assert_ne(idx, -1, "main.tscn must contain an explicit %s node" % PROVIDER_NODE_NAME)
	assert_eq(str(_state.get_node_path(idx)), PROVIDER_NODE_PATH)

func test_text_line_provider_has_yarn_project_assigned():
	var idx := _find_node_index(PROVIDER_NODE_NAME)
	var project = _get_property(idx, "YarnProject")
	assert_not_null(project,
		"TextLineProvider.YarnProject must be set in the scene so it is valid at _Ready()")
	assert_eq(project.resource_path, YARN_PROJECT_PATH)
```

**Step 2: Run test to verify it fails**

```powershell
dotnet build "Outpost Nova.csproj"
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_dialogue_wiring.gd" -gexit
```

Expected: **4 of 5 tests FAIL.**
- `test_dialogue_runner_exists_in_scene` — PASSES (the node is already there)
- `test_dialogue_runner_has_yarn_project_assigned` — FAILS (`yarnProject` is null)
- `test_dialogue_runner_line_provider_points_at_provider_node` — FAILS (`lineProvider` is null)
- `test_text_line_provider_node_exists_under_runner` — FAILS (index is `-1`)
- `test_text_line_provider_has_yarn_project_assigned` — FAILS (index is `-1`)

If the failure counts differ from this, **stop** — the test is not measuring what it claims to and must be corrected before Task 2.

**Step 3: Write minimal implementation**

None in this task. The implementation is Task 2 — this task deliberately ends on red.

**Step 4: Run tests to verify they pass**

Deferred to Task 2 Step 2.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?"

The helpers `_find_node_index` and `_get_property` match by name across all nodes, so a second `DialogueRunner` in a future scene would need a path-scoped lookup rather than a name-scoped one. That is acceptable today — verified above that exactly one `DialogueRunner` exists project-wide. Do **not** generalize preemptively (YAGNI). If a second runner is ever added, this test must be revisited.

**Step 6: Commit**

```powershell
git add tests/test_dialogue_wiring.gd
git commit -m "test: guard DialogueRunner line provider wiring in main.tscn (#98)"
```

---

### Task 2: Wire the explicit TextLineProvider in main.tscn

**Files:**
- Modify: `scenes/main.tscn`

**Depends on:** Task 1 — the test must have been observed failing first.
**Parallelizable with:** none — it is the sole implementation task in this batch and depends on Task 1's red state.

**Step 1: Write the content**

Three edits to `scenes/main.tscn`.

**Edit 1 — bump the load step count** (line 1). One new `ext_resource` is being added.

Replace:
```
[gd_scene load_steps=14 format=3]
```
with:
```
[gd_scene load_steps=15 format=3]
```

**Edit 2 — add the `TextLineProvider` script resource.** Ids 1-10 are taken, so use `11`. Insert immediately after the existing id `9` line:

Replace:
```
[ext_resource type="Resource" uid="uid://b63maae1xqnff" path="res://data/dialogue/outpost-nova.yarnproject" id="9"]
```
with:
```
[ext_resource type="Resource" uid="uid://b63maae1xqnff" path="res://data/dialogue/outpost-nova.yarnproject" id="9"]
[ext_resource type="Script" path="res://addons/YarnSpinner-Godot/Runtime/LineProviders/TextLineProvider.cs" id="11"]
```

**Edit 3 — rewrite the `DialogueRunner` node block and add the provider child.**

Replace:
```
[node name="DialogueRunner" type="Node" parent="." groups=["dialogue_runner"] node_paths=PackedStringArray("dialoguePresenters")]
process_mode = 3
script = ExtResource("8")
auto_start = false
dialoguePresenters = [NodePath("../DialogueBox")]
```
with:
```
[node name="DialogueRunner" type="Node" parent="." groups=["dialogue_runner"] node_paths=PackedStringArray("dialoguePresenters", "lineProvider")]
process_mode = 3
script = ExtResource("8")
autoStart = false
yarnProject = ExtResource("9")
dialoguePresenters = [NodePath("../DialogueBox")]
lineProvider = NodePath("TextLineProvider")

[node name="TextLineProvider" type="Node" parent="DialogueRunner"]
script = ExtResource("11")
YarnProject = ExtResource("9")
```

Notes on this block, so it is not "fixed" incorrectly later:
- `lineProvider` is added to `node_paths` because it holds a **Node** reference; without that entry Godot would not resolve the `NodePath` at instantiation.
- `NodePath("TextLineProvider")` is relative to the `DialogueRunner` node that owns the property, not to the scene root.
- `auto_start` → `autoStart` corrects the silently-discarded property documented in "Verified facts". The value is unchanged.
- The `TextLineProvider` node must be declared **after** the `DialogueRunner` block, since it declares `parent="DialogueRunner"`.

**Step 2: Verify**

First, the automated check — the Task 1 test must now go green:

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_dialogue_wiring.gd" -gexit
```
Expected: **all 5 tests PASS, zero failures.**

Second, confirm the hand-written `.tscn` is well-formed by opening it in the editor:

```powershell
./tools/godot.ps1
```
Open `scenes/main.tscn`. Confirm: no parse errors in the Output panel; a `TextLineProvider` node appears under `DialogueRunner`; selecting `DialogueRunner` shows `Yarn Project` and `Line Provider` populated in the Inspector. **Close the editor without saving** — an editor save would rewrite the scene and produce diff noise.

**Step 3: Commit**

```powershell
git add scenes/main.tscn
git commit -m "fix: wire explicit TextLineProvider into DialogueRunner (#98)"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 1 | Must complete and be observed **failing** before Task 2 begins |
| B (sequential) | Task 2 | Depends on Task 1's red state; turns the same test green |

No parallelism is available in this batch: it is a two-step red/green TDD pair on a single defect, and Task 2 is validated exclusively by the test Task 1 creates.

---

### Smoketest Checkpoint 1 — no `YarnProject is not set` error on first conversation

**Step 1: Fetch and merge latest master**

```powershell
git fetch origin
git merge origin/master
```

**Step 2: Build and run all GUT tests**

```powershell
dotnet build "Outpost Nova.csproj"
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: all tests pass, zero failures. This includes the five pre-existing test scripts (`test_clock_manager`, `test_crafting_system`, `test_game_state`, `test_resource_plot`, `test_ui_input`) plus the new `test_dialogue_wiring`.

This checkpoint does not modify any existing test. If a pre-existing test fails, **stop and ask the user** before touching it.

**Step 3: Launch the game with full output captured**

```powershell
./tools/godot.ps1 -Console --path . *> "$env:TEMP\outpost-nova-issue98.log"
```

If this is the first launch in a fresh worktree, Godot must import assets once — open the editor (`./tools/godot.ps1`) and let importing finish before running the capture, otherwise the log fills with unrelated missing-resource errors for `res://assets/fonts/m5x7.ttf` and the theme that depends on it.

**Step 4: Confirm with user**

Tell the user to, in the running game:
1. Walk up to any NPC and press the interact key to start a conversation.
2. Confirm the dialogue box appears and lines render with their text (not blank, not a raw line ID).
3. Advance through at least two lines, then end the conversation and quit the game.

Then check the captured log:

```powershell
Select-String -Path "$env:TEMP\outpost-nova-issue98.log" -Pattern "YarnProject is not set"
```
Expected: **no output** (zero matches).

Also scan for anything newly surfaced by the `CheckCompilationErrors()` behavior change:

```powershell
Select-String -Path "$env:TEMP\outpost-nova-issue98.log" -Pattern "compilation errors"
```
Expected: no output. If this *does* match, the Yarn project has real compile errors that were previously hidden — report them to the user rather than reverting the fix.

Wait for the user's confirmation that dialogue rendered correctly before proceeding.
