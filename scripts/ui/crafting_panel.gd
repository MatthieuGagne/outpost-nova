# scripts/ui/crafting_panel.gd
extends CanvasLayer

@onready var recipe_list: VBoxContainer = $PanelContainer/VBoxContainer/ScrollContainer/RecipeList
@onready var close_btn: Button = $PanelContainer/VBoxContainer/CloseButton

func _ready() -> void:
	hide()
	close_btn.pressed.connect(hide)
	CraftingSystem.item_crafted.connect(_on_item_crafted)
	GameState.resource_changed.connect(_refresh)
	GameState.flag_changed.connect(_on_flag_changed)

func open() -> void:
	_build_recipe_list()
	show()

func _build_recipe_list() -> void:
	for child in recipe_list.get_children():
		child.queue_free()

	for recipe_id in CraftingSystem.get_all_recipes():
		if not CraftingSystem.is_recipe_available(recipe_id):
			continue
		var btn = Button.new()
		btn.text = _recipe_label(recipe_id)
		btn.disabled = not CraftingSystem.can_craft(recipe_id)
		btn.pressed.connect(func(): CraftingSystem.craft(recipe_id))
		recipe_list.add_child(btn)

func _recipe_label(recipe_id: String) -> String:
	var recipe = CraftingSystem.get_all_recipes()[recipe_id]
	var parts = []
	for input in recipe["inputs"]:
		parts.append("%d %s" % [input["qty"], input["id"]])
	return "%s  [%s]" % [recipe_id.replace("_", " ").capitalize(), ", ".join(parts)]

func _refresh(_id, _amount) -> void:
	if visible:
		_build_recipe_list()

func _on_flag_changed(_flag: String, _value: bool) -> void:
	if visible:
		_build_recipe_list()

func _on_item_crafted(item_id: String) -> void:
	print("Crafted: ", item_id)  # Hook for future inventory system
