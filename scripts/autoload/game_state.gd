# scripts/autoload/game_state.gd
extends Node

signal resource_changed(resource_id: String, new_amount: int)
signal flag_changed(flag_id: String, value: bool)

var player_name: String = ""
var player_background: String = ""  # "engineer", "medic", "drifter"
var player_appearance: int = 0

var _resources: Dictionary = {}
var _flags: Dictionary = {}
var _npc_flags: Dictionary = {}  # { npc_id: [flag1, flag2, ...] }

const BACKGROUND_BONUSES = {
	"engineer": { "parts": 3 },
	"medic": { "rations": 3 },
	"drifter": { "energy_cells": 3 }
}

func reset() -> void:
	player_name = ""
	player_background = ""
	player_appearance = 0
	_resources = { "rations": 0, "parts": 0, "energy_cells": 0, "scrap": 0 }
	_flags = {}
	_npc_flags = {}

func _ready() -> void:
	reset()

func set_player_identity(name: String, background: String, appearance: int) -> void:
	player_name = name
	player_background = background
	player_appearance = appearance

func apply_background_bonus(background: String) -> void:
	if not BACKGROUND_BONUSES.has(background):
		return
	for resource_id in BACKGROUND_BONUSES[background]:
		add_resource(resource_id, BACKGROUND_BONUSES[background][resource_id])

func get_resource(id: String) -> int:
	return _resources.get(id, 0)

func add_resource(id: String, amount: int) -> void:
	_resources[id] = _resources.get(id, 0) + amount
	resource_changed.emit(id, _resources[id])

func spend_resource(id: String, amount: int) -> bool:
	if _resources.get(id, 0) < amount:
		return false
	_resources[id] -= amount
	resource_changed.emit(id, _resources[id])
	return true

func get_flag(id: String) -> bool:
	return _flags.get(id, false)

func set_flag(id: String, value: bool) -> void:
	_flags[id] = value
	flag_changed.emit(id, value)

func record_npc_choice(npc_id: String, flag: String) -> void:
	if not _npc_flags.has(npc_id):
		_npc_flags[npc_id] = []
	if not _npc_flags[npc_id].has(flag):
		_npc_flags[npc_id].append(flag)

func has_npc_flag(npc_id: String, flag: String) -> bool:
	return _npc_flags.get(npc_id, []).has(flag)
