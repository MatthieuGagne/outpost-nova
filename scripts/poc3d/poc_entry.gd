# scripts/poc3d/poc_entry.gd
@tool
extends Node

## Entry point for the Xenogears-presentation POC (issue #101).
##
## Tree shape, and why:
##
##   PocEntry
##   ├── SubViewportContainer   stretch = true, full-rect
##   │   └── SubViewport        the 3D world renders here, at 480x270
##   │       └── TestRoom
##   │           └── ExitDoor   reports through the HUD, wired below (#103)
##   ├── HUD                    instanced hud.tscn — a SIBLING, never a child
##   └── DialogueBox            instanced dialogue_box.tscn, also a SIBLING (#103).
##                              layer = 10 against the HUD's 1, so it draws above both
##                              the upscaled world and the HUD, at full resolution.
##
## THE INVARIANT: the HUD must never be parented under the SubViewport. Anything
## inside the SubViewport is rendered into the low-res target and upscaled with
## it, which would turn the UI text into mush. hud.tscn is already a CanvasLayer
## with layer = 1, so as a sibling it draws above the container at full window
## resolution with no wrapper node needed. tests/test_poc3d_pipeline.gd asserts
## this and will fail if a later PRD reparents it.
##
## SubViewport.size is deliberately NOT assigned here. SubViewportContainer with
## stretch = true drives the SubViewport's size from the container, so any
## assignment would be silently overwritten. The container measures 480x270
## because project.godot's stretch/mode = "canvas_items" gives the root viewport
## that logical size; the root stretch then does the nearest-neighbour upscale,
## nearest because rendering/textures/canvas_textures/default_texture_filter=0
## applies to the container's canvas texture. WorldScale.RENDER_WIDTH/HEIGHT are
## the expected values the structural test asserts against.

## The door reports through the HUD's existing message banner rather than a fade: this
## PRD does no transitions, and hud.gd.show_message() already exists and auto-hides.
const DOOR_NODE_PATH := "SubViewportContainer/SubViewport/TestRoom/ExitDoor"
const HUD_NODE_PATH := "HUD"

@onready var _viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var _door: ExitDoor = get_node(DOOR_NODE_PATH)
## Untyped on purpose: hud.gd carries no class_name, and typing this as CanvasLayer would
## leave show_message() resolvable only at runtime, which reads as a type error waiting
## to happen rather than the deliberate duck-typed call it is.
@onready var _hud = get_node(HUD_NODE_PATH)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var actual := _viewport.size
	var expected := Vector2i(WorldScale.RENDER_WIDTH, WorldScale.RENDER_HEIGHT)
	if actual != expected:
		push_warning(
			"POC render target is %s, expected %s — check display/window/stretch/mode in project.godot"
			% [actual, expected])
	_door.triggered.connect(_on_door_triggered)


## Wiring the room to its host lives HERE, at the composition root, not inside the room:
## the HUD is deliberately outside the SubViewport, and a NodePath reaching across that
## boundary from inside the room would couple the room to whatever hosts it.
func _on_door_triggered(destination_id: String) -> void:
	_hud.show_message(ExitDoor.MESSAGE_FORMAT % destination_id)
