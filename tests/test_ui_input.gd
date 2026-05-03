# tests/test_ui_input.gd
extends GutTest

func _make_action_event(action: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev

func test_is_confirm_accepts_ui_accept():
	assert_true(UIInput.is_confirm(_make_action_event("ui_accept")))

func test_is_confirm_accepts_ui_select():
	assert_true(UIInput.is_confirm(_make_action_event("ui_select")))

func test_is_confirm_rejects_ui_cancel():
	assert_false(UIInput.is_confirm(_make_action_event("ui_cancel")))

func test_is_cancel_accepts_ui_cancel():
	assert_true(UIInput.is_cancel(_make_action_event("ui_cancel")))

func test_is_cancel_rejects_ui_accept():
	assert_false(UIInput.is_cancel(_make_action_event("ui_accept")))

func test_navigate_down_increments():
	var items: Array = [Control.new(), Control.new(), Control.new()]
	assert_eq(UIInput.navigate(_make_action_event("ui_down"), items, 0), 1)

func test_navigate_up_decrements():
	var items: Array = [Control.new(), Control.new(), Control.new()]
	assert_eq(UIInput.navigate(_make_action_event("ui_up"), items, 2), 1)

func test_navigate_down_wraps():
	var items: Array = [Control.new(), Control.new(), Control.new()]
	assert_eq(UIInput.navigate(_make_action_event("ui_down"), items, 2), 0)

func test_navigate_up_wraps():
	var items: Array = [Control.new(), Control.new(), Control.new()]
	assert_eq(UIInput.navigate(_make_action_event("ui_up"), items, 0), 2)

func test_navigate_returns_current_on_unrelated_action():
	var items: Array = [Control.new(), Control.new(), Control.new()]
	assert_eq(UIInput.navigate(_make_action_event("ui_accept"), items, 1), 1)

func test_navigate_returns_current_on_empty_items():
	assert_eq(UIInput.navigate(_make_action_event("ui_down"), [], 0), 0)
