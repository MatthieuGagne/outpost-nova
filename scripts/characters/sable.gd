# scripts/characters/sable.gd
extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
	super()
	npc_id = "sable"
	display_name = "Sable"
	$AnimatedSprite2D.modulate = Color(0.7, 1.0, 0.7)  # green tint

func get_dialogue_tree() -> Dictionary:
	if not GameState.get_flag("met_sable"):
		return _tree_first_meeting()
	elif GameState.get_flag("sable_past_revealed"):
		return _tree_post_revelation()
	else:
		return _tree_guarded()

func _tree_first_meeting() -> Dictionary:
	return {
		"start": {
			"speaker": "Sable",
			"text": "You're new. I'm Sable. I'm just passing through.",
			"beat": "sable_arrives",
			"choices": [
				{ "text": "Where are you headed?", "register": "curious", "next": "where_headed" },
				{ "text": "We're glad you're here.", "register": "warm", "next": "glad_here" },
				{ "text": "Same.", "register": "detached", "next": "end" },
			]
		},
		"where_headed": {
			"speaker": "Sable",
			"text": "Somewhere that isn't here. No offence.",
			"choices": []
		},
		"glad_here": {
			"speaker": "Sable",
			"text": "Don't be. I might be gone by morning.",
			"choices": []
		},
		"end": {
			"speaker": "Sable",
			"text": "Right.",
			"choices": []
		}
	}

func _tree_guarded() -> Dictionary:
	return {
		"start": {
			"speaker": "Sable",
			"text": "Still here, apparently.",
			"choices": [
				{ "text": "What's keeping you?", "register": "curious", "next": "keeping_here" },
				{ "text": "Glad you stayed.", "register": "warm", "next": "glad_stayed" },
				{ "text": "Hm.", "register": "detached", "next": "end" },
			]
		},
		"keeping_here": {
			"speaker": "Sable",
			"text": "Honestly? I don't know. Something about this place feels unfinished.",
			"choices": []
		},
		"glad_stayed": {
			"speaker": "Sable",
			"text": "Don't read into it.",
			"choices": []
		},
		"end": {
			"speaker": "Sable",
			"text": "...",
			"choices": []
		}
	}

func _tree_post_revelation() -> Dictionary:
	return {
		"start": {
			"speaker": "Sable",
			"text": "I didn't think I'd tell anyone that. About the lower decks. About what I saw before the seal.",
			"choices": [
				{ "text": "You can trust us.", "register": "warm", "next": "trust_us" },
				{ "text": "What exactly did you see?", "register": "curious", "next": "what_saw" },
			]
		},
		"trust_us": {
			"speaker": "Sable",
			"text": "Maybe. I'm still deciding.",
			"choices": []
		},
		"what_saw": {
			"speaker": "Sable",
			"text": "Something that was still alive. And it recognised me.",
			"choices": []
		}
	}
