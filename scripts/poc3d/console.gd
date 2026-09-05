# scripts/poc3d/console.gd
class_name PocConsole
extends Area3D

## The room's interactable console. PRD 3 (#103) R5.
##
## An Area3D rather than a body: the player's InteractionZone scans overlapping areas as
## well as bodies, and the console's *solidity* is authored separately as a blocked tile
## in TileCollision. Keeping the two apart is R3 — PRD 4 swaps the visual mesh and must
## not be able to disturb either the collision or the interaction volume.

## Which resource the console dispenses. All four GameState ids appear on the HUD, so any
## would prove AC2; `parts` is the one this room grants.
const RESOURCE_ID := "parts"

## How much per interact. Named so no call site carries a bare literal.
const CONSOLE_YIELD := 1

## Emitted after the grant, so a room or a test can observe the interaction without
## reaching into GameState. Nothing in this PRD consumes it; it exists for the test.
signal dispensed(resource_id: String, amount: int)


func _ready() -> void:
	add_to_group(InteractScan.INTERACTABLE_GROUP)


## Duck-typed entry point. The player never knows this type — see InteractScan.
func interact() -> void:
	GameState.add_resource(RESOURCE_ID, CONSOLE_YIELD)
	dispensed.emit(RESOURCE_ID, CONSOLE_YIELD)
