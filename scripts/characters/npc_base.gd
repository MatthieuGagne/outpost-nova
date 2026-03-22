# scripts/characters/npc_base.gd
extends CharacterBody2D

@export var npc_id: String = "unknown"
@export var display_name: String = "NPC"
@export var wander_bounds: Rect2 = Rect2(-50, -50, 100, 100)  # Local space

const WANDER_SPEED = 30.0

@onready var wander_timer: Timer = $WanderTimer
@onready var interaction_area: Area2D = $InteractionArea

var _wander_target: Vector2 = Vector2.ZERO
var _is_talking: bool = false

func _ready() -> void:
	add_to_group("npcs")
	add_to_group("interactable")
	wander_timer.timeout.connect(_pick_wander_target)
	wander_timer.wait_time = randf_range(2.0, 5.0)
	wander_timer.start()
	_pick_wander_target()

func _physics_process(_delta: float) -> void:
	if _is_talking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var diff = _wander_target - position
	if diff.length() > 4.0:
		velocity = diff.normalized() * WANDER_SPEED
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func _pick_wander_target() -> void:
	_wander_target = position + Vector2(
		randf_range(wander_bounds.position.x, wander_bounds.end.x),
		randf_range(wander_bounds.position.y, wander_bounds.end.y)
	)
	wander_timer.wait_time = randf_range(2.0, 5.0)
	wander_timer.start()

func interact() -> void:
	_is_talking = true
	var tree = get_dialogue_tree()
	DialogueManager.conversation_ended.connect(_on_conversation_ended, CONNECT_ONE_SHOT)
	DialogueManager.start_conversation(tree)
	get_tree().get_first_node_in_group("dialogue_box").show_current_node()

func _on_conversation_ended() -> void:
	_is_talking = false

func get_dialogue_tree() -> Dictionary:
	return {
		"start": {
			"speaker": display_name,
			"text": "...",
			"choices": []
		}
	}
