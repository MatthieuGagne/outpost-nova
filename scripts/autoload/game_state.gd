# scripts/autoload/game_state.gd
extends Node

signal resource_changed(resource_id: String, new_amount: int)
signal flag_changed(flag_id: String, value: bool)
signal pair_state_changed(pair_id: String, new_state: int)

enum PairState { TENSION = 0, NEUTRAL = 1, COLLEGIAL = 2, BONDED = 3 }

const _PAIR_STATE_LABELS: Dictionary = {
	PairState.TENSION:   "Tension",
	PairState.NEUTRAL:   "Neutral",
	PairState.COLLEGIAL: "Collegial",
	PairState.BONDED:    "Bonded",
}

const DEFAULT_PAIR_STATES: Dictionary = {
	"maris_velreth": PairState.COLLEGIAL,
	"dex_velreth":   PairState.COLLEGIAL,
}

var _pair_states: Dictionary = {}

var player_name: String = ""
var player_background: String = ""  # "engineer", "medic", "drifter"
var player_appearance: int = 0

var _resources: Dictionary = {}
var _flags: Dictionary = {}
var _npc_flags: Dictionary = {}  # { npc_id: [flag1, flag2, ...] }
var _register_history: Dictionary = {}

const BACKGROUND_BONUSES = {
	"engineer": { "parts": 3 },
	"medic": { "rations": 3 },
	"drifter": { "energy_cells": 3 }
}

const ARRIVAL_KIT: Dictionary = {
	"rations": 1,
	"parts": 1,
	"energy_cells": 1,
}

func reset() -> void:
	player_name = ""
	player_background = ""
	player_appearance = 0
	_resources = { "rations": 0, "parts": 0, "energy_cells": 0, "scrap": 0 }
	_flags = {}
	_npc_flags = {}
	_register_history = {}
	_pair_states = DEFAULT_PAIR_STATES.duplicate()

func _ready() -> void:
	reset()

func set_player_identity(name: String, background: String, appearance: int) -> void:
	player_name = name
	player_background = background
	player_appearance = appearance

func apply_background_bonus(background: String) -> void:
	for resource_id in ARRIVAL_KIT:
		add_resource(resource_id, ARRIVAL_KIT[resource_id])
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

func record_register(register: String) -> void:
	_register_history[register] = _register_history.get(register, 0) + 1

func get_register_history() -> Dictionary:
	return _register_history.duplicate()

func set_flag_on(flag_id: String) -> void:
	set_flag(flag_id, true)

func _normalize_pair_id(pair_id: String) -> String:
	var parts := pair_id.split("_")
	parts.sort()
	return "_".join(parts)

func get_pair_state(pair_id: String) -> PairState:
	return _pair_states.get(_normalize_pair_id(pair_id), PairState.NEUTRAL)

func set_pair_state(pair_id: String, state: PairState) -> void:
	var normalized := _normalize_pair_id(pair_id)
	_pair_states[normalized] = state
	pair_state_changed.emit(normalized, state)

func get_pairs_for_npc(npc_id: String) -> Dictionary:
	var result: Dictionary = {}
	for pair_id in _pair_states:
		if pair_id.split("_").has(npc_id):
			result[pair_id] = _pair_states[pair_id]
	return result

func get_pair_state_label(state: PairState) -> String:
	return _PAIR_STATE_LABELS.get(state, "Unknown")
