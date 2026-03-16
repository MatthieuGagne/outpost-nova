# scripts/characters/dex.gd
extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
	super()
	npc_id = "dex"
	display_name = "Dex"

func get_dialogue_tree() -> Dictionary:
	if not GameState.get_flag("met_dex"):
		return _tree_first_meeting()
	elif GameState.get_flag("power_flicker_noticed") and not GameState.get_flag("dex_secret_known"):
		return _tree_power_concern()
	elif GameState.get_flag("dex_secret_known"):
		return _tree_post_secret()
	else:
		return _tree_casual()

func _tree_first_meeting() -> Dictionary:
	return {
		"start": {
			"speaker": "Dex",
			"text": "You're the new one. Dex. I keep the lights on — literally. Don't touch anything in Engineering without asking.",
			"beat": "check_engineering",
			"choices": [
				{ "text": "Understood. What should I know?", "register": "curious", "next": "what_to_know" },
				{ "text": "Fair enough.", "register": "detached", "next": "fair_enough" },
				{ "text": "I'll try not to break anything.", "register": "sharp", "next": "sharp_reply" },
			]
		},
		"what_to_know": {
			"speaker": "Dex",
			"text": "Power's stable. For now. The lower decks draw from the same grid. Whatever's down there — it's pulling more than it should.",
			"choices": []
		},
		"fair_enough": {
			"speaker": "Dex",
			"text": "Good. We understand each other.",
			"choices": []
		},
		"sharp_reply": {
			"speaker": "Dex",
			"text": "See that you don't. This station runs on experience, not good intentions.",
			"choices": []
		}
	}

func _tree_casual() -> Dictionary:
	return {
		"start": {
			"speaker": "Dex",
			"text": "Systems are nominal. Don't quote me on that.",
			"choices": [
				{ "text": "The lower decks — you ever been down there?", "register": "curious", "next": "lower_decks" },
				{ "text": "Good to hear.", "register": "hopeful", "next": "end" },
			]
		},
		"lower_decks": {
			"speaker": "Dex",
			"text": "Once. Before the seal. I don't talk about it.",
			"choices": []
		},
		"end": {
			"speaker": "Dex",
			"text": "Keep it that way.",
			"choices": []
		}
	}

func _tree_power_concern() -> Dictionary:
	return {
		"start": {
			"speaker": "Dex",
			"text": "The flicker last night — that wasn't random. Something in the lower decks is drawing power on a cycle. It's been doing it for months.",
			"beat": "power_flicker",
			"choices": [
				{ "text": "We should open the door and find out.", "register": "instinct", "next": "open_door" },
				{ "text": "What's the risk if we leave it?", "register": "logical", "next": "risk_if_left" },
				{ "text": "Why didn't you report this?", "register": "sharp", "next": "why_not_report" },
			]
		},
		"open_door": {
			"speaker": "Dex",
			"text": "...Yeah. I think so too. I'll start the unlock sequence. It'll take until tomorrow.",
			"choices": []
		},
		"risk_if_left": {
			"speaker": "Dex",
			"text": "Grid failure in 2-3 weeks, best case. We'd lose life support.",
			"choices": []
		},
		"why_not_report": {
			"speaker": "Dex",
			"text": "Because I knew whoever was down there sealed that door for a reason.",
			"choices": []
		}
	}

func _tree_post_secret() -> Dictionary:
	return {
		"start": {
			"speaker": "Dex",
			"text": "Now you know. I'm sorry I didn't tell you sooner.",
			"choices": [
				{ "text": "What do we do now?", "register": "hopeful", "next": "what_now" },
				{ "text": "We deal with what's in front of us.", "register": "logical", "next": "deal_with_it" },
			]
		},
		"what_now": {
			"speaker": "Dex",
			"text": "We fix it. Or we don't. But at least we know.",
			"choices": []
		},
		"deal_with_it": {
			"speaker": "Dex",
			"text": "Yeah. That's all we can do.",
			"choices": []
		}
	}
