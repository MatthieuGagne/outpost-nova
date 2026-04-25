# scripts/areas/security_post.gd
extends Node2D

@onready var cantina_door: Area2D = $CantinaDoor
@onready var med_bay_door: Area2D = $MedBayDoor
@onready var trade_dock_door: Area2D = $TradeDockDoor

func _ready() -> void:
	var main := get_tree().get_root().get_node("Main")
	cantina_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			main.go_to_area("cantina")
	)
	med_bay_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			main.go_to_area("med_bay")
	)
	trade_dock_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			main.go_to_area("trade_dock")
	)
