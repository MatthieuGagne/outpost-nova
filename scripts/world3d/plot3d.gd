class_name Plot3D
extends Area3D

## The 3D production plot (issue #130 R2).
##
## A direct port of scripts/resource_node.gd: same state machine, same flag key, same clock
## cost, same duck-typed surface (resource_id / yield_amount / start_plot) that the
## unmodified 2D scripts/ui/action_menu.gd consumes. Only the presentation differs — two
## MeshInstance3D children swap in place of the 2D ColorRect.
##
## The root is an Area3D, not a Node3D + InteractTarget child, so it lands directly in
## Player3D's get_overlapping_areas() scan and satisfies R2's "in the interactable group"
## the same literal way the 2D plot does.
##
## start_plot deliberately grants NO resources. The 2D plot never did, and AC2 forbids
## introducing an economy change here — the plot is planted now and harvested later.

enum PlotState { EMPTY, GROWING }

signal plot_state_changed(new_state: PlotState)

const FLAG_FORMAT := "plot_%s_growing"
const START_COST_MINUTES := 90
const LOG_FORMAT := "Started %s plot"
const ALREADY_GROWING_MESSAGE := "Plot is already growing."
const ACTION_MENU_GROUP := "action_menu"

@export var resource_id := "rations"
@export var yield_amount := 1

@onready var _empty_visual: MeshInstance3D = $EmptyVisual
@onready var _growing_visual: MeshInstance3D = $GrowingVisual

var _state: PlotState = PlotState.EMPTY


func _ready() -> void:
	add_to_group(InteractScan.INTERACTABLE_GROUP)
	if GameState.get_flag(FLAG_FORMAT % resource_id):
		_state = PlotState.GROWING
	_apply_visual()


func interact() -> void:
	if _state == PlotState.GROWING:
		var main := get_tree().get_root().get_node_or_null("Main")
		if main != null:
			main.show_hud_message(ALREADY_GROWING_MESSAGE)
		return
	var menus := get_tree().get_nodes_in_group(ACTION_MENU_GROUP)
	if menus.is_empty():
		return
	menus[0].show_for_plot(self)


func start_plot() -> void:
	if _state != PlotState.EMPTY:
		return
	_state = PlotState.GROWING
	_apply_visual()
	GameState.set_flag(FLAG_FORMAT % resource_id, true)
	ClockManager.commit_action(START_COST_MINUTES)
	ClockManager.log_action(LOG_FORMAT % resource_id)
	plot_state_changed.emit(_state)


func get_plot_state() -> PlotState:
	return _state


func _apply_visual() -> void:
	_empty_visual.visible = _state == PlotState.EMPTY
	_growing_visual.visible = _state == PlotState.GROWING
