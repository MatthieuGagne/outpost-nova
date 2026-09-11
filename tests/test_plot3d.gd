extends GutTest

## Plot3D state machine (issue #130 R2). Deliberate parity with tests/test_resource_plot.gd:
## start_plot must NOT grant resources — the 2D plot never did, and AC2 forbids changing it.

const PLOT_3D := "res://scenes/poc3d/plot3d.tscn"

var _plot

func before_each():
	GameState.reset()
	ClockManager.reset()
	_plot = load(PLOT_3D).instantiate()
	add_child_autofree(_plot)

func test_starts_empty_and_joins_the_interactable_group():
	assert_eq(_plot.get_plot_state(), _plot.PlotState.EMPTY)
	assert_true(_plot.is_in_group(InteractScan.INTERACTABLE_GROUP),
		"Plot3D must be scannable by Player3D._try_interact")

func test_start_plot_sets_the_growing_flag():
	_plot.start_plot()
	assert_eq(_plot.get_plot_state(), _plot.PlotState.GROWING)
	assert_true(GameState.get_flag("plot_rations_growing"))

func test_start_plot_costs_ninety_minutes_and_logs_the_action():
	_plot.start_plot()
	assert_eq(ClockManager.current_time, ClockManager.START_TIME + 90)
	assert_eq(ClockManager._actions_log[0], "Started rations plot")

func test_start_plot_emits_plot_state_changed_once():
	watch_signals(_plot)
	_plot.start_plot()
	assert_signal_emit_count(_plot, "plot_state_changed", 1)

func test_start_plot_grants_no_resources():
	# AC2: parity with 2D — the plot is planted now, harvested later. No economy change.
	watch_signals(GameState)
	_plot.start_plot()
	assert_signal_emit_count(GameState, "resource_changed", 0)
	assert_eq(GameState.get_resource("rations"), 0)

func test_start_plot_is_idempotent():
	_plot.start_plot()
	var time_after_first := ClockManager.current_time
	_plot.start_plot()
	assert_eq(ClockManager.current_time, time_after_first,
		"a second start_plot must not re-charge the clock")

func test_visuals_swap_with_state():
	assert_true(_plot.get_node("EmptyVisual").visible)
	assert_false(_plot.get_node("GrowingVisual").visible)
	_plot.start_plot()
	assert_false(_plot.get_node("EmptyVisual").visible)
	assert_true(_plot.get_node("GrowingVisual").visible)

func test_restores_growing_state_from_the_flag_on_ready():
	GameState.set_flag("plot_rations_growing", true)
	var restored = load(PLOT_3D).instantiate()
	add_child_autofree(restored)
	assert_eq(restored.get_plot_state(), restored.PlotState.GROWING)
	assert_true(restored.get_node("GrowingVisual").visible)

func test_exposes_the_action_menu_duck_typed_surface():
	# scripts/ui/action_menu.gd reads these two properties and calls start_plot().
	assert_eq(_plot.resource_id, "rations")
	assert_eq(typeof(_plot.yield_amount), TYPE_INT)
	assert_true(_plot.has_method("start_plot"))
	assert_true(_plot.has_method("interact"))
