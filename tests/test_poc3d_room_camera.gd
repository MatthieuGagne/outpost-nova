extends GutTest

const ANGLE_TOLERANCE := 0.001


func test_camera_adopts_the_contract_angle_by_default():
	var camera := RoomCamera.new()
	add_child_autofree(camera)
	assert_almost_eq(camera.fov, WorldScale.CAMERA_FOV, ANGLE_TOLERANCE)
	assert_almost_eq(camera.rotation_degrees.x, WorldScale.CAMERA_PITCH_DEGREES, ANGLE_TOLERANCE)
	assert_almost_eq(camera.rotation_degrees.y, WorldScale.CAMERA_YAW_DEGREES, ANGLE_TOLERANCE)
	assert_eq(camera.projection, Camera3D.PROJECTION_PERSPECTIVE)


func test_a_room_can_hand_author_its_own_angle():
	# R6: the hand-placed node IS the contract, so a room must be able to depart
	# from the shared starting values without the script stamping them back.
	var camera := RoomCamera.new()
	camera.use_contract_angle = false
	camera.rotation_degrees = Vector3(-20.0, 90.0, 0.0)
	add_child_autofree(camera)
	assert_almost_eq(camera.rotation_degrees.x, -20.0, ANGLE_TOLERANCE)
	assert_almost_eq(camera.rotation_degrees.y, 90.0, ANGLE_TOLERANCE)


func test_position_is_never_touched_by_the_script():
	# Only the ANGLE is contractual. Framing is hand-placed per room.
	var camera := RoomCamera.new()
	camera.position = Vector3(3.0, 9.0, 3.0)
	add_child_autofree(camera)
	assert_almost_eq(camera.position.y, 9.0, ANGLE_TOLERANCE)
