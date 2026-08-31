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
