# scripts/derelict/run.gd
extends Node2D

var _room_sequence: Array = []
var _current_room_index: int = 0
var _current_room: Node = null
var _gathered_loot: Dictionary = {}

@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	_room_sequence = RoomGenerator.generate_sequence()
	_load_room(0)

func _load_room(index: int) -> void:
	if _current_room:
		_current_room.queue_free()
	var scene = load(_room_sequence[index])
	_current_room = scene.instantiate()
	add_child(_current_room)
	# Place player at room entry point
	var entry = _current_room.get_node_or_null("EntryPoint")
	if entry:
		player.position = entry.position
	# Connect exit door
	var exit_door = _current_room.get_node_or_null("ExitDoor")
	if exit_door:
		exit_door.body_entered.connect(func(body):
			if body.is_in_group("player"):
				_on_exit_reached()
		)
	# Spawn enemies
	_spawn_enemies()

func _spawn_enemies() -> void:
	var spawns = _current_room.get_children().filter(func(n): return n.name.begins_with("EnemySpawn"))
	for spawn in spawns:
		var drone = load("res://scenes/derelict/enemies/drone.tscn").instantiate()
		drone.position = spawn.position
		_current_room.add_child(drone)

func _on_exit_reached() -> void:
	_current_room_index += 1
	if _current_room_index >= _room_sequence.size():
		_exit_run(true)
	else:
		_load_room(_current_room_index)

func add_loot(resource_id: String, amount: int) -> void:
	_gathered_loot[resource_id] = _gathered_loot.get(resource_id, 0) + amount

func _exit_run(survived: bool) -> void:
	if survived:
		for resource_id in _gathered_loot:
			GameState.add_resource(resource_id, _gathered_loot[resource_id])
	ClockManager.log_action("Completed derelict run")
	GameState.set_flag("first_derelict_run", true)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
