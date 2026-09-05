# Sprite Facing & Camera Yaw (#116) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a `PixelSprite3D` face the camera that actually renders it, so a room authoring its own angle no longer shows the sprite's mirrored back face — and settle, with an executable test, whether the left/right sprite sheets are mislabelled.

**Architecture:** `PixelSprite3D._ready()` currently hard-stamps `rotation_degrees.y = WorldScale.CAMERA_YAW_DEGREES`. That is the same global-constant coupling issue #114 removed from `Player3D`'s *input*, applied to *rendering*. The fix mirrors #114: resolve the yaw from the live `Camera3D`, fall back to the contract angle. Because both `Player3D` and `PixelSprite3D` now need that resolution, it is extracted once into `WorldScale` — the class that already owns the contract angle the fallback returns. One change covers `Player3D` and `Npc3D`, since both instance `PixelSprite3D`.

**Tech Stack:** Godot 4.7.1 (mono), GDScript, GUT for tests. Mobile renderer.

**Spec:** GitHub issue #116 (`gh issue view 116`). Epic context: #100. Direct precedent: #114 / PR #115.

## Global Constraints

- Godot is invoked **only** through `tools/godot.ps1`. The `godot` / `godot_console` commands on PATH are WinGet shims and crash with `.NET: Assemblies not found`.
- PowerShell splits an unquoted `res://` argument on the colon. Quote every `res://` argument.
- 16 pixels = 1 world unit. Every scale-derived number comes from `WorldScale`, never hand-typed.
- `WorldScale.CAMERA_YAW_DEGREES` is `45.0`. It is the contract angle and the documented fallback; a room opts out with `RoomCamera.use_contract_angle = false`.
- Positional / float assertions use `assert_almost_eq` with an explicit tolerance, never `assert_eq`.
- `main.tscn`, `go_to_area()` and the seven existing 2D areas stay untouched (epic #100).
- The autoloads (`GameState`, `CraftingSystem`, `ClockManager`) are not modified.

## A correction to the issue text, established before this plan was written

Issue #116 Part 2 asserts that `data/sprites/player_frames.tres` maps left and right to
the wrong sheets, and leaves open "which of the two sheets is mislabelled". Both PNGs were
opened and measured before writing this plan. The findings:

1. `player_left.png` (64x32) is a **pixel-identical horizontal mirror** of `player.png`'s
   `y=64` row. `maris_left.png` / `maris.png` likewise. Max channel difference: 0.
2. In `player.png`'s `y=64` row — the row mapped to `right` — the single visible cheek
   blush sits at **x = 9-10** in every one of the four 16px-wide frames, i.e. right of the
   frame centre, on the same side as the eye and the nose protrusion. In
   `player_left.png` — mapped to `left` — it sits at **x = 5-6**, left of centre.

A profile sprite's visible blush, eye and nose are on the side it faces. The mapping in
the `.tres` is therefore **correct as authored**, and the "swap the two sheets" fix implied
by the issue would *introduce* the inversion rather than remove it.

That leaves the reported in-game symptom unexplained by the asset data. The one
mirroring mechanism that provably exists in the 3D path is Part 1's back-face rendering,
which Task 2 fixes. Task 3 locks the asset ground truth down as a test so nobody swaps the
sheets on a hunch; Task 4 re-observes the symptom after the fix and closes Part 2 out on
evidence. Do not touch `player_frames.tres` or `npc_frames.tres` in this plan.

## File Structure

| File | Change | Responsibility |
|------|--------|----------------|
| `scripts/poc3d/world_scale.gd` | Modify | Gains `camera_yaw_degrees(viewport)` — the single place the "live camera, else contract angle" rule lives |
| `scripts/poc3d/player3d.gd` | Modify | Drops its private copy of that rule, calls the helper |
| `scripts/poc3d/pixel_sprite_3d.gd` | Modify | Turns the quad toward the live camera each frame instead of stamping a constant once |
| `tests/test_poc3d_world_scale.gd` | Modify | Covers the helper, including the nested-rotated-parent case PR #115 could not reach |
| `tests/test_poc3d_pixel_sprite.gd` | Modify | Covers the quad following the camera |
| `tests/test_poc3d_npc3d.gd` | Modify | Proves one change covered the NPC too |
| `tests/test_sprite_sheet_facing.gd` | Create | Ground-truth lock on which sheet faces which way (2D and 3D both consume these `.tres` files) |
| `scenes/poc3d/README.md` | Modify | Documents sprite yaw derivation next to the existing input-yaw section |

---

### Task 1: One shared rule for "which way is the camera looking"

`Player3D._camera_yaw_degrees()` is about to be needed verbatim by `PixelSprite3D`. Move it
to `WorldScale`, which already owns `CAMERA_YAW_DEGREES` — the value the fallback returns.

**Files:**
- Modify: `scripts/poc3d/world_scale.gd` (append after the camera contract block, ~line 38)
- Modify: `scripts/poc3d/player3d.gd:55` and `:60-73`
- Test: `tests/test_poc3d_world_scale.gd`

**Interfaces:**
- Consumes: `WorldScale.CAMERA_YAW_DEGREES` (existing, `45.0`)
- Produces: `static func WorldScale.camera_yaw_degrees(viewport: Viewport) -> float` —
  returns the global Y rotation in degrees of `viewport.get_camera_3d()`, or
  `CAMERA_YAW_DEGREES` when `viewport` is `null` or has no current 3D camera. Task 2 calls it.

- [ ] **Step 1: Write the failing tests**

Append to `tests/test_poc3d_world_scale.gd`:

```gdscript
## Yaw comparisons are float degrees; a hundredth of a degree is far below anything
## authored by hand and far above float noise.
const YAW_TOLERANCE := 0.01

## Used for the "room authors its own angle" cases. 90 and the 30/60 split are chosen so
## the expected results are checkable facts rather than copied floats.
const HAND_AUTHORED_YAW := 90.0
const PARENT_YAW := 30.0
const CHILD_LOCAL_YAW := 60.0


func test_a_null_viewport_falls_back_to_the_contract_angle():
	assert_almost_eq(WorldScale.camera_yaw_degrees(null),
		WorldScale.CAMERA_YAW_DEGREES, YAW_TOLERANCE,
		"a caller not yet in the tree must still get a usable yaw")


func test_a_viewport_with_no_camera_falls_back_to_the_contract_angle():
	# The normal headless-test path: the GUT runner's viewport has no Camera3D.
	assert_null(get_viewport().get_camera_3d(),
		"this test is only meaningful with no Camera3D in the runner's viewport")
	assert_almost_eq(WorldScale.camera_yaw_degrees(get_viewport()),
		WorldScale.CAMERA_YAW_DEGREES, YAW_TOLERANCE)


func test_a_current_camera_wins_over_the_contract_angle():
	var camera := Camera3D.new()
	camera.rotation_degrees = Vector3(WorldScale.CAMERA_PITCH_DEGREES, HAND_AUTHORED_YAW, 0.0)
	add_child_autofree(camera)
	camera.make_current()
	await wait_frames(1)
	assert_almost_eq(WorldScale.camera_yaw_degrees(get_viewport()),
		HAND_AUTHORED_YAW, YAW_TOLERANCE,
		"the live camera, not the shared constant, is the contract at runtime")


func test_a_camera_under_a_rotated_parent_reports_its_global_yaw():
	# The gap PR #115 flagged: its helper added the camera directly under the test root,
	# where local and global transforms coincide, so a rotation_degrees /
	# global_rotation_degrees mix-up could not fail. 30 + 60 = 90 here, and only the
	# global read produces it.
	var pivot := Node3D.new()
	pivot.rotation_degrees = Vector3(0.0, PARENT_YAW, 0.0)
	add_child_autofree(pivot)
	var camera := Camera3D.new()
	camera.rotation_degrees = Vector3(0.0, CHILD_LOCAL_YAW, 0.0)
	pivot.add_child(camera)
	camera.make_current()
	await wait_frames(1)
	assert_almost_eq(WorldScale.camera_yaw_degrees(get_viewport()),
		PARENT_YAW + CHILD_LOCAL_YAW, YAW_TOLERANCE,
		"must read global_rotation_degrees, not rotation_degrees")
```

- [ ] **Step 2: Run the tests to verify they fail**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_world_scale.gd" -gexit
```

Expected: 4 failures, each reporting an invalid call to a nonexistent function
`camera_yaw_degrees` on `WorldScale`.

- [ ] **Step 3: Add the helper**

In `scripts/poc3d/world_scale.gd`, immediately after `const CAMERA_YAW_DEGREES := 45.0`:

```gdscript

## Yaw of the Camera3D currently rendering `viewport`, in degrees.
##
## Both movement (#114) and the sprite quad's own rotation (#116) have to agree with what
## is actually on screen, so the rule lives here once rather than in each caller. Callers
## read it live rather than caching at _ready(): nothing orders the camera before other
## nodes in a room scene, and a cached value taken before the camera existed would be
## silently wrong for the life of the room.
##
## global_ so a camera parented under a rotated node still resolves correctly.
##
## Fallback: CAMERA_YAW_DEGREES when there is no camera. Silent on purpose — a room with
## no Camera3D renders a black screen, so a warning would add no diagnostic value, and
## the no-camera path is the normal one under headless tests.
static func camera_yaw_degrees(viewport: Viewport) -> float:
	if viewport == null:
		return CAMERA_YAW_DEGREES
	var camera := viewport.get_camera_3d()
	if camera == null:
		return CAMERA_YAW_DEGREES
	return camera.global_rotation_degrees.y
```

- [ ] **Step 4: Run the tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_world_scale.gd" -gexit
```

Expected: PASS, all tests in the file green.

- [ ] **Step 5: Point Player3D at the helper**

In `scripts/poc3d/player3d.gd`, replace line 55:

```gdscript
	velocity = SpriteFacing.input_to_world(input, _camera_yaw_degrees()) * SPEED
```

with:

```gdscript
	velocity = SpriteFacing.input_to_world(
		input, WorldScale.camera_yaw_degrees(get_viewport())) * SPEED
```

Then delete the whole `_camera_yaw_degrees()` function and its doc comment (lines 60-73),
since `WorldScale.camera_yaw_degrees()` now carries that documentation. Update the header
comment at lines 10-12 to read:

```gdscript
## The camera yaw is read from the Camera3D actually rendering the player — see
## WorldScale.camera_yaw_degrees() — so a room may author its own angle via
## RoomCamera.use_contract_angle = false without desyncing the controls (#114).
```

- [ ] **Step 6: Run the player tests to verify nothing regressed**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_player3d.gd" -gexit
```

Expected: PASS — all 9 tests, including
`test_a_room_that_authors_its_own_yaw_gets_controls_that_match_the_screen` and
`test_without_a_camera_the_yaw_falls_back_to_the_contract_angle`. These are the behaviour
this step must preserve unchanged; a failure means the extraction changed semantics.

- [ ] **Step 7: Commit**

```bash
git add scripts/poc3d/world_scale.gd scripts/poc3d/player3d.gd tests/test_poc3d_world_scale.gd
git commit -m "refactor: hoist camera yaw resolution into WorldScale (#116)"
```

---

### Task 2: The sprite quad turns toward the camera that renders it

The defect itself. Billboarding is deliberately off, so the sprite is a flat quad; if its
yaw does not follow the camera, a room at a sufficiently different angle sees the quad
edge-on or — at 180 degrees — sees its mirrored back face.

**Files:**
- Modify: `scripts/poc3d/pixel_sprite_3d.gd:13-16` (header comment) and `:19-26` (`_ready`)
- Test: `tests/test_poc3d_pixel_sprite.gd`, `tests/test_poc3d_npc3d.gd`

**Interfaces:**
- Consumes: `WorldScale.camera_yaw_degrees(viewport)` from Task 1
- Produces: nothing new. `PixelSprite3D` keeps its existing surface; only its
  `global_rotation_degrees.y` behaviour changes. `Player3D` and `Npc3D` need no edits.

- [ ] **Step 1: Write the failing tests**

In `tests/test_poc3d_pixel_sprite.gd`, add these constants and helper below the existing
`TOLERANCE`, then the three tests:

```gdscript
## A hand-authored room angle, deliberately 180 degrees off the contract angle: this is
## the case where the old code showed the quad's mirrored back face.
const FLIPPED_YAW := -135.0
const PARENT_YAW := 30.0
const CHILD_LOCAL_YAW := 60.0


## A current Camera3D at `yaw_degrees`, standing in for a room that set
## RoomCamera.use_contract_angle = false and authored its own angle.
func _current_camera_at(yaw_degrees: float) -> Camera3D:
	var camera := Camera3D.new()
	camera.rotation_degrees = Vector3(WorldScale.CAMERA_PITCH_DEGREES, yaw_degrees, 0.0)
	add_child_autofree(camera)
	camera.make_current()
	return camera


func test_the_quad_follows_a_room_that_authors_its_own_yaw():
	# The #116 Part 1 defect. At -135 the old code left the quad at +45, a 180-degree
	# difference, so the camera saw its back face and the sprite rendered mirrored.
	_current_camera_at(FLIPPED_YAW)
	var sprite := _build_sprite()
	await wait_frames(2)
	assert_almost_eq(sprite.global_rotation_degrees.y, FLIPPED_YAW, TOLERANCE,
		"a flat quad with billboarding off must be turned toward its camera")


func test_the_quad_uses_the_cameras_global_yaw_not_its_local_one():
	# Same gap as the Player3D helper: a camera under a rotated pivot is the only case
	# that can tell rotation_degrees and global_rotation_degrees apart.
	var pivot := Node3D.new()
	pivot.rotation_degrees = Vector3(0.0, PARENT_YAW, 0.0)
	add_child_autofree(pivot)
	var camera := Camera3D.new()
	camera.rotation_degrees = Vector3(0.0, CHILD_LOCAL_YAW, 0.0)
	pivot.add_child(camera)
	camera.make_current()
	var sprite := _build_sprite()
	await wait_frames(2)
	assert_almost_eq(sprite.global_rotation_degrees.y,
		PARENT_YAW + CHILD_LOCAL_YAW, TOLERANCE)


func test_a_sprite_under_a_rotated_parent_still_lands_on_the_camera_angle():
	# Rooms nest sprites under pivots and NPC nodes. The quad's angle is a global fact
	# about what the camera sees, so a rotated ancestor must not offset it.
	_current_camera_at(FLIPPED_YAW)
	var pivot := Node3D.new()
	pivot.rotation_degrees = Vector3(0.0, PARENT_YAW, 0.0)
	add_child_autofree(pivot)
	var sprite := PixelSprite3D.new()
	sprite.sprite_frames = load(FRAMES_PATH)
	sprite.animation = &"idle_down"
	pivot.add_child(sprite)
	await wait_frames(2)
	assert_almost_eq(sprite.global_rotation_degrees.y, FLIPPED_YAW, TOLERANCE)
```

Also add to `tests/test_poc3d_npc3d.gd` — the issue's claim that one change covers both
characters is worth an assertion rather than a comment:

```gdscript
## Matches tests/test_poc3d_pixel_sprite.gd: 180 degrees off the contract angle.
const FLIPPED_YAW := -135.0
const YAW_TOLERANCE := 0.01

func test_the_npc_sprite_follows_the_room_camera_like_the_players_does():
	# Npc3D has no yaw code of its own; this passes only because the fix lives in the
	# shared PixelSprite3D, which is the point.
	var camera := Camera3D.new()
	camera.rotation_degrees = Vector3(WorldScale.CAMERA_PITCH_DEGREES, FLIPPED_YAW, 0.0)
	add_child_autofree(camera)
	camera.make_current()
	var npc = await _npc_ready("down")
	await wait_frames(2)
	var sprite := npc.get_node("PixelSprite3D") as PixelSprite3D
	assert_almost_eq(sprite.global_rotation_degrees.y, FLIPPED_YAW, YAW_TOLERANCE)
```

- [ ] **Step 2: Run the tests to verify they fail**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_pixel_sprite.gd" -gexit
```

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_npc3d.gd" -gexit
```

Expected: the four new tests FAIL, each reporting the yaw as `45` (the stamped contract
angle) where `-135` or `90` was expected. Every pre-existing test in both files still
passes — including `test_sprite_faces_the_contract_camera_yaw`, which has no camera in its
viewport and so exercises the fallback.

- [ ] **Step 3: Make the quad follow the camera**

In `scripts/poc3d/pixel_sprite_3d.gd`, replace the header comment lines 13-16 with:

```gdscript
## Billboarding is off and alpha_cut is ALPHA_CUT_DISCARD so the depth buffer
## handles occlusion against geometry rather than the sprite always drawing on
## top. With billboarding off the quad is flat, so it is turned to face whatever
## camera renders it — see _face_active_camera(). With 4-direction atlases and a
## locked per-room camera there is nothing further to rotate toward.
```

Replace `_ready()` (lines 19-26) with:

```gdscript
func _ready() -> void:
	pixel_size = WorldScale.SPRITE_PIXEL_SIZE
	billboard = BaseMaterial3D.BILLBOARD_DISABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	# default_texture_filter in project.godot is 2D-only and does not reach here.
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_face_active_camera()
	_lift_feet_to_origin()


## In the editor there is no room camera to follow: get_viewport() resolves to the 3D
## editor's own viewport, and tracking its free camera would billboard the quad while a
## room is being composed by eye. The contract angle is stamped once at _ready() instead,
## which is exactly what this node did before #116.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_face_active_camera()


## The quad is flat and billboarding is off, so it has to be turned toward the camera that
## renders it; at a 180-degree difference the camera sees its mirrored back face instead
## (#116). Same rule and same fallback as the player's movement yaw (#114).
##
## Written as a global rotation so a sprite nested under a rotated pivot or NPC node still
## lands on the camera's angle rather than that angle plus its ancestors'.
func _face_active_camera() -> void:
	var yaw := WorldScale.CAMERA_YAW_DEGREES
	if not Engine.is_editor_hint():
		yaw = WorldScale.camera_yaw_degrees(get_viewport())
	var euler := global_rotation_degrees
	euler.y = yaw
	global_rotation_degrees = euler
```

- [ ] **Step 4: Run the tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_pixel_sprite.gd" -gexit
```

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_npc3d.gd" -gexit
```

Expected: PASS for both files.

- [ ] **Step 5: Run the whole suite**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```

Expected: PASS, 0 failures. Read the printed summary line rather than the exit code — a
piped `$LASTEXITCODE` is unreliable in PowerShell.

- [ ] **Step 6: Commit**

```bash
git add scripts/poc3d/pixel_sprite_3d.gd tests/test_poc3d_pixel_sprite.gd tests/test_poc3d_npc3d.gd
git commit -m "fix: turn the sprite quad toward the camera that renders it (#116)"
```

---

### Task 3: Lock down which sheet faces which way

Issue #116 Part 2 proposes swapping the left/right sheets. The pixel data says that would
be wrong (see the correction section above). Encode the ground truth as a test so the
question is settled by a command rather than by eyeballing 16x32 art.

**Files:**
- Create: `tests/test_sprite_sheet_facing.gd`
- Modify: none. `data/sprites/player_frames.tres` and `npc_frames.tres` are **not** edited.

**Interfaces:**
- Consumes: `res://data/sprites/player_frames.tres`, `res://data/sprites/npc_frames.tres`,
  `res://assets/sprites/characters/{player,player_left,maris,maris_left}.png`
- Produces: nothing consumed by later tasks. Task 4 cites it.

- [ ] **Step 1: Write the test**

This one is expected to pass immediately — it asserts the current, correct state. That is
the point: it fails only if someone later swaps the sheets. Step 3 proves it can fail.

Create `tests/test_sprite_sheet_facing.gd`:

```gdscript
# tests/test_sprite_sheet_facing.gd
extends GutTest

## Ground truth for issue #116 Part 2, which proposed that the left and right sprite
## sheets are swapped. They are not, and this file is why the question stays settled.
##
## These .tres files are shared by the 2D build (scenes/characters/player.tscn,
## npc_base.tscn) and the 3D POC (scenes/poc3d/), so a swap here would break both.

## The side-facing row of a base sheet starts at y=64; the *_left sheets are single-row.
const SIDE_ROW_Y := 64
const FRAME_SIZE := Vector2i(16, 32)
const FRAME_COUNT := 4

## Half of FRAME_SIZE.x. A blush centroid above this sits on the right of the frame.
const FRAME_CENTRE_X := 8.0

## The cheek blush is (209, 157, 167): clearly redder than it is green or blue, unlike
## every other colour in these palettes. Thresholds in 0..1 float, from 25/255 and 10/255.
const BLUSH_RED_OVER_GREEN := 0.09
const BLUSH_RED_OVER_BLUE := 0.03

const SHEETS := [
	{"base": "res://assets/sprites/characters/player.png",
	 "mirror": "res://assets/sprites/characters/player_left.png",
	 "frames": "res://data/sprites/player_frames.tres"},
	{"base": "res://assets/sprites/characters/maris.png",
	 "mirror": "res://assets/sprites/characters/maris_left.png",
	 "frames": "res://data/sprites/npc_frames.tres"},
]


func _image(path: String) -> Image:
	var texture: Texture2D = load(path)
	assert_not_null(texture, "missing texture: " + path)
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	return image


## Mean x of the blush pixels in `image`, or -1.0 if the sprite shows no blush.
func _blush_centre_x(image: Image) -> float:
	var total := 0.0
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			if c.r > c.g + BLUSH_RED_OVER_GREEN and c.r > c.b + BLUSH_RED_OVER_BLUE:
				total += float(x)
				count += 1
	if count == 0:
		return -1.0
	return total / float(count)


## The blush centroid of one frame of `animation`, decompressed and measured.
func _frame_blush_centre_x(frames: SpriteFrames, animation: String, index: int) -> float:
	var texture := frames.get_frame_texture(animation, index)
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	return _blush_centre_x(image)


func test_each_side_sheet_is_an_exact_mirror_of_the_other():
	# If these ever stop being mirrors, the two sheets have diverged and the "just swap
	# them" fix proposed in #116 stops being a no-op even in principle.
	for sheet in SHEETS:
		var base := _image(sheet["base"])
		var mirror := _image(sheet["mirror"])
		var row := base.get_region(Rect2i(
			0, SIDE_ROW_Y, FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y))
		row.flip_x()
		assert_eq(mirror.get_size(), row.get_size(),
			"%s must be the same size as the base sheet's side row" % sheet["mirror"])
		var differing := 0
		for y in row.get_height():
			for x in row.get_width():
				if not row.get_pixel(x, y).is_equal_approx(mirror.get_pixel(x, y)):
					differing += 1
		assert_eq(differing, 0,
			"%s must stay a pixel-exact horizontal mirror of %s row y=%d"
				% [sheet["mirror"], sheet["base"], SIDE_ROW_Y])


func test_the_right_facing_frames_show_the_blush_on_the_right():
	# The visible cheek blush, eye and nose of a profile sprite are on the side it faces.
	# In the row mapped to "right" the blush sits at x=9-10 of a 16px frame; in its mirror
	# it lands at x=5-6. Swapping the sheets flips this assertion, which is the whole
	# point of having it.
	for sheet in SHEETS:
		var frames: SpriteFrames = load(sheet["frames"])
		for animation in ["idle_right", "walk_right"]:
			for index in frames.get_frame_count(animation):
				var centre := _frame_blush_centre_x(frames, animation, index)
				assert_gt(centre, 0.0,
					"no blush found in %s frame %d of %s; the art or the colour thresholds changed"
						% [animation, index, sheet["frames"]])
				assert_gt(centre, FRAME_CENTRE_X,
					"%s frame %d of %s faces left, not right"
						% [animation, index, sheet["frames"]])


func test_the_left_facing_frames_show_the_blush_on_the_left():
	for sheet in SHEETS:
		var frames: SpriteFrames = load(sheet["frames"])
		for animation in ["idle_left", "walk_left"]:
			for index in frames.get_frame_count(animation):
				var centre := _frame_blush_centre_x(frames, animation, index)
				assert_gt(centre, 0.0,
					"no blush found in %s frame %d of %s; the art or the colour thresholds changed"
						% [animation, index, sheet["frames"]])
				assert_lt(centre, FRAME_CENTRE_X,
					"%s frame %d of %s faces right, not left"
						% [animation, index, sheet["frames"]])
```

- [ ] **Step 2: Run it**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_sprite_sheet_facing.gd" -gexit
```

Expected: PASS, 3 tests.

If the blush detection instead finds nothing, the textures reimported with VRAM
compression despite `detect_3d/compress_to=0` — check the `.import` files described in
`scenes/poc3d/README.md` before touching the colour thresholds.

- [ ] **Step 3: Prove the test can fail**

Temporarily swap `id="1"` and `id="2"` on the two `ext_resource` lines at the top of
`data/sprites/player_frames.tres`, re-run the command from Step 2, and confirm
`test_the_right_facing_frames_show_the_blush_on_the_right` and
`test_the_left_facing_frames_show_the_blush_on_the_left` both FAIL. Then restore the file:

```bash
git checkout data/sprites/player_frames.tres
```

A guard that cannot fail guards nothing.

- [ ] **Step 4: Commit**

```bash
git add tests/test_sprite_sheet_facing.gd
git commit -m "test: lock the left/right sprite sheet mapping against a swap (#116)"
```

---

### Task 4: Verify in the running game and document

Green tests have hidden runtime defects in this repo before. #116 was found by hand and has
to be closed by hand.

**Files:**
- Modify: `scenes/poc3d/README.md` (the "Controls" section, lines 42-47)

**Interfaces:**
- Consumes: everything from Tasks 1-3.
- Produces: the evidence that closes #116, and the note that unblocks #103.

- [ ] **Step 1: Confirm Part 1 is fixed at the contract angle**

Build and run the POC:

```powershell
dotnet build "Outpost Nova.csproj"
```

```powershell
./tools/godot.ps1 --path . "res://scenes/poc3d/poc_entry.tscn"
```

Walk the player in all four directions. Confirm each direction shows the matching sprite
and that the sprite is neither edge-on nor mirrored. Note what you observe for left and
right specifically — that observation is the input to Step 3.

- [ ] **Step 2: Confirm Part 1 is fixed at a hand-authored angle**

In `scenes/poc3d/rooms/test_room.tscn`, select the `RoomCamera` node, set
`use_contract_angle = false`, and set its `rotation_degrees` to `(-35, -135, 0)` — 180
degrees off the contract angle, the exact case reported in #116. Reposition the camera so
it still frames the room. Run the POC again.

Expected: the sprite faces the camera and renders un-mirrored, where before this task's
changes it showed its back face. Movement was already correct here (that is what #114
fixed) and must stay correct.

Revert the scene when done:

```bash
git checkout scenes/poc3d/rooms/test_room.tscn
```

- [ ] **Step 3: Settle Part 2**

Run the 2D build, which shares `player_frames.tres` but has no 3D quad and therefore no
back-face mirroring:

```powershell
./tools/godot.ps1 --path .
```

Press left and right, and compare against the 3D observation from Step 1.

- **If both builds agree and both look correct:** Part 2 was the back-face mirroring from
  Part 1, or a misreading of 16x32 art. Close #116 citing Step 1, Step 2, this step, and
  `tests/test_sprite_sheet_facing.gd`.
- **If the 2D build also shows left/right reversed:** the fault is upstream of the 3D work
  and predates this epic. The sheets are mirrors and correctly labelled per Task 3, so the
  cause is neither the `.tres` nor `PixelSprite3D` — file a fresh issue against the 2D
  player with the observation, and close #116 Part 2 as not-an-asset-bug, referencing it.
- **If only the 3D build shows it:** stop and report. Nothing in the 3D path mirrors a
  sprite once Task 2 lands, so this outcome contradicts the code and needs fresh
  investigation rather than a guess.

- [ ] **Step 4: Document the sprite yaw**

In `scenes/poc3d/README.md`, replace the paragraph at lines 42-47 with:

```markdown
That yaw is read every physics frame from the `Camera3D` actually rendering the
player (`WorldScale.camera_yaw_degrees()`), so a room that sets
`RoomCamera.use_contract_angle = false` and hand-authors its own angle gets
controls that match what is on screen. When the viewport has no camera at all —
headless tests, mainly — the yaw falls back silently to
`WorldScale.CAMERA_YAW_DEGREES` (45°).

The **sprite quad** reads the same yaw, through the same helper, every frame
(`PixelSprite3D._face_active_camera()`). Billboarding is off, so the quad is flat:
if it did not turn with the camera, a room at a different angle would see it
edge-on, and a room 180° away would see its mirrored back face (#116). In the
editor the contract angle is stamped instead, because `get_viewport()` there is
the 3D editor's own viewport and following its free camera would billboard the
sprite while a room is being composed.
```

- [ ] **Step 5: Run the whole suite one more time**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```

Expected: PASS, 0 failures. Then confirm `git status` shows `test_room.tscn` and
`player_frames.tres` unmodified.

- [ ] **Step 6: Commit**

```bash
git add scenes/poc3d/README.md
git commit -m "docs: describe the camera-derived sprite yaw (#116)"
```

---

## Notes for the reviewer

- **Why `_process` and not `_ready`:** the same reason #114 gave for reading the yaw every
  physics frame. Nothing orders a room's camera before its sprites, so a value cached at
  `_ready()` can stay the fallback forever in a room that does have a camera.
- **Why this unblocks #103:** the first room #103 authors with its own angle would
  otherwise render every character in it wrong.
- **Not done here:** issue #116's proposed swap of `player_left.png` and `player.png`.
  Task 3 documents why, with a test.
