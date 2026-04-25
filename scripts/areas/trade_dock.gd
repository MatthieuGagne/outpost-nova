# scripts/areas/trade_dock.gd
extends Node2D

@onready var cantina_exit_door: Area2D = $CantinaExitDoor
@onready var security_post_door: Area2D = $SecurityPostDoor
@onready var spine_prop_trigger: Area2D = $SpinePropTrigger
@onready var spine_door_label: Label = $SpineDoorLabel

func _ready() -> void:
	var main := get_tree().get_root().get_node("Main")
	cantina_exit_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			main.go_to_area("cantina")
	)
	security_post_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			main.go_to_area("security_post")
	)
	spine_prop_trigger.body_entered.connect(func(body):
		if body.is_in_group("player"):
			spine_door_label.visible = true
	)
	spine_prop_trigger.body_exited.connect(func(body):
		if body.is_in_group("player"):
			spine_door_label.visible = false
	)
	spine_door_label.visible = false
