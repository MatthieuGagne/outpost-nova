# scripts/ui/character_creation.gd
extends Control

@onready var name_input: LineEdit = $VBoxContainer/NameInput
@onready var start_btn: Button = $VBoxContainer/StartBtn
@onready var appearance_picker: HBoxContainer = $VBoxContainer/AppearancePicker
@onready var background_picker: VBoxContainer = $VBoxContainer/BackgroundPicker
@onready var _cursor: MenuCursor = $MenuCursor

const BACKGROUNDS = ["engineer", "medic", "drifter"]

var _selected_appearance: int = -1
var _selected_background: String = ""
var _name_field_active: bool = false

func _ready() -> void:
	name_input.text_submitted.connect(_on_name_submitted)
	name_input.editable = false
	for i in appearance_picker.get_child_count():
		appearance_picker.get_child(i).pressed.connect(_set_appearance.bind(i))
		appearance_picker.get_child(i).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in background_picker.get_child_count():
		background_picker.get_child(i).pressed.connect(_set_background.bind(i))
		background_picker.get_child(i).mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_appearance(0)
	_set_background(0)
	_cursor.track(appearance_picker)
	_cursor.track(background_picker)
	_cursor.track_item(name_input)
	_cursor.track_item(start_btn)
	name_input.grab_focus()
	_update_start_btn()

func _unhandled_input(event: InputEvent) -> void:
	if _name_field_active:
		if UIInput.is_cancel(event):
			name_input.text = ""
			_deactivate_name_field()
			get_viewport().set_input_as_handled()
		return
	if UIInput.is_confirm(event):
		var focused := get_viewport().gui_get_focus_owner()
		if focused == name_input:
			_activate_name_field()
			get_viewport().set_input_as_handled()
			return
		if focused == start_btn:
			_on_start()
			get_viewport().set_input_as_handled()
			return
	if UIInput.is_cancel(event):
		get_tree().quit()
		get_viewport().set_input_as_handled()

func _activate_name_field() -> void:
	_name_field_active = true
	name_input.editable = true
	name_input.grab_focus()
	_cursor.clear()

func _deactivate_name_field() -> void:
	_name_field_active = false
	name_input.editable = false
	name_input.grab_focus()
	_update_start_btn()

func _on_name_submitted(_text: String) -> void:
	_deactivate_name_field()
	appearance_picker.get_child(0).grab_focus()

func _set_appearance(idx: int) -> void:
	_selected_appearance = idx
	_update_start_btn()

func _set_background(idx: int) -> void:
	_selected_background = BACKGROUNDS[idx]
	_update_start_btn()

func _update_start_btn(_ignored: String = "") -> void:
	start_btn.disabled = (
		name_input.text.strip_edges() == "" or
		_selected_appearance == -1 or
		_selected_background == ""
	)

func _on_start() -> void:
	if start_btn.disabled:
		return
	GameState.set_player_identity(name_input.text.strip_edges(), _selected_background, _selected_appearance)
	GameState.apply_background_bonus(_selected_background)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
