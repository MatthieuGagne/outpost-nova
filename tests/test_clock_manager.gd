# tests/test_clock_manager.gd
extends GutTest

func before_each():
	ClockManager.reset()

func test_initial_time_is_0600():
	assert_eq(ClockManager.current_time, 360)

func test_initial_day_is_1():
	assert_eq(ClockManager.current_day, 1)

func test_get_time_string_at_start():
	assert_eq(ClockManager.get_time_string(), "06:00")

func test_commit_action_advances_time():
	ClockManager.commit_action(30)
	assert_eq(ClockManager.current_time, 390)
	assert_eq(ClockManager.get_time_string(), "06:30")

func test_can_act_true_when_time_available():
	assert_true(ClockManager.can_act(30))

func test_can_act_false_when_cost_exceeds_end_time():
	ClockManager.current_time = 940
	assert_false(ClockManager.can_act(30))

func test_can_act_true_at_exact_boundary():
	ClockManager.current_time = 930
	assert_true(ClockManager.can_act(30))  # 930+30=960 exactly

func test_commit_action_emits_time_advanced():
	var emitted := [false]
	var cb := func(_t: int): emitted[0] = true
	ClockManager.time_advanced.connect(cb)
	ClockManager.commit_action(30)
	ClockManager.time_advanced.disconnect(cb)
	assert_true(emitted[0])

func test_overflow_emits_day_ended():
	ClockManager.current_time = 940
	var day_num := [0]
	var cb := func(d: int): day_num[0] = d
	ClockManager.day_ended.connect(cb)
	ClockManager.commit_action(30)  # 940+30=970 > 960
	ClockManager.day_ended.disconnect(cb)
	assert_eq(day_num[0], 1)

func test_overflow_does_not_error():
	ClockManager.current_time = 950
	ClockManager.commit_action(30)  # 950+30=980 > 960
	assert_eq(ClockManager.current_time, 980)

func test_end_day_manually_emits_day_ended():
	var day_num := [0]
	var cb := func(d: int): day_num[0] = d
	ClockManager.day_ended.connect(cb)
	ClockManager.end_day_manually()
	ClockManager.day_ended.disconnect(cb)
	assert_eq(day_num[0], 1)

func test_advance_day_increments_day():
	ClockManager.advance_day()
	assert_eq(ClockManager.current_day, 2)

func test_advance_day_resets_time():
	ClockManager.commit_action(60)
	ClockManager.advance_day()
	assert_eq(ClockManager.current_time, 360)

func test_advance_day_emits_time_advanced_360():
	var new_time := [0]
	var cb := func(t: int): new_time[0] = t
	ClockManager.time_advanced.connect(cb)
	ClockManager.advance_day()
	ClockManager.time_advanced.disconnect(cb)
	assert_eq(new_time[0], 360)

func test_advance_day_clears_actions_log():
	ClockManager.log_action("Did something")
	ClockManager.advance_day()
	assert_eq(ClockManager._actions_log.size(), 0)

func test_log_action_appends():
	ClockManager.log_action("Met Maris")
	assert_eq(ClockManager._actions_log.size(), 1)
	assert_eq(ClockManager._actions_log[0], "Met Maris")

func test_reset_clears_log():
	ClockManager.log_action("Something")
	ClockManager.reset()
	assert_eq(ClockManager._actions_log.size(), 0)
