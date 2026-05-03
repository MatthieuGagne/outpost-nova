# scripts/ui/menu_cursor.gd
class_name MenuCursor
extends Label

const BLINK_INTERVAL := 0.6
const CURSOR_X_OFFSET := -14.0

var _focused: Control = null
var _blink_timer: float = 0.0

func _ready() -> void:
	text = "▶"
	add_theme_font_override("font", load("res://data/fonts/m5x7.tres"))
	add_theme_font_size_override("font_size", 13)
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func _process(delta: float) -> void:
	if _focused == null:
		return
	global_position = Vector2(_focused.global_position.x + CURSOR_X_OFFSET, _focused.global_position.y)
	_blink_timer += delta
	if _blink_timer >= BLINK_INTERVAL:
		_blink_timer = 0.0
		visible = not visible

func track(container: Control) -> void:
	for child in container.get_children():
		if child is Control and child.focus_mode != Control.FOCUS_NONE:
			child.focus_entered.connect(_on_focus_entered.bind(child))

func track_item(item: Control) -> void:
	if item.focus_mode != Control.FOCUS_NONE:
		item.focus_entered.connect(_on_focus_entered.bind(item))

func clear() -> void:
	_focused = null
	hide()

func _on_focus_entered(item: Control) -> void:
	_focused = item
	_blink_timer = 0.0
	show()
