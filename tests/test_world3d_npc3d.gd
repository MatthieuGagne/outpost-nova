extends GutTest

const NPC_SCENE := "res://scenes/poc3d/npc3d.tscn"
const RUNNER_STUB := "res://tests/helpers/dialogue_runner_stub.gd"
const BOX_STUB := "res://tests/helpers/dialogue_box_stub.gd"

func test_wander_speed_matches_2d_npc():
	assert_eq(Npc3D.WANDER_SPEED, 30.0 / WorldScale.PIXELS_PER_UNIT)

func test_npc3d_is_a_character_body():
	var npc = load(NPC_SCENE).instantiate()
	add_child_autofree(npc)
	assert_true(npc is CharacterBody3D)

func test_wander_stays_on_xz_and_faces_velocity():
	var npc = load(NPC_SCENE).instantiate()
	add_child_autofree(npc)
	npc._wander_target = npc.position + Vector3(5.0, 0.0, 0.0)
	npc._physics_process(0.016)
	assert_eq(npc.velocity.y, 0.0)
	assert_almost_eq(npc.velocity.length(), Npc3D.WANDER_SPEED, 0.001)
	# walking +X at the 45° contract yaw resolves to "right"
	assert_eq(npc._facing, "right")

func test_near_target_idles_and_repicks():
	var npc = load(NPC_SCENE).instantiate()
	add_child_autofree(npc)
	npc._wander_target = npc.position + Vector3(0.05, 0.0, 0.0)
	npc._physics_process(0.016)
	assert_eq(npc.velocity, Vector3.ZERO)

func test_set_present_toggles_sprite_and_interact_target():
	var npc = load(NPC_SCENE).instantiate()
	add_child_autofree(npc)
	npc.set_present(false)
	assert_false(npc.visible)
	assert_false(npc.get_node("InteractTarget").visible)

func test_interact_starts_dialogue_and_guards_reentry():
	var runner = load(RUNNER_STUB).new()
	runner.add_to_group("dialogue_runner")
	add_child_autofree(runner)
	var box = load(BOX_STUB).new()
	box.add_to_group("dialogue_box")
	add_child_autofree(box)
	var npc = load(NPC_SCENE).instantiate()
	npc.dialogue_node = "Sable"
	add_child_autofree(npc)
	npc.interact()
	assert_true(npc._is_talking)
	assert_eq(runner.started_node, "Sable")
	runner.started_node = ""
	npc.interact()
	assert_eq(runner.started_node, "", "second interact must be a no-op while talking")

func test_conversation_end_commits_30_minutes_once():
	ClockManager.reset()
	var box = load(BOX_STUB).new()
	box.add_to_group("dialogue_box")
	add_child_autofree(box)
	var runner = load(RUNNER_STUB).new()
	runner.add_to_group("dialogue_runner")
	add_child_autofree(runner)
	var npc = load(NPC_SCENE).instantiate()
	npc.dialogue_node = "Sable"
	add_child_autofree(npc)
	npc.interact()
	var before := ClockManager.current_time
	box.conversation_ended.emit()
	box.conversation_ended.emit()
	assert_eq(ClockManager.current_time, before + 30, "one-shot connect must fire once")
	assert_false(npc._is_talking)
