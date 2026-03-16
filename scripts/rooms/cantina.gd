# scripts/rooms/cantina.gd
extends Node2D

@onready var food_printer_btn: Button = $UpgradeFoodPrinter
@onready var lighting_btn: Button = $UpgradeLighting
@onready var workshop_btn: Button = $UnlockWorkshop

const UPGRADE_COSTS = {
	"food_printer": [{ "id": "rations", "qty": 2 }],
	"lighting": [{ "id": "parts", "qty": 1 }, { "id": "energy_cells", "qty": 1 }],
	"workshop": [{ "id": "parts", "qty": 2 }, { "id": "energy_cells", "qty": 2 }]
}

func _ready() -> void:
	food_printer_btn.pressed.connect(_upgrade_food_printer)
	lighting_btn.pressed.connect(_upgrade_lighting)
	workshop_btn.pressed.connect(_unlock_workshop)
	$OpenCraftingBtn.pressed.connect(_open_crafting)
	GameState.resource_changed.connect(_refresh_buttons)
	GameState.flag_changed.connect(_on_flag_changed)
	_refresh_buttons("", 0)

	for character in get_tree().get_nodes_in_group("characters"):
		character.interaction_requested.connect(_on_character_interaction)

func _can_afford(costs: Array) -> bool:
	for cost in costs:
		if GameState.get_resource(cost["id"]) < cost["qty"]:
			return false
	return true

func _refresh_buttons(_id, _amount) -> void:
	food_printer_btn.disabled = GameState.get_flag("food_printer_upgraded") or not _can_afford(UPGRADE_COSTS["food_printer"])
	lighting_btn.disabled = GameState.get_flag("lighting_upgraded") or not _can_afford(UPGRADE_COSTS["lighting"])
	workshop_btn.disabled = GameState.get_flag("workshop_unlocked") or not _can_afford(UPGRADE_COSTS["workshop"])

func _on_flag_changed(_flag: String, _value: bool) -> void:
	_refresh_buttons("", 0)

func _upgrade_food_printer() -> void:
	for cost in UPGRADE_COSTS["food_printer"]:
		GameState.spend_resource(cost["id"], cost["qty"])
	GameState.set_flag("food_printer_upgraded", true)
	food_printer_btn.text = "Food Printer Upgraded ✓"

func _upgrade_lighting() -> void:
	for cost in UPGRADE_COSTS["lighting"]:
		GameState.spend_resource(cost["id"], cost["qty"])
	GameState.set_flag("lighting_upgraded", true)
	lighting_btn.text = "Lighting Upgraded ✓"

func _unlock_workshop() -> void:
	for cost in UPGRADE_COSTS["workshop"]:
		GameState.spend_resource(cost["id"], cost["qty"])
	GameState.set_flag("workshop_unlocked", true)
	workshop_btn.text = "Workshop Unlocked! →"

func _open_crafting() -> void:
	var crafting_panel = get_tree().root.find_child("CraftingPanel", true, false)
	if crafting_panel:
		crafting_panel.open()

func _on_character_interaction(character: Node) -> void:
	var dialogue_box = get_tree().root.find_child("DialogueBox", true, false)
	if dialogue_box:
		dialogue_box.show_dialogue(character.character_name, character.get_dialogue())
