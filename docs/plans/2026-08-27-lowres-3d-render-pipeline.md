# Low-Res 3D Render Pipeline & Camera Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a standalone POC scene in which a 3D world renders into a 480x270 `SubViewport`, upscaled nearest-neighbour, with the existing HUD crisp above it — establishing the world-scale constant and the per-room camera contract that PRDs 2-4 build on.

**Architecture:** `poc_entry.tscn` owns a full-rect `SubViewportContainer` -> `SubViewport` -> an instanced room scene, with `hud.tscn` instanced as a **sibling** so it renders outside the low-res target. A single `WorldScale` class holds every constant (16 px = 1 world unit, camera angle, sheet geometry); `@tool` scripts push those values into `Camera3D`, `AnimatedSprite3D` and the floor mesh in both editor and runtime, so `.tscn` literals are never the source of truth. The floor is one `ArrayMesh` of 1x1-unit quads whose UVs address a single 16x16 region of the existing roguelike tile sheet.

**Tech Stack:** Godot 4.7.1 (mono), GDScript, Mobile renderer, GUT for tests. No C# in this PRD. No new binary assets.

**Issue:** #101 (PRD 1 of epic #100)

## Open questions (must resolve before starting)

None. All forks were resolved during the grill; the decisions and their rationale are recorded in `## Design Decisions Resolved` below.

---

## Design Decisions Resolved

Read this section before Task 1. It exists so you do not "fix" something that is deliberate.

1. **`WorldScale` is a `class_name` script, not an autoload and not a const on a scene script.** `project.godot` is read-only in this PRD and the epic states autoloads are untouched. PRDs 2 and 4 both need this constant.
2. **`@tool` scripts apply the constants.** A `.tscn` cannot reference a GDScript constant — Godot serialises the resolved number. The `@tool` scripts overwrite those literals on load in editor *and* runtime, so the editor viewport is truthful while you hand-author the camera angle by eye (R6).
3. **HUD is a sibling of the `SubViewportContainer`, not wrapped in a new `CanvasLayer`.** `hud.tscn` is already a `CanvasLayer` with `layer = 1`. The invariant that matters is that it is never a descendant of the `SubViewport`; a wrapper layer would add a node that changes nothing.
4. **`SubViewportContainer.stretch = true`, riding the existing root `canvas_items` stretch.** Do not assign `SubViewport.size` in code — with `stretch = true` the container drives it, so an assignment would be silently overwritten. `WorldScale.RENDER_WIDTH/HEIGHT` are the *expected* values the structural test asserts against, which is how they earn their keep.
5. **The floor is one `ArrayMesh`, not N `MeshInstance3D` nodes.** The tile sheet has 1px separation, so an `AtlasTexture` region cannot be tiled — UV repeat repeats the whole texture. Writing per-quad UVs solves that and, unlike the node-per-tile approach, produces pure logic worth unit-testing.
6. **UVs are inset by half a texel.** The camera is at pitch -35 / yaw 45, so quads never align to the screen pixel grid; without the inset, nearest sampling at a region edge can bleed the adjacent 1px separation pixel.
7. **`detect_3d/compress_to` must be disabled on every texture used in 3D.** Godot re-imports a texture the first time it appears in a 3D material, switching it to VRAM block compression with mipmaps — blurry mush on pixel art — and silently rewrites the `.import` file, which this repo now tracks in git.
8. **`project.godot` is not modified.** The POC is launched by explicit scene argument or F6.

---

## Batch 1 — Foundation: constants, floor mesh, import safety

### Task 1: `WorldScale` constants and tile UV math

**Files:**
- Create: `scripts/poc3d/world_scale.gd`
- Test: `tests/test_poc3d_world_scale.gd`

**Depends on:** none
**Parallelizable with:** Task 3 — Task 3 only edits `.import` files and shares no symbol with this task.

**Step 1: Write the failing GUT test**

```gdscript
# tests/test_poc3d_world_scale.gd
extends GutTest

# The tile sheet's grid, restated here as the expected value. It is deliberately
# a literal: a test that derived its expectation the same way the implementation
# does would assert nothing.
const EXPECTED_GRID := Vector2i(57, 31)
const EXPECTED_SHEET_SIZE := Vector2i(968, 526)

# UV comparisons are float division of pixel counts, so never use ==.
const UV_TOLERANCE := 0.000001


func test_sprite_pixel_size_is_the_inverse_of_pixels_per_unit():
	assert_almost_eq(WorldScale.SPRITE_PIXEL_SIZE, 1.0 / WorldScale.PIXELS_PER_UNIT, UV_TOLERANCE,
		"SPRITE_PIXEL_SIZE must stay derived from PIXELS_PER_UNIT, not hand-typed")


func test_sheet_size_matches_the_shipped_texture():
	assert_eq(WorldScale.sheet_size(), EXPECTED_SHEET_SIZE,
		"the tile sheet changed size; the UV math and EXPECTED_GRID both need revisiting")


func test_tile_grid_size_accounts_for_separation():
	# 968 px / 16 px would give 60 columns; the 1px separation makes it 57.
	assert_eq(WorldScale.tile_grid_size(), EXPECTED_GRID,
		"grid must be computed with the 1px separation stride, not by naive division")


func test_first_tile_uv_rect_is_inset_by_half_a_texel():
	var sheet := Vector2(WorldScale.sheet_size())
	var rect := WorldScale.tile_uv_rect(0, 0)
	assert_almost_eq(rect.position.x, 0.5 / sheet.x, UV_TOLERANCE)
	assert_almost_eq(rect.position.y, 0.5 / sheet.y, UV_TOLERANCE)
	assert_almost_eq(rect.size.x, 15.0 / sheet.x, UV_TOLERANCE)
	assert_almost_eq(rect.size.y, 15.0 / sheet.y, UV_TOLERANCE)


func test_tile_uv_rect_advances_by_the_separation_stride():
	var sheet := Vector2(WorldScale.sheet_size())
	var rect := WorldScale.tile_uv_rect(1, 2)
	# stride is 16 + 1 = 17 px per tile step, then the half-texel inset.
	assert_almost_eq(rect.position.x, 17.5 / sheet.x, UV_TOLERANCE)
	assert_almost_eq(rect.position.y, 34.5 / sheet.y, UV_TOLERANCE)


func test_last_tile_uv_rect_stays_inside_the_texture():
	var last := WorldScale.tile_grid_size() - Vector2i.ONE
	var rect := WorldScale.tile_uv_rect(last.x, last.y)
	assert_lt(rect.end.x, 1.0, "last column's UV overruns the right edge of the sheet")
	assert_lt(rect.end.y, 1.0, "last row's UV overruns the bottom edge of the sheet")


func test_tile_bounds_check_rejects_coordinates_off_the_grid():
	var grid := WorldScale.tile_grid_size()
	assert_true(WorldScale.is_tile_in_bounds(0, 0))
	assert_true(WorldScale.is_tile_in_bounds(grid.x - 1, grid.y - 1))
	assert_false(WorldScale.is_tile_in_bounds(grid.x, 0))
	assert_false(WorldScale.is_tile_in_bounds(0, grid.y))
	assert_false(WorldScale.is_tile_in_bounds(-1, 0))
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_world_scale.gd" -gexit
```
Expected: FAIL — parse error, `WorldScale` is an unknown identifier.

**Step 3: Write minimal implementation**

```gdscript
# scripts/poc3d/world_scale.gd
@tool
class_name WorldScale
extends RefCounted

## Single source of truth for the POC's 3D presentation constants.
##
## Not an autoload on purpose: project.godot is read-only in PRD 1 and epic #100
## states the autoloads are untouched. A class_name is globally reachable from
## any script or @tool script without registering anything.


# --- World scale -------------------------------------------------------------

## 16 texels of art occupy one world unit, matching the 16x32 character sprites.
const PIXELS_PER_UNIT := 16.0

## Value for Sprite3D.pixel_size. Derived, never typed by hand.
const SPRITE_PIXEL_SIZE := 1.0 / PIXELS_PER_UNIT


# --- Render target -----------------------------------------------------------

## Matches display/window/size/viewport_* in project.godot. These are the
## EXPECTED values asserted by tests/test_poc3d_pipeline.gd, not values assigned
## at runtime: SubViewportContainer.stretch = true makes the container drive the
## SubViewport's size, so any assignment here would be overwritten.
const RENDER_WIDTH := 480
const RENDER_HEIGHT := 270


# --- Camera contract ---------------------------------------------------------

## The authored starting angle every POC room inherits. A room may override it
## by setting RoomCamera.use_contract_angle = false and hand-authoring rotation.
const CAMERA_FOV := 40.0
const CAMERA_PITCH_DEGREES := -35.0
const CAMERA_YAW_DEGREES := 45.0


# --- Tile sheet geometry -----------------------------------------------------

## The sheet already used by data/tilesets/station.tres in 2D. Its 16px grid
## matches PIXELS_PER_UNIT exactly, so one tile covers exactly one world unit.
const SHEET_PATH := "res://assets/sprites/tiles/roguelikeSheet_transparent.png"

## Mirrors TileSetAtlasSource.texture_region_size / .separation in
## data/tilesets/station.tres. tests/test_tileset_bounds.gd guards that file.
const TILE_SIZE := Vector2i(16, 16)
const TILE_SEPARATION := Vector2i(1, 1)

## Half a texel, pulled off every edge of a tile's UV rect. The camera is at
## pitch -35 / yaw 45, so quads never align to the screen pixel grid; without
## this, nearest sampling at a region edge can bleed the 1px separation pixel.
const UV_INSET_TEXELS := 0.5

static var _sheet_size_cache := Vector2i.ZERO


## Sheet dimensions read from the imported texture rather than hard-coded, so
## swapping the sheet cannot silently desync the UV math.
static func sheet_size() -> Vector2i:
	if _sheet_size_cache == Vector2i.ZERO:
		var texture: Texture2D = load(SHEET_PATH)
		if texture == null:
			push_error("WorldScale: could not load tile sheet at %s" % SHEET_PATH)
			return Vector2i.ZERO
		_sheet_size_cache = Vector2i(texture.get_size())
	return _sheet_size_cache


## Number of whole tiles the sheet holds. Tile (c, r) starts at
## c * (size + separation), so the last valid index is
## floor((sheet - size) / stride) — the same stride math as
## tests/test_tileset_bounds.gd.
static func tile_grid_size() -> Vector2i:
	var stride := TILE_SIZE + TILE_SEPARATION
	var sheet := sheet_size()
	if sheet == Vector2i.ZERO:
		return Vector2i.ZERO
	return Vector2i(
		(sheet.x - TILE_SIZE.x) / stride.x + 1,
		(sheet.y - TILE_SIZE.y) / stride.y + 1)


static func is_tile_in_bounds(col: int, row: int) -> bool:
	var grid := tile_grid_size()
	return col >= 0 and row >= 0 and col < grid.x and row < grid.y


## Normalised UV rect of one tile, inset by UV_INSET_TEXELS on every edge.
static func tile_uv_rect(col: int, row: int) -> Rect2:
	var sheet := Vector2(sheet_size())
	if sheet == Vector2.ZERO:
		return Rect2()
	var stride := TILE_SIZE + TILE_SEPARATION
	var inset := Vector2(UV_INSET_TEXELS, UV_INSET_TEXELS)
	var origin_px := Vector2(col * stride.x, row * stride.y) + inset
	var size_px := Vector2(TILE_SIZE) - inset * 2.0
	return Rect2(origin_px / sheet, size_px / sheet)
```

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_world_scale.gd" -gexit
```
Expected: PASS, 7 tests, zero failures.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" Specifically: does `tile_uv_rect` work for any (col, row) on the grid, not just (0,0)? `test_tile_uv_rect_advances_by_the_separation_stride` and `test_last_tile_uv_rect_stays_inside_the_texture` are the two that answer this. If either was made to pass by special-casing, fix it now.

**Step 6: Commit**

```powershell
git add scripts/poc3d/world_scale.gd tests/test_poc3d_world_scale.gd
git commit -m "feat: add WorldScale constants and tile UV math for the 3D POC (#101)"
```

---

### Task 2: `TileFloor` — one ArrayMesh of UV-mapped quads

**Files:**
- Create: `scripts/poc3d/tile_floor.gd`
- Test: `tests/test_poc3d_tile_floor.gd`

**Depends on:** Task 1 — calls `WorldScale.tile_uv_rect()` and `WorldScale.is_tile_in_bounds()`.
**Parallelizable with:** Task 3 — Task 3 only edits `.import` files and defines no symbol this task uses.

**Step 1: Write the failing GUT test**

```gdscript
# tests/test_poc3d_tile_floor.gd
extends GutTest

const FLOOR_TILES := Vector2i(4, 3)   # small and non-square, so a transposed
                                      # width/height bug cannot hide
const VERTS_PER_QUAD := 6             # two triangles, un-indexed
const POSITION_TOLERANCE := 0.0001
const UV_TOLERANCE := 0.000001


func _build_floor() -> TileFloor:
	var floor_node := TileFloor.new()
	floor_node.tiles = FLOOR_TILES
	add_child_autofree(floor_node)
	return floor_node


func test_mesh_has_one_surface_covering_every_tile():
	var floor_node := _build_floor()
	assert_not_null(floor_node.mesh, "TileFloor did not build a mesh")
	assert_eq(floor_node.mesh.get_surface_count(), 1,
		"the whole floor must be a single surface, so it is one draw call")
	var verts: PackedVector3Array = floor_node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_eq(verts.size(), FLOOR_TILES.x * FLOOR_TILES.y * VERTS_PER_QUAD)


func test_floor_is_one_world_unit_per_tile_and_centred_on_origin():
	var floor_node := _build_floor()
	var aabb: AABB = floor_node.mesh.get_aabb()
	assert_almost_eq(aabb.size.x, float(FLOOR_TILES.x), POSITION_TOLERANCE,
		"one tile must span exactly one world unit")
	assert_almost_eq(aabb.size.z, float(FLOOR_TILES.y), POSITION_TOLERANCE)
	assert_almost_eq(aabb.position.x, -FLOOR_TILES.x * 0.5, POSITION_TOLERANCE,
		"floor must be centred on the origin so the camera framing is predictable")
	assert_almost_eq(aabb.position.z, -FLOOR_TILES.y * 0.5, POSITION_TOLERANCE)


func test_every_uv_lies_inside_the_selected_tile_region():
	var floor_node := _build_floor()
	var expected := WorldScale.tile_uv_rect(floor_node.tile_col, floor_node.tile_row)
	var uvs: PackedVector2Array = floor_node.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	assert_gt(uvs.size(), 0, "mesh carries no UVs")
	var strays := 0
	for uv in uvs:
		if uv.x < expected.position.x - UV_TOLERANCE or uv.x > expected.end.x + UV_TOLERANCE \
				or uv.y < expected.position.y - UV_TOLERANCE or uv.y > expected.end.y + UV_TOLERANCE:
			strays += 1
	assert_eq(strays, 0,
		"%d UV(s) fall outside the tile region %s — they would sample the 1px separation gap"
		% [strays, expected])


func test_changing_the_tile_rebuilds_the_uvs():
	var floor_node := _build_floor()
	var before: PackedVector2Array = floor_node.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	floor_node.tile_col = floor_node.tile_col + 1
	var after: PackedVector2Array = floor_node.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	assert_ne(before[0], after[0], "setting tile_col must rebuild the mesh, not just store a value")


func test_material_samples_with_nearest_filtering():
	# The epic's finding #2: default_texture_filter=0 is a 2D-only setting, so a
	# 3D material that does not opt in renders pixel art smoothed.
	var floor_node := _build_floor()
	var material := floor_node.get_active_material(0) as StandardMaterial3D
	assert_not_null(material, "floor has no StandardMaterial3D")
	assert_eq(material.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST)
	assert_not_null(material.albedo_texture, "floor material has no albedo texture")


func test_out_of_bounds_tile_is_rejected_rather_than_sampling_off_sheet():
	var floor_node := _build_floor()
	var grid := WorldScale.tile_grid_size()
	floor_node.tile_col = grid.x + 10
	assert_true(WorldScale.is_tile_in_bounds(floor_node.tile_col, floor_node.tile_row),
		"tile_col must clamp into the grid rather than store an off-sheet coordinate")
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_tile_floor.gd" -gexit
```
Expected: FAIL — `TileFloor` is an unknown identifier.

**Step 3: Write minimal implementation**

```gdscript
# scripts/poc3d/tile_floor.gd
@tool
class_name TileFloor
extends MeshInstance3D

## A flat floor built as ONE ArrayMesh of 1x1-world-unit quads, every quad's UVs
## addressing the same 16x16 region of the shared roguelike tile sheet.
##
## Why not one MeshInstance3D per tile with an AtlasTexture: the sheet has 1px
## separation between tiles, and Godot's UV repeat repeats the whole texture,
## not a region — so a tiled AtlasTexture would smear the neighbouring tiles in.
## Writing the UVs directly sidesteps that and keeps the floor at one draw call.
##
## @tool so the editor viewport shows the true texel density while the room's
## camera angle is being hand-authored (issue #101, R6).

## Floor extent in tiles. One tile is one world unit.
@export var tiles := Vector2i(12, 12):
	set(value):
		tiles = Vector2i(maxi(1, value.x), maxi(1, value.y))
		_rebuild()

@export var tile_col := 5:
	set(value):
		tile_col = clampi(value, 0, maxi(0, WorldScale.tile_grid_size().x - 1))
		_rebuild()

@export var tile_row := 0:
	set(value):
		tile_row = clampi(value, 0, maxi(0, WorldScale.tile_grid_size().y - 1))
		_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	mesh = _build_mesh()
	material_override = _build_material()


func _build_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(WorldScale.SHEET_PATH)
	# Explicit: rendering/textures/canvas_textures/default_texture_filter is a
	# 2D-only project setting and does not reach 3D materials.
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.texture_repeat = false
	return material


func _build_mesh() -> ArrayMesh:
	var uv := WorldScale.tile_uv_rect(tile_col, tile_row)
	var origin := Vector3(-tiles.x * 0.5, 0.0, -tiles.y * 0.5)

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3.UP)

	for row in tiles.y:
		for col in tiles.x:
			var x0 := origin.x + col
			var z0 := origin.z + row
			var x1 := x0 + 1.0
			var z1 := z0 + 1.0

			# Godot treats CLOCKWISE winding as the front face. Viewed from +Y
			# with +X to the right, a -> b -> c below reads clockwise, so the
			# floor faces up.
			var a := Vector3(x0, 0.0, z0)
			var b := Vector3(x1, 0.0, z0)
			var c := Vector3(x1, 0.0, z1)
			var d := Vector3(x0, 0.0, z1)

			var uv_a := uv.position
			var uv_b := Vector2(uv.end.x, uv.position.y)
			var uv_c := uv.end
			var uv_d := Vector2(uv.position.x, uv.end.y)

			_add_triangle(surface, a, b, c, uv_a, uv_b, uv_c)
			_add_triangle(surface, a, c, d, uv_a, uv_c, uv_d)

	return surface.commit()


func _add_triangle(surface: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3,
		uv0: Vector2, uv1: Vector2, uv2: Vector2) -> void:
	surface.set_uv(uv0)
	surface.add_vertex(p0)
	surface.set_uv(uv1)
	surface.add_vertex(p1)
	surface.set_uv(uv2)
	surface.add_vertex(p2)
```

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_tile_floor.gd" -gexit
```
Expected: PASS, 6 tests, zero failures.

If `test_every_uv_lies_inside_the_selected_tile_region` fails, the bug is in `WorldScale.tile_uv_rect`, not here — go back to Task 1 rather than loosening the tolerance.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" The test uses a deliberately non-square 4x3 floor precisely to catch a transposed `tiles.x` / `tiles.y`. Also confirm `_rebuild()` is driven by the setters, not only by `_ready()` — otherwise the `@tool` editor preview will not update when you change the tile in the Inspector, which is the whole point of `@tool` here.

**Step 6: Commit**

```powershell
git add scripts/poc3d/tile_floor.gd tests/test_poc3d_tile_floor.gd
git commit -m "feat: build the POC floor as one UV-mapped ArrayMesh (#101)"
```

---

### Task 3: Stop Godot re-importing pixel-art textures for 3D

**Files:**
- Modify: `assets/sprites/tiles/roguelikeSheet_transparent.png.import`
- Modify: `assets/sprites/characters/player.png.import`
- Modify: `assets/sprites/characters/player_left.png.import`

**Depends on:** none
**Parallelizable with:** Task 1, Task 2 — touches only `.import` files; defines and consumes no GDScript symbol.

**Step 1: Write the content**

In each of the three files, change the single line:

```
detect_3d/compress_to=1
```

to:

```
detect_3d/compress_to=0
```

Leave `compress/mode=0` and `mipmaps/generate=false` exactly as they are — they are already correct for pixel art.

Why all three: the floor material uses the tile sheet, and the Task 8 reference sprite uses `data/sprites/player_frames.tres`, which pulls both `player.png` and `player_left.png`. Godot re-imports a texture the first time it is used in a 3D material — switching it to VRAM block compression and generating mipmaps — and rewrites the `.import` file in place. Since commit `1b5e967` this repo tracks `.import` metadata in git, so leaving this on produces both blurry textures and a mystery diff.

**Step 2: Verify**

```powershell
git diff --stat
grep -n "detect_3d" assets/sprites/tiles/roguelikeSheet_transparent.png.import assets/sprites/characters/player.png.import assets/sprites/characters/player_left.png.import
```
Expected: three files changed, one line each; every `detect_3d/compress_to` now reads `0`.

Then confirm the 2D game is unaffected — this setting only governs what happens on first 3D use, so the 2D tileset must render identically:

```powershell
./tools/godot.ps1 --path .
```
Expected: the game launches to character creation and the station tiles look exactly as before. Close it.

**Step 3: Commit**

```powershell
git add assets/sprites/tiles/roguelikeSheet_transparent.png.import assets/sprites/characters/player.png.import assets/sprites/characters/player_left.png.import
git commit -m "chore: disable detect_3d reimport on textures the 3D POC will use (#101)"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 1, Task 3 | Different output files, no shared symbols |
| B (sequential) | Task 2 | Depends on Task 1's `WorldScale`; may start as soon as Task 1 commits, regardless of Task 3 |

### Smoketest Checkpoint 1 — foundation is green and the 2D game is untouched

**Step 1: Fetch and merge latest master**
```powershell
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: all tests pass, zero failures — the two new suites plus every pre-existing one. `test_tileset_bounds.gd` in particular must still pass; it reads the same sheet this batch touched.

**Step 3: Launch game and verify visually**
```powershell
./tools/godot.ps1 --path .
```

**Step 4: Confirm with user**

Ask the user to confirm: the 2D game still launches to character creation, plays into the station, and the tilemap art is unchanged — no blurring, no colour shift. Nothing 3D exists yet; this checkpoint exists solely to prove the shared-asset change was harmless. Wait for confirmation before starting Batch 2.

---

## Batch 2 — First light: a room on screen

### Task 4: `RoomCamera` — the per-room camera contract

**Files:**
- Create: `scripts/poc3d/room_camera.gd`
- Create: `scenes/poc3d/room_camera.tscn`
- Test: `tests/test_poc3d_room_camera.gd`

**Depends on:** Task 1 — reads `WorldScale.CAMERA_FOV` / `CAMERA_PITCH_DEGREES` / `CAMERA_YAW_DEGREES`.
**Parallelizable with:** none — Task 5 instances the scene this task creates, and Task 6 instances Task 5's scene, so Batch 2 is a strict chain.

**Step 1: Write the failing GUT test**

```gdscript
# tests/test_poc3d_room_camera.gd
extends GutTest

const ANGLE_TOLERANCE := 0.001


func test_camera_adopts_the_contract_angle_by_default():
	var camera := RoomCamera.new()
	add_child_autofree(camera)
	assert_almost_eq(camera.fov, WorldScale.CAMERA_FOV, ANGLE_TOLERANCE)
	assert_almost_eq(camera.rotation_degrees.x, WorldScale.CAMERA_PITCH_DEGREES, ANGLE_TOLERANCE)
	assert_almost_eq(camera.rotation_degrees.y, WorldScale.CAMERA_YAW_DEGREES, ANGLE_TOLERANCE)
	assert_eq(camera.projection, Camera3D.PROJECTION_PERSPECTIVE)


func test_a_room_can_hand_author_its_own_angle():
	# R6: the hand-placed node IS the contract, so a room must be able to depart
	# from the shared starting values without the script stamping them back.
	var camera := RoomCamera.new()
	camera.use_contract_angle = false
	camera.rotation_degrees = Vector3(-20.0, 90.0, 0.0)
	add_child_autofree(camera)
	assert_almost_eq(camera.rotation_degrees.x, -20.0, ANGLE_TOLERANCE)
	assert_almost_eq(camera.rotation_degrees.y, 90.0, ANGLE_TOLERANCE)


func test_position_is_never_touched_by_the_script():
	# Only the ANGLE is contractual. Framing is hand-placed per room.
	var camera := RoomCamera.new()
	camera.position = Vector3(3.0, 9.0, 3.0)
	add_child_autofree(camera)
	assert_almost_eq(camera.position.y, 9.0, ANGLE_TOLERANCE)
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_room_camera.gd" -gexit
```
Expected: FAIL — `RoomCamera` is an unknown identifier.

**Step 3: Write minimal implementation**

```gdscript
# scripts/poc3d/room_camera.gd
@tool
class_name RoomCamera
extends Camera3D

## The camera contract for POC rooms (issue #101, R6/R7).
##
## The ANGLE is shared and lives in WorldScale, so every room starts from the
## same authored look and changing it changes every room. The POSITION is not:
## framing is hand-placed per room and this script never writes it.
##
## There is deliberately no rotation input and no runtime controller (R7).
##
## @tool so the editor viewport shows the contract angle while the room is being
## composed by eye, rather than whatever literal the .tscn last happened to hold.

## Set false in a room that needs its own angle; the hand-authored rotation is
## then left alone.
@export var use_contract_angle := true


func _ready() -> void:
	if not use_contract_angle:
		return
	projection = PROJECTION_PERSPECTIVE
	fov = WorldScale.CAMERA_FOV
	rotation_degrees = Vector3(
		WorldScale.CAMERA_PITCH_DEGREES,
		WorldScale.CAMERA_YAW_DEGREES,
		0.0)
```

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_room_camera.gd" -gexit
```
Expected: PASS, 3 tests, zero failures.

**Step 5: Create the scene**

In the Godot editor: new scene, root node `Camera3D`, rename to `RoomCamera`, attach `scripts/poc3d/room_camera.gd`, save as `scenes/poc3d/room_camera.tscn`. Set `position` to `(9, 9, 9)` as a starting framing — it will be adjusted by eye at Smoketest 2. Do not set `fov` or `rotation` by hand; the script owns those.

**Step 6: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" Concretely: a second room instancing this scene must be able to sit at a different position and, if it opts out, a different angle. Both are covered by the tests above.

**Step 7: Commit**

```powershell
git add scripts/poc3d/room_camera.gd scenes/poc3d/room_camera.tscn tests/test_poc3d_room_camera.gd
git commit -m "feat: add the RoomCamera contract for POC rooms (#101)"
```

---

### Task 5: `test_room.tscn` — greyboxed geometry, light and camera

**Files:**
- Create: `scenes/poc3d/rooms/test_room.tscn`

**Depends on:** Task 2 (`TileFloor`), Task 3 (`.import` fix must land before the sheet is first used in 3D), Task 4 (`room_camera.tscn`).
**Parallelizable with:** none — it consumes the output of three prior tasks and is consumed by Task 6.

**Step 1: Write the content**

Build this tree in the Godot editor and save to `scenes/poc3d/rooms/test_room.tscn`:

```
TestRoom (Node3D)
├── Floor (MeshInstance3D, script scripts/poc3d/tile_floor.gd)
│     tiles = (12, 12)     # 12x12 world units, centred on the origin
│     tile_col = 5, tile_row = 0    # neutral floor tile; adjust by eye later
├── Blocks (Node3D)
│   ├── BlockA (MeshInstance3D)  BoxMesh size (2, 1, 2)   position (-3, 0.5, 2)
│   ├── BlockB (MeshInstance3D)  BoxMesh size (1, 3, 1)   position (2, 1.5, -1)
│   └── BlockC (MeshInstance3D)  BoxMesh size (3, 2, 1)   position (1, 1.0, 3)
├── Sun (DirectionalLight3D)
│     rotation_degrees = (-50, -40, 0)
│     shadow_enabled = true
├── Env (WorldEnvironment)
└── RoomCamera (instance of scenes/poc3d/room_camera.tscn)
      position = (9, 9, 9)   # hand-authored framing; angle comes from the script
```

Details that matter:

- Each block's `MeshInstance3D` gets its own `StandardMaterial3D` with a flat `albedo_color` (three distinguishable greys, e.g. `#8a8f98`, `#6d727a`, `#a7adb6`). Blocks stay untextured on purpose — their job is to give the camera something to occlude against and to show polygon edge aliasing. The floor is the surface that proves texel density and filtering.
- The `WorldEnvironment` needs a new `Environment` resource with `background_mode = Custom Color` (a dark slate, e.g. `#1a1d24`), `ambient_light_source = Color`, and a low ambient energy (~0.3). **Do not** enable SSAO, SSIL, SSR, SDFGI or volumetric fog — none are available on the Mobile renderer.
- Only one `DirectionalLight3D`. No `OmniLight3D` in this PRD: the Mobile renderer caps omni/spot lights per object and PRD 1 has no need of them.
- Block heights are deliberately different so the fixed camera angle produces visible depth layering.

**Step 2: Verify**

Open `scenes/poc3d/rooms/test_room.tscn` in the editor and press F6. Expected: a 12x12 tiled floor with three grey blocks on it, viewed corner-on from above. Because the scripts are `@tool`, the editor viewport should already show this before you press anything — the floor textured with a single repeated tile, not a stretched sheet.

At this point adjust `RoomCamera.position` by eye until the floor roughly fills the frame. Leave `fov` and `rotation` alone.

**Step 3: Commit**

```powershell
git add scenes/poc3d/rooms/test_room.tscn
git commit -m "feat: add the greybox test room for the 3D POC (#101)"
```

---

### Task 6: `poc_entry.tscn` — the low-res render target and the HUD above it

**Files:**
- Create: `scripts/poc3d/poc_entry.gd`
- Create: `scenes/poc3d/poc_entry.tscn`
- Create: `scenes/poc3d/README.md`

**Depends on:** Task 5 — instances `test_room.tscn`.
**Parallelizable with:** none — it is the last link in Batch 2's chain and every other task in the batch feeds it.

**Step 1: Write the script**

```gdscript
# scripts/poc3d/poc_entry.gd
@tool
extends Node

## Entry point for the Xenogears-presentation POC (issue #101).
##
## Tree shape, and why:
##
##   PocEntry
##   ├── SubViewportContainer   stretch = true, full-rect
##   │   └── SubViewport        the 3D world renders here, at 480x270
##   │       └── TestRoom
##   └── HUD                    instanced hud.tscn — a SIBLING, never a child
##
## THE INVARIANT: the HUD must never be parented under the SubViewport. Anything
## inside the SubViewport is rendered into the low-res target and upscaled with
## it, which would turn the UI text into mush. hud.tscn is already a CanvasLayer
## with layer = 1, so as a sibling it draws above the container at full window
## resolution with no wrapper node needed. tests/test_poc3d_pipeline.gd asserts
## this and will fail if a later PRD reparents it.
##
## SubViewport.size is deliberately NOT assigned here. SubViewportContainer with
## stretch = true drives the SubViewport's size from the container, so any
## assignment would be silently overwritten. The container measures 480x270
## because project.godot's stretch/mode = "canvas_items" gives the root viewport
## that logical size; the root stretch then does the nearest-neighbour upscale,
## nearest because rendering/textures/canvas_textures/default_texture_filter=0
## applies to the container's canvas texture. WorldScale.RENDER_WIDTH/HEIGHT are
## the expected values the structural test asserts against.

@onready var _viewport: SubViewport = $SubViewportContainer/SubViewport


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var actual := _viewport.size
	var expected := Vector2i(WorldScale.RENDER_WIDTH, WorldScale.RENDER_HEIGHT)
	if actual != expected:
		push_warning(
			"POC render target is %s, expected %s — check display/window/stretch/mode in project.godot"
			% [actual, expected])
```

**Step 2: Build the scene**

New scene in the editor, saved as `scenes/poc3d/poc_entry.tscn`:

```
PocEntry (Node)                          script = scripts/poc3d/poc_entry.gd
├── SubViewportContainer
│     anchors_preset = Full Rect
│     stretch = true
│     mouse_filter = Ignore
│   └── SubViewport
│         render_target_update_mode = Always
│         handle_input_locally = false
│         transparent_bg = false
│       └── TestRoom  (instance of scenes/poc3d/rooms/test_room.tscn)
└── HUD  (instance of scenes/ui/hud.tscn, UNMODIFIED)
```

`hud.tscn` is instanced with no property overrides whatsoever — R4 requires it render correctly unchanged. Its `_ready()` connects to `GameState.resource_changed` and `ClockManager.time_advanced`, both of which are autoloads and therefore already available in this scene.

**Step 3: Write `scenes/poc3d/README.md`**

Create the file with this content (the fenced blocks below are part of the file):

- Title: `# 3D presentation POC`
- Opening paragraph: Standalone proof-of-concept for epic #100 (Xenogears-style presentation). Nothing here is reachable from the 2D game: `main.tscn`, `go_to_area()` and the seven existing areas are untouched, and `project.godot` still boots `scenes/character_creation.tscn`.
- Section `## Running it`, containing a `powershell` fenced block with:
  `./tools/godot.ps1 --path . "res://scenes/poc3d/poc_entry.tscn"`
- Immediately after it, the note: Quote the `res://` argument — PowerShell splits an unquoted one on the colon.
- A second `powershell` fenced block for reading renderer warnings:
  `./tools/godot.ps1 -Console --path . "res://scenes/poc3d/poc_entry.tscn"`
- Note that opening `scenes/poc3d/poc_entry.tscn` in the editor and pressing F6 also works.
- Section `## Shape`, containing this table:

  | File | Role |
  |------|------|
  | `poc_entry.tscn` | The 480x270 `SubViewport` render target, with `hud.tscn` as a sibling above it |
  | `rooms/test_room.tscn` | Greybox geometry, one directional light, the camera |
  | `room_camera.tscn` | The per-room camera contract — FOV/pitch/yaw from `WorldScale` |
  | `scripts/poc3d/world_scale.gd` | Every constant. 16 px = 1 world unit |

- Closing line: The HUD must never be moved inside the `SubViewport`; see the comment in `scripts/poc3d/poc_entry.gd`.

No `docs/index.md` entry is needed — this README lives under `scenes/`, not `docs/`.

**Step 4: Verify**

```powershell
./tools/godot.ps1 -Console --path . "res://scenes/poc3d/poc_entry.tscn"
```
Expected: the greybox room fills the window with visibly chunky pixels, and the HUD row (`Rations: 0  Parts: 0  Energy: 0  Scrap: 0  Day 1  06:00`) is crisp along the top.

**Step 5: Commit**

```powershell
git add scripts/poc3d/poc_entry.gd scenes/poc3d/poc_entry.tscn scenes/poc3d/README.md
git commit -m "feat: add the low-res 3D POC entry scene (#101)"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 4 | Depends on Task 1; produces `room_camera.tscn` |
| B (sequential) | Task 5 | Depends on Tasks 2, 3, 4 — instances the camera scene and uses `TileFloor` |
| C (sequential) | Task 6 | Depends on Task 5 — instances the room scene |

Batch 2 is a strict chain; nothing in it parallelises.

### Smoketest Checkpoint 2 — AC1, AC3, AC4, AC6, AC7

**Step 1: Fetch and merge latest master**
```powershell
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: all tests pass, zero failures.

**Step 3: Launch the POC and verify visually**
```powershell
./tools/godot.ps1 -Console --path . "res://scenes/poc3d/poc_entry.tscn"
```

**Step 4: Confirm with user**

Walk the user through each acceptance criterion and wait for confirmation on all of them:

- **AC1** — the 3D image is visibly chunky: individual pixels are square and discernible, block edges are hard stair-steps rather than smooth or blurred lines.
- **AC3** — the HUD text along the top is crisp and full-resolution, clearly sharper than the 3D behind it.
- **AC4** — resize the window (drag a corner, then maximise). The 3D upscale stays nearest-neighbour and the HUD stays crisp. Black bars on a non-16:9 window are *expected*, not a defect: `stretch/aspect` is at the engine default, which is how the 2D game already behaves.
- **AC7** — read the console. Confirm no renderer or Mobile-backend errors or warnings. Godot's normal startup chatter (Vulkan device selection, driver name) is benign; anything mentioning an unsupported feature, a missing texture, or the POC's own `push_warning` about the render target size is not.
- **AC6** — separately launch the 2D game and confirm no regression:
  ```powershell
  ./tools/godot.ps1 --path .
  ```

**Contingency (only if AC4 fails):** if the image is soft, or resizing produces a double-scale shimmer, the root `canvas_items` stretch is not composing cleanly with the container. Fall back to: set `SubViewportContainer.stretch = false`, pin `SubViewport.size` to `Vector2i(WorldScale.RENDER_WIDTH, WorldScale.RENDER_HEIGHT)`, and have `poc_entry.gd` compute an integer scale factor on `get_tree().root.size_changed`. Do this as its own task and commit separately so the two approaches stay distinguishable in the history. Do not attempt it unless the smoketest actually fails.

---

## Batch 3 — Sprite reference and the structural guard

### Task 7: `PixelSprite3D` — sprite settings derived from `WorldScale`

**Files:**
- Create: `scripts/poc3d/pixel_sprite_3d.gd`
- Test: `tests/test_poc3d_pixel_sprite.gd`

**Depends on:** Task 1 — reads `WorldScale.SPRITE_PIXEL_SIZE` and `WorldScale.CAMERA_YAW_DEGREES`.
**Parallelizable with:** none — Task 8 places the node this task defines, and Task 9 asserts against the result of Task 8.

**Step 1: Write the failing GUT test**

```gdscript
# tests/test_poc3d_pixel_sprite.gd
extends GutTest

const FRAMES_PATH := "res://data/sprites/player_frames.tres"
const TOLERANCE := 0.0001


func _build_sprite() -> PixelSprite3D:
	var sprite := PixelSprite3D.new()
	sprite.sprite_frames = load(FRAMES_PATH)
	sprite.animation = &"idle_down"
	add_child_autofree(sprite)
	return sprite


func test_pixel_size_comes_from_the_world_scale_constant():
	var sprite := _build_sprite()
	assert_almost_eq(sprite.pixel_size, WorldScale.SPRITE_PIXEL_SIZE, TOLERANCE,
		"pixel_size must be derived from PIXELS_PER_UNIT, not stored in the .tscn")


func test_billboarding_is_off_so_the_z_buffer_can_occlude_the_sprite():
	var sprite := _build_sprite()
	assert_eq(sprite.billboard, BaseMaterial3D.BILLBOARD_DISABLED)
	assert_eq(sprite.alpha_cut, SpriteBase3D.ALPHA_CUT_DISCARD,
		"alpha scissor is what lets geometry occlude the sprite correctly")


func test_sprite_samples_with_nearest_filtering():
	var sprite := _build_sprite()
	assert_eq(sprite.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST)


func test_sprite_faces_the_contract_camera_yaw():
	var sprite := _build_sprite()
	assert_almost_eq(sprite.rotation_degrees.y, WorldScale.CAMERA_YAW_DEGREES, TOLERANCE)


func test_offset_lifts_the_feet_to_the_node_origin():
	# A 32px-tall frame is centred by default, sinking half of it below the
	# floor. The lift is half the frame height, read from the frame itself.
	var sprite := _build_sprite()
	var frame: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	assert_almost_eq(sprite.offset.y, frame.get_height() * 0.5, TOLERANCE)
```

**Step 2: Run test to verify it fails**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_pixel_sprite.gd" -gexit
```
Expected: FAIL — `PixelSprite3D` is an unknown identifier.

**Step 3: Write minimal implementation**

```gdscript
# scripts/poc3d/pixel_sprite_3d.gd
@tool
class_name PixelSprite3D
extends AnimatedSprite3D

## A character sprite standing in the 3D world at the project's pixel scale.
##
## PRD 1 scope: this node is a MEASURING STICK. It exists so AC2 can be judged —
## is a 16x32 sprite's pixel the same size as a 3D pixel? — and so pixel_size is
## proven to come from WorldScale. It has no movement, no input, and no facing
## logic; PRD 2 (#102) owns all sprite behaviour.
##
## Billboarding is off and alpha_cut is ALPHA_CUT_DISCARD so the depth buffer
## handles occlusion against geometry rather than the sprite always drawing on
## top. Yaw is fixed to the camera's contract angle: with 4-direction atlases and
## a locked camera there is nothing to rotate toward.


func _ready() -> void:
	pixel_size = WorldScale.SPRITE_PIXEL_SIZE
	billboard = BaseMaterial3D.BILLBOARD_DISABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	# default_texture_filter in project.godot is 2D-only and does not reach here.
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	rotation_degrees.y = WorldScale.CAMERA_YAW_DEGREES
	_lift_feet_to_origin()


## AnimatedSprite3D centres the frame on the node, so half the sprite would sink
## below the floor. offset is in pixels and +Y is up in 3D, so lifting by half
## the frame height puts the feet on the node's origin. Read from the frame
## rather than typed, so a different-sized character needs no code change.
func _lift_feet_to_origin() -> void:
	if sprite_frames == null or not sprite_frames.has_animation(animation):
		return
	if sprite_frames.get_frame_count(animation) == 0:
		return
	var frame: Texture2D = sprite_frames.get_frame_texture(animation, 0)
	if frame == null:
		return
	offset = Vector2(0.0, frame.get_height() * 0.5)
```

**Step 4: Run tests to verify they pass**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_pixel_sprite.gd" -gexit
```
Expected: PASS, 5 tests, zero failures.

**Step 5: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" `_lift_feet_to_origin` must read the frame height rather than assume 32 — a taller NPC in PRD 2 must need no edit here. If `32` appears anywhere in this file, that is the defect.

**Step 6: Commit**

```powershell
git add scripts/poc3d/pixel_sprite_3d.gd tests/test_poc3d_pixel_sprite.gd
git commit -m "feat: add PixelSprite3D deriving sprite scale from WorldScale (#101)"
```

---

### Task 8: Place the reference sprite in the test room

**Files:**
- Modify: `scenes/poc3d/rooms/test_room.tscn`

**Depends on:** Task 5 (the room exists), Task 7 (`PixelSprite3D`).
**Parallelizable with:** none — it edits the file Task 5 created and is asserted against by Task 9.

**Step 1: Write the content**

Add one node to `scenes/poc3d/rooms/test_room.tscn`:

```
TestRoom (Node3D)
└── ReferenceSprite (AnimatedSprite3D, script scripts/poc3d/pixel_sprite_3d.gd)
      sprite_frames = res://data/sprites/player_frames.tres
      animation = "idle_down"
      position = (2, 0, 0.5)
```

Set nothing else. `pixel_size`, `billboard`, `alpha_cut`, `texture_filter`, `rotation` and `offset` are all owned by the script and will be overwritten — leave the Inspector defaults alone so the `.tscn` never looks like the source of truth.

The position places it close to `BlockB`, so occlusion is observable: the sprite must read as correctly behind or in front of geometry rather than always drawing on top.

**Step 2: Verify**

Open the room and press F6. Expected: the player sprite stands on the floor — feet on the surface, not sunk into it or floating — at the same chunky pixel scale as the floor texture. Because the script is `@tool`, this should already be visible in the editor viewport before pressing anything.

**Step 3: Commit**

```powershell
git add scenes/poc3d/rooms/test_room.tscn
git commit -m "feat: place the AC2 reference sprite in the test room (#101)"
```

---

### Task 9: Structural test guarding the pipeline invariants

**Files:**
- Test: `tests/test_poc3d_pipeline.gd`

**Depends on:** Task 6 (`poc_entry.tscn`), Task 8 (the sprite is in the room).
**Parallelizable with:** none — it asserts against the fully-assembled scene tree, so every other task must be complete.

**Step 1: Write the test**

This is a regression guard over scenes that already exist, so it is expected to pass on first run. Step 3 proves it can actually fail before it is trusted.

```gdscript
# tests/test_poc3d_pipeline.gd
extends GutTest

## Guards the invariants PRD 1 (#101) exists to establish, so PRDs 2-4 cannot
## silently undo them while editing these same scenes.

const ENTRY_PATH := "res://scenes/poc3d/poc_entry.tscn"
const ANGLE_TOLERANCE := 0.001
const SIZE_TOLERANCE := 0.0001

var _entry: Node


func before_each():
	_entry = load(ENTRY_PATH).instantiate()
	add_child_autofree(_entry)
	# Control layout and the container-driven SubViewport resize both settle
	# over a frame, so read nothing before this.
	await wait_frames(2)


func _viewport() -> SubViewport:
	return _entry.get_node("SubViewportContainer/SubViewport")


func test_the_world_renders_into_a_480x270_target():
	assert_eq(_viewport().size, Vector2i(WorldScale.RENDER_WIDTH, WorldScale.RENDER_HEIGHT),
		"the 3D world is not rendering at the low-res size; check stretch/mode in project.godot")


func test_the_container_upscales_rather_than_cropping():
	var container: SubViewportContainer = _entry.get_node("SubViewportContainer")
	assert_true(container.stretch,
		"stretch = false would crop the SubViewport instead of upscaling it")


func test_the_hud_is_not_inside_the_low_res_target():
	# THE invariant of this PRD. A HUD parented under the SubViewport would be
	# rendered at 480x270 and upscaled with the world, turning the text to mush.
	var hud := _entry.find_child("HUD", true, false)
	assert_not_null(hud, "poc_entry.tscn no longer instances hud.tscn")
	assert_false(_viewport().is_ancestor_of(hud),
		"the HUD has been reparented under the SubViewport — it must stay a sibling")
	assert_true(hud is CanvasLayer, "hud.tscn must remain a CanvasLayer to draw above the container")


func test_the_room_camera_uses_the_contract_angle():
	var camera := _entry.find_child("RoomCamera", true, false) as Camera3D
	assert_not_null(camera, "the test room has no RoomCamera")
	assert_almost_eq(camera.fov, WorldScale.CAMERA_FOV, ANGLE_TOLERANCE)
	assert_almost_eq(camera.rotation_degrees.x, WorldScale.CAMERA_PITCH_DEGREES, ANGLE_TOLERANCE)
	assert_almost_eq(camera.rotation_degrees.y, WorldScale.CAMERA_YAW_DEGREES, ANGLE_TOLERANCE)


func test_the_floor_material_samples_with_nearest_filtering():
	var floor_node := _entry.find_child("Floor", true, false) as MeshInstance3D
	assert_not_null(floor_node, "the test room has no Floor")
	var material := floor_node.get_active_material(0) as StandardMaterial3D
	assert_not_null(material)
	assert_eq(material.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST,
		"a smoothed 3D material is the epic's finding #2 regressing")


func test_the_reference_sprite_matches_the_world_scale():
	var sprite := _entry.find_child("ReferenceSprite", true, false) as AnimatedSprite3D
	assert_not_null(sprite, "the AC2 reference sprite is missing from the test room")
	assert_almost_eq(sprite.pixel_size, WorldScale.SPRITE_PIXEL_SIZE, SIZE_TOLERANCE)
	assert_eq(sprite.billboard, BaseMaterial3D.BILLBOARD_DISABLED)
	assert_eq(sprite.alpha_cut, SpriteBase3D.ALPHA_CUT_DISCARD)


func test_only_one_directional_light_within_mobile_limits():
	var lights := 0
	for node in _entry.find_children("*", "Light3D", true, false):
		lights += 1
		assert_false(node is OmniLight3D or node is SpotLight3D,
			"PRD 1 lights with a single DirectionalLight3D; Mobile caps omni/spot per object")
	assert_eq(lights, 1, "expected exactly one light in the POC scene")
```

**Step 2: Run the test**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_pipeline.gd" -gexit
```
Expected: PASS, 7 tests, zero failures.

**Step 3: Prove the test can fail**

A regression guard that has never gone red is not yet a test. Temporarily reparent the `HUD` node under the `SubViewport` in `poc_entry.tscn`, re-run:

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_poc3d_pipeline.gd" -gexit
```
Expected: `test_the_hud_is_not_inside_the_low_res_target` FAILS.

Then revert the scene change (`git checkout -- scenes/poc3d/poc_entry.tscn`) and re-run to confirm green again. Do not commit the broken state.

**Step 4: Refactor checkpoint**

Ask: "Does this generalize, or did I hard-code something that breaks when N > 1?" The test uses `find_child` rather than fixed paths precisely so PRD 3 can restructure the room without breaking it. If any assertion depends on a literal node path beyond `SubViewportContainer/SubViewport`, loosen it now.

**Step 5: Commit**

```powershell
git add tests/test_poc3d_pipeline.gd
git commit -m "test: guard the low-res pipeline invariants against later PRDs (#101)"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 3

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 7 | Depends on Task 1; defines `PixelSprite3D` |
| B (sequential) | Task 8 | Depends on Tasks 5 and 7 — edits `test_room.tscn` |
| C (sequential) | Task 9 | Depends on Tasks 6 and 8 — asserts the assembled tree |

Batch 3 is a strict chain; nothing in it parallelises.

### Smoketest Checkpoint 3 — full acceptance sweep

**Step 1: Fetch and merge latest master**
```powershell
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit
```
Expected: all tests pass, zero failures — five new suites plus every pre-existing one.

**Step 3: Launch and verify visually**
```powershell
./tools/godot.ps1 -Console --path . "res://scenes/poc3d/poc_entry.tscn"
```

**Step 4: Confirm with user — every acceptance criterion on #101**

- **AC1** — the 3D render is visibly chunky; individual pixels are square and discernible at the default window size.
- **AC2** — the sprite's pixels are the same size as the floor texture's pixels and the same size as the stair-steps on the block edges. If the sprite reads finer or coarser than the world, `pixel_size` and the floor's texel density have diverged.
- **AC3** — `hud.tscn` is instanced unmodified and its text is crisp, not pixelated by the low-res target.
- **AC4** — resize and maximise the window; nearest upscale and crisp UI both survive. Letterboxing on non-16:9 is expected.
- **AC5** — confirm the constant lives in exactly one place:
  ```powershell
  grep -rn "0.0625" scripts/ tests/
  grep -rn "PIXELS_PER_UNIT" scripts/ tests/
  ```
  Expected: `0.0625` appears nowhere; `PIXELS_PER_UNIT` is *defined* once, in `scripts/poc3d/world_scale.gd`.
- **AC6** — the 2D game still launches and plays with no regression:
  ```powershell
  ./tools/godot.ps1 --path .
  ```
  Walk from character creation into the station, change rooms, confirm the tilemaps and the HUD are unchanged.
- **AC7** — the console shows no renderer or Mobile-backend errors or warnings.

Also confirm the diff is clean of unintended `.import` churn:
```powershell
git status --short
```
Expected: nothing modified. If a `.import` file reappears as changed, Task 3 missed a texture — fix it before opening the PR.

Wait for the user's confirmation on all seven criteria before finishing the branch.

---

## Finishing

Once Smoketest Checkpoint 3 is confirmed, use the `finishing-a-development-branch` skill. The PR body should state that the go/no-go gate is **not** reached yet — that gate belongs to PRD 3 (#103), after #102 and #103 land.

Do not close #100. Close #101 only.
