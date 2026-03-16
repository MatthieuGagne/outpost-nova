# scripts/main.gd
extends Node2D

func _ready() -> void:
	GameState.flag_changed.connect(_on_flag_changed)

func _on_flag_changed(flag: String, value: bool) -> void:
	if flag == "workshop_unlocked" and value:
		_celebrate_workshop_unlock()

func _celebrate_workshop_unlock() -> void:
	var label = Label.new()
	label.text = "The Workshop is open."
	label.add_theme_font_size_override("font_size", 32)
	label.set_anchors_preset(Control.PRESET_CENTER)
	add_child(label)
	await get_tree().create_timer(3.0).timeout
	label.queue_free()
