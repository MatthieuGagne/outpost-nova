# scripts/derelict/drone.gd
extends "res://scripts/derelict/enemy_base.gd"

@onready var detect_zone: Area2D = $DetectZone
@onready var hit_zone: Area2D = $HitZone

var _player: CharacterBody2D = null
var _patrol_points: Array = []
var _patrol_index: int = 0

func _ready() -> void:
	super()
	detect_zone.body_entered.connect(func(body):
		if body.is_in_group("player"):
			_player = body
	)
	detect_zone.body_exited.connect(func(body):
		if body.is_in_group("player"):
			_player = null
	)
	hit_zone.body_entered.connect(func(body):
		if body.is_in_group("player"):
			GameState.set_flag("player_hurt", true)
	)
	# Set simple patrol points relative to spawn
	_patrol_points = [position + Vector2(-40, 0), position + Vector2(40, 0)]

func _physics_process(_delta: float) -> void:
	if _player:
		var dir = (_player.position - position).normalized()
		velocity = dir * move_speed
	else:
		var target = _patrol_points[_patrol_index]
		var diff = target - position
		if diff.length() < 4.0:
			_patrol_index = (_patrol_index + 1) % _patrol_points.size()
		velocity = diff.normalized() * (move_speed * 0.5)
	move_and_slide()
