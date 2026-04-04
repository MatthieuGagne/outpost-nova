# scripts/characters/dex.gd
extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
	super()
	npc_id = "dex"
	display_name = "Dex"
	$AnimatedSprite2D.modulate = Color(0.7, 0.9, 1.0)  # cool blue tint

func get_dialogue_node() -> String:
	return "Dex"
