# scripts/characters/velreth.gd
extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
	super()
	npc_id = "velreth"
	display_name = "Velreth"
	$AnimatedSprite2D.modulate = Color(0.7, 0.9, 0.85)

func get_dialogue_node() -> String:
	return "Velreth"
