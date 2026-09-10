extends GutTest

# Facing is derived in CAMERA space, so the input vector is already screen-relative:
# +x is screen-right, +y is screen-down (matching Input.get_axis("ui_up", "ui_down")).
# No yaw rotation belongs in this function — see input_to_world for that half.

func test_cardinal_inputs_map_to_the_four_animation_suffixes():
	assert_eq(SpriteFacing.from_input(Vector2(0, -1)), "up")
	assert_eq(SpriteFacing.from_input(Vector2(0, 1)), "down")
	assert_eq(SpriteFacing.from_input(Vector2(-1, 0)), "left")
	assert_eq(SpriteFacing.from_input(Vector2(1, 0)), "right")

func test_diagonals_break_the_tie_toward_horizontal():
	# Mirrors scripts/characters/player.gd:42 — abs(x) >= abs(y) favours horizontal,
	# so a perfect diagonal shows a left/right sprite, not up/down.
	assert_eq(SpriteFacing.from_input(Vector2(1, 1)), "right")
	assert_eq(SpriteFacing.from_input(Vector2(1, -1)), "right")
	assert_eq(SpriteFacing.from_input(Vector2(-1, 1)), "left")
	assert_eq(SpriteFacing.from_input(Vector2(-1, -1)), "left")

func test_a_shallow_diagonal_still_resolves_to_the_dominant_axis():
	assert_eq(SpriteFacing.from_input(Vector2(0.2, -1)), "up")
	assert_eq(SpriteFacing.from_input(Vector2(-1, 0.2)), "left")

func test_zero_input_returns_empty_so_the_caller_keeps_its_last_facing():
	assert_eq(SpriteFacing.from_input(Vector2.ZERO), "",
		"zero input must not silently resolve to 'left' via the abs(x) >= abs(y) branch")

func test_every_returned_facing_is_a_valid_animation_suffix():
	for input in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
		assert_true(SpriteFacing.is_valid(SpriteFacing.from_input(input)))
	assert_false(SpriteFacing.is_valid(""))

const AXIS_TOLERANCE := 0.0001

func _assert_axes(actual: Vector3, expected: Vector3, context: String) -> void:
	# Component-wise with a tolerance, never strict equality — these are trig results.
	assert_almost_eq(actual.x, expected.x, AXIS_TOLERANCE, context + " (x)")
	assert_almost_eq(actual.y, expected.y, AXIS_TOLERANCE, context + " (y)")
	assert_almost_eq(actual.z, expected.z, AXIS_TOLERANCE, context + " (z)")

func test_at_zero_yaw_input_maps_straight_onto_the_world_axes():
	_assert_axes(SpriteFacing.input_to_world(Vector2(0, -1), 0.0), Vector3(0, 0, -1), "screen-up at yaw 0")
	_assert_axes(SpriteFacing.input_to_world(Vector2(0, 1), 0.0), Vector3(0, 0, 1), "screen-down at yaw 0")
	_assert_axes(SpriteFacing.input_to_world(Vector2(1, 0), 0.0), Vector3(1, 0, 0), "screen-right at yaw 0")
	_assert_axes(SpriteFacing.input_to_world(Vector2(-1, 0), 0.0), Vector3(-1, 0, 0), "screen-left at yaw 0")

func test_at_the_contract_yaw_screen_up_walks_directly_away_from_the_camera():
	# This is R6, the highest-risk requirement in the PRD. The camera sits at (9, 9, 9)
	# yawed 45 degrees, so "away from the camera" is the -X -Z diagonal. If this returns
	# (0, 0, -1) instead, input is being applied in world space and the character will
	# slide sideways while showing the up sprite.
	var half := sqrt(0.5)
	_assert_axes(
		SpriteFacing.input_to_world(Vector2(0, -1), WorldScale.CAMERA_YAW_DEGREES),
		Vector3(-half, 0, -half),
		"screen-up at the contract yaw")
	_assert_axes(
		SpriteFacing.input_to_world(Vector2(1, 0), WorldScale.CAMERA_YAW_DEGREES),
		Vector3(half, 0, -half),
		"screen-right at the contract yaw")

func test_movement_never_leaves_the_xz_plane():
	for input in [Vector2(0, -1), Vector2(1, 1), Vector2(-1, 0.3)]:
		assert_almost_eq(
			SpriteFacing.input_to_world(input, WorldScale.CAMERA_YAW_DEGREES).y, 0.0, AXIS_TOLERANCE,
			"PRD 2 has no elevation; movement must stay flat")

func test_the_result_is_normalised_so_diagonals_are_not_faster():
	assert_almost_eq(
		SpriteFacing.input_to_world(Vector2(1, 1), WorldScale.CAMERA_YAW_DEGREES).length(), 1.0, AXIS_TOLERANCE,
		"an unnormalised diagonal would move the player ~41% faster")

func test_zero_input_produces_no_movement():
	_assert_axes(SpriteFacing.input_to_world(Vector2.ZERO, WorldScale.CAMERA_YAW_DEGREES), Vector3.ZERO, "zero input")

func test_from_world_maps_world_velocity_back_to_facing():
	# contract yaw 45°: screen-up walks (-sin45, 0, -cos45) = (-√½, 0, -√½)
	assert_eq(SpriteFacing.from_world(Vector3(-0.707, 0.0, -0.707), 45.0), "up")
	# screen-right walks (√½, 0, -√½)
	assert_eq(SpriteFacing.from_world(Vector3(0.707, 0.0, -0.707), 45.0), "right")
	# y is ignored — facing is XZ-only
	assert_eq(SpriteFacing.from_world(Vector3(-0.707, 99.0, -0.707), 45.0), "up")
	# zero velocity → no facing
	assert_eq(SpriteFacing.from_world(Vector3.ZERO, 45.0), SpriteFacing.NO_FACING)
