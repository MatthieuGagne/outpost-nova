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
		var labels := _choices_container.get_children()
		if event.is_action_pressed("ui_up"):
			_move_selection(labels, -1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			_move_selection(labels, 1)
			get_viewport().set_input_as_handled()
		else:
			for i in range(min(4, labels.size())):
				if event is InputEventKey and event.pressed and \
				   event.keycode == KEY_1 + i:
					_select_choice(labels[i])
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
	_dialogue_text.visible = false
	_speaker_label.visible = false
	_build_choices(options, on_option_selected)
	_choices_container.visible = true
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
	for child in _choices_container.get_children():
		child.queue_free()
	for i in range(options.size()):
		var option := YarnSpinner.DialogueOption.from_dictionary(options[i])
		if option == null:
			continue
		var text := option.line.text_without_character_name.text
		var is_inner_voice := false
		var tag_label := ""
		for tag in option.line.metadata:
			var tag_s: String = str(tag)
			if tag_s == "inner_voice":
				is_inner_voice = true
			elif tag_s.begins_with("register:"):
				tag_label = "[%s] " % tag_s.substr(9).capitalize()
			elif tag_s.begins_with("pair:"):
				var pair_id: String = tag_s.substr(5)
				var state := GameState.get_pair_state(pair_id)
				tag_label = "[%s] " % GameState.get_pair_state_label(state)
		var body: String
		if is_inner_voice:
			body = "[i]… %s%s[/i]" % [tag_label, text]
		else:
			body = "%s%s" % [tag_label, text]
		var display: String = "%d  %s" % [i + 1, body]
		if not option.is_available:
			display = "[color=#808080]%s[/color]" % display
		var lbl := RichTextLabel.new()
		lbl.bbcode_enabled = true
		lbl.fit_content = true
		lbl.scroll_active = false
		lbl.focus_mode = Control.FOCUS_ALL
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		lbl.add_theme_font_override("normal_font", load("res://data/fonts/m5x7.tres"))
		lbl.add_theme_font_size_override("normal_font_size", 13)
		lbl.add_theme_font_override("italics_font", load("res://data/fonts/m5x7.tres"))
		lbl.add_theme_font_size_override("italics_font_size", 13)
		lbl.text = display
		lbl.set_meta("option_id", option.dialogue_option_id)
		lbl.set_meta("on_option_selected", on_option_selected)
		lbl.set_meta("is_available", option.is_available)
		if option.is_available:
			lbl.gui_input.connect(_on_choice_gui_input.bind(lbl))
		lbl.focus_entered.connect(_on_label_focus_entered.bind(lbl))
		lbl.focus_exited.connect(_on_label_focus_exited.bind(lbl))
		_choices_container.add_child(lbl)
	for child in _choices_container.get_children():
		if child.focus_mode != Control.FOCUS_NONE:
			child.grab_focus()
			break

func _on_choice_gui_input(event: InputEvent, lbl: RichTextLabel) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_commit_choice(lbl)
		get_viewport().set_input_as_handled()

func _on_label_focus_entered(lbl: RichTextLabel) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.08)
	sb.border_color = Color(1, 1, 1, 0.4)
	sb.set_border_width_all(1)
	lbl.add_theme_stylebox_override("normal", sb)

func _on_label_focus_exited(lbl: RichTextLabel) -> void:
	lbl.remove_theme_stylebox_override("normal")

func _commit_choice(lbl: RichTextLabel) -> void:
	if not lbl.get_meta("is_available", false):
		return
	_state = _State.IDLE
	_choices_container.visible = false
	lbl.get_meta("on_option_selected").call(lbl.get_meta("option_id"))
	_option_chosen.emit()

func _move_selection(labels: Array, direction: int) -> void:
	var focused := _choices_container.get_viewport().gui_get_focus_owner()
	var current_idx := labels.find(focused)
	if current_idx == -1:
		current_idx = 0
	var next_idx := wrapi(current_idx + direction, 0, labels.size())
	labels[next_idx].grab_focus()

func _select_choice(lbl: RichTextLabel) -> void:
	_commit_choice(lbl)
