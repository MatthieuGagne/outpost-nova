# tools/fix_oob_tiles.gd
@tool
extends EditorScript

const DRY_RUN := true  # set false to apply fixes

const AREA_SCENES := [
	"res://scenes/areas/cantina.tscn",
	"res://scenes/areas/workshop.tscn",
	"res://scenes/areas/security_post.tscn",
	"res://scenes/areas/med_bay.tscn",
	"res://scenes/areas/quarters.tscn",
	"res://scenes/areas/derelict_entrance.tscn",
]

func _run() -> void:
	print("=== fix_oob_tiles — DRY_RUN=%s ===" % DRY_RUN)
	for path in AREA_SCENES:
		_process_scene(path)
	print("=== done ===")

func _process_scene(path: String) -> void:
	var packed := load(path) as PackedScene
	var root := packed.instantiate()
	var found := _scan_node(root, path)
	if found > 0 and not DRY_RUN:
		var new_packed := PackedScene.new()
		new_packed.pack(root)
		ResourceSaver.save(new_packed, path)
		print("[SAVED] %s (%d cells removed)" % [path, found])
	elif found == 0:
		print("[CLEAN] %s" % path)
	root.queue_free()

func _scan_node(node: Node, path: String) -> int:
	var count := 0
	if node is TileMapLayer:
		var layer := node as TileMapLayer
		for cell_pos in layer.get_used_cells():
			var atlas := layer.get_cell_atlas_coords(cell_pos)
			if atlas.x >= 57:
				var verb := "ERASE" if not DRY_RUN else "WOULD ERASE"
				print("  [%s] %s | node=%s | cell=%s | atlas=%s" % [
					verb, path, layer.get_path(), cell_pos, atlas
				])
				if not DRY_RUN:
					layer.erase_cell(cell_pos)
				count += 1
	for child in node.get_children():
		count += _scan_node(child, path)
	return count
