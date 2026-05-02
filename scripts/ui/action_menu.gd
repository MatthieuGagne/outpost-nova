extends CanvasLayer

@onready var _preview_lbl: Label = $PanelContainer/VBoxContainer/PreviewLabel
@onready var _start_btn: Button = $PanelContainer/VBoxContainer/StartButton

const START_COST_MINUTES: int = 90

var _current_plot: Node = null

func _ready() -> void:
	add_to_group("action_menu")
	_start_btn.pressed.connect(_on_start_pressed)
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		hide()
		_current_plot = null
		get_viewport().set_input_as_handled()

func show_for_plot(plot: Node) -> void:
	_current_plot = plot
	var can_start := ClockManager.can_act(START_COST_MINUTES)
	_preview_lbl.text = "Yield: %d %s\nTime: 1.5 hr%s" % [
		plot.yield_amount,
		plot.resource_id,
		"" if can_start else "\nNot enough time today."
	]
	_start_btn.disabled = not can_start
	show()
	_start_btn.grab_focus()

func _on_start_pressed() -> void:
	if _current_plot == null:
		return
	_current_plot.start_plot()
	hide()
	_current_plot = null
