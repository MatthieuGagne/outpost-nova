@tool
class_name Npc3D
extends Node3D

## A static sprite character sharing the player's sprite setup.
##
## PRD 2 (#102) R9. No movement, no pathfinding, no AI — those are explicitly out of
## scope. The point of this node is to prove the same sprite pipeline works for a second
## character and to give the player something to walk in front of and behind.

const DEFAULT_FACING := "down"

## The group dialogue_box.gd joins in its own _ready(). Looked up rather than hard-pathed:
## the box lives in poc_entry.tscn, outside the SubViewport this NPC renders into, and a
## NodePath across that boundary would couple the room to its host.
const DIALOGUE_BOX_GROUP := "dialogue_box"

## Which way the NPC is turned. Must be one of SpriteFacing.FACINGS.
@export var facing := DEFAULT_FACING:
	set(value):
		facing = value
		_apply_facing()

## Who is speaking. Must match a key of dialogue_box.NPC_PORTRAIT_INDEX to get a portrait
## rather than the fallback. Empty means this NPC is silent.
@export var speaker_name := ""

## The single hardcoded line. R7: no YarnSpinner, no DialogueRunner, no yarnproject —
## what this PRD needs to prove is that the dialogue UI layers over the low-res
## SubViewport legibly, and one line answers that.
@export_multiline var dialogue_line := ""

@onready var sprite: PixelSprite3D = $PixelSprite3D


func _ready() -> void:
	_apply_facing()


func _apply_facing() -> void:
	if sprite == null:
		return
	var resolved := facing if SpriteFacing.is_valid(facing) else DEFAULT_FACING
	sprite.play("idle_" + resolved)


## Duck-typed entry point, reached via the child InteractTarget. Drives the REAL
## dialogue box through its real view protocol — typewriter, portrait, tree pause and
## ui_accept advance all included — so what AC3 is judged on is the production UI.
func interact() -> void:
	if speaker_name.is_empty() or dialogue_line.is_empty():
		return
	var boxes := get_tree().get_nodes_in_group(DIALOGUE_BOX_GROUP)
	if boxes.is_empty():
		push_warning("Npc3D: no node in the '%s' group — is dialogue_box.tscn instanced?"
			% DIALOGUE_BOX_GROUP)
		return
	var box: Node = boxes[0]
	box.on_dialogue_start_async()
	await box.run_line_async(PocDialogueLine.build(speaker_name, dialogue_line))
	box.on_dialogue_complete_async()
