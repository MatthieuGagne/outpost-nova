# scripts/characters/player.gd
extends CharacterBody2D

const SPEED = 80.0

@onready var interaction_zone: Area2D = $InteractionZone

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
