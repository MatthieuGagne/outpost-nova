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


const EXPECTED_PLOTS := {
	"PartsPlot":  "parts",
	"EnergyPlot": "energy_cells",
}


func test_room_hosts_both_production_plots_with_the_2d_yields():
	var room := _room()
	for plot_name in EXPECTED_PLOTS:
		var plot = room.find_child(plot_name, false, false)
		assert_not_null(plot, "3D workshop must host '%s'" % plot_name)
		assert_true(plot is Plot3D, "'%s' must be a Plot3D instance" % plot_name)
		assert_eq(plot.resource_id, EXPECTED_PLOTS[plot_name])
		assert_eq(plot.yield_amount, 1,
			"the 2D workshop plots never overrode yield_amount — parity, not a new number")


func test_the_two_plots_have_independent_flags():
	# Plot3D keys its flag off resource_id, so two plots in one room must not share state.
	var room := _room()
	var parts: Plot3D = room.find_child("PartsPlot", false, false)
	var energy: Plot3D = room.find_child("EnergyPlot", false, false)
	parts.start_plot()
	assert_true(GameState.get_flag("plot_parts_growing"), "starting the parts plot must set its own flag")
	assert_false(GameState.get_flag("plot_energy_cells_growing"),
		"starting the parts plot must NOT start the energy_cells plot")
	assert_eq(energy.get_plot_state(), Plot3D.PlotState.EMPTY,
		"the energy plot must still be empty")


func test_room_hosts_the_workbench():
	var room := _room()
	var bench = room.find_child("Workbench", false, false)
	assert_not_null(bench, "3D workshop must host the workbench")
	assert_true(bench is Workbench3D, "the workbench must be a Workbench3D instance")


func test_room_hosts_dex_as_a_production_npc3d():
	var room := _room()
	var dex = room.find_child("Dex", false, false)
	assert_not_null(dex, "3D workshop must host Dex in-scene, like cantina hosts Maris")
	assert_true(dex is Npc3D, "Dex must be an Npc3D instance")
	assert_eq(dex.dialogue_node, "Dex", "Dex must point at the 'Dex' Yarn node")


func test_dex_wander_box_stays_inside_the_walkable_floor():
	var room := _room()
	var dex: Npc3D = room.find_child("Dex", false, false)
	var half := dex.wander_half_extents
	assert_between(dex.position.x - half.x, -7.0, 7.0, "Dex can wander out of the floor in -X")
	assert_between(dex.position.x + half.x, -7.0, 7.0, "Dex can wander out of the floor in +X")
	assert_between(dex.position.z - half.y, -5.0, 5.0, "Dex can wander out of the floor in -Z")
	assert_between(dex.position.z + half.y, -5.0, 5.0, "Dex can wander out of the floor in +Z")
