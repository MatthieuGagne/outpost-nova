# scripts/poc3d/pixel_sprite_3d.gd
@tool
class_name PixelSprite3D
extends AnimatedSprite3D

## A character sprite standing in the 3D world at the project's pixel scale.
##
## PRD 1 scope: this node is a MEASURING STICK. It exists so AC2 can be judged —
## is a 16x32 sprite's pixel the same size as a 3D pixel? — and so pixel_size is
## proven to come from WorldScale. It has no movement, no input, and no facing
## logic; PRD 2 (#102) owns all sprite behaviour.
##
## Billboarding is off and alpha_cut is ALPHA_CUT_DISCARD so the depth buffer
## handles occlusion against geometry rather than the sprite always drawing on
## top. With billboarding off the quad is flat, so it is turned to face whatever
## camera renders it — see _face_active_camera(). With 4-direction atlases and a
## locked per-room camera there is nothing further to rotate toward.


func _ready() -> void:
	pixel_size = WorldScale.SPRITE_PIXEL_SIZE
	billboard = BaseMaterial3D.BILLBOARD_DISABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	# default_texture_filter in project.godot is 2D-only and does not reach here.
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_face_active_camera()
	_lift_feet_to_origin()


## In the editor there is no room camera to follow: get_viewport() resolves to the 3D
## editor's own viewport, and tracking its free camera would billboard the quad while a
## room is being composed by eye. The contract angle is stamped once at _ready() instead,
## which is exactly what this node did before #116.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_face_active_camera()


## The quad is flat and billboarding is off, so it has to be turned toward the camera that
## renders it; at a 180-degree difference the camera sees its mirrored back face instead
## (#116). Same rule and same fallback as the player's movement yaw (#114).
##
## Written as a global rotation so a sprite nested under a rotated pivot or NPC node still
## lands on the camera's angle rather than that angle plus its ancestors'.
##
## Relies on the camera already having its final rotation for this frame: _process order
## between Node3Ds is unspecified, so if a runtime controller ever rotates the camera
## in _process (there is none today — see scenes/poc3d/README.md and room_camera.gd),
## this quad can trail it by one frame.
func _face_active_camera() -> void:
	var yaw := WorldScale.CAMERA_YAW_DEGREES
	if not Engine.is_editor_hint():
		yaw = WorldScale.camera_yaw_degrees(get_viewport())
	var euler := global_rotation_degrees
	euler.y = yaw
	global_rotation_degrees = euler


## AnimatedSprite3D centres the frame on the node, so half the sprite would sink
## below the floor. offset is in pixels and +Y is up in 3D, so lifting by half
## the frame height puts the feet on the node's origin. Read from the frame
## rather than typed, so a different-sized character needs no code change.
func _lift_feet_to_origin() -> void:
	if sprite_frames == null or not sprite_frames.has_animation(animation):
		return
	if sprite_frames.get_frame_count(animation) == 0:
		return
	var frame: Texture2D = sprite_frames.get_frame_texture(animation, 0)
	if frame == null:
		return
	offset = Vector2(0.0, frame.get_height() * 0.5)
