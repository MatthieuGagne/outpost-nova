@tool
class_name Npc3D
extends CharacterBody3D

## Production 3D NPC (issue #129 R6). Wander on XZ, real Yarn dialogue via
## DialogueRunner, facing derived from world velocity.

const DEFAULT_FACING := "down"

## Matches the 2D npc_base WANDER_SPEED (30 px/s) scaled to world units.
const WANDER_SPEED_PIXELS := 30.0
const WANDER_SPEED := WANDER_SPEED_PIXELS / WorldScale.PIXELS_PER_UNIT

const BODY_RADIUS_PIXELS := 5.0
const BODY_HEIGHT_PIXELS := 16.0
const BODY_RADIUS := BODY_RADIUS_PIXELS / WorldScale.PIXELS_PER_UNIT
const BODY_HEIGHT := BODY_HEIGHT_PIXELS / WorldScale.PIXELS_PER_UNIT

const DIALOGUE_RUNNER_GROUP := "dialogue_runner"
const DIALOGUE_BOX_GROUP := "dialogue_box"
const ARRIVE_RADIUS := 0.25
const CONVERSATION_COST_MINUTES := 30

@export var facing := DEFAULT_FACING:
	set(value):
		facing = value
		_apply_facing()

## Yarn node title to start on interact. Empty means silent.
@export var dialogue_node := ""

## Half-extents (XZ) the NPC wanders within, around its spawn position.
@export var wander_half_extents := Vector2(3.0, 2.0)

@onready var sprite: PixelSprite3D = $PixelSprite3D
@onready var _shape: CollisionShape3D = $CollisionShape3D

var _wander_target := Vector3.ZERO
var _spawn_position := Vector3.ZERO
var _is_talking := false
var _facing := DEFAULT_FACING


func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_facing()
		return
	_spawn_position = position
	add_to_group("npcs")
	_apply_body_shape()
	_apply_facing()
	_pick_wander_target()


func _physics_process(_delta: float) -> void:
	if _is_talking:
		velocity = Vector3.ZERO
		move_and_slide()
		sprite.play("idle_" + _facing)
		return
	var to_target := _wander_target - position
	to_target.y = 0.0
	if to_target.length() > ARRIVE_RADIUS:
		var direction := to_target.normalized()
		velocity = Vector3(direction.x, 0.0, direction.z) * WANDER_SPEED
		_facing = SpriteFacing.from_world(velocity, WorldScale.camera_yaw_degrees(get_viewport()))
		sprite.play("walk_" + _facing)
	else:
		velocity = Vector3.ZERO
		sprite.play("idle_" + _facing)
		_pick_wander_target()
	move_and_slide()


func _pick_wander_target() -> void:
	var offset := Vector2(
		randf_range(-wander_half_extents.x, wander_half_extents.x),
		randf_range(-wander_half_extents.y, wander_half_extents.y))
	_wander_target = _spawn_position + Vector3(offset.x, 0.0, offset.y)


func interact() -> void:
	if _is_talking or dialogue_node.is_empty():
		return
	var runners := get_tree().get_nodes_in_group(DIALOGUE_RUNNER_GROUP)
	if runners.is_empty():
		push_error("Npc3D: no node in group '%s'" % DIALOGUE_RUNNER_GROUP)
		return
	var boxes := get_tree().get_nodes_in_group(DIALOGUE_BOX_GROUP)
	if not boxes.is_empty():
		var box := boxes[0]
		if not box.conversation_ended.is_connected(_on_conversation_ended):
			box.conversation_ended.connect(_on_conversation_ended, CONNECT_ONE_SHOT)
	_is_talking = true
	runners[0].StartDialogueForget(dialogue_node)


func _on_conversation_ended() -> void:
	_is_talking = false
	ClockManager.commit_action(CONVERSATION_COST_MINUTES)


## Present/absent toggle. Node3D.visible only affects rendering — the child
## InteractTarget's own `visible` (which InteractScan gates on) is independent,
## so both must be set together to fully hide the NPC from interaction.
func set_present(present: bool) -> void:
	visible = present
	var target := get_node_or_null("InteractTarget") as Node3D
	if target != null:
		target.visible = present


func _apply_body_shape() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	_shape.shape = capsule
	_shape.position = Vector3(0.0, BODY_HEIGHT * 0.5, 0.0)


func _apply_facing() -> void:
	if sprite == null:
		return
	var resolved := facing if SpriteFacing.is_valid(facing) else DEFAULT_FACING
	_facing = resolved
	sprite.play("idle_" + resolved)
