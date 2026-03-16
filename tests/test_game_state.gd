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
