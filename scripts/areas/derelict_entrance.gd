# scripts/areas/derelict_entrance.gd
extends Node2D

@onready var entrance_trigger: Area2D = $EntranceTrigger
@onready var engineering_door: Area2D = $EngineeringDoor

func _ready() -> void:
	entrance_trigger.body_entered.connect(func(body):
		if body.is_in_group("player"):
			get_tree().change_scene_to_file("res://scenes/derelict/run.tscn")
	)
	engineering_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			get_tree().get_root().get_node("Main").go_to_area("engineering")
	)
