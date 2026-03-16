# scripts/bunk.gd
extends StaticBody2D

func _ready() -> void:
	add_to_group("interactable")

func interact() -> void:
	var main = get_tree().get_root().get_node("Main")
	if DayManager.is_day_complete():
		main.advance_day()
	else:
		main.show_hud_message("You're not ready to rest yet.")
