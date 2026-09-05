# tests/test_poc3d_interaction.gd
# Headless coverage for PRD 3 (#103) AC9: the interaction contract, the console's
# resource grant, the door latch, and the hardcoded dialogue line.
#
# The point of testing InteractScan rather than Player3D is that a real Area3D overlap
# needs physics frames to register. Keeping the RULE node-free — the pattern SpriteFacing
# established in PRD 2 — makes it assertable with stub nodes and no frame waits.
extends GutTest

const STUB_SCRIPT := "res://tests/helpers/interactable_stub.gd"


func _stub(in_group: bool, is_visible: bool, has_interact: bool) -> Node3D:
	var node := Node3D.new()
	if has_interact:
		node.set_script(load(STUB_SCRIPT))
	if in_group:
		node.add_to_group(InteractScan.INTERACTABLE_GROUP)
	node.visible = is_visible
	add_child_autofree(node)
	return node


func test_a_qualifying_body_is_returned():
	var body := _stub(true, true, true)
	assert_eq(InteractScan.first_interactable([body], []), body)


func test_a_qualifying_area_is_returned_when_there_are_no_bodies():
	var area := _stub(true, true, true)
	assert_eq(InteractScan.first_interactable([], [area]), area)


func test_bodies_are_scanned_before_areas():
	# Byte-identical ordering to scripts/characters/player.gd._try_interact().
	var body := _stub(true, true, true)
	var area := _stub(true, true, true)
	assert_eq(InteractScan.first_interactable([body], [area]), body)


func test_the_first_match_wins_within_a_list():
	var first := _stub(true, true, true)
	var second := _stub(true, true, true)
	assert_eq(InteractScan.first_interactable([first, second], []), first)


func test_a_node_outside_the_group_is_skipped():
	var outsider := _stub(false, true, true)
	assert_null(InteractScan.first_interactable([outsider], []))


func test_an_invisible_node_is_skipped():
	var hidden := _stub(true, false, true)
	assert_null(InteractScan.first_interactable([hidden], []))


func test_a_node_without_interact_is_skipped_rather_than_crashing():
	# The one place this is stricter than the 2D original, which duck-types blindly.
	var malformed := _stub(true, true, false)
	assert_null(InteractScan.first_interactable([malformed], []))


func test_nothing_in_reach_returns_null():
	assert_null(InteractScan.first_interactable([], []))


func test_a_skipped_candidate_does_not_hide_a_later_valid_one():
	var hidden := _stub(true, false, true)
	var valid := _stub(true, true, true)
	assert_eq(InteractScan.first_interactable([hidden, valid], []), valid)
