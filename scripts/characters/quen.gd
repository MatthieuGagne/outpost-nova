extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
	super()
	npc_id = "quen"
	display_name = "Quen"
	$AnimatedSprite2D.modulate = Color(0.7, 0.9, 0.85)  # teal
	_add_mask_placeholder()

func get_dialogue_node() -> String:
	return "Quen"

func _add_mask_placeholder() -> void:
	var mask := ColorRect.new()
	mask.name = "MaskPlaceholder"
	mask.color = Color(0.7, 0.1, 0.1)  # crimson
	mask.size = Vector2(12, 8)
	mask.position = Vector2(-6, -14)
	add_child(mask)
