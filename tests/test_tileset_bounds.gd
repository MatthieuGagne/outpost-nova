extends GutTest

# Every .tres in this directory is checked, so adding a second tileset later
# needs no change to this test.
const TILESET_DIR := "res://data/tilesets"

# TileSetAtlasSource omits these keys from the .tres when they match the engine
# default, so an absent key means "default", not "zero". Values are the Godot 4
# documented defaults for TileSetAtlasSource.texture_region_size / .separation.
const GODOT_DEFAULT_REGION_SIZE := Vector2i(16, 16)
const GODOT_DEFAULT_SEPARATION := Vector2i(0, 0)
const GODOT_DEFAULT_MARGINS := Vector2i(0, 0)

# Known limits of this text-based parser, accepted for now because nothing in
# this repo triggers them:
#
# - Multiple atlas sources: a TileSet can hold several
#   [sub_resource type="TileSetAtlasSource"] blocks, each with its own texture,
#   separation, margins and texture_region_size. This parser takes the FIRST
#   match of each of those properties but collects tile coordinates from EVERY
#   source into one set, so a second source's coordinates would be judged
#   against the first source's grid. A correct fix would split the lines into
#   per-sub_resource blocks and return one report per source, then loop over
#   reports instead of files.
# - Full coverage is a project convention, not an engine requirement. Godot
#   does not require a tileset to declare every cell of its sheet — a partial
#   tileset carved from a larger public sheet is perfectly legal.
#   test_all_valid_cells_declared encodes this project's choice that
#   station.tres should expose its whole sheet. Because the tests glob every
#   .tres in the directory, the first deliberately-partial tileset added here
#   will fail that test without being defective, and will need an opt-out.
# - size_in_atlas multi-cell tiles: a tile declared at (0,0) with
#   size_in_atlas = Vector2i(2,1) occupies (0,0) and (1,0) but this parser
#   only records its origin coordinate. That would show as a false
#   "undeclared cell" in the coverage test, and such a tile in the last
#   column could overrun the texture edge without the bounds test noticing.


func _tileset_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	for file_name in DirAccess.get_files_at(TILESET_DIR):
		if file_name.ends_with(".tres"):
			paths.append("%s/%s" % [TILESET_DIR, file_name])
	assert_gt(paths.size(), 0, "no .tres tilesets found under %s" % TILESET_DIR)
	return paths


func _read_lines(path: String) -> PackedStringArray:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		fail_test("could not open %s" % path)
		return PackedStringArray()
	var text := file.get_as_text()
	file.close()
	return text.split("\n")


func _parse_vector2i(lines: PackedStringArray, key: String, fallback: Vector2i) -> Vector2i:
	var re := RegEx.new()
	re.compile("^%s *= *Vector2i\\( *(-?\\d+) *, *(-?\\d+) *\\)$" % key)
	for line in lines:
		var found := re.search(line.strip_edges())
		if found != null:
			return Vector2i(found.get_string(1).to_int(), found.get_string(2).to_int())
	return fallback


func _parse_texture_size(lines: PackedStringArray, path: String) -> Vector2i:
	# Only the PNG is loaded here, never the tileset itself: loading the .tres
	# would let Godot drop the out-of-bounds tiles before we could see them.
	var re := RegEx.new()
	re.compile("^\\[ext_resource type=\"Texture2D\".*path=\"([^\"]+)\"")
	for line in lines:
		var found := re.search(line)
		if found != null:
			var texture: Texture2D = load(found.get_string(1))
			if texture != null:
				return Vector2i(texture.get_size())
	fail_test("no loadable Texture2D ext_resource found in %s" % path)
	return Vector2i.ZERO


func _parse_declared_coords(lines: PackedStringArray) -> Dictionary:
	# Tile entries look like "12:30/0 = 0"; per-tile property lines reuse the
	# same "<col>:<row>/" prefix, so match the prefix only and de-duplicate.
	var re := RegEx.new()
	re.compile("^(\\d+):(\\d+)/")
	var coords := {}
	for line in lines:
		var found := re.search(line)
		if found != null:
			coords[Vector2i(found.get_string(1).to_int(), found.get_string(2).to_int())] = true
	return coords


func _grid_size(texture_size: Vector2i, region_size: Vector2i, separation: Vector2i, margins: Vector2i) -> Vector2i:
	# Tile (c, r) starts at margin + c * (region + separation) and spans region
	# px, so the last valid index is floor((texture - margins - region) / stride).
	var stride := region_size + separation
	if stride.x <= 0 or stride.y <= 0:
		fail_test("non-positive atlas stride %s" % stride)
		return Vector2i.ZERO
	var usable := texture_size - margins
	var cols := 0 if usable.x < region_size.x else (usable.x - region_size.x) / stride.x + 1
	var rows := 0 if usable.y < region_size.y else (usable.y - region_size.y) / stride.y + 1
	return Vector2i(cols, rows)


func _atlas_report(path: String) -> Dictionary:
	var lines := _read_lines(path)
	var texture_size := _parse_texture_size(lines, path)
	var region_size := _parse_vector2i(lines, "texture_region_size", GODOT_DEFAULT_REGION_SIZE)
	var separation := _parse_vector2i(lines, "separation", GODOT_DEFAULT_SEPARATION)
	var margins := _parse_vector2i(lines, "margins", GODOT_DEFAULT_MARGINS)
	return {
		"path": path,
		"texture_size": texture_size,
		"region_size": region_size,
		"separation": separation,
		"margins": margins,
		"grid": _grid_size(texture_size, region_size, separation, margins),
		"coords": _parse_declared_coords(lines),
	}


func test_no_tiles_outside_texture():
	for path in _tileset_paths():
		var atlas := _atlas_report(path)
		var grid: Vector2i = atlas["grid"]
		var outside: Array[Vector2i] = []
		for coord in atlas["coords"]:
			if coord.x < 0 or coord.y < 0 or coord.x >= grid.x or coord.y >= grid.y:
				outside.append(coord)
		outside.sort()
		assert_eq(outside.size(), 0,
			"%s declares %d tile(s) outside the %d x %d atlas grid (texture %s, region %s, separation %s): %s"
			% [path, outside.size(), grid.x, grid.y,
				atlas["texture_size"], atlas["region_size"], atlas["separation"], outside])


func test_all_valid_cells_declared():
	for path in _tileset_paths():
		var atlas := _atlas_report(path)
		var grid: Vector2i = atlas["grid"]
		var declared: Dictionary = atlas["coords"]
		var missing: Array[Vector2i] = []
		for row in grid.y:
			for col in grid.x:
				var coord := Vector2i(col, row)
				if not declared.has(coord):
					missing.append(coord)
		assert_eq(missing.size(), 0,
			"%s leaves %d of %d valid atlas cell(s) undeclared, so that artwork cannot be painted: %s"
			% [path, missing.size(), grid.x * grid.y, missing])
