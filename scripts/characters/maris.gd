# scripts/characters/maris.gd
extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
	super()
	npc_id = "maris"
	display_name = "Maris"
	$AnimatedSprite2D.modulate = Color(1.0, 0.7, 0.7)  # warm pink tint

func get_dialogue_tree() -> Dictionary:
	if not GameState.get_flag("met_maris"):
		return _tree_first_meeting()
	elif GameState.get_flag("maris_confided") and not GameState.get_flag("maris_favour_done"):
		return _tree_favour_pending()
	elif GameState.get_flag("maris_favour_done"):
		return _tree_post_favour()
	else:
		return _tree_casual()

func _tree_first_meeting() -> Dictionary:
	return {
		"start": {
			"speaker": "Maris",
			"text": "Oh — you're the new one. I'm Maris. I run the food printer, for what that's worth.",
			"beat": "meet_maris",
			"choices": [
				{ "text": "Nice to meet you. I'm %s." % GameState.player_name, "register": "warm", "next": "warm_reply" },
				{ "text": "What's wrong with the food printer?", "register": "curious", "next": "printer_reply" },
				{ "text": "Right.", "register": "detached", "next": "detached_reply" },
			]
		},
		"warm_reply": {
			"speaker": "Maris",
			"text": "Well. It's nice to have someone introduce themselves properly for once.",
			"choices": []
		},
		"printer_reply": {
			"speaker": "Maris",
			"text": "Nothing you'd want to know about. Eat the output, don't ask questions.",
			"choices": []
		},
		"detached_reply": {
			"speaker": "Maris",
			"text": "Sure. The food's over there when you want it.",
			"choices": []
		}
	}

func _tree_casual() -> Dictionary:
	return {
		"start": {
			"speaker": "Maris",
			"text": "The printer's running. That's about as good as it gets today.",
			"choices": [
				{ "text": "How are you holding up?", "register": "warm", "next": "holding_up" },
				{ "text": "Good to know.", "register": "detached", "next": "end" },
			]
		},
		"holding_up": {
			"speaker": "Maris",
			"text": "Honestly? I've had better weeks. But I'm here.",
			"choices": []
		},
		"end": {
			"speaker": "Maris",
			"text": "Yeah.",
			"choices": []
		}
	}

func _tree_favour_pending() -> Dictionary:
	return {
		"start": {
			"speaker": "Maris",
			"text": "Hey — did you get a chance to look at what I asked? The ration stores are lower than I reported.",
			"beat": "maris_asks_favour",
			"choices": [
				{ "text": "I'll handle it.", "register": "hopeful", "next": "handle_it" },
				{ "text": "Why didn't you tell the others?", "register": "curious", "next": "why_not_tell" },
				{ "text": "That's not really my problem.", "register": "cynical", "next": "not_my_problem" },
			]
		},
		"handle_it": {
			"speaker": "Maris",
			"text": "Thank you. I mean it.",
			"choices": []
		},
		"why_not_tell": {
			"speaker": "Maris",
			"text": "Because Dex would spiral and Sable would leave. I need someone who can be calm about it.",
			"choices": []
		},
		"not_my_problem": {
			"speaker": "Maris",
			"text": "...Right. Sorry to bother you.",
			"choices": []
		}
	}

func _tree_post_favour() -> Dictionary:
	return {
		"start": {
			"speaker": "Maris",
			"text": "You came through. I won't forget that.",
			"choices": [
				{ "text": "Anyone would have done the same.", "register": "warm", "next": "end" },
				{ "text": "Don't mention it.", "register": "detached", "next": "end" },
			]
		},
		"end": {
			"speaker": "Maris",
			"text": "Still. It matters.",
			"choices": []
		}
	}
