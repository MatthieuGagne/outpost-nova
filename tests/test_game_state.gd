# tests/test_game_state.gd
extends GutTest

func test_resources_start_at_zero():
	GameState.reset()
	assert_eq(GameState.get_resource("rations"), 0)
	assert_eq(GameState.get_resource("parts"), 0)
	assert_eq(GameState.get_resource("energy_cells"), 0)

func test_add_resource():
	GameState.reset()
	GameState.add_resource("rations", 3)
	assert_eq(GameState.get_resource("rations"), 3)

func test_spend_resource_succeeds():
	GameState.reset()
	GameState.add_resource("parts", 5)
	var ok = GameState.spend_resource("parts", 3)
	assert_true(ok)
	assert_eq(GameState.get_resource("parts"), 2)

func test_spend_resource_fails_if_insufficient():
	GameState.reset()
	GameState.add_resource("parts", 1)
	var ok = GameState.spend_resource("parts", 3)
	assert_false(ok)
	assert_eq(GameState.get_resource("parts"), 1)

func test_flags_default_false():
	GameState.reset()
	assert_false(GameState.get_flag("workshop_unlocked"))

func test_set_flag():
	GameState.reset()
	GameState.set_flag("workshop_unlocked", true)
	assert_true(GameState.get_flag("workshop_unlocked"))

func test_player_background_defaults_empty():
	GameState.reset()
	assert_eq(GameState.player_background, "")

func test_set_player_identity():
	GameState.reset()
	GameState.set_player_identity("Kael", "engineer", 0)
	assert_eq(GameState.player_name, "Kael")
	assert_eq(GameState.player_background, "engineer")
	assert_eq(GameState.player_appearance, 0)

func test_engineer_background_starts_with_parts():
	GameState.reset()
	GameState.apply_background_bonus("engineer")
	assert_eq(GameState.get_resource("parts"), 4)

func test_medic_background_starts_with_rations():
	GameState.reset()
	GameState.apply_background_bonus("medic")
	assert_eq(GameState.get_resource("rations"), 4)

func test_drifter_background_starts_with_energy_cells():
	GameState.reset()
	GameState.apply_background_bonus("drifter")
	assert_eq(GameState.get_resource("energy_cells"), 4)

func test_arrival_kit_applied():
	for background in ["engineer", "medic", "drifter"]:
		GameState.reset()
		GameState.apply_background_bonus(background)
		assert_gte(GameState.get_resource("rations"), 1, "rations >= 1 for %s" % background)
		assert_gte(GameState.get_resource("parts"), 1, "parts >= 1 for %s" % background)
		assert_gte(GameState.get_resource("energy_cells"), 1, "energy_cells >= 1 for %s" % background)

func test_npc_flag_history():
	GameState.reset()
	GameState.record_npc_choice("maris", "was_honest")
	assert_true(GameState.has_npc_flag("maris", "was_honest"))
	assert_false(GameState.has_npc_flag("maris", "helped_her"))

func test_record_register_increments_count():
	GameState.reset()
	GameState.record_register("warm")
	GameState.record_register("warm")
	GameState.record_register("curious")
	var history = GameState.get_register_history()
	assert_eq(history.get("warm", 0), 2)
	assert_eq(history.get("curious", 0), 1)

func test_record_register_cleared_on_reset():
	GameState.record_register("warm")
	GameState.reset()
	assert_eq(GameState.get_register_history().is_empty(), true)

func test_set_flag_on():
	GameState.reset()
	GameState.set_flag_on("met_maris")
	assert_true(GameState.get_flag("met_maris"))

func test_set_flag_on_cleared_on_reset():
	GameState.set_flag_on("met_maris")
	GameState.reset()
	assert_false(GameState.get_flag("met_maris"))

# --- PairState tests ---

func test_pair_state_defaults_neutral_for_unknown_pair():
	GameState.reset()
	assert_eq(GameState.get_pair_state("no_such_pair"), GameState.PairState.NEUTRAL)

func test_set_pair_state_stores_value():
	GameState.reset()
	GameState.set_pair_state("maris_dex", GameState.PairState.COLLEGIAL)
	assert_eq(GameState.get_pair_state("maris_dex"), GameState.PairState.COLLEGIAL)

func test_set_pair_state_emits_signal():
	GameState.reset()
	watch_signals(GameState)
	GameState.set_pair_state("maris_dex", GameState.PairState.COLLEGIAL)
	assert_signal_emitted(GameState, "pair_state_changed")

func test_authored_default_maris_velreth_is_collegial():
	GameState.reset()
	assert_eq(GameState.get_pair_state("maris_velreth"), GameState.PairState.COLLEGIAL)

func test_authored_default_dex_velreth_is_collegial():
	GameState.reset()
	assert_eq(GameState.get_pair_state("dex_velreth"), GameState.PairState.COLLEGIAL)

func test_authored_default_maris_dex_is_neutral():
	GameState.reset()
	assert_eq(GameState.get_pair_state("maris_dex"), GameState.PairState.NEUTRAL)

func test_reset_restores_authored_defaults():
	GameState.reset()
	GameState.set_pair_state("maris_velreth", GameState.PairState.TENSION)
	GameState.reset()
	assert_eq(GameState.get_pair_state("maris_velreth"), GameState.PairState.COLLEGIAL)

func test_get_pairs_for_npc_returns_only_pairs_involving_npc():
	GameState.reset()
	var pairs := GameState.get_pairs_for_npc("maris")
	assert_true(pairs.has("maris_velreth"))
	assert_false(pairs.has("dex_velreth"))

func test_get_pair_state_label_neutral():
	assert_eq(GameState.get_pair_state_label(GameState.PairState.NEUTRAL), "Neutral")

func test_get_pair_state_label_collegial():
	assert_eq(GameState.get_pair_state_label(GameState.PairState.COLLEGIAL), "Collegial")

func test_get_pair_state_label_tension():
	assert_eq(GameState.get_pair_state_label(GameState.PairState.TENSION), "Tension")

func test_get_pair_state_label_bonded():
	assert_eq(GameState.get_pair_state_label(GameState.PairState.BONDED), "Bonded")

func test_pair_state_normalizes_order():
	GameState.reset()
	GameState.set_pair_state("velreth_maris", GameState.PairState.TENSION)
	assert_eq(GameState.get_pair_state("maris_velreth"), GameState.PairState.TENSION)
