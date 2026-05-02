# scripts/bunk.gd
extends StaticBody2D

func _ready() -> void:
	add_to_group("interactable")

func interact() -> void:
	var main = get_tree().get_root().get_node("Main")
	main.advance_day()
