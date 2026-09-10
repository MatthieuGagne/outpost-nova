# tests/test_poc3d_npc3d.gd
extends GutTest

const SIZE_TOLERANCE := 0.0001

## Matches tests/test_poc3d_pixel_sprite.gd: 180 degrees off the contract angle.
const FLIPPED_YAW := -135.0
const YAW_TOLERANCE := 0.01

func _npc_ready(facing: String) -> Node3D:
	var npc = load("res://scenes/poc3d/npc3d.tscn").instantiate()
	npc.facing = facing
	add_child_autofree(npc)
	await wait_frames(1)
	return npc

func test_the_npc_plays_the_idle_animation_for_its_authored_facing():
	var npc = await _npc_ready("right")
	assert_eq(npc.get_node("PixelSprite3D").animation, "idle_right")

func test_every_valid_facing_resolves_to_an_animation_that_exists():
	for facing in SpriteFacing.FACINGS:
		var npc = await _npc_ready(facing)
		var sprite := npc.get_node("PixelSprite3D") as AnimatedSprite3D
		assert_true(sprite.sprite_frames.has_animation("idle_" + facing),
			"npc_frames.tres is missing idle_" + facing)

func test_an_invalid_facing_falls_back_rather_than_playing_a_missing_animation():
	var npc = await _npc_ready("sideways")
	assert_eq(npc.get_node("PixelSprite3D").animation, "idle_" + Npc3D.DEFAULT_FACING)

func test_the_npc_uses_the_same_pixel_sprite_setup_as_the_player():
	var npc = await _npc_ready("down")
	var sprite = npc.get_node("PixelSprite3D")
	assert_true(sprite is PixelSprite3D)
	assert_eq(sprite.billboard, BaseMaterial3D.BILLBOARD_DISABLED)
	assert_eq(sprite.alpha_cut, SpriteBase3D.ALPHA_CUT_DISCARD)
	assert_almost_eq(sprite.pixel_size, WorldScale.SPRITE_PIXEL_SIZE, SIZE_TOLERANCE)

func test_the_npc_does_not_move():
	# R9: static facing, no movement, no AI. A physics body here would be scope creep.
	var npc = await _npc_ready("down")
	assert_false(npc is CharacterBody3D, "PRD 2 NPCs are static; movement is out of scope")

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
