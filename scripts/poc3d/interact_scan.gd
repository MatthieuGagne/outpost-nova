# scripts/poc3d/interact_scan.gd
class_name InteractScan
extends RefCounted

## The interaction-scan rule, lifted out of any node so it can be asserted headlessly.
##
## PRD 3 (#103) R4/AC9. scripts/characters/player.gd._try_interact() is the 2D original:
## bodies before areas, first match wins, a candidate qualifies on group membership plus
## visibility. This adds one stricter filter — has_method("interact") — so a malformed
## prop is skipped instead of erroring. That differs from 2D only where 2D crashes.
##
## Not an autoload and not a node: a class_name is globally reachable and costs nothing.

## The group both the console and the NPC's interact target join. Named here so no
## call site types the string.
const INTERACTABLE_GROUP := "interactable"

## The duck-typed method the contract is built on.
const INTERACT_METHOD := "interact"


## The node the player would interact with, or null when nothing in reach qualifies.
## `bodies` is scanned before `areas`, matching the 2D contract exactly.
static func first_interactable(bodies: Array, areas: Array) -> Node:
	var found := _first_in(bodies)
	if found != null:
		return found
	return _first_in(areas)


## Whether one overlap candidate qualifies. Public so a prop can self-check in a test.
static func is_interactable(candidate: Variant) -> bool:
	if not (candidate is Node):
		return false
	var node: Node = candidate
	if not node.is_in_group(INTERACTABLE_GROUP):
		return false
	if not node.has_method(INTERACT_METHOD):
		return false
	# `visible` lives on Node3D/CanvasItem, not on Node. A qualifying prop that is
	# neither cannot be hidden, so it counts as visible.
	if node is Node3D:
		return (node as Node3D).visible
	if node is CanvasItem:
		return (node as CanvasItem).visible
	return true


static func _first_in(candidates: Array) -> Node:
	for candidate in candidates:
		if is_interactable(candidate):
			return candidate
	return null
