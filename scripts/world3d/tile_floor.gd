@tool
class_name TileFloor
extends MeshInstance3D

## A flat floor built as ONE ArrayMesh of 1x1-world-unit quads, every quad's UVs
## addressing the same 16x16 region of the shared roguelike tile sheet.
##
## Why not one MeshInstance3D per tile with an AtlasTexture: the sheet has 1px
## separation between tiles, and Godot's UV repeat repeats the whole texture,
## not a region — so a tiled AtlasTexture would smear the neighbouring tiles in.
## Writing the UVs directly sidesteps that and keeps the floor at one draw call.
##
## @tool so the editor viewport shows the true texel density while the room's
## camera angle is being hand-authored (issue #101, R6).

## Floor extent in tiles. One tile is one world unit.
@export var tiles := Vector2i(12, 12):
	set(value):
		tiles = Vector2i(maxi(1, value.x), maxi(1, value.y))
		_rebuild()

@export var tile_col := 5:
	set(value):
		tile_col = clampi(value, 0, maxi(0, WorldScale.tile_grid_size().x - 1))
		_rebuild()

@export var tile_row := 0:
	set(value):
		tile_row = clampi(value, 0, maxi(0, WorldScale.tile_grid_size().y - 1))
		_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	mesh = _build_mesh()
	material_override = _build_material()


func _build_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(WorldScale.SHEET_PATH)
	# Explicit: rendering/textures/canvas_textures/default_texture_filter is a
	# 2D-only project setting and does not reach 3D materials.
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.texture_repeat = false
	return material


func _build_mesh() -> ArrayMesh:
	var uv := WorldScale.tile_uv_rect(tile_col, tile_row)
	var origin := Vector3(-tiles.x * 0.5, 0.0, -tiles.y * 0.5)

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3.UP)

	for row in tiles.y:
		for col in tiles.x:
			var x0 := origin.x + col
			var z0 := origin.z + row
			var x1 := x0 + 1.0
			var z1 := z0 + 1.0

			# Godot treats CLOCKWISE winding as the front face. Viewed from +Y
			# with +X to the right, a -> b -> c below reads clockwise, so the
			# floor faces up.
			var a := Vector3(x0, 0.0, z0)
			var b := Vector3(x1, 0.0, z0)
			var c := Vector3(x1, 0.0, z1)
			var d := Vector3(x0, 0.0, z1)

			var uv_a := uv.position
			var uv_b := Vector2(uv.end.x, uv.position.y)
			var uv_c := uv.end
			var uv_d := Vector2(uv.position.x, uv.end.y)

			_add_triangle(surface, a, b, c, uv_a, uv_b, uv_c)
			_add_triangle(surface, a, c, d, uv_a, uv_c, uv_d)

	return surface.commit()


func _add_triangle(surface: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3,
		uv0: Vector2, uv1: Vector2, uv2: Vector2) -> void:
	surface.set_uv(uv0)
	surface.add_vertex(p0)
	surface.set_uv(uv1)
	surface.add_vertex(p1)
	surface.set_uv(uv2)
	surface.add_vertex(p2)
