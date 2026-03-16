# scripts/characters/drifter.gd
extends "res://scripts/characters/character.gd"

func _ready() -> void:
	super._ready()
	character_name = "Sable"

func get_dialogue() -> String:
	if GameState.get_flag("workshop_unlocked"):
		return "Hm. Maybe I'll stick around a bit longer. See what you do with that Workshop."
	elif GameState.get_flag("food_printer_upgraded"):
		return "Better food. That's a reason to stay, I suppose."
	else:
		return "Just passing through. No offence."
