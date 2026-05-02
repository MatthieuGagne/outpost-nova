# tests/test_resource_plot.gd
extends GutTest

var _plot: Node = null

func before_each():
	GameState.reset()
	ClockManager.reset()
	_plot = load("res://scenes/resource_node.tscn").instantiate()
	add_child_autofree(_plot)

func test_starts_in_empty_state():
	assert_eq(_plot.get_plot_state(), _plot.PlotState.EMPTY)

func test_start_plot_transitions_to_growing():
	_plot.start_plot()
	assert_eq(_plot.get_plot_state(), _plot.PlotState.GROWING)

func test_start_plot_emits_plot_state_changed():
	watch_signals(_plot)
	_plot.start_plot()
	assert_signal_emitted(_plot, "plot_state_changed")

func test_start_plot_when_growing_is_idempotent():
	_plot.start_plot()
	_plot.start_plot()
	assert_eq(_plot.get_plot_state(), _plot.PlotState.GROWING)

func test_interact_when_growing_does_not_change_state():
	_plot.start_plot()
	_plot.interact()
	assert_eq(_plot.get_plot_state(), _plot.PlotState.GROWING)

func test_start_plot_advances_clock_90_minutes():
	_plot.start_plot()
	assert_eq(ClockManager.current_time, 360 + 90)

func test_start_plot_logs_action():
	_plot.start_plot()
	assert_eq(ClockManager._actions_log.size(), 1)
	assert_eq(ClockManager._actions_log[0], "Started rations plot")
