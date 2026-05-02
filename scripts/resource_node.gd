# scripts/resource_node.gd
extends Area2D

enum PlotState { EMPTY, GROWING }

signal plot_state_changed(new_state: PlotState)

@export var resource_id: String = "rations"
@export var yield_amount: int = 1

@onready var _visual: ColorRect = $ColorRect

var _state: PlotState = PlotState.EMPTY

const COLOR_EMPTY: Color = Color(0.2, 0.7, 0.2)
const COLOR_GROWING: Color = Color(0.8, 0.6, 0.1)

func _ready() -> void:
	add_to_group("interactable")
	_visual.color = COLOR_EMPTY

func interact() -> void:
	if _state == PlotState.GROWING:
		var main := get_tree().get_root().get_node_or_null("Main")
		if main:
			main.show_hud_message("Plot is already growing.")
		return
	var menus := get_tree().get_nodes_in_group("action_menu")
	if menus.is_empty():
		return
	menus[0].show_for_plot(self)

func start_plot() -> void:
	if _state != PlotState.EMPTY:
		return
	_state = PlotState.GROWING
	_visual.color = COLOR_GROWING
	ClockManager.commit_action(90)
	ClockManager.log_action("Started %s plot" % resource_id)
	plot_state_changed.emit(_state)

func get_plot_state() -> PlotState:
	return _state
