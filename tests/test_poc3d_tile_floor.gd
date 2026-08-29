extends GutTest

const FLOOR_TILES := Vector2i(4, 3)   # small and non-square, so a transposed
                                      # width/height bug cannot hide
const VERTS_PER_QUAD := 6             # two triangles, un-indexed
const POSITION_TOLERANCE := 0.0001
const UV_TOLERANCE := 0.000001


func _build_floor() -> TileFloor:
	var floor_node := TileFloor.new()
	floor_node.tiles = FLOOR_TILES
	add_child_autofree(floor_node)
	return floor_node


func test_mesh_has_one_surface_covering_every_tile():
	var floor_node := _build_floor()
	assert_not_null(floor_node.mesh, "TileFloor did not build a mesh")
	assert_eq(floor_node.mesh.get_surface_count(), 1,
		"the whole floor must be a single surface, so it is one draw call")
	var verts: PackedVector3Array = floor_node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_eq(verts.size(), FLOOR_TILES.x * FLOOR_TILES.y * VERTS_PER_QUAD)


func test_floor_is_one_world_unit_per_tile_and_centred_on_origin():
	var floor_node := _build_floor()
	var aabb: AABB = floor_node.mesh.get_aabb()
	assert_almost_eq(aabb.size.x, float(FLOOR_TILES.x), POSITION_TOLERANCE,
		"one tile must span exactly one world unit")
	assert_almost_eq(aabb.size.z, float(FLOOR_TILES.y), POSITION_TOLERANCE)
	assert_almost_eq(aabb.position.x, -FLOOR_TILES.x * 0.5, POSITION_TOLERANCE,
		"floor must be centred on the origin so the camera framing is predictable")
	assert_almost_eq(aabb.position.z, -FLOOR_TILES.y * 0.5, POSITION_TOLERANCE)


func test_every_uv_lies_inside_the_selected_tile_region():
	var floor_node := _build_floor()
	var expected := WorldScale.tile_uv_rect(floor_node.tile_col, floor_node.tile_row)
	var uvs: PackedVector2Array = floor_node.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	assert_gt(uvs.size(), 0, "mesh carries no UVs")
	var strays := 0
	for uv in uvs:
		if uv.x < expected.position.x - UV_TOLERANCE or uv.x > expected.end.x + UV_TOLERANCE \
				or uv.y < expected.position.y - UV_TOLERANCE or uv.y > expected.end.y + UV_TOLERANCE:
			strays += 1
	assert_eq(strays, 0,
		"%d UV(s) fall outside the tile region %s — they would sample the 1px separation gap"
		% [strays, expected])


func test_changing_the_tile_rebuilds_the_uvs():
	var floor_node := _build_floor()
	var before: PackedVector2Array = floor_node.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	floor_node.tile_col = floor_node.tile_col + 1
	var after: PackedVector2Array = floor_node.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	assert_ne(before[0], after[0], "setting tile_col must rebuild the mesh, not just store a value")


func test_material_samples_with_nearest_filtering():
	# The epic's finding #2: default_texture_filter=0 is a 2D-only setting, so a
	# 3D material that does not opt in renders pixel art smoothed.
	var floor_node := _build_floor()
	var material := floor_node.get_active_material(0) as StandardMaterial3D
	assert_not_null(material, "floor has no StandardMaterial3D")
	assert_eq(material.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST)
	assert_not_null(material.albedo_texture, "floor material has no albedo texture")


func test_out_of_bounds_tile_is_clamped_into_the_grid():
	var floor_node := _build_floor()
	var grid := WorldScale.tile_grid_size()
	floor_node.tile_col = grid.x + 10
	assert_true(WorldScale.is_tile_in_bounds(floor_node.tile_col, floor_node.tile_row),
		"tile_col must clamp into the grid rather than store an off-sheet coordinate")
