# tests/test_med_bay3d.gd
extends GutTest

## Seam test for the 3D med bay (issue #133 R1/R3).

const MED_BAY_3D := "res://scenes/areas3d/med_bay.tscn"

const EXPECTED_EXITS := {
	"SecurityPostExit": "security_post",
}

const EXPECTED_MARKERS := [
	"EntryFromSecurityPost",
	"DefaultSpawn",
]

func before_each():
	GameState.reset()
	ClockManager.reset()

func _room() -> Node3D:
	var room = load(MED_BAY_3D).instantiate()
	add_child_autofree(room)
	return room

func test_room_authors_an_exit_for_every_neighbour():
	var room := _room()
	for exit_name in EXPECTED_EXITS:
		var door = room.find_child(exit_name, false, false)
		assert_not_null(door, "3D med_bay missing exit '%s'" % exit_name)
		assert_eq(door.destination_id, EXPECTED_EXITS[exit_name],
			"exit '%s' points at the wrong area" % exit_name)

func test_room_authors_entry_markers_as_direct_children():
	# main._find_3d_entry_marker searches non-recursively, so nesting a marker breaks spawning.
	var room := _room()
	for marker in EXPECTED_MARKERS:
		assert_not_null(room.find_child(marker, false, false),
			"3D med_bay missing root-level marker '%s'" % marker)

func test_entry_markers_sit_inside_the_walkable_floor():
	# Floor is 14x10 centred on the origin: X in [-7,7], Z in [-5,5].
	var room := _room()
	for marker in EXPECTED_MARKERS:
		var node: Node3D = room.find_child(marker, false, false)
		assert_between(node.position.x, -7.0, 7.0, "%s is outside the floor in X" % marker)
		assert_between(node.position.z, -5.0, 5.0, "%s is outside the floor in Z" % marker)

func test_exits_forward_to_the_main_area_router():
	var room := _room()
	assert_true(room.has_method("_on_exit_triggered"),
		"med_bay.gd must forward ExitDoor.triggered to Main.go_to_area")

func test_room_hosts_velreth_as_a_production_npc3d():
	var room := _room()
	var velreth = room.find_child("Velreth", false, false)
	assert_not_null(velreth, "3D med_bay must host Velreth in-scene, like security_post hosts Quen")
	assert_true(velreth is Npc3D, "Velreth must be an Npc3D instance")
	assert_eq(velreth.dialogue_node, "Velreth", "Velreth must point at the 'Velreth' Yarn node")

func test_velreth_wander_box_stays_inside_the_walkable_floor():
	var room := _room()
	var velreth: Npc3D = room.find_child("Velreth", false, false)
	var half := velreth.wander_half_extents
	assert_between(velreth.position.x - half.x, -7.0, 7.0, "Velreth can wander out of the floor in -X")
	assert_between(velreth.position.x + half.x, -7.0, 7.0, "Velreth can wander out of the floor in +X")
	assert_between(velreth.position.z - half.y, -5.0, 5.0, "Velreth can wander out of the floor in -Z")
	assert_between(velreth.position.z + half.y, -5.0, 5.0, "Velreth can wander out of the floor in +Z")
