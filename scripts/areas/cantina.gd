# scripts/areas/cantina.gd
extends Node2D

@onready var engineering_door: Area2D = $EngineeringDoor

func _ready() -> void:
	engineering_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			get_tree().get_root().get_node("Main").go_to_area("workshop")
	)
