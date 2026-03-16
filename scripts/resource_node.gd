# scripts/resource_node.gd
extends Area2D

@export var resource_id: String = "rations"
@export var amount_per_collect: int = 1
@export var cooldown_seconds: float = 5.0

@onready var timer: Timer = $Timer
@onready var sprite: Sprite2D = $Sprite2D

var _ready_to_collect: bool = true

func _ready() -> void:
	timer.wait_time = cooldown_seconds
	timer.one_shot = true
	timer.timeout.connect(_on_cooldown_done)

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and _ready_to_collect:
		_collect()

func _collect() -> void:
	_ready_to_collect = false
	GameState.add_resource(resource_id, amount_per_collect)
	modulate = Color(0.5, 0.5, 0.5)  # Grey out while on cooldown
	timer.start()

func _on_cooldown_done() -> void:
	_ready_to_collect = true
	modulate = Color(1, 1, 1)
