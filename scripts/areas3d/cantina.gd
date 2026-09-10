extends Node3D

## The 3D cantina (issue #130). Mirrors scripts/areas3d/trade_dock.gd: the room owns its
## door wiring and reaches /root/Main directly to request the area change.

const EXIT_NODES := ["WorkshopExit", "QuartersExit", "SecurityPostExit", "TradeDockExit"]


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for exit_name in EXIT_NODES:
		var door := get_node_or_null(exit_name) as ExitDoor
		if door == null:
			push_error("cantina: missing exit '%s'" % exit_name)
			continue
		door.triggered.connect(_on_exit_triggered)


func _on_exit_triggered(destination_id: String) -> void:
	get_tree().get_root().get_node("Main").go_to_area(destination_id)
