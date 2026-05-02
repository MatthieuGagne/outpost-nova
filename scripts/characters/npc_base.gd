# scripts/characters/npc_base.gd
extends CharacterBody2D

@export var npc_id: String = "unknown"
@export var display_name: String = "NPC"
@export var wander_bounds: Rect2 = Rect2(-50, -50, 100, 100)

const WANDER_SPEED = 30.0

@onready var wander_timer: Timer = $WanderTimer
@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _wander_target: Vector2 = Vector2.ZERO
var _is_talking: bool = false
var _facing: String = "down"

static var _commands_registered: bool = false

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
		sprite.play("idle_" + _facing)
		return
	var diff = _wander_target - position
	if diff.length() > 4.0:
		velocity = diff.normalized() * WANDER_SPEED
		_facing = _get_facing(velocity)
		sprite.play("walk_" + _facing)
	else:
		velocity = Vector2.ZERO
		sprite.play("idle_" + _facing)
	move_and_slide()

func _get_facing(direction: Vector2) -> String:
	if abs(direction.x) >= abs(direction.y):
		return "right" if direction.x > 0 else "left"
	return "down" if direction.y > 0 else "up"

func _pick_wander_target() -> void:
	_wander_target = position + Vector2(
		randf_range(wander_bounds.position.x, wander_bounds.end.x),
		randf_range(wander_bounds.position.y, wander_bounds.end.y)
	)
	wander_timer.wait_time = randf_range(2.0, 5.0)
	wander_timer.start()

func interact() -> void:
	if _is_talking:
		return
	var runners := get_tree().get_nodes_in_group("dialogue_runner")
	if runners.is_empty():
		push_error("npc_base: no node in group 'dialogue_runner'")
		return
	var runner := runners[0]
	if not _commands_registered:
		runner.AddCommandHandlerCallable("register", Callable(GameState, "record_register"))
		runner.AddCommandHandlerCallable("log_action", Callable(ClockManager, "log_action"))
		runner.AddCommandHandlerCallable("flag", Callable(GameState, "set_flag_on"))
		_commands_registered = true
	var boxes := get_tree().get_nodes_in_group("dialogue_box")
	if not boxes.is_empty():
		var box := boxes[0]
		if not box.conversation_ended.is_connected(_on_conversation_ended):
			box.conversation_ended.connect(_on_conversation_ended)
	_is_talking = true
	runner.StartDialogueForget(get_dialogue_node())

func _on_conversation_ended() -> void:
	_is_talking = false
	ClockManager.commit_action(30)

## Override in subclass to return the Yarn node title for this NPC.
func get_dialogue_node() -> String:
	return display_name
