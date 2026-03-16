# tests/test_crafting_system.gd
extends GutTest

func before_each():
	GameState.reset()

func test_can_craft_when_resources_sufficient():
	GameState.add_resource("rations", 2)
	assert_true(CraftingSystem.can_craft("hot_meal"))

func test_cannot_craft_when_resources_insufficient():
	GameState.add_resource("rations", 1)
	assert_false(CraftingSystem.can_craft("hot_meal"))

func test_craft_consumes_resources():
	GameState.add_resource("rations", 2)
	CraftingSystem.craft("hot_meal")
	assert_eq(GameState.get_resource("rations"), 0)

func test_craft_returns_false_if_cannot_afford():
	var ok = CraftingSystem.craft("hot_meal")
	assert_false(ok)

func test_get_recipes_returns_all():
	var recipes = CraftingSystem.get_all_recipes()
	assert_gt(recipes.size(), 0)

func test_workshop_recipe_locked_by_default():
	assert_false(CraftingSystem.is_recipe_available("power_relay"))

func test_workshop_recipe_available_after_unlock():
	GameState.set_flag("workshop_unlocked", true)
	assert_true(CraftingSystem.is_recipe_available("power_relay"))
