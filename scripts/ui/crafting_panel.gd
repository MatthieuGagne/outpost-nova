# scripts/ui/crafting_panel.gd
extends CanvasLayer

@onready var recipes_container: VBoxContainer = $PanelContainer/VBoxContainer/RecipesContainer
@onready var _cursor: MenuCursor = $MenuCursor

func _ready() -> void:
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if UIInput.is_cancel(event):
		hide()
		get_viewport().set_input_as_handled()
		return
	var buttons := recipes_container.get_children()
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		var focused := get_viewport().gui_get_focus_owner()
		var curr := buttons.find(focused)
		var next := UIInput.navigate(event, buttons, curr if curr != -1 else 0)
		buttons[next].grab_focus()
		get_viewport().set_input_as_handled()
	elif UIInput.is_confirm(event):
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button and focused.get_parent() == recipes_container and not focused.disabled:
			focused.pressed.emit()
		get_viewport().set_input_as_handled()

func open() -> void:
	_build_recipe_list()
	show()

func _build_recipe_list() -> void:
	for child in recipes_container.get_children():
		child.queue_free()
	for recipe_id in CraftingSystem.get_all_recipes():
		if not CraftingSystem.is_recipe_available(recipe_id):
			continue
		var recipe = CraftingSystem.get_all_recipes()[recipe_id]
		var cost_parts = []
		for input in recipe["inputs"]:
			cost_parts.append("%d %s" % [input["qty"], input["id"].replace("_", " ")])
		var can = CraftingSystem.can_craft(recipe_id)
		var label = "%s  (%s)" % [recipe_id.replace("_", " ").capitalize(), ", ".join(cost_parts)]
		if not can:
			label += "  —  need more"
		var btn := Button.new()
		btn.text = label
		btn.disabled = not can
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.pressed.connect(_craft.bind(recipe_id))
		recipes_container.add_child(btn)
	_cursor.track(recipes_container)
	for btn in recipes_container.get_children():
		if not btn.disabled:
			btn.grab_focus()
			break

func _craft(recipe_id: String) -> void:
	CraftingSystem.craft(recipe_id)
	hide()
