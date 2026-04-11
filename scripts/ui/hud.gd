# scripts/ui/hud.gd
extends CanvasLayer

@onready var rations_lbl: Label = $HBoxContainer/RationsLabel
@onready var parts_lbl: Label = $HBoxContainer/PartsLabel
@onready var energy_lbl: Label = $HBoxContainer/EnergyLabel
@onready var scrap_lbl: Label = $HBoxContainer/ScrapLabel
@onready var day_lbl: Label = $HBoxContainer/DayLabel
@onready var beats_lbl: Label = $HBoxContainer/BeatsLabel
@onready var message_lbl: Label = $MessageLabel

func _ready() -> void:
	GameState.resource_changed.connect(_refresh_resources)
	DayManager.beat_completed.connect(_refresh_beats)
	DayManager.day_ended.connect(_on_day_ended)
	message_lbl.hide()
	_refresh_resources("", 0)
	_refresh_beats("")

func _refresh_resources(_id, _amt) -> void:
	rations_lbl.text = "Rations: %d" % GameState.get_resource("rations")
	parts_lbl.text = "Parts: %d" % GameState.get_resource("parts")
	energy_lbl.text = "Energy: %d" % GameState.get_resource("energy_cells")
	scrap_lbl.text = "Scrap: %d" % GameState.get_resource("scrap")
	day_lbl.text = "Day %d" % DayManager.current_day

func _refresh_beats(_beat_id) -> void:
	var remaining = 0
	for beat in DayManager.get_todays_beats():
		if beat.get("required", false) and not DayManager.is_beat_complete(beat["id"]):
			remaining += 1
	if DayManager.is_day_complete():
		beats_lbl.text = "Rest when ready (bunk in Quarters)"
	elif remaining > 0:
		beats_lbl.text = "Story beats: %d remaining" % remaining
	else:
		beats_lbl.text = ""

func _on_day_ended(_day) -> void:
	day_lbl.text = "Day %d" % DayManager.current_day
	_refresh_beats("")

func show_message(text: String) -> void:
	message_lbl.text = text
	message_lbl.show()
	await get_tree().create_timer(3.0).timeout
	message_lbl.hide()
