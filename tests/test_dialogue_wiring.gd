# tests/test_dialogue_wiring.gd
# Guards the DialogueRunner <-> TextLineProvider wiring in main.tscn (issue #98).
# YarnSpinner's DialogueRunner.LineProvider getter calls AddChild() before it
# assigns YarnProject, so a lazily-created provider always errors in _Ready().
# The scene must therefore declare the provider explicitly.
extends GutTest

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const RUNNER_NODE_NAME := "DialogueRunner"
const PROVIDER_NODE_NAME := "TextLineProvider"
const PROVIDER_NODE_PATH := "./DialogueRunner/TextLineProvider"
const PROVIDER_RELATIVE_PATH := "TextLineProvider"
const YARN_PROJECT_PATH := "res://data/dialogue/outpost-nova.yarnproject"
const PROVIDER_SCRIPT_PATH := "res://addons/YarnSpinner-Godot/Runtime/LineProviders/TextLineProvider.cs"

var _state: SceneState

func before_each():
	var packed: PackedScene = load(MAIN_SCENE_PATH)
	_state = packed.get_state()

func _find_node_index(node_name: String) -> int:
	for i in _state.get_node_count():
		if _state.get_node_name(i) == node_name:
			return i
	return -1

func _get_property(node_index: int, property_name: String) -> Variant:
	for p in _state.get_node_property_count(node_index):
		if _state.get_node_property_name(node_index, p) == property_name:
			return _state.get_node_property_value(node_index, p)
	return null

func test_dialogue_runner_exists_in_scene():
	assert_ne(_find_node_index(RUNNER_NODE_NAME), -1,
		"main.tscn must contain a %s node" % RUNNER_NODE_NAME)

func test_dialogue_runner_has_yarn_project_assigned():
	var idx := _find_node_index(RUNNER_NODE_NAME)
	var project = _get_property(idx, "yarnProject")
	assert_true(project != null,
		"DialogueRunner.yarnProject must be assigned in the scene, not only at runtime")
	if project == null:
		return
	assert_eq(project.resource_path, YARN_PROJECT_PATH)

func test_dialogue_runner_line_provider_points_at_provider_node():
	var idx := _find_node_index(RUNNER_NODE_NAME)
	var path = _get_property(idx, "lineProvider")
	assert_not_null(path,
		"DialogueRunner.lineProvider must be wired, or YarnSpinner lazily builds a broken one")
	if path == null:
		return
	assert_eq(str(path), PROVIDER_RELATIVE_PATH)

func test_text_line_provider_node_exists_under_runner():
	var idx := _find_node_index(PROVIDER_NODE_NAME)
	assert_ne(idx, -1, "main.tscn must contain an explicit %s node" % PROVIDER_NODE_NAME)
	if idx == -1:
		return
	assert_eq(str(_state.get_node_path(idx)), PROVIDER_NODE_PATH)
	var script = _get_property(idx, "script")
	assert_true(script != null and script.resource_path == PROVIDER_SCRIPT_PATH,
		"%s node must use the TextLineProvider script, or lineProvider will fail to bind" % PROVIDER_NODE_NAME)

func test_text_line_provider_has_yarn_project_assigned():
	var idx := _find_node_index(PROVIDER_NODE_NAME)
	if idx == -1:
		assert_ne(idx, -1, "main.tscn must contain an explicit %s node" % PROVIDER_NODE_NAME)
		return
	var project = _get_property(idx, "YarnProject")
	assert_true(project != null,
		"TextLineProvider.YarnProject must be set in the scene so it is valid at _Ready()")
	if project == null:
		return
	assert_eq(project.resource_path, YARN_PROJECT_PATH)
