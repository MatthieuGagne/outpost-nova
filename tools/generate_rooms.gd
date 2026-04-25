# tools/generate_rooms.gd
# Run via Godot Script Editor: File → Run (or Ctrl+Shift+X)
@tool
extends EditorScript

const ROOM_W: int = 30
const ROOM_H: int = 16
const TILE_SOURCE_ID: int = 0
const TILESET_PATH: String = "res://data/tilesets/station.tres"

const FLOOR_ATLAS: Vector2i = Vector2i(18, 15)
const WALL_ATLAS: Vector2i  = Vector2i(25, 15)

func _run() -> void:
	var tileset = load(TILESET_PATH)
	if not tileset:
		push_error("station.tres not found at: " + TILESET_PATH)
		return

	# Workshop — right wall → Cantina (only door)
	_process_area(
		"res://scenes/areas/workshop.tscn",
		tileset,
		{"right_door": true, "left_door": false},
		{
			"CantinaDoor": Vector2(472, 128),
			"DexSpawn":    Vector2(300, 128),
			"Workbench":   Vector2(240, 128),
			"PartsNode":   Vector2(80, 80),
			"EnergyNode":  Vector2(80, 176),
		}
	)

	# Cantina — 4-way hub
	_process_area(
		"res://scenes/areas/cantina.tscn",
		tileset,
		{"left_door": true, "right_door": true, "top_door": true, "bottom_door": true},
		{
			"WorkshopDoor":     Vector2(8, 128),
			"SecurityPostDoor": Vector2(472, 128),
			"QuartersDoor":     Vector2(240, 8),
			"TradeDockDoor":    Vector2(240, 248),
			"MarisSpawn":       Vector2(120, 128),
			"QuenSpawn":        Vector2(360, 128),
			"RationsNode":      Vector2(80, 80),
		}
	)

	# Quarters — bottom door only → Cantina
	_process_area(
		"res://scenes/areas/quarters.tscn",
		tileset,
		{"bottom_door": true},
		{
			"CantinaBottomDoor": Vector2(240, 248),
			"PlayerBunk":        Vector2(240, 128),
		}
	)

	# Derelict Entrance — left door → Trade Dock
	_process_area(
		"res://scenes/areas/derelict_entrance.tscn",
		tileset,
		{"left_door": true},
		{
			"TradeDockDoor":   Vector2(8, 128),
			"EntranceTrigger": Vector2(240, 128),
			"DoorVisual":      Vector2(240, 128),
			"DoorLabel":       Vector2(170, 100),
		}
	)

	# Trade Dock — left→Cantina, right→Security Post; bottom prop door (no tile gap)
	_process_area(
		"res://scenes/areas/trade_dock.tscn",
		tileset,
		{"left_door": true, "right_door": true},
		{
			"CantinaExitDoor":  Vector2(8, 128),
			"SecurityPostDoor": Vector2(472, 128),
			"SableSpawn":       Vector2(240, 128),
			"SpinePropTrigger": Vector2(240, 200),
			"SpineDoorLabel":   Vector2(170, 175),
		}
	)

	# Security Post — left→Cantina, right→Med Bay, bottom→Trade Dock
	_process_area(
		"res://scenes/areas/security_post.tscn",
		tileset,
		{"left_door": true, "right_door": true, "bottom_door": true},
		{
			"CantinaDoor":   Vector2(8, 128),
			"MedBayDoor":    Vector2(472, 128),
			"TradeDockDoor": Vector2(240, 248),
		}
	)

	# Med Bay — left door only → Security Post (dead end)
	_process_area(
		"res://scenes/areas/med_bay.tscn",
		tileset,
		{"left_door": true},
		{
			"SecurityPostDoor": Vector2(8, 128),
			"VelrethSpawn":     Vector2(300, 128),
		}
	)

	print("✓ Room generation complete.")

func _process_area(
	scene_path: String,
	tileset: TileSet,
	doors: Dictionary,
	node_positions: Dictionary
) -> void:
	var packed: PackedScene = load(scene_path)
	var scene: Node = packed.instantiate()

	# Remove old Polygon2D floor and StaticBody2D walls
	for old_name in ["Floor", "Walls"]:
		var old: Node = scene.get_node_or_null(old_name)
		if old:
			scene.remove_child(old)
			old.free()

	# Remove existing TileMapLayer if regenerating
	var existing_tm: Node = scene.get_node_or_null("TileMapLayer")
	if existing_tm:
		scene.remove_child(existing_tm)
		existing_tm.free()

	# Create and configure TileMapLayer
	var tilemap: TileMapLayer = TileMapLayer.new()
	tilemap.name = "TileMapLayer"
	tilemap.tile_set = tileset
	scene.add_child(tilemap)
	tilemap.owner = scene
	scene.move_child(tilemap, 0)  # Render behind all other nodes

	# Paint tiles from layout
	var layout: Array = _make_layout(
		doors.get("right_door", false),
		doors.get("left_door", false),
		doors.get("top_door", false),
		doors.get("bottom_door", false)
	)
	for y in ROOM_H:
		for x in ROOM_W:
			var atlas: Vector2i = WALL_ATLAS if layout[y][x] == 1 else FLOOR_ATLAS
			tilemap.set_cell(Vector2i(x, y), TILE_SOURCE_ID, atlas)

	# Update node positions (doors, spawns, props)
	for node_name in node_positions:
		var node: Node = scene.find_child(node_name, true, false)
		if node and node.has_method("set") and "position" in node:
			node.position = node_positions[node_name]
		elif node:
			push_warning("Node '%s' found but has no position property" % node_name)
		else:
			push_warning("Node '%s' not found in %s" % [node_name, scene_path])

	# Save scene
	var new_packed: PackedScene = PackedScene.new()
	new_packed.pack(scene)
	ResourceSaver.save(new_packed, scene_path)
	scene.free()
	print("  ✓ Generated: ", scene_path)

func _make_layout(right_door: bool, left_door: bool, top_door: bool = false, bottom_door: bool = false) -> Array:
	# Returns a ROOM_H × ROOM_W array: 1 = wall tile, 0 = floor tile
	# Left/right gaps: 3 tiles tall at y=6–8
	# Top/bottom gaps: 3 tiles wide at x=13–15 (centered, no collision)
	var layout: Array = []
	for y in ROOM_H:
		var row: Array = []
		for x in ROOM_W:
			var is_wall: bool = false
			if y == 0:
				is_wall = not (top_door and x >= 13 and x <= 15)
			elif y == ROOM_H - 1:
				is_wall = not (bottom_door and x >= 13 and x <= 15)
			elif x == 0:
				is_wall = not (left_door and y >= 6 and y <= 8)
			elif x == ROOM_W - 1:
				is_wall = not (right_door and y >= 6 and y <= 8)
			row.append(1 if is_wall else 0)
		layout.append(row)
	return layout
