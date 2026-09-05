# scripts/poc3d/interact_target.gd
class_name InteractTarget
extends Area3D

## An interaction volume that forwards to the node that owns the behaviour.
##
## PRD 3 (#103) R7. Npc3D is a plain Node3D — tests/test_poc3d_npc3d.gd asserts it is not
## a physics body — so it is invisible to the player's Area3D scan. Rather than re-typing
## Npc3D's root and mixing "is a character" with "is an interaction volume", the volume is
## a child that hands the call back up. That gives the NPC the same interactable shape as
## the console: one contract, not two.


func _ready() -> void:
	add_to_group(InteractScan.INTERACTABLE_GROUP)


func interact() -> void:
	var owner_node := get_parent()
	if owner_node == null or not owner_node.has_method(InteractScan.INTERACT_METHOD):
		return
	owner_node.interact()
