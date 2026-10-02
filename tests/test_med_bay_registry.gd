# tests/test_med_bay_registry.gd
extends GutTest

## Guards the registry flip for issue #133 R4.

func _main_script():
	return load("res://scripts/main.gd")

func test_med_bay_is_registered_as_a_3d_area():
	var entry: Dictionary = _main_script().AREA_SCENES["med_bay"]
	assert_eq(entry["presentation"], "3d", "med_bay must be dispatched through _enter_3d")
	assert_eq(entry["scene"], "res://scenes/areas3d/med_bay.tscn")

func test_med_bay_has_no_2d_entry_position_block():
	# 3D rooms spawn from EntryFrom* markers, never from AREA_ENTRY_POSITIONS.
	assert_false(_main_script().AREA_ENTRY_POSITIONS.has("med_bay"),
		"the 2D entry-position block for med_bay must be removed")

func test_velreth_is_no_longer_a_2d_roster_npc():
	# The 3D med bay hosts Velreth in-scene as an Npc3D, like security_post hosts Quen.
	assert_false(_main_script().NPC_SPAWN_AREAS.has("velreth"),
		"velreth must be dropped from the 2D NPC roster")
