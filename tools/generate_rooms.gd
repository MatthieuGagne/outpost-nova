# tools/generate_rooms.gd
# Run via Godot Script Editor: File → Run (or Ctrl+Shift+X)
@tool
extends EditorScript

const ROOM_W: int = 30
const ROOM_H: int = 16
const TILE_SOURCE_ID: int = 0
const TILESET_PATH: String = "res://data/tilesets/station.tres"

# ⚠ UPDATE THESE after importing your tileset in Task 8
# Open station.tres in the TileSet editor, hover tiles to read their atlas coords
const FLOOR_ATLAS: Vector2i = Vector2i(0, 0)  # <-- set to your floor tile
const WALL_ATLAS: Vector2i  = Vector2i(1, 0)  # <-- set to your wall tile

func _run() -> void:
	var tileset = load(TILESET_PATH)
	if not tileset:
		push_error("station.tres not found at: " + TILESET_PATH)
		return

	_process_area(
		"res://scenes/areas/cantina.tscn",
		tileset,
		{"right_door": true, "left_door": false},
		{
			"EngineeringDoor": Vector2(472, 128),
			"MarisSpawn":      Vector2(120, 128),
			"SableSpawn":      Vector2(240, 128),
			"RationsNode":     Vector2(80, 80),
		}
	)

	_process_area(
		"res://scenes/areas/engineering.tscn",
		tileset,
		{"right_door": true, "left_door": true},
		{
			"CantinaDoor":  Vector2(8, 128),
			"QuartersDoor": Vector2(472, 128),
			"DexSpawn":     Vector2(300, 128),
			"Workbench":    Vector2(240, 128),
			"PartsNode":    Vector2(80, 80),
			"EnergyNode":   Vector2(80, 176),
		}
	)

	_process_area(
		"res://scenes/areas/quarters.tscn",
		tileset,
		{"right_door": false, "left_door": true},
		{
			"EngineeringDoor": Vector2(8, 128),
			"PlayerBunk":      Vector2(240, 128),
		}
	)

	_process_area(
		"res://scenes/areas/derelict_entrance.tscn",
		tileset,
		{"right_door": false, "left_door": true},
		{
			"EngineeringDoor": Vector2(8, 128),
			"EntranceTrigger": Vector2(240, 128),
			"DoorVisual":      Vector2(240, 128),
			"DoorLabel":       Vector2(170, 100),
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
	var layout: Array = _make_layout(doors.get("right_door", false), doors.get("left_door", false))
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

func _make_layout(right_door: bool, left_door: bool) -> Array:
	# Returns a ROOM_H × ROOM_W array: 1 = wall tile, 0 = floor tile
	# Door gaps: 3 tiles tall at y=6, 7, 8 on left/right walls
	var layout: Array = []
	for y in ROOM_H:
		var row: Array = []
		for x in ROOM_W:
			var is_wall: bool = false
			if y == 0 or y == ROOM_H - 1:
				is_wall = true
			elif x == 0:
				is_wall = not (left_door and y >= 6 and y <= 8)
			elif x == ROOM_W - 1:
				is_wall = not (right_door and y >= 6 and y <= 8)
			row.append(1 if is_wall else 0)
		layout.append(row)
	return layout
