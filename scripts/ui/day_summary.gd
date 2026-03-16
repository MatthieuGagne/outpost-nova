# scripts/ui/day_summary.gd
extends CanvasLayer

@onready var day_lbl: Label = $Panel/VBox/DayLabel
@onready var events_container: VBoxContainer = $Panel/VBox/EventsContainer
@onready var rest_btn: Button = $Panel/VBox/RestButton

func _ready() -> void:
	hide()
	rest_btn.pressed.connect(_on_rest)

func show_summary() -> void:
	day_lbl.text = "End of Day %d" % DayManager.current_day
	for child in events_container.get_children():
		child.queue_free()
	for beat in DayManager.get_todays_beats():
		if DayManager.is_beat_complete(beat["id"]):
			var lbl = Label.new()
			lbl.text = "✓ %s" % beat["id"].replace("_", " ").capitalize()
			events_container.add_child(lbl)
	show()

func _on_rest() -> void:
	hide()
	DayManager.advance_day()
