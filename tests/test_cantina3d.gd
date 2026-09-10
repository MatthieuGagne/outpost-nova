extends GutTest

## Seam test for the 3D cantina (issue #130 R1/R4).

const CANTINA_3D := "res://scenes/areas3d/cantina.tscn"

const EXPECTED_EXITS := {
	"WorkshopExit":     "workshop",
	"QuartersExit":     "quarters",
	"SecurityPostExit": "security_post",
	"TradeDockExit":    "trade_dock",
}

const EXPECTED_MARKERS := [
	"EntryFromWorkshop",
	"EntryFromQuarters",
	"EntryFromSecurityPost",
	"EntryFromTradeDock",
	"DefaultSpawn",
]

func before_each():
	GameState.reset()
	ClockManager.reset()

func _room() -> Node3D:
	var room = load(CANTINA_3D).instantiate()
	add_child_autofree(room)
	return room

func test_room_authors_an_exit_for_every_neighbour():
	var room := _room()
	for exit_name in EXPECTED_EXITS:
		var door = room.find_child(exit_name, false, false)
		assert_not_null(door, "3D cantina missing exit '%s'" % exit_name)
		assert_eq(door.destination_id, EXPECTED_EXITS[exit_name],
			"exit '%s' points at the wrong area" % exit_name)

func test_room_authors_entry_markers_as_direct_children():
	# main._find_3d_entry_marker searches non-recursively, so nesting a marker breaks spawning.
	var room := _room()
	for marker in EXPECTED_MARKERS:
		assert_not_null(room.find_child(marker, false, false),
			"3D cantina missing root-level marker '%s'" % marker)

func test_entry_markers_sit_inside_the_walkable_floor():
	# Floor is 16x12 centred on the origin: X in [-8,8], Z in [-6,6].
	var room := _room()
	for marker in EXPECTED_MARKERS:
		var node: Node3D = room.find_child(marker, false, false)
		assert_between(node.position.x, -8.0, 8.0, "%s is outside the floor in X" % marker)
		assert_between(node.position.z, -6.0, 6.0, "%s is outside the floor in Z" % marker)

func test_exits_forward_to_the_main_area_router():
	var room := _room()
	assert_true(room.has_method("_on_exit_triggered"),
		"cantina.gd must forward ExitDoor.triggered to Main.go_to_area")
