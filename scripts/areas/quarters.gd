# scripts/areas/quarters.gd
extends Node2D

@onready var cantina_bottom_door: Area2D = $CantinaBottomDoor

func _ready() -> void:
	cantina_bottom_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			get_tree().get_root().get_node("Main").go_to_area("cantina")
	)
