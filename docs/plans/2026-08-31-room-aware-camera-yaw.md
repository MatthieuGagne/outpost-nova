# Room-Aware Camera Yaw Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `Player3D` derive its movement yaw from the `Camera3D` actually rendering it, and cover the previously untested camera-space wiring with headless GUT tests (issue #114).

**Architecture:** `Player3D._physics_process` currently rotates input by the global constant `WorldScale.CAMERA_YAW_DEGREES`. It will instead call a new private `_camera_yaw_degrees()` that reads `get_viewport().get_camera_3d().global_rotation_degrees.y` every physics frame, falling back silently to the contract constant when no camera exists. `SpriteFacing`, `RoomCamera`, and `WorldScale` are untouched — their signatures and constants stay exactly as they are, so all existing `SpriteFacing` and `RoomCamera` assertions remain valid. The new tests drive real global input (`Input.action_press`) through the instanced `player3d.tscn` and assert both world velocity and facing string, parameterised over two camera yaws.

**Tech Stack:** Godot 4.7.1 (mono), GDScript, GUT.

## Open questions (must resolve before starting)

None. All decisions were settled in the grill-me pass — see "Decisions already made" below.

---

## Decisions already made (do not re-litigate)

| Decision | Choice |
|---|---|
| When yaw is resolved | Every physics frame — not cached at `_ready` (nothing orders camera before player in a room scene) |
| No-camera behaviour | Silent fallback to `WorldScale.CAMERA_YAW_DEGREES`, documented in the method's doc comment. No `push_warning` |
| How yaw is read | `camera.global_rotation_degrees.y` — `global_` so a camera under a rotated parent resolves correctly |
| Test camera setup | Two `RoomCamera` instances: default (`use_contract_angle = true` → 45°) and hand-authored (`use_contract_angle = false` → 90°) |
| Input mechanism | Real global input via `Input.action_press` / `Input.action_release`, with an `after_each()` release net |
| Accessor visibility | Private `_camera_yaw_degrees()`; the fallback is proven behaviourally through `velocity` |
| AC4 evidence | Headless test + a throwaway manual flip during smoketest. **No new room scene is committed** |
| Docs | Remove `player3d.gd:9-13` AND rewrite the `scenes/poc3d/README.md` Controls paragraph. `docs/index.md` needs no change |

**Explicitly out of scope:** a second committed POC room (#103 owns real rooms), any change to `SpriteFacing` / `RoomCamera` / `WorldScale`, any camera-rotation input.

## Two risks with pre-agreed fallbacks

Both surface at a task's "run it and expect FAIL" step. Do not silently work around them — apply the stated fallback and note it in the commit message.

1. **Headless input may not reach `Input.get_axis`.** If a test fails because `velocity` stayed `Vector3.ZERO` (rather than failing on a value mismatch), replace `Input.action_press("ui_up")` with:
   ```gdscript
   var ev := InputEventAction.new()
   ev.action = "ui_up"
   ev.pressed = true
   Input.parse_input_event(ev)
   ```
   and the matching `pressed = false` event for release. Do this **before** writing any implementation code.
2. **The GUT runner's viewport may already contain a `Camera3D`.** Task 2's fallback test asserts this is not the case. If that assertion fails, the fallback is unreachable behaviourally: make the accessor public (`get_camera_yaw_degrees()`) and assert its return value directly instead.

---

## Batch 1 — camera-space wiring coverage and room-aware yaw

### Task 1: Cover the existing camera-space wiring at the contract yaw

This task adds **no production code**. It closes Part 1 of #114: the maths in `SpriteFacing` is proven, but `Player3D` calling it correctly is not. These tests are expected to **pass on the first run** — the whole point is that today's behaviour is correct but unguarded. Step 2 therefore proves the tests have teeth by mutation instead of by a red run.

**Files:**
- Modify: `tests/test_poc3d_player3d.gd`

**Depends on:** none
**Parallelizable with:** none — Task 2 writes the same test file, and Task 2's implementation must not land before this characterization baseline is committed.

**Step 1: Add the constants, the input release net, and the room helper**

Append to the top of `tests/test_poc3d_player3d.gd`, directly under the existing `const SIZE_TOLERANCE := 0.0001`:

```gdscript
## Velocity assertions compare against SPEED-scaled unit vectors; 0.01 units/s is far
## below any real movement and far above float noise from the yaw rotation.
const VELOCITY_TOLERANCE := 0.01

## The four actions Player3D reads. Released after every test so a failed assertion
## mid-test cannot leave a key stuck down and cascade into unrelated failures.
const MOVEMENT_ACTIONS := ["ui_up", "ui_down", "ui_left", "ui_right"]

## The yaw used for the "room authors its own angle" case. 90 degrees on purpose: it
## makes screen-up map to exactly (-1, 0, 0), so the expected velocity is a checkable
## fact rather than a copied float.
const HAND_AUTHORED_YAW_DEGREES := 90.0


func after_each():
	for action in MOVEMENT_ACTIONS:
		Input.action_release(action)


## Builds the minimum of a room: a RoomCamera made current, plus the player scene.
## use_contract_angle = true lets RoomCamera stamp WorldScale.CAMERA_YAW_DEGREES;
## false leaves the rotation set here alone, which is the AC4 case.
func _player_under_camera(yaw_degrees: float, use_contract_angle: bool) -> Player3D:
	var camera := RoomCamera.new()
	camera.use_contract_angle = use_contract_angle
	if not use_contract_angle:
		camera.rotation_degrees = Vector3(
			WorldScale.CAMERA_PITCH_DEGREES, yaw_degrees, 0.0)
	add_child_autofree(camera)
	camera.make_current()
	var player: Player3D = load("res://scenes/poc3d/player3d.tscn").instantiate()
	add_child_autofree(player)
	await wait_frames(1)
	return player
```

Then append these two tests to the end of the file:

```gdscript
func test_screen_up_walks_away_from_the_contract_camera_and_shows_the_up_sprite():
	# The camera is yawed 45 degrees, so "away from the camera" is the -X -Z diagonal.
	# Facing must still be "up": it comes from the RAW input, never from the rotated
	# velocity. Deriving it from velocity is the failure mode PRD 2 (#102) named as its
	# highest risk — the up sprite while sliding diagonally across the screen.
	var player := await _player_under_camera(WorldScale.CAMERA_YAW_DEGREES, true)
	Input.action_press("ui_up")
	await wait_physics_frames(2)
	var expected := -sqrt(0.5) * Player3D.SPEED
	assert_almost_eq(player.velocity.x, expected, VELOCITY_TOLERANCE)
	assert_almost_eq(player.velocity.z, expected, VELOCITY_TOLERANCE)
	assert_eq(player.get_facing(), "up",
		"facing must come from the raw input, not from the rotated velocity")


func test_releasing_input_keeps_the_last_facing_and_returns_to_idle():
	# Automates AC2 of #102, which was manual-only until now.
	var player := await _player_under_camera(WorldScale.CAMERA_YAW_DEGREES, true)
	Input.action_press("ui_up")
	await wait_physics_frames(2)
	Input.action_release("ui_up")
	await wait_physics_frames(2)
	assert_eq(player.get_facing(), "up", "released input keeps the last facing")
	assert_eq(player.get_node("PixelSprite3D").animation, "idle_up")
	assert_almost_eq(player.velocity.length(), 0.0, VELOCITY_TOLERANCE)
```

**Step 2: Run the tests, then prove they have teeth**

Run:
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_player3d.gd" -gexit
```
Expected: **PASS** (8 tests). This is correct — today's wiring is right, it was just unguarded.

If instead the velocity assertions fail with `velocity` at `0.0`, headless input is not reaching `Input.get_axis`: apply **Risk 1's** `Input.parse_input_event` fallback and re-run before continuing.

Now the mutation check. Temporarily edit `scripts/poc3d/player3d.gd`, changing the last line of `_physics_process` from:
```gdscript
	_update_animation(input)
```
to:
```gdscript
	_update_animation(Vector2(velocity.x, velocity.z))
```
Re-run the same command.
Expected: **FAIL** on `test_screen_up_walks_away_from_the_contract_camera_and_shows_the_up_sprite`, reporting a facing other than `"up"`.

**Revert that edit** and re-run:
```powershell
git checkout -- scripts/poc3d/player3d.gd
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_player3d.gd" -gexit
```
Expected: **PASS** (8 tests).

If the mutated run passed, the test is not actually observing facing — stop and fix the test before continuing.

**Step 3: No implementation**

This task is coverage only. `scripts/poc3d/player3d.gd` must be unchanged at commit time — confirm with `git status`.

**Step 4: Run the whole suite**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: all tests pass, zero failures. Pay attention to test files that run *after* this one — if any newly fail, the `after_each()` release net is not doing its job.

**Step 5: Refactor checkpoint**

Ask: "Does `_player_under_camera` generalize, or did I hard-code something that breaks when N > 1?" It takes both the yaw and the `use_contract_angle` flag as parameters precisely so Task 2 can reuse it unchanged. If Task 2 would need to copy it rather than call it, fix that now.

**Step 6: Commit**

```powershell
git add tests/test_poc3d_player3d.gd
git commit -m "test: cover Player3D's camera-space wiring and facing retention (#114)"
```

---

### Task 2: Resolve the yaw from the active camera

**Files:**
- Modify: `scripts/poc3d/player3d.gd`
- Modify: `tests/test_poc3d_player3d.gd`

**Depends on:** Task 1 — writes the same test file and reuses its `_player_under_camera` helper, `VELOCITY_TOLERANCE`, and `HAND_AUTHORED_YAW_DEGREES`.
**Parallelizable with:** none — same two files as Task 1, sequential by construction.

**Step 1: Write the failing tests**

Append to `tests/test_poc3d_player3d.gd`:

```gdscript
func test_a_room_that_authors_its_own_yaw_gets_controls_that_match_the_screen():
	# AC4. RoomCamera.use_contract_angle = false leaves the hand-authored rotation
	# alone; Player3D must follow the camera rather than the shared constant. At yaw 90
	# the camera looks down -X, so screen-up is exactly (-1, 0, 0).
	var player := await _player_under_camera(HAND_AUTHORED_YAW_DEGREES, false)
	Input.action_press("ui_up")
	await wait_physics_frames(2)
	assert_almost_eq(player.velocity.x, -Player3D.SPEED, VELOCITY_TOLERANCE)
	assert_almost_eq(player.velocity.z, 0.0, VELOCITY_TOLERANCE)
	assert_eq(player.get_facing(), "up",
		"facing is camera-space and must not change with the camera yaw")


func test_without_a_camera_the_yaw_falls_back_to_the_contract_angle():
	# The documented fallback. Asserted through velocity rather than through a getter,
	# so it also proves the call site uses the resolved value.
	var player: Player3D = load("res://scenes/poc3d/player3d.tscn").instantiate()
	add_child_autofree(player)
	await wait_frames(1)
	assert_null(player.get_viewport().get_camera_3d(),
		"this test is only meaningful with no Camera3D in the runner's viewport")
	Input.action_press("ui_up")
	await wait_physics_frames(2)
	var expected := -sqrt(0.5) * Player3D.SPEED
	assert_almost_eq(player.velocity.x, expected, VELOCITY_TOLERANCE)
	assert_almost_eq(player.velocity.z, expected, VELOCITY_TOLERANCE)
```

**Step 2: Run tests to verify they fail**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_player3d.gd" -gexit
```
Expected: `test_a_room_that_authors_its_own_yaw_gets_controls_that_match_the_screen` **FAILS** — `velocity.x` is about `-3.54` (the 45° diagonal) instead of `-5.0`, and `velocity.z` is about `-3.54` instead of `0.0`. That is exactly the silent mismatch #114 describes.

`test_without_a_camera_the_yaw_falls_back_to_the_contract_angle` is expected to **PASS** already — it guards the fallback against the change about to be made. If its `assert_null` fails instead, apply **Risk 2's** public-accessor fallback.

**Step 3: Write minimal implementation**

In `scripts/poc3d/player3d.gd`, change the one line in `_physics_process` to:

```gdscript
	velocity = SpriteFacing.input_to_world(input, _camera_yaw_degrees()) * SPEED
```

and add this method immediately after `_physics_process`, above `_update_animation`:

```gdscript
## Yaw of the Camera3D actually rendering this player, so a room that authors its own
## angle (RoomCamera.use_contract_angle = false) gets controls consistent with what is
## on screen. Read every physics frame rather than cached at _ready: nothing orders the
## camera before the player in a room scene, and a cached null would silently mis-steer.
## global_ so a camera parented under a rotated node still resolves correctly.
##
## Fallback: WorldScale.CAMERA_YAW_DEGREES when the viewport has no camera. Silent on
## purpose — a room with no Camera3D renders a black screen, so a warning would add no
## diagnostic value, and the no-camera path is the normal one under headless tests.
func _camera_yaw_degrees() -> float:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return WorldScale.CAMERA_YAW_DEGREES
	return camera.global_rotation_degrees.y
```

Do **not** touch `_update_animation` — it must keep receiving the raw `input`.

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_player3d.gd" -gexit
```
Expected: **PASS** (10 tests) — including both of Task 1's tests, which prove the contract-angle path still resolves to 45° now that it goes through the camera.

Then the full suite:
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: all tests pass, zero failures. `test_poc3d_sprite_facing.gd` and `test_poc3d_room_camera.gd` must be untouched and still green — if either changed, the implementation strayed outside scope.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" Two specific checks:
- `WorldScale.CAMERA_YAW_DEGREES` must now appear in `player3d.gd` exactly once, inside the fallback branch. Verify: `grep -n "CAMERA_YAW_DEGREES" scripts/poc3d/player3d.gd`
- The method must read the yaw off the camera, not off `WorldScale`, when a camera exists — a second room at a third angle must need zero further changes.

If either fails and you are not fixing it now, open a follow-up GitHub issue before closing this task.

**Step 6: Commit**

```powershell
git add scripts/poc3d/player3d.gd tests/test_poc3d_player3d.gd
git commit -m "fix: derive Player3D's movement yaw from the active camera (#114)"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 1 | Establishes the test helper and the characterization baseline |
| B (sequential) | Task 2 | Depends on Task 1 — same test file, reuses `_player_under_camera` |

No parallelism is available in this batch: both tasks write `tests/test_poc3d_player3d.gd`, and Task 2's red run is only meaningful once Task 1's baseline is green and committed.

### Smoketest Checkpoint 1 — controls still feel right, and a non-contract room now steers correctly

**Step 1: Fetch and merge latest master**
```powershell
git fetch origin; git merge origin/master
```

**Step 2: Run all GUT tests**
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: All tests pass, zero failures.

**Step 3: Launch the game and verify the contract angle is unchanged**
```powershell
dotnet build "Outpost Nova.csproj"
./tools/godot.ps1 --path .
```
Run `scenes/poc3d/poc_entry.tscn`. With the arrow keys, confirm nothing regressed: up walks the character *away* from the camera along the diagonal while showing the up sprite, down walks toward the camera, left/right track the screen axes, and releasing a key leaves the character idle in the direction it was last heading.

**Step 4: Verify AC4 by hand, then revert**

In the Godot editor open `scenes/poc3d/rooms/test_room.tscn`, select the `RoomCamera` node, and in the Inspector:
- uncheck **Use Contract Angle**
- set **Rotation** to `(-35, 135, 0)`

Save and run the POC again. The room is now viewed from the opposite diagonal. Confirm that **up still walks the character away from the camera** — before this change it would have walked sideways across the screen.

Then **revert the scene** — nothing here is committed:
```powershell
git checkout -- scenes/poc3d/rooms/test_room.tscn
git status
```
Expected: `test_room.tscn` is not listed as modified.

**Step 5: Confirm with user**

Report both observations (contract angle unchanged; 135° room steers correctly) and confirm `test_room.tscn` is clean. Wait for confirmation before proceeding to Batch 2.

---

## Batch 2 — retire the stale limitation notes

### Task 3: Remove the stale limitation comment in `player3d.gd`

**Files:**
- Modify: `scripts/poc3d/player3d.gd`

**Depends on:** Task 2 — the comment only becomes false once the implementation lands.
**Parallelizable with:** Task 4 — different files, no shared symbols.

**Step 1: Write the content**

Delete the `Known limitation` block at the top of `scripts/poc3d/player3d.gd` (lines 9-13), which currently reads:

```gdscript
##
## Known limitation: _physics_process rotates input by the constant
## WorldScale.CAMERA_YAW_DEGREES, not by the room's actual Camera3D. RoomCamera exposes
## use_contract_angle for a room to author a different angle; a room that opts out today
## would get silently mismatched controls, with no error and no test failure.
```

Replace it with:

```gdscript
##
## The camera yaw is read from the Camera3D actually rendering the player — see
## _camera_yaw_degrees() — so a room may author its own angle via
## RoomCamera.use_contract_angle = false without desyncing the controls (#114).
```

The two lines above the deleted block (`## PRD 2 (#102) R5/R6/R7. ...`) stay exactly as they are.

**Step 2: Verify**

```powershell
grep -n "Known limitation" scripts/poc3d/player3d.gd
```
Expected: no output.

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: all tests pass — a comment edit must not change behaviour, and this confirms no code was caught in the deletion.

**Step 3: Commit**

```powershell
git add scripts/poc3d/player3d.gd
git commit -m "docs: retire the stale camera-yaw limitation note (#114)"
```

---

### Task 4: Update the POC README's Controls section

**Files:**
- Modify: `scenes/poc3d/README.md`

**Depends on:** Task 2 — describes behaviour that only exists once the implementation lands.
**Parallelizable with:** Task 3 — different files, no shared symbols.

**Step 1: Write the content**

In the `### Controls` section, replace this paragraph (it ends at "mean the same thing."):

```markdown
The player reads `ui_left` / `ui_right` / `ui_up` / `ui_down` (Godot's default
arrow-key bindings — `project.godot` defines no overrides) via
`Input.get_axis()` in `scripts/poc3d/player3d.gd`. Input is camera-relative:
"up" moves the player away from the camera along the room's authored yaw, not
along world -Z. There is no camera rotation anywhere in the POC — every room
inherits the fixed yaw from `WorldScale.CAMERA_YAW_DEGREES` (45°) — so
camera-relative and room-relative currently mean the same thing.
```

with:

```markdown
The player reads `ui_left` / `ui_right` / `ui_up` / `ui_down` (Godot's default
arrow-key bindings — `project.godot` defines no overrides) via
`Input.get_axis()` in `scripts/poc3d/player3d.gd`. Input is camera-relative:
"up" moves the player away from the camera along the room's authored yaw, not
along world -Z.

That yaw is read every physics frame from the `Camera3D` actually rendering the
player (`Player3D._camera_yaw_degrees()`), so a room that sets
`RoomCamera.use_contract_angle = false` and hand-authors its own angle gets
controls that match what is on screen. When the viewport has no camera at all —
headless tests, mainly — the yaw falls back silently to
`WorldScale.CAMERA_YAW_DEGREES` (45°).

There is still no camera *rotation* anywhere in the POC: the angle is authored
per room and fixed at runtime.
```

Leave the `### The two-function facing contract` section below it unchanged — it is still accurate.

**Step 2: Verify**

```powershell
grep -n "currently mean the same thing" scenes/poc3d/README.md
```
Expected: no output.

Read the rewritten section top to bottom and confirm it names `_camera_yaw_degrees()`, `use_contract_angle`, and the fallback constant.

**Step 3: Commit**

```powershell
git add scenes/poc3d/README.md
git commit -m "docs: describe the room-aware camera yaw in the POC README (#114)"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 3, Task 4 | Different output files (`player3d.gd` vs `README.md`), no shared state; both depend only on Task 2 |

### Smoketest Checkpoint 2 — the change is complete and nothing stale remains

**Step 1: Fetch and merge latest master**
```powershell
git fetch origin; git merge origin/master
```

**Step 2: Run all GUT tests**
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: All tests pass, zero failures.

**Step 3: Launch the game and confirm no regression**
```powershell
./tools/godot.ps1 --path .
```
Run `scenes/poc3d/poc_entry.tscn` and walk in all four directions once. Nothing should differ from Checkpoint 1 — this is a docs-only batch.

**Step 4: Confirm the acceptance criteria with the user**

Walk #114's ACs one by one:
- AC1 — two distinct yaws (45° and 90°), both asserting velocity *and* facing.
- AC2 — release retains facing and returns to `idle_up`.
- AC3 — `_camera_yaw_degrees()` with a documented fallback.
- AC4 — proven headlessly at 90° and by eye at 135° in Checkpoint 1.
- AC5 — the `player3d.gd` limitation note is gone and the README paragraph is rewritten.

Also confirm the working tree is clean (`git status`) — in particular that `scenes/poc3d/rooms/test_room.tscn` was never committed with a flipped camera.

Wait for confirmation before opening a PR.
