# scripts/ui/dialogue_box.gd
extends CanvasLayer

@onready var speaker_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/DialogueText
@onready var choices_container: VBoxContainer = $PanelContainer/VBoxContainer/ChoicesContainer
@onready var portrait: TextureRect = $PanelContainer/VBoxContainer/HBoxContainer/Portrait

func _ready() -> void:
	add_to_group("dialogue_box")
	hide()
	DialogueManager.conversation_ended.connect(hide)

func show_current_node() -> void:
	var node = DialogueManager.get_current_node()
	if node.is_empty():
		hide()
		return
	speaker_label.text = node.get("speaker", "")
	dialogue_text.text = node.get("text", "")
	_build_choices(node.get("choices", []))
	show()

func _build_choices(choices: Array) -> void:
	for child in choices_container.get_children():
		child.queue_free()

	if choices.is_empty():
		var btn = Button.new()
		btn.text = "..."
		btn.add_theme_font_override("font", load("res://data/fonts/m5x7.tres"))
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(hide)
		choices_container.add_child(btn)
		return

	var inner_voice_flags = DialogueManager.get_inner_voice_flags()
	for i in range(choices.size()):
		var choice = choices[i]
		var btn = Button.new()
		var label = choice.get("text", "")
		btn.add_theme_font_override("font", load("res://data/fonts/m5x7.tres"))
		btn.add_theme_font_size_override("font_size", 16)
		if inner_voice_flags.has(i):
			btn.text = "[%s] %s" % [GameState.player_background.capitalize(), label]
			btn.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		else:
			btn.text = label
		btn.pressed.connect(_on_choice.bind(i))
		choices_container.add_child(btn)

func _on_choice(index: int) -> void:
	DialogueManager.make_choice(index)
	if not DialogueManager.is_conversation_over():
		show_current_node()
