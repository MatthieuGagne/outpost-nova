extends CanvasLayer

signal conversation_ended

const PORTRAIT_SHEET := preload("res://assets/portraits/portrait_sheet.png")
const PORTRAIT_WIDTH := 64
const PORTRAIT_HEIGHT := 64
const PORTRAIT_COLS := 5

const NPC_PORTRAIT_INDEX: Dictionary = {
	"Maris": 0,
	"Dex": 1,
	"Sable": 2,
}
const PLAYER_PORTRAIT_INDEX := 9
const FALLBACK_PORTRAIT_INDEX := 3

const TYPEWRITER_CHARS_PER_SECOND := 30.0

enum _State { IDLE, TYPEWRITING, COMPLETE, CHOOSING }

var _state: _State = _State.IDLE

signal _line_advance_requested
signal _option_chosen

@onready var _npc_portrait: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/PortraitContainer/NPCPortrait
@onready var _player_portrait: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/PortraitContainer/PlayerPortrait
@onready var _speaker_label: Label = $PanelContainer/MarginContainer/HBoxContainer/ContentContainer/SpeakerLabel
@onready var _dialogue_text: RichTextLabel = $PanelContainer/MarginContainer/HBoxContainer/ContentContainer/DialogueText
@onready var _choices_container: VBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/ContentContainer/ChoicesContainer

var _typewriter_timer: float = 0.0
var _typewriter_target: int = 0
var _full_text: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("dialogue_box")
	_player_portrait.texture = _make_atlas(PLAYER_PORTRAIT_INDEX)
	hide()

func _process(delta: float) -> void:
	if _state != _State.TYPEWRITING:
		return
	_typewriter_timer += delta
	var chars_to_show := int(_typewriter_timer * TYPEWRITER_CHARS_PER_SECOND)
	_dialogue_text.visible_characters = min(chars_to_show, _typewriter_target)
	if _dialogue_text.visible_characters >= _typewriter_target:
		_state = _State.COMPLETE

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match _state:
			_State.TYPEWRITING:
				_dialogue_text.visible_characters = -1
				_typewriter_timer = 9999.0
				_state = _State.COMPLETE
			_State.COMPLETE:
				_state = _State.IDLE
				_line_advance_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		match _state:
			_State.TYPEWRITING:
				_dialogue_text.visible_characters = -1
				_typewriter_timer = 9999.0
				_state = _State.COMPLETE
			_State.COMPLETE:
				_state = _State.IDLE
				_line_advance_requested.emit()
		get_viewport().set_input_as_handled()
	if _state == _State.CHOOSING:
		var buttons := _choices_container.get_children()
		if event.is_action_pressed("ui_up"):
			_move_selection(buttons, -1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			_move_selection(buttons, 1)
			get_viewport().set_input_as_handled()
		else:
			for i in range(min(4, buttons.size())):
				if event is InputEventKey and event.pressed and \
				   event.keycode == KEY_1 + i:
					_select_choice(buttons[i])
					get_viewport().set_input_as_handled()

# ── YarnSpinner GDScript view protocol ───────────────────────────────────────

func on_dialogue_start_async() -> void:
	show()
	get_tree().paused = true

func run_line_async(line: Dictionary) -> void:
	_choices_container.visible = false
	get_viewport().gui_release_focus()
	var localized_line := YarnSpinner.LocalizedLine.from_dictionary(line)
	_speaker_label.text = localized_line.character_name
	_update_portrait(localized_line.character_name)
	_start_typewriter(localized_line.text_without_character_name.text)
	await _line_advance_requested

func run_options_async(options: Array, on_option_selected: Callable) -> void:
	push_warning("run_options_async called, options count: %d" % options.size())
	_dialogue_text.visible = false
	_speaker_label.visible = false
	_build_choices(options, on_option_selected)
	_choices_container.visible = true
	push_warning("choices_container children: %d, visible: %s" % [_choices_container.get_child_count(), _choices_container.visible])
	_state = _State.CHOOSING
	await _option_chosen
	_dialogue_text.visible = true
	_speaker_label.visible = true

func on_dialogue_complete_async() -> void:
	_choices_container.visible = false
	_state = _State.IDLE
	hide()
	get_tree().paused = false
	conversation_ended.emit()

# ── Internal helpers ──────────────────────────────────────────────────────────

func _start_typewriter(text: String) -> void:
	_full_text = text
	_dialogue_text.text = text
	_dialogue_text.visible_characters = 0
	_typewriter_timer = 0.0
	_typewriter_target = len(text)
	_state = _State.TYPEWRITING

func _update_portrait(speaker: String) -> void:
	var idx: int = NPC_PORTRAIT_INDEX.get(speaker, FALLBACK_PORTRAIT_INDEX)
	_npc_portrait.texture = _make_atlas(idx)

func _make_atlas(index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = PORTRAIT_SHEET
	var col := index % PORTRAIT_COLS
	var row := index / PORTRAIT_COLS
	atlas.region = Rect2(col * PORTRAIT_WIDTH, row * PORTRAIT_HEIGHT, PORTRAIT_WIDTH, PORTRAIT_HEIGHT)
	return atlas

func _build_choices(options: Array, on_option_selected: Callable) -> void:
	push_warning("_build_choices called, options: %d" % options.size())
	for child in _choices_container.get_children():
		child.queue_free()
	for i in range(options.size()):
		push_warning("option[%d] keys: %s" % [i, str(options[i].keys())])
		var option := YarnSpinner.DialogueOption.from_dictionary(options[i])
		if option == null:
			push_warning("option %d is null!" % i)
			continue
		push_warning("option %d text: %s" % [i, option.line.text_without_character_name.text])
		var btn := Button.new()
		btn.text = "[%d] %s" % [i + 1, option.line.text_without_character_name.text]
		btn.add_theme_font_override("font", load("res://data/fonts/m5x7.tres"))
		btn.add_theme_font_size_override("font_size", 13)
		btn.disabled = not option.is_available
		btn.pressed.connect(_on_choice_pressed.bind(option.dialogue_option_id, on_option_selected))
		_choices_container.add_child(btn)
	for child in _choices_container.get_children():
		if not child.disabled:
			child.grab_focus()
			break

func _on_choice_pressed(option_id: int, on_option_selected: Callable) -> void:
	_state = _State.IDLE
	_choices_container.visible = false
	on_option_selected.call(option_id)
	_option_chosen.emit()

func _move_selection(buttons: Array, direction: int) -> void:
	var focused := _choices_container.get_viewport().gui_get_focus_owner()
	var current_idx := buttons.find(focused)
	if current_idx == -1:
		current_idx = 0
	var next_idx := wrapi(current_idx + direction, 0, buttons.size())
	buttons[next_idx].grab_focus()

func _select_choice(btn: Button) -> void:
	if not btn.disabled:
		btn.emit_signal("pressed")
