extends GutTest

## Seam test for the 3D workshop (issue #131 R1/R5).

const WORKSHOP_3D := "res://scenes/areas3d/workshop.tscn"

const EXPECTED_EXITS := {
	"CantinaExit": "cantina",
}

const EXPECTED_MARKERS := [
	"EntryFromCantina",
	"DefaultSpawn",
]


func before_each():
	GameState.reset()
	ClockManager.reset()


func _room() -> Node3D:
	var room = load(WORKSHOP_3D).instantiate()
	add_child_autofree(room)
	return room


func test_room_authors_an_exit_for_every_neighbour():
	var room := _room()
	for exit_name in EXPECTED_EXITS:
		var door = room.find_child(exit_name, false, false)
		assert_not_null(door, "3D workshop missing exit '%s'" % exit_name)
		assert_eq(door.destination_id, EXPECTED_EXITS[exit_name],
			"exit '%s' points at the wrong area" % exit_name)


func test_room_authors_entry_markers_as_direct_children():
	# main._find_3d_entry_marker searches non-recursively, so nesting a marker breaks spawning.
	var room := _room()
	for marker in EXPECTED_MARKERS:
		assert_not_null(room.find_child(marker, false, false),
			"3D workshop missing root-level marker '%s'" % marker)


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
		"workshop.gd must forward ExitDoor.triggered to Main.go_to_area")
