# scripts/ui/ui_input.gd
class_name UIInput

static func is_confirm(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select")

static func is_cancel(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_cancel")

static func navigate(event: InputEvent, items: Array, current: int) -> int:
	if items.is_empty():
		return current
	if event.is_action_pressed("ui_up"):
		return wrapi(current - 1, 0, items.size())
	if event.is_action_pressed("ui_down"):
		return wrapi(current + 1, 0, items.size())
	return current
