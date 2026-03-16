# scripts/ui/crafting_panel.gd
extends CanvasLayer

@onready var recipes_container: VBoxContainer = $PanelContainer/VBoxContainer/RecipesContainer
@onready var close_btn: Button = $PanelContainer/VBoxContainer/CloseButton

func _ready() -> void:
	hide()
	close_btn.pressed.connect(hide)

func open() -> void:
	_build_recipe_list()
	show()

func _build_recipe_list() -> void:
	for child in recipes_container.get_children():
		child.queue_free()

	for recipe_id in CraftingSystem.get_all_recipes():
		if not CraftingSystem.is_recipe_available(recipe_id):
			continue
		var hbox = HBoxContainer.new()
		var lbl = Label.new()
		var recipe = CraftingSystem.get_all_recipes()[recipe_id]
		var cost_parts = []
		for input in recipe["inputs"]:
			cost_parts.append("%d %s" % [input["qty"], input["id"]])
		lbl.text = "%s  (%s)" % [recipe_id.replace("_", " ").capitalize(), ", ".join(cost_parts)]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn = Button.new()
		btn.text = "Craft"
		btn.disabled = not CraftingSystem.can_craft(recipe_id)
		btn.pressed.connect(_craft.bind(recipe_id))
		hbox.add_child(lbl)
		hbox.add_child(btn)
		recipes_container.add_child(hbox)

func _craft(recipe_id: String) -> void:
	CraftingSystem.craft(recipe_id)
	_build_recipe_list()
