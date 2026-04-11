# scripts/characters/quen.gd
extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
	super()
	npc_id = "quen"
	display_name = "Quen"
	$AnimatedSprite2D.modulate = Color(0.85, 0.75, 1.0)  # lavender

func get_dialogue_node() -> String:
	return "Quen"
