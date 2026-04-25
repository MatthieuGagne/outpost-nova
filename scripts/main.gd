# scripts/main.gd
extends Node2D

const AREA_SCENES = {
	"trade_dock":        "res://scenes/areas/trade_dock.tscn",
	"cantina":           "res://scenes/areas/cantina.tscn",
	"workshop":          "res://scenes/areas/workshop.tscn",
	"quarters":          "res://scenes/areas/quarters.tscn",
	"security_post":     "res://scenes/areas/security_post.tscn",
	"med_bay":           "res://scenes/areas/med_bay.tscn",
	"derelict_entrance": "res://scenes/areas/derelict_entrance.tscn",
}

const NPC_SPAWN_AREAS = {
	"maris":   "cantina",
	"quen":    "cantina",
	"dex":     "workshop",
	"velreth": "med_bay",
	"sable":   "trade_dock",
}

# Entry spawn positions per area, keyed by the previous area.
# Left wall entry: x=32, right wall entry: x=448, top wall entry: y=32, bottom wall entry: y=224
const AREA_ENTRY_POSITIONS = {
	"trade_dock": {
		"cantina":           Vector2(32, 128),   # cantina bottom → trade_dock left
		"security_post":     Vector2(448, 128),  # security_post bottom → trade_dock right
		"derelict_entrance": Vector2(240, 200),
		"default":           Vector2(240, 128),
	},
	"cantina": {
		"workshop":      Vector2(32, 128),   # workshop right → cantina left
		"security_post": Vector2(448, 128),  # security_post left → cantina right
		"quarters":      Vector2(240, 32),   # quarters bottom → cantina top
		"trade_dock":    Vector2(240, 224),  # trade_dock left → cantina bottom
		"default":       Vector2(240, 128),
	},
	"workshop": {
		"cantina": Vector2(448, 128),
		"default": Vector2(240, 128),
	},
	"quarters": {
		"cantina": Vector2(240, 224),
		"default": Vector2(240, 128),
	},
	"security_post": {
		"cantina":    Vector2(32, 128),   # cantina right → security_post left
		"med_bay":    Vector2(448, 128),  # med_bay left → security_post right
		"trade_dock": Vector2(240, 224),  # trade_dock right → security_post bottom
		"default":    Vector2(240, 128),
	},
	"med_bay": {
		"security_post": Vector2(32, 128),
		"default":       Vector2(240, 128),
	},
	"derelict_entrance": {
		"trade_dock": Vector2(32, 128),
		"default":    Vector2(240, 128),
	},
}

@onready var area_container: Node2D = $AreaContainer
@onready var player: CharacterBody2D = $AreaContainer/Player
@onready var hud = $HUD
@onready var day_summary = $DaySummary
@onready var crafting_panel = $CraftingPanel
@onready var arc_events = $ArcEvents
@onready var fade_anim: AnimationPlayer = $FadeLayer/AnimationPlayer

var _current_area_id: String = ""
var _current_area: Node = null
var _npc_instances: Dictionary = {}
var _is_transitioning: bool = false

func _ready() -> void:
	DayManager.day_ended.connect(_on_day_ended)
	DayManager.all_beats_done.connect(_on_all_beats_done)
	_setup_dialogue_runner()
	_spawn_npcs()
	go_to_area("trade_dock")
	get_viewport().gui_release_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()

func _setup_dialogue_runner() -> void:
	var runners := get_tree().get_nodes_in_group("dialogue_runner")
	if runners.is_empty():
		push_error("main: no dialogue_runner in scene")
		return
	var project := load("res://data/dialogue/outpost-nova.yarnproject")
	runners[0].SetProject(project)

func _spawn_npcs() -> void:
	var npc_scripts = {
		"maris":   "res://scripts/characters/maris.gd",
		"quen":    "res://scripts/characters/quen.gd",
		"dex":     "res://scripts/characters/dex.gd",
		"velreth": "res://scripts/characters/velreth.gd",
		"sable":   "res://scripts/characters/sable.gd",
	}
	for npc_id in npc_scripts:
		var base = load("res://scenes/characters/npc_base.tscn").instantiate()
		base.set_script(load(npc_scripts[npc_id]))
		area_container.add_child(base)
		_npc_instances[npc_id] = base

func go_to_area(area_id: String) -> void:
	if _current_area_id == area_id or _is_transitioning:
		return
	_is_transitioning = true
	var prev = _current_area_id

	fade_anim.play("fade_out")
	await fade_anim.animation_finished

	if _current_area:
		_current_area.queue_free()
		_current_area = null

	var positions = AREA_ENTRY_POSITIONS.get(area_id, {})
	player.position = positions.get(prev, positions.get("default", Vector2(240, 128)))

	var scene = load(AREA_SCENES[area_id])
	_current_area = scene.instantiate()
	area_container.add_child(_current_area)
	area_container.move_child(_current_area, 0)
	_current_area_id = area_id

	for npc_id in _npc_instances:
		var npc = _npc_instances[npc_id]
		var spawn_area = NPC_SPAWN_AREAS.get(npc_id, "cantina")
		var in_area = (spawn_area == area_id)
		if npc_id == "sable":
			npc.visible = in_area and GameState.get_flag("sable_arrived")
		else:
			npc.visible = in_area
		if npc.visible:
			var spawn = _current_area.get_node_or_null("%sSpawn" % npc_id.capitalize())
			if spawn:
				npc.position = spawn.global_position
			if npc.has_method("_pick_wander_target"):
				npc._pick_wander_target()

	fade_anim.play("fade_in")
	await fade_anim.animation_finished
	_is_transitioning = false
	get_viewport().gui_release_focus()

func open_crafting() -> void:
	crafting_panel.open()

func advance_day() -> void:
	day_summary.show_summary()

func show_hud_message(text: String) -> void:
	hud.show_message(text)

func _on_day_ended(day: int) -> void:
	if day == 7:
		_show_ending()
	else:
		if DayManager.current_day == 7:
			arc_events.trigger_final_choice()
		else:
			show_hud_message("Day %d begins." % DayManager.current_day)

func _on_all_beats_done() -> void:
	show_hud_message("All story beats complete. Rest at your bunk in Quarters.")

func _show_ending() -> void:
	if GameState.get_flag("ending_pragmatic"):
		get_tree().change_scene_to_file("res://scenes/ui/ending_pragmatic.tscn")
	elif GameState.get_flag("ending_hopeful"):
		get_tree().change_scene_to_file("res://scenes/ui/ending_hopeful.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/ending_deferred.tscn")
