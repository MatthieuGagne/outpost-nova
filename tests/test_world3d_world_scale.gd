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
