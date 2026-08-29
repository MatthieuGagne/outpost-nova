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
