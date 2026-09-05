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
