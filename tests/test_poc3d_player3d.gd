# tests/test_poc3d_player3d.gd
extends GutTest

const SIZE_TOLERANCE := 0.0001

## Velocity assertions compare against SPEED-scaled unit vectors; 0.01 units/s is far
## below any real movement and far above float noise from the yaw rotation.
const VELOCITY_TOLERANCE := 0.01

## The four actions Player3D reads. Released after every test so a failed assertion
## mid-test cannot leave a key stuck down and cascade into unrelated failures.
const MOVEMENT_ACTIONS := ["ui_up", "ui_down", "ui_left", "ui_right"]


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

func test_screen_up_walks_away_from_the_contract_camera_and_shows_the_up_sprite():
	# The camera is yawed 45 degrees, so "away from the camera" is the -X -Z diagonal.
	# Facing must still be "up": it comes from the RAW input, never from the rotated
	# velocity. Deriving it from velocity is the failure mode PRD 2 (#102) named as its
	# highest risk — the up sprite while sliding diagonally across the screen.
	var player = await _player_under_camera(WorldScale.CAMERA_YAW_DEGREES, true)
	Input.action_press("ui_up")
	await wait_physics_frames(2)
	var expected := -sqrt(0.5) * Player3D.SPEED
	assert_almost_eq(player.velocity.x, expected, VELOCITY_TOLERANCE)
	assert_almost_eq(player.velocity.z, expected, VELOCITY_TOLERANCE)
	assert_eq(player.get_facing(), "up",
		"facing must come from the raw input, not from the rotated velocity")

func test_releasing_input_keeps_the_last_facing_and_returns_to_idle():
	# Automates AC2 of #102, which was manual-only until now.
	var player = await _player_under_camera(WorldScale.CAMERA_YAW_DEGREES, true)
	Input.action_press("ui_up")
	await wait_physics_frames(2)
	Input.action_release("ui_up")
	await wait_physics_frames(2)
	assert_eq(player.get_facing(), "up", "released input keeps the last facing")
	assert_eq(player.get_node("PixelSprite3D").animation, "idle_up")
	assert_almost_eq(player.velocity.length(), 0.0, VELOCITY_TOLERANCE)
