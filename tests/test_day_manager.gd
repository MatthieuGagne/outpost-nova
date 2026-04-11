# tests/test_day_manager.gd
extends GutTest

func before_each():
	GameState.reset()
	DayManager.reset()

func test_starts_on_day_one():
	assert_eq(DayManager.current_day, 1)

func test_reset_loads_day_one_beats():
	assert_eq(DayManager.get_todays_beats().size(), 3)

func test_complete_beat():
	DayManager.reset()
	DayManager._override_beats_for_test([{ "id": "meet_maris", "required": true }])
	DayManager.complete_beat("meet_maris")
	assert_true(DayManager.is_beat_complete("meet_maris"))

func test_day_not_complete_if_required_beats_remain():
	DayManager.reset()
	DayManager._override_beats_for_test([
		{ "id": "beat_a", "required": true },
		{ "id": "beat_b", "required": true }
	])
	DayManager.complete_beat("beat_a")
	assert_false(DayManager.is_day_complete())

func test_day_complete_when_all_required_beats_done():
	DayManager.reset()
	DayManager._override_beats_for_test([
		{ "id": "beat_a", "required": true },
		{ "id": "beat_b", "required": false }
	])
	DayManager.complete_beat("beat_a")
	assert_true(DayManager.is_day_complete())

func test_advance_day_increments_counter():
	DayManager.reset()
	DayManager._override_beats_for_test([])
	DayManager.advance_day()
	assert_eq(DayManager.current_day, 2)

func test_advance_day_clears_completed_beats():
	DayManager.reset()
	DayManager._override_beats_for_test([{ "id": "beat_a", "required": true }])
	DayManager.complete_beat("beat_a")
	DayManager.advance_day()
	assert_false(DayManager.is_beat_complete("beat_a"))

func test_all_beats_done_fires_once():
	DayManager._override_beats_for_test([
		{ "id": "beat_required", "required": true },
		{ "id": "beat_optional", "required": false }
	])
	var count = [0]
	var cb = func(): count[0] += 1
	DayManager.all_beats_done.connect(cb)
	DayManager.complete_beat("beat_required")   # day is now complete → should emit once
	DayManager.complete_beat("beat_optional")   # day still complete → should NOT emit again
	DayManager.all_beats_done.disconnect(cb)
	assert_eq(count[0], 1)
