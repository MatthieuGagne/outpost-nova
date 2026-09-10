# scripts/main.gd
extends Node2D

const AREA_SCENES = {
	"trade_dock":        {"scene": "res://scenes/areas/trade_dock.tscn", "presentation": "2d"},
	"cantina":           {"scene": "res://scenes/areas/cantina.tscn", "presentation": "2d"},
	"workshop":          {"scene": "res://scenes/areas/workshop.tscn", "presentation": "2d"},
	"quarters":          {"scene": "res://scenes/areas/quarters.tscn", "presentation": "2d"},
	"security_post":     {"scene": "res://scenes/areas/security_post.tscn", "presentation": "2d"},
	"med_bay":           {"scene": "res://scenes/areas/med_bay.tscn", "presentation": "2d"},
	"derelict_entrance": {"scene": "res://scenes/areas/derelict_entrance.tscn", "presentation": "2d"},
}

const NPC_SPAWN_AREAS = {
	"maris":   "cantina",
	"quen":    "security_post",
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
@onready var world3d: SubViewportContainer = $World3D
@onready var area3d: Node3D = $World3D/SubViewport/Area3D
@onready var player3d: CharacterBody3D = $World3D/SubViewport/Area3D/Player3D
@onready var hud = $HUD
@onready var day_summary = $DaySummary
@onready var crafting_panel = $CraftingPanel
@onready var fade_anim: AnimationPlayer = $FadeLayer/AnimationPlayer

var _current_area_id: String = ""
var _current_area: Node = null
var _npc_instances: Dictionary = {}
var _is_transitioning: bool = false

func _ready() -> void:
	ClockManager.day_ended.connect(_on_day_ended)
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
	# Yarn functions are registered explicitly rather than relying on the
	# YarnSpinner source generator, which Windows Application Control can block.
	var yarn_functions = load("res://scripts/YarnGameState.cs").new()
	yarn_functions.Register(runners[0])

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

	var entry: Dictionary = AREA_SCENES[area_id]
	if entry["presentation"] == "3d":
		_enter_3d(area_id, prev)
	else:
		_enter_2d(area_id, prev)
	_current_area_id = area_id

	fade_anim.play("fade_in")
	await fade_anim.animation_finished
	_is_transitioning = false
	get_viewport().gui_release_focus()

func _enter_2d(area_id: String, prev: String) -> void:
	_set_presentation("2d")
	var positions = AREA_ENTRY_POSITIONS.get(area_id, {})
	player.position = positions.get(prev, positions.get("default", Vector2(240, 128)))
	var scene = load(AREA_SCENES[area_id]["scene"])
	_current_area = scene.instantiate()
	area_container.add_child(_current_area)
	area_container.move_child(_current_area, 0)
	for npc_id in _npc_instances:
		var npc = _npc_instances[npc_id]
		var spawn_area = NPC_SPAWN_AREAS.get(npc_id, "cantina")
		var in_area = (spawn_area == area_id)
		if npc_id == "sable":
			npc.visible = in_area and GameState.get_flag("sable_arrived")
		else:
			npc.visible = in_area
		if npc.visible:
			var spawn = _current_area.find_child("%sSpawn" % npc_id.capitalize(), true, false)
			if spawn:
				npc.position = spawn.global_position
			if npc.has_method("_pick_wander_target"):
				npc._pick_wander_target()


func _enter_3d(area_id: String, prev: String) -> void:
	_set_presentation("3d")
	var scene = load(AREA_SCENES[area_id]["scene"])
	_current_area = scene.instantiate()
	area3d.add_child(_current_area)
	var marker := _find_3d_entry_marker(_current_area, prev, area_id)
	if marker != null:
		player3d.global_position = marker.global_position


func _find_3d_entry_marker(room: Node, prev: String, area_id: String) -> Node3D:
	var marker := room.find_child(AreaEntry.marker_name(prev), false, false)
	if marker == null:
		marker = room.find_child("DefaultSpawn", false, false)
	if marker == null:
		push_error("main: 3D room '%s' has no '%s' or 'DefaultSpawn' marker" % [area_id, AreaEntry.marker_name(prev)])
	return marker


func _set_presentation(presentation: String) -> void:
	if presentation == "3d":
		area_container.visible = false
		world3d.visible = true
		player.velocity = Vector2.ZERO
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.get_node("Camera2D").enabled = false
		player3d.velocity = Vector3.ZERO
		player3d.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		area_container.visible = true
		world3d.visible = false
		player3d.velocity = Vector3.ZERO
		player3d.process_mode = Node.PROCESS_MODE_DISABLED
		player.velocity = Vector2.ZERO
		player.process_mode = Node.PROCESS_MODE_INHERIT
		player.get_node("Camera2D").enabled = true

func open_crafting() -> void:
	crafting_panel.open()

func advance_day() -> void:
	day_summary.show_summary()

func show_hud_message(text: String) -> void:
	hud.show_message(text)

func _on_day_ended(_day: int) -> void:
	day_summary.show_summary()
