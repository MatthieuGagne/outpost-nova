@tool
class_name TileCollision
extends Node3D

## Compiles a 2D blocked-tile grid on the XZ plane into physics bodies.
##
## PRD 2 (#102). Collision for the POC rooms is AUTHORED IN 2D, like a tilemap: you list
## which tiles are solid and this node turns each one into a full-height box at _ready.
## That keeps the source of truth flat and diffable while still giving CharacterBody3D
## real bodies for move_and_slide() — a raw grid check cannot drive move_and_slide, which
## is a physics call.
##
## One tile is one world unit, matching TileFloor. Tile (i, j) covers world X in [i, i+1)
## and Z in [j, j+1).

## Name of the generated body. Tests and any future queries look it up by this.
const BODY_NAME := "GeneratedBody"

## Blocks are at most 3 units tall in the test room, and PRD 2 has no jumping or
## elevation, so a single uniform wall height is sufficient and keeps authoring flat.
const DEFAULT_WALL_HEIGHT := 3.0

## One world unit per tile — the same grid TileFloor renders on.
const TILE_EXTENT := 1.0

@export var blocked: Array[Vector2i] = []:
	set(value):
		blocked = value
		_rebuild()

## When non-zero, the boundary ring for a floor of this many tiles is generated and
## appended to `blocked` at build time. Keeps the ring in ONE place — the .tscn would
## otherwise hand-maintain 52 tiles that border_tiles() already knows how to derive.
@export var border_for_floor := Vector2i.ZERO:
	set(value):
		border_for_floor = value
		_rebuild()

@export var wall_height := DEFAULT_WALL_HEIGHT:
	set(value):
		wall_height = maxf(value, 0.01)
		_rebuild()


func _ready() -> void:
	_rebuild()


## Centre of tile (i, j) for a box of the given height resting on the floor.
static func tile_centre(tile: Vector2i, height: float) -> Vector3:
	return Vector3(
		tile.x + TILE_EXTENT * 0.5,
		height * 0.5,
		tile.y + TILE_EXTENT * 0.5)


## The ring of tiles immediately OUTSIDE a floor of the given tile dimensions, assuming
## the floor is centred on the origin the way TileFloor builds it. Placing the ring
## outside rather than on the outermost row keeps every visible tile walkable.
static func border_tiles(tiles: Vector2i) -> Array[Vector2i]:
	var min_x := -tiles.x / 2 - 1
	var max_x := tiles.x / 2
	var min_z := -tiles.y / 2 - 1
	var max_z := tiles.y / 2
	var ring: Array[Vector2i] = []
	for x in range(min_x, max_x + 1):
		for z in range(min_z, max_z + 1):
			var on_edge := x == min_x or x == max_x or z == min_z or z == max_z
			if on_edge:
				ring.append(Vector2i(x, z))
	return ring


## Every solid tile: the authored ones plus, when border_for_floor is set, the generated
## boundary ring. Duplicates are harmless (they would only stack identical boxes) but are
## removed so the shape count stays a meaningful assertion.
func solid_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile in blocked:
		if not tiles.has(tile):
			tiles.append(tile)
	if border_for_floor != Vector2i.ZERO:
		for tile in border_tiles(border_for_floor):
			if not tiles.has(tile):
				tiles.append(tile)
	return tiles


func _rebuild() -> void:
	if not is_inside_tree():
		return
	var existing := get_node_or_null(BODY_NAME)
	if existing != null:
		remove_child(existing)
		existing.queue_free()
	var body := StaticBody3D.new()
	body.name = BODY_NAME
	for tile in solid_tiles():
		var shape_node := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(TILE_EXTENT, wall_height, TILE_EXTENT)
		shape_node.shape = box
		shape_node.position = tile_centre(tile, wall_height)
		body.add_child(shape_node)
	add_child(body)
