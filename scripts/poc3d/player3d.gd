# scripts/poc3d/player3d.gd
class_name Player3D
extends CharacterBody3D

## The POC player: a sprite in 3D space, moved camera-relative on the XZ plane.
##
## PRD 2 (#102) R5/R6/R7. All of the interesting maths lives in SpriteFacing so it can be
## tested headlessly; this script is the thin node-side wiring around it.
##
## The camera yaw is read from the Camera3D actually rendering the player — see
## WorldScale.camera_yaw_degrees() — so a room may author its own angle via
## RoomCamera.use_contract_angle = false without desyncing the controls (#114).

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
	velocity = SpriteFacing.input_to_world(
		input, WorldScale.camera_yaw_degrees(get_viewport())) * SPEED
	move_and_slide()
	_update_animation(input)


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
