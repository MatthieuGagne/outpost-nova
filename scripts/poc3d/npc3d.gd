@tool
class_name Npc3D
extends Node3D

## A static sprite character sharing the player's sprite setup.
##
## PRD 2 (#102) R9. No movement, no pathfinding, no AI — those are explicitly out of
## scope. The point of this node is to prove the same sprite pipeline works for a second
## character and to give the player something to walk in front of and behind.

const DEFAULT_FACING := "down"

## Which way the NPC is turned. Must be one of SpriteFacing.FACINGS.
@export var facing := DEFAULT_FACING:
	set(value):
		facing = value
		_apply_facing()

@onready var sprite: PixelSprite3D = $PixelSprite3D


func _ready() -> void:
	_apply_facing()


func _apply_facing() -> void:
	if sprite == null:
		return
	var resolved := facing if SpriteFacing.is_valid(facing) else DEFAULT_FACING
	sprite.play("idle_" + resolved)
