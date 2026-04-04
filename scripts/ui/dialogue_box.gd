# scripts/ui/dialogue_box.gd
# Stub — full YarnSpinner view implementation written in Task 10
extends CanvasLayer

signal conversation_ended

func _ready() -> void:
	add_to_group("dialogue_box")
	hide()
