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


# ── Console (R5 / AC2) ────────────────────────────────────────────────────────

const CONSOLE_SCENE := "res://scenes/poc3d/console.tscn"


func _console() -> PocConsole:
	var node: PocConsole = load(CONSOLE_SCENE).instantiate()
	add_child_autofree(node)
	return node


func test_the_console_joins_the_interactable_group():
	assert_true(_console().is_in_group(InteractScan.INTERACTABLE_GROUP))


func test_the_console_satisfies_the_scan_contract():
	# Guards the whole chain at once: group, visibility and the duck-typed method.
	var console := _console()
	assert_true(InteractScan.is_interactable(console))


func test_interacting_grants_the_console_yield():
	GameState.reset()
	var before := GameState.get_resource(PocConsole.RESOURCE_ID)
	_console().interact()
	assert_eq(GameState.get_resource(PocConsole.RESOURCE_ID), before + PocConsole.CONSOLE_YIELD)


func test_the_console_is_repeatable():
	# Deliberately has no one-shot latch: the gate play-session hammers this prop.
	GameState.reset()
	var console := _console()
	console.interact()
	console.interact()
	console.interact()
	assert_eq(GameState.get_resource(PocConsole.RESOURCE_ID), PocConsole.CONSOLE_YIELD * 3)


func test_interacting_emits_dispensed():
	GameState.reset()
	var console := _console()
	watch_signals(console)
	console.interact()
	assert_signal_emitted_with_parameters(
		console, "dispensed", [PocConsole.RESOURCE_ID, PocConsole.CONSOLE_YIELD])


# ── AC2: the HUD updates from the signal, not from polling ───────────────────

const HUD_SCENE := "res://scenes/ui/hud.tscn"


func test_the_hud_reflects_a_console_grant_through_the_resource_changed_signal():
	# AC2. hud.gd connects GameState.resource_changed in _ready() and never polls; this
	# asserts the connection itself, so deleting it fails here even if a later _process
	# happened to refresh the same label.
	GameState.reset()
	# Untyped on purpose: hud.gd carries no class_name, and typing this as CanvasLayer
	# would make _refresh_resources an unknown member at parse time.
	var hud = load(HUD_SCENE).instantiate()
	add_child_autofree(hud)
	await wait_frames(1)
	assert_true(GameState.resource_changed.is_connected(hud._refresh_resources),
		"hud.gd must stay connected to GameState.resource_changed — AC2 is signal discipline")
	_console().interact()
	await wait_frames(1)
	var label: Label = hud.get_node("HBoxContainer/PartsLabel")
	assert_eq(label.text, "Parts: %d" % GameState.get_resource(PocConsole.RESOURCE_ID))


# ── Player3D reach (R4) ──────────────────────────────────────────────────────

const PLAYER_SCENE := "res://scenes/poc3d/player3d.tscn"

## Just inside INTERACT_RADIUS (20 px / 16 = 1.25 units), and just outside it.
const WITHIN_REACH := 1.0
const BEYOND_REACH := 3.0


func _player_and_console_at(separation: float) -> Player3D:
	# The console's own 1x2 box is centred on it, so `separation` is measured between
	# origins; anything under INTERACT_RADIUS plus half the box depth overlaps.
	var player: Player3D = load(PLAYER_SCENE).instantiate()
	var console: PocConsole = load(CONSOLE_SCENE).instantiate()
	add_child_autofree(player)
	add_child_autofree(console)
	console.global_position = Vector3(separation, 0.0, 0.0)
	# Overlaps are resolved by the physics server, not on add_child.
	await wait_physics_frames(2)
	return player


func test_the_player_reaches_a_console_standing_next_to_it():
	GameState.reset()
	var player = await _player_and_console_at(WITHIN_REACH)
	player._try_interact()
	assert_eq(GameState.get_resource(PocConsole.RESOURCE_ID), PocConsole.CONSOLE_YIELD,
		"INTERACT_RADIUS does not reach a prop the player is standing against")


func test_the_player_does_not_reach_a_distant_console():
	GameState.reset()
	var player = await _player_and_console_at(BEYOND_REACH)
	player._try_interact()
	assert_eq(GameState.get_resource(PocConsole.RESOURCE_ID), 0,
		"the interaction zone is reaching further than INTERACT_RADIUS allows")


func test_interacting_with_nothing_in_reach_is_a_no_op():
	GameState.reset()
	var player: Player3D = load(PLAYER_SCENE).instantiate()
	add_child_autofree(player)
	await wait_physics_frames(2)
	player._try_interact()
	pass_test("an empty interaction zone must not error")


# ── Exit door (R8 / AC4) ──────────────────────────────────────────────────────

const DOOR_SCENE := "res://scenes/poc3d/exit_door.tscn"


func _door() -> ExitDoor:
	var node: ExitDoor = load(DOOR_SCENE).instantiate()
	add_child_autofree(node)
	return node


func _player_body() -> Node3D:
	# A stand-in for Player3D: the door filters on the group, not the type.
	var body := Node3D.new()
	body.add_to_group(ExitDoor.PLAYER_GROUP)
	add_child_autofree(body)
	return body


func test_entering_fires_the_trigger_once():
	var door := _door()
	watch_signals(door)
	door._on_body_entered(_player_body())
	assert_signal_emit_count(door, "triggered", 1)


func test_the_trigger_reports_the_destination_id():
	var door := _door()
	door.destination_id = "cantina"
	watch_signals(door)
	door._on_body_entered(_player_body())
	assert_signal_emitted_with_parameters(door, "triggered", ["cantina"])


func test_jitter_inside_the_zone_does_not_refire():
	# AC4: "exactly once per entry". Physics can re-emit body_entered while the player is
	# pressed against the wall inside the trigger; the latch is what makes AC4 true.
	var door := _door()
	var body := _player_body()
	watch_signals(door)
	door._on_body_entered(body)
	door._on_body_entered(body)
	door._on_body_entered(body)
	assert_signal_emit_count(door, "triggered", 1)


func test_leaving_and_re_entering_fires_again():
	var door := _door()
	var body := _player_body()
	watch_signals(door)
	door._on_body_entered(body)
	door._on_body_exited(body)
	door._on_body_entered(body)
	assert_signal_emit_count(door, "triggered", 2)


func test_a_non_player_body_is_ignored():
	var door := _door()
	var crate := Node3D.new()
	add_child_autofree(crate)
	watch_signals(door)
	door._on_body_entered(crate)
	assert_signal_emit_count(door, "triggered", 0)


func test_a_non_player_leaving_does_not_clear_the_latch():
	var door := _door()
	var body := _player_body()
	var crate := Node3D.new()
	add_child_autofree(crate)
	watch_signals(door)
	door._on_body_entered(body)
	door._on_body_exited(crate)
	door._on_body_entered(body)
	assert_signal_emit_count(door, "triggered", 1)


# ── Hardcoded dialogue line (R7 / AC3) ───────────────────────────────────────

const SPEAKER := "Maris"
const BODY := "The recycler's coughing again. Third time this week."


func _localized() -> YarnSpinner.LocalizedLine:
	return YarnSpinner.LocalizedLine.from_dictionary(PocDialogueLine.build(SPEAKER, BODY))


func test_the_line_round_trips_into_a_localized_line():
	assert_not_null(_localized(),
		"from_dictionary() returns null and push_errors when a required key is missing")


func test_the_speaker_is_recoverable_as_the_character_name():
	# This is what drives dialogue_box's SpeakerLabel and its portrait lookup.
	assert_eq(_localized().character_name, SPEAKER)


func test_the_body_survives_with_the_speaker_prefix_stripped():
	assert_eq(_localized().text_without_character_name.text, BODY)


func test_the_raw_text_keeps_the_full_line():
	assert_eq(_localized().raw_text, SPEAKER + PocDialogueLine.SPEAKER_SEPARATOR + BODY)


func test_the_speaker_maps_to_a_real_portrait_index():
	# dialogue_box falls back to FALLBACK_PORTRAIT_INDEX for an unknown speaker; AC3 wants
	# Maris's actual portrait, so the name must match NPC_PORTRAIT_INDEX exactly.
	var box = load("res://scenes/ui/dialogue_box.tscn").instantiate()
	add_child_autofree(box)
	assert_true(box.NPC_PORTRAIT_INDEX.has(SPEAKER),
		"'%s' is not a key of dialogue_box.NPC_PORTRAIT_INDEX" % SPEAKER)
