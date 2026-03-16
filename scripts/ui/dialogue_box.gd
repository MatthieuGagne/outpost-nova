# scripts/ui/dialogue_box.gd
extends CanvasLayer

@onready var name_label: Label = $PanelContainer/VBoxContainer/NameLabel
@onready var text_label: RichTextLabel = $PanelContainer/VBoxContainer/RichTextLabel
@onready var close_btn: Button = $PanelContainer/VBoxContainer/CloseButton

func _ready() -> void:
	hide()
	close_btn.pressed.connect(hide)

func show_dialogue(character_name: String, text: String) -> void:
	name_label.text = character_name
	text_label.text = text
	show()
