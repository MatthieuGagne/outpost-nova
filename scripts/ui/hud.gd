extends CanvasLayer

@onready var rations_lbl: Label = $HBoxContainer/RationsLabel
@onready var parts_lbl: Label = $HBoxContainer/PartsLabel
@onready var energy_lbl: Label = $HBoxContainer/EnergyLabel
@onready var scrap_lbl: Label = $HBoxContainer/ScrapLabel
@onready var day_lbl: Label = $HBoxContainer/DayLabel
@onready var clock_lbl: Label = $HBoxContainer/ClockLabel
@onready var message_lbl: Label = $MessageLabel

func _ready() -> void:
	GameState.resource_changed.connect(_refresh_resources)
	ClockManager.time_advanced.connect(_on_time_advanced)
	message_lbl.hide()
	_refresh_resources("", 0)
	_on_time_advanced(ClockManager.current_time)

func _refresh_resources(_id, _amt) -> void:
	rations_lbl.text = "Rations: %d" % GameState.get_resource("rations")
	parts_lbl.text = "Parts: %d" % GameState.get_resource("parts")
	energy_lbl.text = "Energy: %d" % GameState.get_resource("energy_cells")
	scrap_lbl.text = "Scrap: %d" % GameState.get_resource("scrap")

func _on_time_advanced(_new_time: int) -> void:
	clock_lbl.text = ClockManager.get_time_string()
	day_lbl.text = "Day %d" % ClockManager.current_day

func show_message(text: String) -> void:
	message_lbl.text = text
	message_lbl.show()
	await get_tree().create_timer(3.0).timeout
	message_lbl.hide()
