# scripts/ui/character_creation.gd
extends Control

@onready var name_input: LineEdit = $VBoxContainer/NameInput
@onready var start_btn: Button = $VBoxContainer/StartBtn
@onready var appearance_picker: HBoxContainer = $VBoxContainer/AppearancePicker
@onready var background_picker: VBoxContainer = $VBoxContainer/BackgroundPicker

const BACKGROUNDS = ["engineer", "medic", "drifter"]

var _selected_appearance: int = 0
var _selected_background: String = "drifter"

func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	for i in appearance_picker.get_child_count():
		appearance_picker.get_child(i).pressed.connect(_set_appearance.bind(i))
	for i in background_picker.get_child_count():
		background_picker.get_child(i).pressed.connect(_set_background.bind(i))

func _set_appearance(idx: int) -> void:
	_selected_appearance = idx

func _set_background(idx: int) -> void:
	_selected_background = BACKGROUNDS[idx]

func _on_start() -> void:
	var name_val = name_input.text.strip_edges()
	if name_val == "":
		name_val = "Crew"
	GameState.set_player_identity(name_val, _selected_background, _selected_appearance)
	GameState.apply_background_bonus(_selected_background)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
