# scripts/poc3d/player3d.gd
class_name Player3D
extends CharacterBody3D

## The POC player: a sprite in 3D space, moved camera-relative on the XZ plane.
##
## PRD 2 (#102) R5/R6/R7. All of the interesting maths lives in SpriteFacing so it can be
## tested headlessly; this script is the thin node-side wiring around it.
##
## Known limitation: _physics_process rotates input by the constant
## WorldScale.CAMERA_YAW_DEGREES, not by the room's actual Camera3D. RoomCamera exposes
## use_contract_angle for a room to author a different angle; a room that opts out today
## would get silently mismatched controls, with no error and no test failure.

## The 2D player moves at 80 px/s. Divided by the world scale that is world units/s, so
## the two builds move at visually identical speeds and neither number is magic.
const SPEED_PIXELS := 80.0
const SPEED := SPEED_PIXELS / WorldScale.PIXELS_PER_UNIT

## A foot-print collider, deliberately narrower than the 16 px sprite so the player does
## not snag on tile corners they can visually clear.
const BODY_RADIUS_PIXELS := 5.0
const BODY_HEIGHT_PIXELS := 16.0
const BODY_RADIUS := BODY_RADIUS_PIXELS / WorldScale.PIXELS_PER_UNIT
const BODY_HEIGHT := BODY_HEIGHT_PIXELS / WorldScale.PIXELS_PER_UNIT

## Reach of the (unwired) interaction zone: 20 px, matching the 2D player's
## InteractionZone circle in scenes/characters/player.tscn. PRD 3 (#103) wires it up.
const INTERACT_RADIUS_PIXELS := 20.0
const INTERACT_RADIUS := INTERACT_RADIUS_PIXELS / WorldScale.PIXELS_PER_UNIT

## Facing the player falls back to when input is released.
const INITIAL_FACING := "down"

@onready var sprite: PixelSprite3D = $PixelSprite3D
@onready var _shape: CollisionShape3D = $CollisionShape3D
@onready var _interact_shape: CollisionShape3D = $InteractionZone/CollisionShape3D

var _facing := INITIAL_FACING


func _ready() -> void:
	add_to_group("player")
	_apply_body_shape()
	sprite.play("idle_" + _facing)


func get_facing() -> String:
	return _facing


func _physics_process(_delta: float) -> void:
	var input := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down"))
	velocity = SpriteFacing.input_to_world(input, _camera_yaw_degrees()) * SPEED
	move_and_slide()
	_update_animation(input)


## Yaw of the Camera3D actually rendering this player, so a room that authors its own
## angle (RoomCamera.use_contract_angle = false) gets controls consistent with what is
## on screen. Read every physics frame rather than cached at _ready: nothing orders the
## camera before the player in a room scene, and a cached null would silently mis-steer.
## global_ so a camera parented under a rotated node still resolves correctly.
##
## Fallback: WorldScale.CAMERA_YAW_DEGREES when the viewport has no camera. Silent on
## purpose — a room with no Camera3D renders a black screen, so a warning would add no
## diagnostic value, and the no-camera path is the normal one under headless tests.
func _camera_yaw_degrees() -> float:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return WorldScale.CAMERA_YAW_DEGREES
	return camera.global_rotation_degrees.y


## Facing is resolved from the RAW input, not from velocity: velocity has already been
## rotated into world space, and re-deriving facing from it would show the wrong sprite.
func _update_animation(input: Vector2) -> void:
	var facing := SpriteFacing.from_input(input)
	if facing == SpriteFacing.NO_FACING:
		sprite.play("idle_" + _facing)
		return
	_facing = facing
	sprite.play("walk_" + _facing)


## Derived at runtime rather than frozen into the .tscn, so PIXELS_PER_UNIT stays the
## single source of truth (AC5).
func _apply_body_shape() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	_shape.shape = capsule
	_shape.position = Vector3(0.0, BODY_HEIGHT * 0.5, 0.0)
	var reach := SphereShape3D.new()
	reach.radius = INTERACT_RADIUS
	_interact_shape.shape = reach
	_interact_shape.position = Vector3(0.0, BODY_HEIGHT * 0.5, 0.0)
