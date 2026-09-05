# tests/test_menu_cursor.gd
# Guards MenuCursor.track()/track_item() against double-connecting focus_entered
# (issue #119). Godot rejects duplicate connections and prints an engine error, so
# the observable symptom is the error itself — asserted via GUT's error tracker.
extends GutTest

func test_track_is_idempotent():
	var cursor := MenuCursor.new()
	var container := VBoxContainer.new()
	var child := Button.new()
	container.add_child(child)
	add_child_autofree(cursor)
	add_child_autofree(container)

	cursor.track(container)
	cursor.track(container)

	assert_engine_error_count(0, "track() must not connect focus_entered twice")

func test_track_item_is_idempotent():
	var cursor := MenuCursor.new()
	var item := Button.new()
	add_child_autofree(cursor)
	add_child_autofree(item)

	cursor.track_item(item)
	cursor.track_item(item)

	assert_engine_error_count(0, "track_item() must not connect focus_entered twice")
