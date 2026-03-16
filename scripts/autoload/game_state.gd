# scripts/autoload/game_state.gd
extends Node

signal resource_changed(resource_id: String, new_amount: int)
signal flag_changed(flag_id: String, value: bool)

var _resources: Dictionary = {}
var _flags: Dictionary = {}

func reset() -> void:
	_resources = { "rations": 0, "parts": 0, "energy_cells": 0 }
	_flags = {}

func _ready() -> void:
	reset()

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
