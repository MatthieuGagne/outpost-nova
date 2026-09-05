# scripts/poc3d/exit_door.gd
class_name ExitDoor
extends Area3D

## The doorway trigger. PRD 3 (#103) R8/AC4.
##
## It REPORTS and nothing more — real area-to-area transitions are PRD 6. The collision
## ring stays solid across the doorway, so the player is stopped at the threshold and this
## zone covers the floor tiles immediately in front of the opening.
##
## The door does not reach for the HUD itself: the HUD lives outside the SubViewport, in
## poc_entry.tscn, and a NodePath across that boundary would hard-wire the room to its
## host. poc_entry.gd connects `triggered` to HUD.show_message() at the composition root.

## Group the player joins in Player3D._ready(). Anything else entering is ignored.
const PLAYER_GROUP := "player"

## Console line format. The HUD message uses the same text.
const MESSAGE_FORMAT := "Exit door: %s"

## Fired once per entry. `destination_id` is passed through so PRD 6 has the hook already
## named when real transitions arrive.
signal triggered(destination_id: String)

## Where this door would lead. Nothing consumes it yet — that is the point of R8.
@export var destination_id := "unwired"

## The latch that makes AC4's "exactly once per entry" true. Physics can re-emit
## body_entered while the player is pressed against the wall inside the zone.
var _occupied := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if _occupied or not body.is_in_group(PLAYER_GROUP):
		return
	_occupied = true
	print(MESSAGE_FORMAT % destination_id)
	triggered.emit(destination_id)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group(PLAYER_GROUP):
		_occupied = false
