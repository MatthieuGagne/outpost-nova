class_name Workbench3D
extends Area3D

## The 3D workbench (issue #131 R3).
##
## A direct port of the deleted scripts/workbench.gd: same interactable group, same
## one-line forward to Main.open_crafting(). The existing 2D crafting_panel is a
## CanvasLayer sibling of the SubViewport, so it opens over the 3D view unchanged and
## CraftingSystem is not touched at all.
##
## Area3D root, not StaticBody3D: Plot3D established that an interactable's root must
## land in Player3D's get_overlapping_areas() scan to be reachable. The 2D workbench was
## a solid StaticBody2D; the 3D one is walk-through, exactly like Plot3D. If that reads
## wrong in play, the fix is one entry in the room's TileCollision.blocked, not a
## change here.
##
## get_node_or_null, unlike the 2D original's get_node: headless tests and the editor
## have no Main, and interact() must degrade quietly rather than crash.


func _ready() -> void:
	add_to_group(InteractScan.INTERACTABLE_GROUP)


func interact() -> void:
	var main := get_tree().get_root().get_node_or_null("Main")
	if main == null:
		return
	main.open_crafting()
