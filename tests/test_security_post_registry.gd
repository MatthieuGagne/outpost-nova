# tests/test_security_post_registry.gd
extends GutTest

## Guards the registry flip for issue #132 R4.

func _main_script():
	return load("res://scripts/main.gd")

func test_security_post_is_registered_as_a_3d_area():
	var entry: Dictionary = _main_script().AREA_SCENES["security_post"]
	assert_eq(entry["presentation"], "3d", "security_post must be dispatched through _enter_3d")
	assert_eq(entry["scene"], "res://scenes/areas3d/security_post.tscn")

func test_security_post_has_no_2d_entry_position_block():
	# 3D rooms spawn from EntryFrom* markers, never from AREA_ENTRY_POSITIONS.
	assert_false(_main_script().AREA_ENTRY_POSITIONS.has("security_post"),
		"the 2D entry-position block for security_post must be removed")

func test_quen_is_no_longer_a_2d_roster_npc():
	# The 3D security post hosts Quen in-scene as an Npc3D, like the cantina hosts Maris.
	assert_false(_main_script().NPC_SPAWN_AREAS.has("quen"),
		"quen must be dropped from the 2D NPC roster")
