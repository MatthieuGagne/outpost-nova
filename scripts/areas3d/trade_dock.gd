extends Node3D

## The first live 3D room (issue #129 R7). Sable's presence is gated by the
## sable_arrived flag, read room-side. Exits report through ExitDoor.triggered.

@onready var sable: Npc3D = $Sable

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_refresh_sable()
	GameState.flag_changed.connect(_on_flag_changed)
	for door in [$CantinaExit, $SecurityPostExit]:
		door.triggered.connect(_on_exit_triggered)

func _on_flag_changed(flag_id: String, _value: bool) -> void:
	if flag_id == "sable_arrived":
		_refresh_sable()

func _refresh_sable() -> void:
	sable.set_present(GameState.get_flag("sable_arrived"))

func _on_exit_triggered(destination_id: String) -> void:
	get_tree().get_root().get_node("Main").go_to_area(destination_id)
