# scripts/characters/player.gd
extends CharacterBody2D

const SPEED = 80.0

@export var attack_damage: int = 1

@onready var interaction_zone: Area2D = $InteractionZone

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var direction = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	velocity = direction * SPEED
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("attack"):
		_do_attack()

func _try_interact() -> void:
	var bodies = interaction_zone.get_overlapping_bodies()
	var areas = interaction_zone.get_overlapping_areas()
	# NPCs are CharacterBody2D (bodies), resource nodes are Area2D (areas)
	for body in bodies:
		if body.is_in_group("interactable"):
			body.interact()
			return
	for area in areas:
		if area.is_in_group("interactable"):
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
