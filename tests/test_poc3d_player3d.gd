# tests/test_poc3d_player3d.gd
extends GutTest

const SIZE_TOLERANCE := 0.0001

func test_speed_is_derived_from_the_world_scale_not_hard_coded():
	# The 2D player moves at 80 px/s (scripts/characters/player.gd:4). At 16 px per world
	# unit that is 5.0 units/s — derived, so changing PIXELS_PER_UNIT moves both together.
	assert_almost_eq(Player3D.SPEED, 80.0 / WorldScale.PIXELS_PER_UNIT, SIZE_TOLERANCE)
	assert_almost_eq(Player3D.SPEED, 5.0, SIZE_TOLERANCE)

func test_the_body_radius_and_height_are_derived_from_the_world_scale():
	assert_almost_eq(Player3D.BODY_RADIUS,
		Player3D.BODY_RADIUS_PIXELS / WorldScale.PIXELS_PER_UNIT, SIZE_TOLERANCE)
	assert_almost_eq(Player3D.BODY_HEIGHT,
		Player3D.BODY_HEIGHT_PIXELS / WorldScale.PIXELS_PER_UNIT, SIZE_TOLERANCE)
	assert_almost_eq(Player3D.INTERACT_RADIUS,
		Player3D.INTERACT_RADIUS_PIXELS / WorldScale.PIXELS_PER_UNIT, SIZE_TOLERANCE)

func test_the_body_is_narrower_than_the_sprite_so_it_reads_as_a_foot_print():
	# A 16px-wide sprite is 1.0 world units. A collider as wide as the art would snag on
	# corners the player can visually clear.
	assert_lt(Player3D.BODY_RADIUS * 2.0, 1.0)

func test_the_scene_stamps_the_collision_shape_from_those_constants():
	var player = load("res://scenes/poc3d/player3d.tscn").instantiate()
	add_child_autofree(player)
	await wait_frames(1)
	var shape_node := player.get_node("CollisionShape3D") as CollisionShape3D
	var capsule := shape_node.shape as CapsuleShape3D
	assert_not_null(capsule, "a capsule slides off tile corners; a box catches on them")
	assert_almost_eq(capsule.radius, Player3D.BODY_RADIUS, SIZE_TOLERANCE,
		"the shape must be derived at _ready, not frozen into the .tscn")
	assert_almost_eq(capsule.height, Player3D.BODY_HEIGHT, SIZE_TOLERANCE)

func test_the_player_starts_facing_down():
	var player = load("res://scenes/poc3d/player3d.tscn").instantiate()
	add_child_autofree(player)
	await wait_frames(1)
	assert_eq(player.get_facing(), "down")

func test_the_sprite_child_is_a_pixel_sprite_so_prd1_invariants_apply():
	var player = load("res://scenes/poc3d/player3d.tscn").instantiate()
	add_child_autofree(player)
	await wait_frames(1)
	var sprite = player.get_node("PixelSprite3D")
	assert_true(sprite is PixelSprite3D,
		"a plain AnimatedSprite3D would skip billboard/alpha_cut/nearest stamping")
	assert_eq(sprite.alpha_cut, SpriteBase3D.ALPHA_CUT_DISCARD)
	assert_almost_eq(sprite.pixel_size, WorldScale.SPRITE_PIXEL_SIZE, SIZE_TOLERANCE)
