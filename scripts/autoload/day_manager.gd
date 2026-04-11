# scripts/autoload/day_manager.gd
extends Node

signal day_ended(day_number: int)
signal beat_completed(beat_id: String)
signal all_beats_done()

var current_day: int = 1
var _completed_beats: Array = []
var _todays_beats: Array = []
var _all_beats_emitted: bool = false

# Arc beat definitions: array of { id, required, npc, flag_to_set }
# Each entry in ARC_BEATS is the beat list for that day (1-indexed).
const ARC_BEATS: Dictionary = {
	1: [
		{ "id": "meet_maris", "required": true, "npc": "maris", "flag_to_set": "met_maris" },
		{ "id": "check_engineering", "required": true, "npc": "dex", "flag_to_set": "met_dex" },
		{ "id": "quen_arrives", "required": false, "npc": "quen", "flag_to_set": "met_quen" },
	],
	2: [
		{ "id": "power_flicker", "required": false, "npc": "dex", "flag_to_set": "power_flicker_noticed" },
	],
	3: [
		{ "id": "maris_food_trouble", "required": true, "npc": "maris", "flag_to_set": "maris_confided" },
		{ "id": "sable_offer", "required": false, "npc": "sable", "flag_to_set": "sable_offered_help" },
	],
	4: [
		{ "id": "derelict_door", "required": true, "npc": "dex", "flag_to_set": "derelict_mentioned" },
		{ "id": "maris_asks_favour", "required": true, "npc": "maris", "flag_to_set": "maris_favour_asked" },
	],
	5: [
		{ "id": "first_derelict_run", "required": true, "npc": "", "flag_to_set": "derelict_entered" },
		{ "id": "sable_past", "required": false, "npc": "sable", "flag_to_set": "sable_past_revealed" },
	],
	6: [
		{ "id": "survivor_found", "required": true, "npc": "", "flag_to_set": "first_survivor_found" },
		{ "id": "dex_secret", "required": true, "npc": "dex", "flag_to_set": "dex_secret_known" },
	],
	7: [
		{ "id": "the_choice", "required": true, "npc": "", "flag_to_set": "final_choice_made" },
	],
}

func reset() -> void:
	current_day = 1
	_completed_beats = []
	_todays_beats = ARC_BEATS.get(1, []).duplicate(true)
	_all_beats_emitted = false

func _ready() -> void:
	reset()

func _override_beats_for_test(beats: Array) -> void:
	_todays_beats = beats.duplicate(true)
	_completed_beats = []
	_all_beats_emitted = false

func get_todays_beats() -> Array:
	return _todays_beats

func complete_beat(beat_id: String) -> void:
	if not _completed_beats.has(beat_id):
		_completed_beats.append(beat_id)
		beat_completed.emit(beat_id)
		for beat in _todays_beats:
			if beat["id"] == beat_id and beat.get("flag_to_set", "") != "":
				GameState.set_flag(beat["flag_to_set"], true)
		if is_day_complete() and not _all_beats_emitted:
			_all_beats_emitted = true
			all_beats_done.emit()

func is_beat_complete(beat_id: String) -> bool:
	return _completed_beats.has(beat_id)

func is_day_complete() -> bool:
	for beat in _todays_beats:
		if beat.get("required", false) and not _completed_beats.has(beat["id"]):
			return false
	return true

func advance_day() -> void:
	var finished_day = current_day
	current_day += 1
	_completed_beats = []
	_todays_beats = ARC_BEATS.get(current_day, []).duplicate(true)
	_all_beats_emitted = false
	day_ended.emit(finished_day)
