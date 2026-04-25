# scripts/areas/med_bay.gd
extends Node2D

@onready var security_post_door: Area2D = $SecurityPostDoor

func _ready() -> void:
	security_post_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			get_tree().get_root().get_node("Main").go_to_area("security_post")
	)
