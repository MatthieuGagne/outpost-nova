# tests/test_day_manager.gd
extends GutTest

func before_each():
	GameState.reset()
	DayManager.reset()

func test_starts_on_day_one():
	assert_eq(DayManager.current_day, 1)

func test_beats_empty_on_reset():
	assert_eq(DayManager.get_todays_beats().size(), 0)

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
