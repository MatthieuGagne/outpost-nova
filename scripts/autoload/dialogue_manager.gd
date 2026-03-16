# scripts/autoload/dialogue_manager.gd
extends Node

signal story_beat_triggered(beat_id: String)
signal conversation_ended()

# Inner voice registers per background
const INNER_VOICE_REGISTERS = {
	"engineer": ["logical", "curious", "sharp"],
	"medic": ["warm", "hopeful", "empathetic"],
	"drifter": ["detached", "cynical", "instinct"]
}

var register_history: Dictionary = {}  # { register: count }
var _current_tree: Dictionary = {}
var _current_node_id: String = ""

func reset() -> void:
	register_history = {}
	_current_tree = {}
	_current_node_id = ""

func _ready() -> void:
	reset()

func start_conversation(tree: Dictionary) -> void:
	_current_tree = tree
	_current_node_id = "start"
	_check_for_beat()

func get_current_node() -> Dictionary:
	return _current_tree.get(_current_node_id, {})

func is_conversation_over() -> bool:
	var node = get_current_node()
	return node.is_empty() or node.get("choices", []).is_empty()

func make_choice(choice_index: int) -> void:
	var node = get_current_node()
	var choices = node.get("choices", [])
	if choice_index >= choices.size():
		return
	var choice = choices[choice_index]
	var register = choice.get("register", "")
	if register != "":
		register_history[register] = register_history.get(register, 0) + 1
	_current_node_id = choice.get("next", "")
	if _current_node_id == "":
		conversation_ended.emit()
		return
	_check_for_beat()
	if is_conversation_over():
		conversation_ended.emit()

func _check_for_beat() -> void:
	var node = get_current_node()
	var beat_id = node.get("beat", "")
	if beat_id != "":
		DayManager.complete_beat(beat_id)
		story_beat_triggered.emit(beat_id)

# Returns a Dictionary (used as set) of choice indices that match
# the player's background inner voice registers.
func get_inner_voice_flags() -> Dictionary:
	var result = {}
	var bg = GameState.player_background
	var voice_registers = INNER_VOICE_REGISTERS.get(bg, [])
	var node = get_current_node()
	var choices = node.get("choices", [])
	for i in range(choices.size()):
		if voice_registers.has(choices[i].get("register", "")):
			result[i] = true
	return result
