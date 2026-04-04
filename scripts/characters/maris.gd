# scripts/characters/maris.gd
extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
	super()
	npc_id = "maris"
	display_name = "Maris"
	$AnimatedSprite2D.modulate = Color(1.0, 0.7, 0.7)  # warm pink tint

func get_dialogue_node() -> String:
	return "Maris"
