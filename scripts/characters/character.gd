# scripts/characters/character.gd
extends Area2D

@export var character_name: String = "Unknown"

signal interaction_requested(character: Node)

func _ready() -> void:
	add_to_group("characters")

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		interaction_requested.emit(self)

func get_dialogue() -> String:
	return "..."  # Overridden by subclass
