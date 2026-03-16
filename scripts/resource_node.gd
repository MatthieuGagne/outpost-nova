# scripts/resource_node.gd
extends Area2D

@export var resource_id: String = "rations"
@export var amount: int = 1
@export var cooldown: float = 8.0

@onready var timer: Timer = $Timer

var _ready_to_collect: bool = true

func _ready() -> void:
	add_to_group("interactable")
	timer.wait_time = cooldown
	timer.one_shot = true
	timer.timeout.connect(func(): _ready_to_collect = true; modulate = Color.WHITE)

func interact() -> void:
	if not _ready_to_collect:
		return
	_ready_to_collect = false
	GameState.add_resource(resource_id, amount)
	modulate = Color(0.5, 0.5, 0.5)
	timer.start()
