@tool
class_name SpriteFacing
extends RefCounted

## Pure, node-free facing and movement maths for sprite characters in the 3D POC.
##
## PRD 2 (#102) R6/R7/R8. Split into two functions on purpose:
##   - from_input()     resolves the animation suffix in CAMERA space
##   - input_to_world() rotates the same input into WORLD space by the camera yaw
##
## Because the input vector is already camera-relative, facing needs no rotation at
## all — only movement does. Folding the two together is the mistake the PRD warns
## about: it makes "up" show the up sprite while sliding diagonally across screen.

## The four animation suffixes. Animation names are built as "idle_" / "walk_" + suffix,
## matching data/sprites/player_frames.tres and data/sprites/npc_frames.tres.
const FACINGS := ["up", "down", "left", "right"]

## Returned when there is no input; the caller keeps whatever it was facing before.
const NO_FACING := ""


static func is_valid(facing: String) -> bool:
	return FACINGS.has(facing)


## Resolves a camera-space input vector to one of FACINGS.
## +x is screen-right, +y is screen-down. Ties favour the horizontal axis, matching
## the 2D player so the two control schemes read identically.
static func from_input(input: Vector2) -> String:
	if input.is_zero_approx():
		return NO_FACING
	if absf(input.x) >= absf(input.y):
		return "right" if input.x > 0.0 else "left"
	return "down" if input.y > 0.0 else "up"


## Rotates a camera-space input vector into a world-space XZ direction.
##
## A Camera3D looks down its local -Z. Under a yaw of theta that forward direction is
## (-sin theta, 0, -cos theta) and its right is (cos theta, 0, -sin theta). Screen-up is
## input.y == -1, hence the negation on the forward term.
static func input_to_world(input: Vector2, yaw_degrees: float) -> Vector3:
	if input.is_zero_approx():
		return Vector3.ZERO
	var yaw := deg_to_rad(yaw_degrees)
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	return (right * input.x + forward * -input.y).normalized()


## Inverts input_to_world: rotates a world-space XZ velocity back into camera
## space, then resolves facing. For NPCs, whose velocity is already world-space.
static func from_world(world: Vector3, yaw_degrees: float) -> String:
	if world.length_squared() < 0.0001:
		return NO_FACING
	var yaw := deg_to_rad(yaw_degrees)
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	return from_input(Vector2(world.dot(right), -world.dot(forward)))
