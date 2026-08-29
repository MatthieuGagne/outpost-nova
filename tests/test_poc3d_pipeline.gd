extends GutTest

## Guards the invariants PRD 1 (#101) exists to establish, so PRDs 2-4 cannot
## silently undo them while editing these same scenes.

const ENTRY_PATH := "res://scenes/poc3d/poc_entry.tscn"
const ANGLE_TOLERANCE := 0.001
const SIZE_TOLERANCE := 0.0001

var _entry: Node


func before_each():
	_entry = load(ENTRY_PATH).instantiate()
	add_child_autofree(_entry)
	# Control layout and the container-driven SubViewport resize both settle
	# over a frame, so read nothing before this.
	await wait_frames(2)


func _viewport() -> SubViewport:
	return _entry.get_node("SubViewportContainer/SubViewport")


func test_the_world_renders_into_a_480x270_target():
	assert_eq(_viewport().size, Vector2i(WorldScale.RENDER_WIDTH, WorldScale.RENDER_HEIGHT),
		"the 3D world is not rendering at the low-res size; check stretch/mode in project.godot")


func test_the_container_upscales_rather_than_cropping():
	var container: SubViewportContainer = _entry.get_node("SubViewportContainer")
	assert_true(container.stretch,
		"stretch = false would crop the SubViewport instead of upscaling it")


func test_the_hud_is_not_inside_the_low_res_target():
	# THE invariant of this PRD. A HUD parented under the SubViewport would be
	# rendered at 480x270 and upscaled with the world, turning the text to mush.
	var hud := _entry.find_child("HUD", true, false)
	assert_not_null(hud, "poc_entry.tscn no longer instances hud.tscn")
	assert_false(_viewport().is_ancestor_of(hud),
		"the HUD has been reparented under the SubViewport — it must stay a sibling")
	assert_true(hud is CanvasLayer, "hud.tscn must remain a CanvasLayer to draw above the container")


func test_the_room_camera_uses_the_contract_angle():
	var camera := _entry.find_child("RoomCamera", true, false) as Camera3D
	assert_not_null(camera, "the test room has no RoomCamera")
	assert_almost_eq(camera.fov, WorldScale.CAMERA_FOV, ANGLE_TOLERANCE)
	assert_almost_eq(camera.rotation_degrees.x, WorldScale.CAMERA_PITCH_DEGREES, ANGLE_TOLERANCE)
	assert_almost_eq(camera.rotation_degrees.y, WorldScale.CAMERA_YAW_DEGREES, ANGLE_TOLERANCE)


func test_the_floor_material_samples_with_nearest_filtering():
	var floor_node := _entry.find_child("Floor", true, false) as MeshInstance3D
	assert_not_null(floor_node, "the test room has no Floor")
	var material := floor_node.get_active_material(0) as StandardMaterial3D
	assert_not_null(material)
	assert_eq(material.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST,
		"a smoothed 3D material is the epic's finding #2 regressing")


func test_the_reference_sprite_matches_the_world_scale():
	var sprite := _entry.find_child("ReferenceSprite", true, false) as AnimatedSprite3D
	assert_not_null(sprite, "the AC2 reference sprite is missing from the test room")
	assert_almost_eq(sprite.pixel_size, WorldScale.SPRITE_PIXEL_SIZE, SIZE_TOLERANCE)
	# No billboard assertion here: the scene is already instantiated by
	# before_each(), so _ready() has already stamped the value and there is no
	# way to pre-set the opposite first — any assertion here would pass even if
	# the stamping in pixel_sprite_3d.gd were deleted. That contract is covered
	# (load-bearingly) by test_poc3d_pixel_sprite.gd instead.
	assert_eq(sprite.alpha_cut, SpriteBase3D.ALPHA_CUT_DISCARD)


func test_only_one_directional_light_within_mobile_limits():
	var lights := 0
	for node in _entry.find_children("*", "Light3D", true, false):
		lights += 1
		assert_false(node is OmniLight3D or node is SpotLight3D,
			"PRD 1 lights with a single DirectionalLight3D; Mobile caps omni/spot per object")
	assert_eq(lights, 1, "expected exactly one light in the POC scene")
