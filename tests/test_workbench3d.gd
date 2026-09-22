extends GutTest

## Workbench3D contract (issue #131 R3). A direct port of the deleted scripts/workbench.gd:
## it joins the interactable group and forwards interact() to Main.open_crafting().
## The 2D crafting_panel is a CanvasLayer sibling of the SubViewport and is untouched.

const WORKBENCH_3D := "res://scenes/poc3d/workbench3d.tscn"


class MainStub extends Node:
	var crafting_opened := 0

	func open_crafting() -> void:
		crafting_opened += 1


func before_each():
	GameState.reset()
	ClockManager.reset()


func _bench() -> Workbench3D:
	var bench = load(WORKBENCH_3D).instantiate()
	add_child_autofree(bench)
	return bench


func test_bench_joins_the_interactable_group():
	var bench := _bench()
	assert_true(bench.is_in_group(InteractScan.INTERACTABLE_GROUP),
		"Workbench3D must be in the interactable group so Player3D's scan finds it")


func test_bench_root_is_an_area3d():
	# Plot3D established that an interactable's ROOT must land in
	# Player3D.get_overlapping_areas() — a StaticBody3D root would never be scanned.
	assert_true(_bench() is Area3D, "Workbench3D root must be an Area3D")


func test_interact_forwards_to_main_open_crafting():
	var root := get_tree().get_root()
	assert_null(root.get_node_or_null("Main"),
		"a real Main is already in the tree; this test's stub would be shadowed")
	var stub := MainStub.new()
	stub.name = "Main"
	root.add_child(stub)

	var bench := _bench()
	bench.interact()
	assert_eq(stub.crafting_opened, 1, "interact() must call Main.open_crafting() exactly once")

	root.remove_child(stub)
	stub.free()


func test_interact_without_a_main_does_not_crash():
	# Headless tests and the editor have no Main; interact() must degrade quietly.
	var bench := _bench()
	bench.interact()
	pass_test("interact() survived a missing Main")
