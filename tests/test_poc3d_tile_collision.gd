extends GutTest

const POSITION_TOLERANCE := 0.0001

var _collision: TileCollision

func before_each():
	_collision = TileCollision.new()

func after_each():
	if is_instance_valid(_collision):
		_collision.free()

# --- pure grid maths ------------------------------------------------------

func test_a_tile_index_maps_to_the_centre_of_its_one_unit_cell():
	# Tile (i, j) covers world X in [i, i+1) and Z in [j, j+1), matching TileFloor,
	# which lays one tile per world unit.
	var centre := TileCollision.tile_centre(Vector2i(0, 0), 3.0)
	assert_almost_eq(centre.x, 0.5, POSITION_TOLERANCE)
	assert_almost_eq(centre.z, 0.5, POSITION_TOLERANCE)
	assert_almost_eq(centre.y, 1.5, POSITION_TOLERANCE, "the box is centred at half its height so it rests on the floor")

func test_negative_tile_indices_map_correctly():
	var centre := TileCollision.tile_centre(Vector2i(-4, 2), 3.0)
	assert_almost_eq(centre.x, -3.5, POSITION_TOLERANCE)
	assert_almost_eq(centre.z, 2.5, POSITION_TOLERANCE)

func test_the_border_ring_sits_just_outside_the_visible_floor():
	# TileFloor(12, 12) is centred on the origin, so visible tiles are -6..5.
	# The ring must be at -7 and 6 so every visible tile stays walkable.
	var ring := TileCollision.border_tiles(Vector2i(12, 12))
	assert_true(ring.has(Vector2i(-7, 0)), "missing the -X wall")
	assert_true(ring.has(Vector2i(6, 0)), "missing the +X wall")
	assert_true(ring.has(Vector2i(0, -7)), "missing the -Z wall")
	assert_true(ring.has(Vector2i(0, 6)), "missing the +Z wall")
	assert_false(ring.has(Vector2i(-6, 0)), "the outermost VISIBLE tile must stay walkable")
	assert_false(ring.has(Vector2i(5, 5)), "the outermost VISIBLE tile must stay walkable")

func test_the_border_ring_is_closed_and_has_no_duplicates():
	var ring := TileCollision.border_tiles(Vector2i(12, 12))
	# A 14x14 perimeter: 14*14 - 12*12
	assert_eq(ring.size(), 52, "the ring must be exactly the perimeter of the padded grid")
	var unique := {}
	for tile in ring:
		unique[tile] = true
	assert_eq(unique.size(), ring.size(), "corner tiles are being emitted twice")

# --- generated bodies -----------------------------------------------------

func _static_body() -> StaticBody3D:
	return _collision.get_node_or_null(TileCollision.BODY_NAME) as StaticBody3D

func test_each_blocked_tile_becomes_one_collision_shape():
	_collision.blocked = [Vector2i(2, -1), Vector2i(0, 3)] as Array[Vector2i]
	add_child_autofree(_collision)
	await wait_frames(1)
	var body := _static_body()
	assert_not_null(body, "TileCollision must own exactly one StaticBody3D")
	assert_eq(body.get_child_count(), 2, "one CollisionShape3D per blocked tile")

func test_a_generated_shape_is_a_one_unit_box_at_the_tile_centre():
	_collision.wall_height = 3.0
	_collision.blocked = [Vector2i(2, -1)] as Array[Vector2i]
	add_child_autofree(_collision)
	await wait_frames(1)
	var shape_node := _static_body().get_child(0) as CollisionShape3D
	var box := shape_node.shape as BoxShape3D
	assert_not_null(box, "blocked tiles must produce BoxShape3D, not a concave mesh")
	assert_almost_eq(box.size.x, 1.0, POSITION_TOLERANCE)
	assert_almost_eq(box.size.z, 1.0, POSITION_TOLERANCE)
	assert_almost_eq(box.size.y, 3.0, POSITION_TOLERANCE)
	assert_almost_eq(shape_node.position.x, 2.5, POSITION_TOLERANCE)
	assert_almost_eq(shape_node.position.z, -0.5, POSITION_TOLERANCE)

func test_reassigning_blocked_tiles_rebuilds_rather_than_accumulates():
	_collision.blocked = [Vector2i(0, 0), Vector2i(1, 0)] as Array[Vector2i]
	add_child_autofree(_collision)
	await wait_frames(1)
	_collision.blocked = [Vector2i(5, 5)] as Array[Vector2i]
	await wait_frames(1)
	assert_eq(_static_body().get_child_count(), 1,
		"stale shapes from the previous grid are still in the scene")

func test_the_boundary_ring_is_generated_rather_than_hand_listed():
	# The .tscn authors only the tiles under the blocks; the ring is derived, so it lives
	# in exactly one place. Without this, border_tiles() would be dead code and the scene
	# would hand-maintain 52 coordinates.
	_collision.blocked = [Vector2i(2, -1)] as Array[Vector2i]
	_collision.border_for_floor = Vector2i(12, 12)
	add_child_autofree(_collision)
	await wait_frames(1)
	assert_eq(_static_body().get_child_count(), 53, "1 authored tile + a 52-tile ring")

func test_no_border_is_generated_when_border_for_floor_is_unset():
	_collision.blocked = [Vector2i(2, -1)] as Array[Vector2i]
	add_child_autofree(_collision)
	await wait_frames(1)
	assert_eq(_static_body().get_child_count(), 1)

func test_a_tile_listed_in_both_the_ring_and_blocked_is_not_duplicated():
	_collision.blocked = [Vector2i(-7, 0)] as Array[Vector2i]
	_collision.border_for_floor = Vector2i(12, 12)
	add_child_autofree(_collision)
	await wait_frames(1)
	assert_eq(_static_body().get_child_count(), 52, "(-7, 0) is already in the ring")

func test_it_adds_no_light_to_the_scene():
	# tests/test_poc3d_pipeline.gd asserts the POC has exactly one Light3D.
	_collision.blocked = [Vector2i(0, 0)] as Array[Vector2i]
	add_child_autofree(_collision)
	await wait_frames(1)
	assert_eq(_collision.find_children("*", "Light3D", true, false).size(), 0)
