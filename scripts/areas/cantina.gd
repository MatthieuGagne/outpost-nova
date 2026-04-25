# scripts/areas/cantina.gd
extends Node2D

@onready var workshop_door: Area2D = $WorkshopDoor
@onready var security_post_door: Area2D = $SecurityPostDoor
@onready var quarters_door: Area2D = $QuartersDoor
@onready var trade_dock_door: Area2D = $TradeDockDoor

func _ready() -> void:
	var main := get_tree().get_root().get_node("Main")
	workshop_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			main.go_to_area("workshop")
	)
	security_post_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			main.go_to_area("security_post")
	)
	quarters_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			main.go_to_area("quarters")
	)
	trade_dock_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			main.go_to_area("trade_dock")
	)
