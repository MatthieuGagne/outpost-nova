# scripts/resource_node.gd
extends Area2D

@export var resource_id: String = "rations"
@export var amount_per_collect: int = 1
@export var cooldown_seconds: float = 5.0

@onready var timer: Timer = $Timer

var _ready_to_collect: bool = true

const _COLORS = {
	"rations": Color(0.2, 0.8, 0.2),
	"parts": Color(0.8, 0.5, 0.2),
	"energy_cells": Color(0.2, 0.5, 0.9),
}

func _ready() -> void:
	timer.wait_time = cooldown_seconds
	timer.one_shot = true
	timer.timeout.connect(_on_cooldown_done)
	print("[ResourceNode] ready: ", resource_id, " at pos ", global_position)

func _draw() -> void:
	var col = _COLORS.get(resource_id, Color.WHITE)
	if not _ready_to_collect:
		col = col * 0.5
	draw_rect(Rect2(-24, -24, 48, 48), col)
	draw_string(ThemeDB.fallback_font, Vector2(-22, 6), resource_id, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("[ResourceNode] click registered: ", resource_id, " ready=", _ready_to_collect)
		if _ready_to_collect:
			_collect()

func _collect() -> void:
	_ready_to_collect = false
	GameState.add_resource(resource_id, amount_per_collect)
	queue_redraw()
	timer.start()

func _on_cooldown_done() -> void:
	_ready_to_collect = true
	queue_redraw()
