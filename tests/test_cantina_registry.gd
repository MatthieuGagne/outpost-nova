extends GutTest

## Guards the registry flip for issue #130 R5.

func _main_script():
	return load("res://scripts/main.gd")

func test_cantina_is_registered_as_a_3d_area():
	var entry: Dictionary = _main_script().AREA_SCENES["cantina"]
	assert_eq(entry["presentation"], "3d", "cantina must be dispatched through _enter_3d")
	assert_eq(entry["scene"], "res://scenes/areas3d/cantina.tscn")

func test_cantina_has_no_2d_entry_position_block():
	# 3D rooms spawn from EntryFrom* markers, never from AREA_ENTRY_POSITIONS.
	assert_false(_main_script().AREA_ENTRY_POSITIONS.has("cantina"),
		"the 2D entry-position block for cantina must be removed")

func test_surviving_2d_neighbours_keep_their_cantina_entry_positions():
	# These describe arrival INTO a 2D room FROM cantina, so they stay.
	var positions: Dictionary = _main_script().AREA_ENTRY_POSITIONS
	for area in ["workshop", "quarters", "security_post"]:
		assert_true(positions[area].has("cantina"),
			"2D area '%s' lost its cantina entry position" % area)

func test_maris_is_no_longer_a_2d_roster_npc():
	# The 3D cantina hosts Maris in-scene as an Npc3D, like trade_dock hosts Sable.
	assert_false(_main_script().NPC_SPAWN_AREAS.has("maris"),
		"maris must be dropped from the 2D NPC roster")
