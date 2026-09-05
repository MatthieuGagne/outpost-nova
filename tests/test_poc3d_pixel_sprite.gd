# tests/test_poc3d_pixel_sprite.gd
extends GutTest

const FRAMES_PATH := "res://data/sprites/player_frames.tres"
const TOLERANCE := 0.0001

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
	# Pre-set the opposite of the contract value before _ready() runs, so the
	# assertion below observes the script stamping it back rather than passing
	# on SpriteBase3D's own default (which happens to already be DISABLED).
	var sprite := PixelSprite3D.new()
	sprite.sprite_frames = load(FRAMES_PATH)
	sprite.animation = &"idle_down"
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child_autofree(sprite)
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
