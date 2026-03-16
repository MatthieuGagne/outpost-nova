# scripts/characters/cook.gd
extends "res://scripts/characters/character.gd"

func _ready() -> void:
	super._ready()
	character_name = "Maris"

func get_dialogue() -> String:
	if GameState.get_flag("workshop_unlocked"):
		return "A workshop! Now we're getting somewhere. I've been wanting to try a few recipes that need proper tools."
	elif GameState.get_flag("food_printer_upgraded"):
		return "That upgrade makes a real difference. Actual flavour. I didn't realise how much I missed it."
	else:
		return "The food printer works, technically. Don't ask me to vouch for the taste."
