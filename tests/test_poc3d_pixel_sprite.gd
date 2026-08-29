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
