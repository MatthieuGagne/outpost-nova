# scripts/workbench.gd
extends StaticBody2D

func _ready() -> void:
	add_to_group("interactable")

func interact() -> void:
	get_tree().get_root().get_node("Main").open_crafting()
