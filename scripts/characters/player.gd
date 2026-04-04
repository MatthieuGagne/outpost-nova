# scripts/characters/player.gd
extends CharacterBody2D

const SPEED = 80.0
const ROOM_W = 30
const ROOM_H = 16
const TILE_SIZE = 16

@export var attack_damage: int = 1

@onready var interaction_zone: Area2D = $InteractionZone
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var _facing: String = "down"

func _ready() -> void:
	add_to_group("player")
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = ROOM_W * TILE_SIZE   # 480
	camera.limit_bottom = ROOM_H * TILE_SIZE  # 256

func _physics_process(_delta: float) -> void:
	var direction = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	velocity = direction * SPEED
	move_and_slide()
	_update_animation(direction)

func _update_animation(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		_facing = _get_facing(direction)
		sprite.play("walk_" + _facing)
	else:
		sprite.play("idle_" + _facing)

func _get_facing(direction: Vector2) -> String:
	if abs(direction.x) >= abs(direction.y):
		return "right" if direction.x > 0 else "left"
	return "down" if direction.y > 0 else "up"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("attack"):
		_do_attack()
		get_viewport().set_input_as_handled()

func _try_interact() -> void:
	var bodies = interaction_zone.get_overlapping_bodies()
	var areas = interaction_zone.get_overlapping_areas()
	for body in bodies:
		if body.is_in_group("interactable") and body.visible:
			body.interact()
			return
	for area in areas:
		if area.is_in_group("interactable") and area.visible:
			area.interact()
			return

func _do_attack() -> void:
	var hitbox = Area2D.new()
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 20.0
	hitbox.add_child(shape)
	hitbox.position = position + Vector2(16, 0)
	get_parent().add_child(hitbox)
	await get_tree().create_timer(0.1).timeout
	for body in hitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)
	hitbox.queue_free()
