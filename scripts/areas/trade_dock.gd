# scripts/areas/trade_dock.gd
extends Node2D

@onready var cantina_door: Area2D = $CantinaExitDoor
@onready var security_post_door: Area2D = $SecurityPostDoor

func _ready() -> void:
	var main := get_tree().get_root().get_node("Main")
	cantina_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			main.go_to_area("cantina")
	)
	security_post_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			main.go_to_area("security_post")
	)
