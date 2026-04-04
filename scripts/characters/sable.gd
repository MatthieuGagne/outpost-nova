# scripts/characters/sable.gd
extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
	super()
	npc_id = "sable"
	display_name = "Sable"
	$AnimatedSprite2D.modulate = Color(0.7, 1.0, 0.7)  # green tint

func get_dialogue_node() -> String:
	return "Sable"
