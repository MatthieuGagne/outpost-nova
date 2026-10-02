# scripts/areas3d/med_bay.gd
extends Node3D

## The 3D med bay (issue #133). Mirrors scripts/areas3d/security_post.gd: the room owns
## its door wiring and reaches /root/Main directly to request the area change.
##
## Velreth is hosted in-scene as an Npc3D and is not flag-gated, so this is the plain
## security_post.gd shape — not trade_dock.gd's, which gates Sable behind sable_arrived.

const EXIT_NODES := ["SecurityPostExit"]


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for exit_name in EXIT_NODES:
		var door := get_node_or_null(exit_name) as ExitDoor
		if door == null:
			push_error("med_bay: missing exit '%s'" % exit_name)
			continue
		door.triggered.connect(_on_exit_triggered)


func _on_exit_triggered(destination_id: String) -> void:
	get_tree().get_root().get_node("Main").go_to_area(destination_id)
