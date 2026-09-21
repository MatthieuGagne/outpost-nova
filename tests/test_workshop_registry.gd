extends GutTest

## Guards the registry flip for issue #131 R6.

func _main_script():
	return load("res://scripts/main.gd")


func test_workshop_is_registered_as_a_3d_area():
	var entry: Dictionary = _main_script().AREA_SCENES["workshop"]
	assert_eq(entry["presentation"], "3d", "workshop must be dispatched through _enter_3d")
	assert_eq(entry["scene"], "res://scenes/areas3d/workshop.tscn")


func test_workshop_has_no_2d_entry_position_block():
	# 3D rooms spawn from EntryFrom* markers, never from AREA_ENTRY_POSITIONS.
	assert_false(_main_script().AREA_ENTRY_POSITIONS.has("workshop"),
		"the 2D entry-position block for workshop must be removed")


func test_no_surviving_2d_area_references_workshop_as_a_neighbour():
	# Unlike cantina, no 2D room has a door into the workshop, so nothing keys off it.
	var positions: Dictionary = _main_script().AREA_ENTRY_POSITIONS
	for area in positions:
		assert_false(positions[area].has("workshop"),
			"2D area '%s' still keys an entry position off the now-3D workshop" % area)


func test_dex_is_no_longer_a_2d_roster_npc():
	# The 3D workshop hosts Dex in-scene as an Npc3D, like cantina hosts Maris.
	assert_false(_main_script().NPC_SPAWN_AREAS.has("dex"),
		"dex must be dropped from the 2D NPC roster")
