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
## top. Yaw is fixed to the camera's contract angle: with 4-direction atlases and
## a locked camera there is nothing to rotate toward.


func _ready() -> void:
	pixel_size = WorldScale.SPRITE_PIXEL_SIZE
	billboard = BaseMaterial3D.BILLBOARD_DISABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	# default_texture_filter in project.godot is 2D-only and does not reach here.
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	rotation_degrees.y = WorldScale.CAMERA_YAW_DEGREES
	_lift_feet_to_origin()


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
