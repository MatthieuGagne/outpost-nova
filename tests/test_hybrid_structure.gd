extends GutTest

## Guards the hybrid invariants (issue #129 R10).

const MAIN_SCENE := "res://scenes/main.tscn"
const TRADE_DOCK_3D := "res://scenes/areas3d/trade_dock.tscn"

func _state() -> SceneState:
	return (load(MAIN_SCENE) as PackedScene).get_state()

func _node_paths() -> Array:
	var state := _state()
	var paths := []
	for i in state.get_node_count():
		# SceneState paths are root-relative but carry a leading "./" (see
		# test_dialogue_wiring.gd's "./DialogueRunner/TextLineProvider").
		paths.append(str(state.get_node_path(i)).trim_prefix("./"))
	return paths

func test_hud_and_dialogue_stay_outside_the_subviewport():
	var paths := _node_paths()
	assert_true(paths.has("HUD"), "main.tscn must keep HUD as a root sibling")
	assert_true(paths.has("DialogueBox"), "main.tscn must keep DialogueBox as a root sibling")
	for p in paths:
		assert_false(p.begins_with("World3D/SubViewport/HUD"), "HUD must not live under the SubViewport")
		assert_false(p.begins_with("World3D/SubViewport/DialogueBox"), "DialogueBox must not live under the SubViewport")

func test_world3d_branch_hosts_the_3d_player():
	var paths := _node_paths()
	assert_true(paths.has("World3D/SubViewport/Area3D/Player3D"),
		"the World3D branch must hold a persistent Player3D")

func test_2d_trade_dock_files_are_gone():
	assert_false(ResourceLoader.exists("res://scenes/areas/trade_dock.tscn"), "2D trade_dock scene must be deleted")
	assert_false(ResourceLoader.exists("res://scripts/areas/trade_dock.gd"), "2D trade_dock script must be deleted")

func test_2d_cantina_files_are_gone():
	assert_false(ResourceLoader.exists("res://scenes/areas/cantina.tscn"), "2D cantina scene must be deleted")
	assert_false(ResourceLoader.exists("res://scripts/areas/cantina.gd"), "2D cantina script must be deleted")

func test_dead_pre_mvp_rooms_cantina_is_gone():
	assert_false(ResourceLoader.exists("res://scenes/rooms/cantina.tscn"), "pre-MVP rooms/cantina scene must be deleted")
	assert_false(ResourceLoader.exists("res://scripts/rooms/cantina.gd"), "pre-MVP rooms/cantina script must be deleted")

func test_orphaned_pre_mvp_character_pair_is_gone():
	# rooms/cantina.tscn was character.tscn's only consumer; deleting it orphaned the pair.
	# The live NPCs (maris/quen/dex/velreth/sable) extend npc_base.gd and are unaffected.
	assert_false(ResourceLoader.exists("res://scenes/characters/character.tscn"), "orphaned character scene must be deleted")
	assert_false(ResourceLoader.exists("res://scripts/characters/character.gd"), "orphaned character script must be deleted")

func test_trade_dock_authors_entry_markers_for_every_2d_neighbour():
	var room = load(TRADE_DOCK_3D).instantiate()
	add_child_autofree(room)
	for marker in ["EntryFromCantina", "EntryFromSecurityPost", "EntryFromDerelictEntrance", "DefaultSpawn"]:
		assert_not_null(room.find_child(marker, false, false), "3D trade_dock missing marker '%s'" % marker)

func test_2d_neighbours_keep_entry_positions_keyed_by_trade_dock():
	var main_script = load("res://scripts/main.gd")
	# cantina left this list in #130 — it is a 3D room now and spawns from EntryFrom* markers.
	for area in ["security_post"]:
		assert_true(main_script.AREA_ENTRY_POSITIONS[area].has("trade_dock"),
			"2D area '%s' lost its trade_dock entry position" % area)
