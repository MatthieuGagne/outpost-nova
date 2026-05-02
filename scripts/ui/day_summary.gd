extends CanvasLayer

@onready var day_lbl: Label = $Panel/VBox/DayLabel
@onready var events_container: VBoxContainer = $Panel/VBox/EventsContainer
@onready var rest_btn: Button = $Panel/VBox/RestButton

func _ready() -> void:
	hide()
	rest_btn.pressed.connect(_on_rest)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_on_rest()
		get_viewport().set_input_as_handled()

func show_summary() -> void:
	day_lbl.text = "End of Day %d" % ClockManager.current_day
	for child in events_container.get_children():
		child.queue_free()
	var font = load("res://data/fonts/m5x7.tres")
	for entry in ClockManager._actions_log:
		var lbl := Label.new()
		lbl.text = "• %s" % entry
		lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", 13)
		events_container.add_child(lbl)
	var sep := Label.new()
	sep.text = "—"
	sep.add_theme_font_override("font", font)
	sep.add_theme_font_size_override("font_size", 13)
	events_container.add_child(sep)
	for res_id in ["rations", "parts", "energy_cells"]:
		var lbl := Label.new()
		lbl.text = "%s: %d" % [res_id.replace("_", " ").capitalize(), GameState.get_resource(res_id)]
		lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", 13)
		events_container.add_child(lbl)
	show()
	rest_btn.grab_focus()

func _on_rest() -> void:
	hide()
	ClockManager.advance_day()
