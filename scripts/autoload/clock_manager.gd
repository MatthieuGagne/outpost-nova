# scripts/autoload/clock_manager.gd
extends Node

signal time_advanced(new_time: int)
signal day_ended(day_number: int)

const START_TIME: int = 360   # 06:00
const END_TIME: int = 960     # 22:00
const SECS_PER_MINUTE: float = 2.0

var current_time: int = START_TIME
var current_day: int = 1
var _actions_log: Array[String] = []
var _tick_accum: float = 0.0

func _ready() -> void:
	reset()

func _process(delta: float) -> void:
	_tick_accum += delta
	if _tick_accum >= SECS_PER_MINUTE:
		_tick_accum -= SECS_PER_MINUTE
		current_time += 1
		time_advanced.emit(current_time)
		if current_time >= END_TIME:
			day_ended.emit(current_day)

func reset() -> void:
	current_time = START_TIME
	current_day = 1
	_actions_log.clear()
	_tick_accum = 0.0

func commit_action(cost_minutes: int) -> void:
	current_time += cost_minutes
	time_advanced.emit(current_time)
	if current_time >= END_TIME:
		day_ended.emit(current_day)

func can_act(cost_minutes: int) -> bool:
	return current_time + cost_minutes <= END_TIME

func get_time_string() -> String:
	var hours: int = current_time / 60
	var minutes: int = current_time % 60
	return "%02d:%02d" % [hours, minutes]

func log_action(message: String) -> void:
	_actions_log.append(message)

func end_day_manually() -> void:
	day_ended.emit(current_day)

func advance_day() -> void:
	current_day += 1
	current_time = START_TIME
	_actions_log.clear()
	_tick_accum = 0.0
	time_advanced.emit(current_time)
