# scripts/ui/ending_screen.gd
extends Control

@onready var _cursor: MenuCursor = $MenuCursor
@onready var _confirm_btn: Button = $VBoxContainer/CreditsBtn

func _ready() -> void:
	_confirm_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.track_item(_confirm_btn)
	_confirm_btn.grab_focus()
	_confirm_btn.pressed.connect(func(): get_tree().quit())

func _unhandled_input(event: InputEvent) -> void:
	if UIInput.is_confirm(event):
		get_tree().quit()
		get_viewport().set_input_as_handled()
