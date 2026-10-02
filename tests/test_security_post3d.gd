# tests/test_security_post3d.gd
extends GutTest

## Seam test for the 3D security post (issue #132 R1/R3).

const SECURITY_POST_3D := "res://scenes/areas3d/security_post.tscn"

const EXPECTED_EXITS := {
	"CantinaExit":   "cantina",
	"MedBayExit":    "med_bay",
	"TradeDockExit": "trade_dock",
}

const EXPECTED_MARKERS := [
	"EntryFromCantina",
	"EntryFromMedBay",
	"EntryFromTradeDock",
	"DefaultSpawn",
]

func before_each():
	GameState.reset()
	ClockManager.reset()

func _room() -> Node3D:
	var room = load(SECURITY_POST_3D).instantiate()
	add_child_autofree(room)
	return room

func test_room_authors_an_exit_for_every_neighbour():
	var room := _room()
	for exit_name in EXPECTED_EXITS:
		var door = room.find_child(exit_name, false, false)
		assert_not_null(door, "3D security_post missing exit '%s'" % exit_name)
		assert_eq(door.destination_id, EXPECTED_EXITS[exit_name],
			"exit '%s' points at the wrong area" % exit_name)

func test_room_authors_entry_markers_as_direct_children():
	# main._find_3d_entry_marker searches non-recursively, so nesting a marker breaks spawning.
	var room := _room()
	for marker in EXPECTED_MARKERS:
		assert_not_null(room.find_child(marker, false, false),
			"3D security_post missing root-level marker '%s'" % marker)

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
		"security_post.gd must forward ExitDoor.triggered to Main.go_to_area")

func test_room_hosts_quen_as_a_production_npc3d():
	var room := _room()
	var quen = room.find_child("Quen", false, false)
	assert_not_null(quen, "3D security_post must host Quen in-scene, like the cantina hosts Maris")
	assert_true(quen is Npc3D, "Quen must be an Npc3D instance")
	assert_eq(quen.dialogue_node, "Quen", "Quen must point at the 'Quen' Yarn node")

func test_quen_wander_box_stays_inside_the_walkable_floor():
	var room := _room()
	var quen: Npc3D = room.find_child("Quen", false, false)
	var half := quen.wander_half_extents
	assert_between(quen.position.x - half.x, -7.0, 7.0, "Quen can wander out of the floor in -X")
	assert_between(quen.position.x + half.x, -7.0, 7.0, "Quen can wander out of the floor in +X")
	assert_between(quen.position.z - half.y, -5.0, 5.0, "Quen can wander out of the floor in -Z")
	assert_between(quen.position.z + half.y, -5.0, 5.0, "Quen can wander out of the floor in +Z")
