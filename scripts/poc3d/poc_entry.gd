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
##   └── HUD                    instanced hud.tscn — a SIBLING, never a child
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

@onready var _viewport: SubViewport = $SubViewportContainer/SubViewport


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var actual := _viewport.size
	var expected := Vector2i(WorldScale.RENDER_WIDTH, WorldScale.RENDER_HEIGHT)
	if actual != expected:
		push_warning(
			"POC render target is %s, expected %s — check display/window/stretch/mode in project.godot"
			% [actual, expected])
