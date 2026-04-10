# scripts/ui/crafting_panel.gd
extends CanvasLayer

@onready var recipes_container: VBoxContainer = $PanelContainer/VBoxContainer/RecipesContainer
@onready var close_btn: Button = $PanelContainer/VBoxContainer/CloseButton

var _recipe_ids: Array = []

func _ready() -> void:
	hide()
	close_btn.pressed.connect(hide)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
		return
	var buttons := recipes_container.get_children()
	if event.is_action_pressed("ui_up"):
		_move_focus(buttons, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_focus(buttons, 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused and focused.get_parent() == recipes_container and not focused.disabled:
			focused.emit_signal("pressed")
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		for i in range(min(9, buttons.size())):
			if event.physical_keycode == KEY_1 + i:
				if not buttons[i].disabled:
					buttons[i].emit_signal("pressed")
				get_viewport().set_input_as_handled()
				return

func open() -> void:
	_build_recipe_list()
	show()

func _build_recipe_list() -> void:
	_recipe_ids = []
	for child in recipes_container.get_children():
		child.queue_free()

	var idx := 0
	for recipe_id in CraftingSystem.get_all_recipes():
		if not CraftingSystem.is_recipe_available(recipe_id):
			continue
		idx += 1
		_recipe_ids.append(recipe_id)
		var recipe = CraftingSystem.get_all_recipes()[recipe_id]
		var cost_parts = []
		for input in recipe["inputs"]:
			cost_parts.append("%d %s" % [input["qty"], input["id"].replace("_", " ")])
		var can = CraftingSystem.can_craft(recipe_id)
		var label = "[%d] %s  (%s)" % [idx, recipe_id.replace("_", " ").capitalize(), ", ".join(cost_parts)]
		if not can:
			label += "  —  need more"
		var btn := Button.new()
		btn.text = label
		btn.add_theme_font_override("font", load("res://data/fonts/m5x7.tres"))
		btn.add_theme_font_size_override("font_size", 13)
		btn.disabled = not can
		btn.pressed.connect(_craft.bind(recipe_id))
		recipes_container.add_child(btn)

	# Focus first craftable button
	for btn in recipes_container.get_children():
		if not btn.disabled:
			btn.grab_focus()
			break

func _craft(recipe_id: String) -> void:
	CraftingSystem.craft(recipe_id)
	_build_recipe_list()

func _move_focus(buttons: Array, direction: int) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	var current := buttons.find(focused)
	if current == -1:
		current = 0
	var next := wrapi(current + direction, 0, buttons.size())
	buttons[next].grab_focus()
