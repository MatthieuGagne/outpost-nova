# scripts/areas/engineering.gd
extends Node2D

@onready var cantina_door: Area2D = $CantinaDoor
@onready var quarters_door: Area2D = $QuartersDoor

func _ready() -> void:
	cantina_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			get_tree().get_root().get_node("Main").go_to_area("cantina")
	)
	quarters_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			get_tree().get_root().get_node("Main").go_to_area("quarters")
	)
