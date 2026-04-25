# scripts/areas/derelict_entrance.gd
extends Node2D

@onready var door_trigger: Area2D = $EntranceTrigger
@onready var door_sprite: Sprite2D = $DoorSprite
@onready var trade_dock_door: Area2D = $TradeDockDoor

func _ready() -> void:
	_refresh_door()
	GameState.flag_changed.connect(func(flag, _val):
		if flag == "derelict_mentioned":
			_refresh_door()
	)
	door_trigger.body_entered.connect(func(body):
		if body.is_in_group("player") and GameState.get_flag("derelict_mentioned"):
			_enter_derelict()
	)
	trade_dock_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			get_tree().get_root().get_node("Main").go_to_area("trade_dock")
	)

func _refresh_door() -> void:
	door_sprite.modulate = Color.GREEN if GameState.get_flag("derelict_mentioned") else Color.RED

func _enter_derelict() -> void:
	if not DayManager.is_beat_complete("first_derelict_run"):
		DayManager.complete_beat("first_derelict_run")
	get_tree().change_scene_to_file("res://scenes/derelict/run.tscn")
