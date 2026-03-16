# scripts/characters/character.gd
extends Area2D

@export var character_name: String = "Unknown"

signal interaction_requested(character: Node)

func _ready() -> void:
	add_to_group("characters")

func _draw() -> void:
	draw_rect(Rect2(-24, -32, 48, 64), Color(0.6, 0.6, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(-22, 6), character_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		interaction_requested.emit(self)

func get_dialogue() -> String:
	return "..."  # Overridden by subclass
