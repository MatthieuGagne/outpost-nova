@tool
class_name RoomCamera
extends Camera3D

## The camera contract for POC rooms (issue #101, R6/R7).
##
## The ANGLE is shared and lives in WorldScale, so every room starts from the
## same authored look and changing it changes every room. The POSITION is not:
## framing is hand-placed per room and this script never writes it.
##
## There is deliberately no rotation input and no runtime controller (R7).
##
## @tool so the editor viewport shows the contract angle while the room is being
## composed by eye, rather than whatever literal the .tscn last happened to hold.

## Set false in a room that needs its own angle; the hand-authored rotation is
## then left alone.
@export var use_contract_angle := true


func _ready() -> void:
	if use_contract_angle:
		projection = PROJECTION_PERSPECTIVE
		fov = WorldScale.CAMERA_FOV
		rotation_degrees = Vector3(
			WorldScale.CAMERA_PITCH_DEGREES,
			WorldScale.CAMERA_YAW_DEGREES,
			0.0)
	# A SubViewport renders 3D through its current Camera3D; nothing else sets this,
	# so without it the viewport falls back to a default origin camera and the room
	# shows as a featureless grey background. Runtime-only: the editor manages its own
	# preview camera and make_current() here would fight it.
	if not Engine.is_editor_hint():
		make_current()
