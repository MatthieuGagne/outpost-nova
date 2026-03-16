# scripts/autoload/crafting_system.gd
extends Node

signal item_crafted(item_id: String)

# Recipe format: { inputs: [{id, qty}], requires_flag: "" }
const RECIPES: Dictionary = {
	"hot_meal": {
		"inputs": [{ "id": "rations", "qty": 2 }],
		"requires_flag": ""
	},
	"decent_drink": {
		"inputs": [{ "id": "rations", "qty": 1 }, { "id": "energy_cells", "qty": 1 }],
		"requires_flag": ""
	},
	"patch_kit": {
		"inputs": [{ "id": "parts", "qty": 2 }],
		"requires_flag": ""
	},
	"power_relay": {
		"inputs": [{ "id": "parts", "qty": 1 }, { "id": "energy_cells", "qty": 2 }],
		"requires_flag": "workshop_unlocked"
	},
	"station_light": {
		"inputs": [{ "id": "parts", "qty": 1 }, { "id": "rations", "qty": 1 }],
		"requires_flag": ""
	}
}

func get_all_recipes() -> Dictionary:
	return RECIPES

func is_recipe_available(recipe_id: String) -> bool:
	if not RECIPES.has(recipe_id):
		return false
	var flag = RECIPES[recipe_id]["requires_flag"]
	if flag != "":
		return GameState.get_flag(flag)
	return true

func can_craft(recipe_id: String) -> bool:
	if not is_recipe_available(recipe_id):
		return false
	for input in RECIPES[recipe_id]["inputs"]:
		if GameState.get_resource(input["id"]) < input["qty"]:
			return false
	return true

func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		return false
	for input in RECIPES[recipe_id]["inputs"]:
		GameState.spend_resource(input["id"], input["qty"])
	item_crafted.emit(recipe_id)
	return true
