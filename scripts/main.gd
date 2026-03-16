# scripts/main.gd
extends Node2D

const AREA_SCENES = {
	"cantina": "res://scenes/areas/cantina.tscn",
	"engineering": "res://scenes/areas/engineering.tscn",
	"quarters": "res://scenes/areas/quarters.tscn",
	"derelict_entrance": "res://scenes/areas/derelict_entrance.tscn",
}

const NPC_SPAWN_AREAS = {
	"maris": "cantina",
	"sable": "cantina",
	"dex": "engineering",
}

@onready var area_container: Node2D = $AreaContainer
@onready var player: CharacterBody2D = $Player
@onready var hud = $HUD
@onready var day_summary = $DaySummary
@onready var crafting_panel = $CraftingPanel
@onready var arc_events = $ArcEvents

var _current_area_id: String = ""
var _npc_instances: Dictionary = {}

# Spawn position when entering area_id coming from prev_area_id
const AREA_ENTRY_POSITIONS = {
	"cantina": { "engineering": Vector2(270, 90), "default": Vector2(160, 90) },
	"engineering": { "cantina": Vector2(50, 90), "quarters": Vector2(270, 90), "default": Vector2(160, 90) },
	"quarters": { "engineering": Vector2(50, 90), "default": Vector2(160, 90) },
	"derelict_entrance": { "engineering": Vector2(50, 90), "default": Vector2(160, 90) },
}

func _ready() -> void:
	DayManager.day_ended.connect(_on_day_ended)
	DayManager.all_beats_done.connect(_on_all_beats_done)
	_spawn_npcs()
	go_to_area("cantina")

func go_to_area(area_id: String) -> void:
	if _current_area_id == area_id:
		return
	var prev = _current_area_id
	for child in area_container.get_children():
		child.queue_free()
	var scene = load(AREA_SCENES[area_id])
	var area = scene.instantiate()
	area_container.add_child(area)
	_current_area_id = area_id
	# Move player to the door they came through
	var positions = AREA_ENTRY_POSITIONS.get(area_id, {})
	player.position = positions.get(prev, positions.get("default", Vector2(160, 90)))
	# Show/hide NPCs that belong in this area
	for npc_id in _npc_instances:
		var npc = _npc_instances[npc_id]
		var spawn_area = NPC_SPAWN_AREAS.get(npc_id, "cantina")
		npc.visible = (spawn_area == area_id)
		if spawn_area == area_id:
			var spawn = area.get_node_or_null("%sSpawn" % npc_id.capitalize())
			if spawn:
				npc.position = spawn.global_position
				npc._pick_wander_target()

func _spawn_npcs() -> void:
	var npc_scripts = {
		"maris": "res://scripts/characters/maris.gd",
		"sable": "res://scripts/characters/sable.gd",
		"dex": "res://scripts/characters/dex.gd",
	}
	for npc_id in npc_scripts:
		var base = load("res://scenes/characters/npc_base.tscn").instantiate()
		base.set_script(load(npc_scripts[npc_id]))
		add_child(base)
		_npc_instances[npc_id] = base

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
		# Trigger final choice overlay when day 7 starts
		if DayManager.current_day == 7:
			arc_events.trigger_final_choice()

func _on_all_beats_done() -> void:
	show_hud_message("All story beats complete. Rest at your bunk in Quarters.")

func _show_ending() -> void:
	if GameState.get_flag("ending_pragmatic"):
		get_tree().change_scene_to_file("res://scenes/ui/ending_pragmatic.tscn")
	elif GameState.get_flag("ending_hopeful"):
		get_tree().change_scene_to_file("res://scenes/ui/ending_hopeful.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/ending_deferred.tscn")
