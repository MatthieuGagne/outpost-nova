# scripts/characters/engineer.gd
extends "res://scripts/characters/character.gd"

func _ready() -> void:
	super._ready()
	character_name = "Dex"

func get_dialogue() -> String:
	if GameState.get_flag("workshop_unlocked"):
		return "Finally. I've got a list of fixes as long as my arm. You won't regret opening that door."
	elif GameState.get_flag("lighting_upgraded"):
		return "Good call on the lights. Can't fix what you can't see."
	else:
		return "Station's holding together. For now. Don't quote me on that."
