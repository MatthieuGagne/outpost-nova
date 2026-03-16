# scripts/derelict/survivor.gd
extends CharacterBody2D

@export var survivor_id: String = "survivor_01"
@export var survivor_name: String = "Stranger"
@export var is_story_character: bool = false

func _ready() -> void:
	add_to_group("interactable")

func interact() -> void:
	var tree = _get_dialogue_tree()
	DialogueManager.conversation_ended.connect(_on_conversation_ended, CONNECT_ONE_SHOT)
	DialogueManager.start_conversation(tree)
	var dialogue_box = get_tree().get_root().find_child("DialogueBox", true, false)
	if dialogue_box:
		dialogue_box.show_current_node()

func _get_dialogue_tree() -> Dictionary:
	return {
		"start": {
			"speaker": survivor_name,
			"text": "I've been down here since the seal. I thought everyone forgot about this place.",
			"choices": [
				{ "text": "Come with me. There's room on the station.", "register": "warm", "next": "come_yes" },
				{ "text": "I can't guarantee your safety up there.", "register": "logical", "next": "come_cautious" },
				{ "text": "What do you know about what happened here?", "register": "curious", "next": "what_happened" },
			]
		},
		"come_yes": {
			"speaker": survivor_name,
			"text": "...Alright. Lead the way.",
			"choices": []
		},
		"come_cautious": {
			"speaker": survivor_name,
			"text": "Nowhere's safe. But up beats down.",
			"choices": []
		},
		"what_happened": {
			"speaker": survivor_name,
			"text": "Something was left running. Something that wasn't supposed to survive the purge.",
			"choices": []
		}
	}

func _on_conversation_ended() -> void:
	GameState.set_flag("survivor_%s_recruited" % survivor_id, true)
	GameState.record_npc_choice("station", "recruited_%s" % survivor_id)
	DayManager.complete_beat("survivor_found")
	queue_free()
