# scripts/derelict/arc_events.gd
extends Node

# Called from Main when day 7 starts
func trigger_final_choice() -> void:
	var overlay = _build_choice_overlay()
	get_tree().root.add_child(overlay)

func _build_choice_overlay() -> CanvasLayer:
	var layer = CanvasLayer.new()
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vbox = VBoxContainer.new()

	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = "[center]You know what's in the lower decks now.\n\nThe thing that survived the purge is still alive.\nDex wants to shut it down. Maris says it might be salvageable.\nSable says it knows something — about all of you.[/center]"
	label.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(label)

	var choices = [
		{ "text": "Shut it down. The station comes first.", "flag": "ending_pragmatic" },
		{ "text": "Try to communicate. There might be a way.", "flag": "ending_hopeful" },
		{ "text": "Let Sable decide. She's the one it recognises.", "flag": "ending_deferred" },
	]
	for choice in choices:
		var btn = Button.new()
		btn.text = choice["text"]
		btn.pressed.connect(_on_final_choice.bind(choice["flag"], layer))
		vbox.add_child(btn)

	panel.add_child(vbox)
	layer.add_child(panel)
	return layer

func _on_final_choice(flag: String, layer: CanvasLayer) -> void:
	GameState.set_flag(flag, true)
	ClockManager.log_action("Made final choice")
	layer.queue_free()
