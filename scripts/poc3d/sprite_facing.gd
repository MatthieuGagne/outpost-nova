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
