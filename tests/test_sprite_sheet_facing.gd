# tests/test_sprite_sheet_facing.gd
extends GutTest

## Ground truth for issue #116 Part 2, which proposed that the left and right sprite
## sheets are swapped. They are not, and this file is why the question stays settled.
##
## These .tres files are shared by the 2D build (scenes/characters/player.tscn,
## npc_base.tscn) and the 3D POC (scenes/poc3d/), so a swap here would break both.

## The side-facing row of a base sheet starts at y=64; the *_left sheets are single-row.
const SIDE_ROW_Y := 64
const FRAME_SIZE := Vector2i(16, 32)
const FRAME_COUNT := 4

## Half of FRAME_SIZE.x. A blush centroid above this sits on the right of the frame.
const FRAME_CENTRE_X := FRAME_SIZE.x * 0.5

## The cheek blush is (209, 157, 167): clearly redder than it is green or blue, unlike
## every other colour in these palettes. Thresholds in 0..1 float, from 25/255 and 10/255.
const BLUSH_RED_OVER_GREEN := 0.09
const BLUSH_RED_OVER_BLUE := 0.03

const SHEETS := [
	{"base": "res://assets/sprites/characters/player.png",
	 "mirror": "res://assets/sprites/characters/player_left.png",
	 "frames": "res://data/sprites/player_frames.tres"},
	{"base": "res://assets/sprites/characters/maris.png",
	 "mirror": "res://assets/sprites/characters/maris_left.png",
	 "frames": "res://data/sprites/npc_frames.tres"},
]


## Decompresses `texture`'s image if needed. The single place that does so, so
## `_image()` and `_frame_blush_centre_x()` cannot drift on the dance.
func _decompressed_image(texture: Texture2D) -> Image:
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	return image


func _image(path: String) -> Image:
	var texture: Texture2D = load(path)
	assert_not_null(texture, "missing texture: " + path)
	return _decompressed_image(texture)


## Mean x of the blush pixels in `image`, or -1.0 if the sprite shows no blush.
func _blush_centre_x(image: Image) -> float:
	var total := 0.0
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			if c.r > c.g + BLUSH_RED_OVER_GREEN and c.r > c.b + BLUSH_RED_OVER_BLUE:
				total += float(x)
				count += 1
	if count == 0:
		return -1.0
	return total / float(count)


## The blush centroid of one frame of `animation`, decompressed and measured.
func _frame_blush_centre_x(frames: SpriteFrames, animation: String, index: int) -> float:
	var texture := frames.get_frame_texture(animation, index)
	return _blush_centre_x(_decompressed_image(texture))


func test_each_side_sheet_is_an_exact_mirror_of_the_other():
	# If these ever stop being mirrors, the two sheets have diverged and the "just swap
	# them" fix proposed in #116 stops being a no-op even in principle.
	for sheet in SHEETS:
		var base := _image(sheet["base"])
		var mirror := _image(sheet["mirror"])
		var row := base.get_region(Rect2i(
			0, SIDE_ROW_Y, FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y))
		row.flip_x()
		assert_eq(mirror.get_size(), row.get_size(),
			"%s must be the same size as the base sheet's side row" % sheet["mirror"])
		## A PNG's fully-transparent pixels carry arbitrary RGB — Godot's decode/decompress
		## does not normalise it away, and different export passes routinely leave different
		## garbage colour behind alpha=0. Comparing those channels would fail this test on
		## bytes nobody ever sees. The invariant this test protects is "the two sheets look
		## identical when mirrored", and an invisible pixel has no look — so alpha is always
		## compared (a pixel becoming visible/invisible IS a visible change), while RGB is
		## only compared where the pixel is actually visible in either image.
		var differing := 0
		for y in row.get_height():
			for x in row.get_width():
				var a := row.get_pixel(x, y)
				var b := mirror.get_pixel(x, y)
				if not is_equal_approx(a.a, b.a):
					differing += 1
				elif a.a > 0.0 and not Color(a.r, a.g, a.b).is_equal_approx(Color(b.r, b.g, b.b)):
					differing += 1
		assert_eq(differing, 0,
			"%s must stay a pixel-exact horizontal mirror of %s row y=%d"
				% [sheet["mirror"], sheet["base"], SIDE_ROW_Y])


func test_the_right_facing_frames_show_the_blush_on_the_right():
	# The visible cheek blush, eye and nose of a profile sprite are on the side it faces.
	# In the row mapped to "right" the blush sits at x=9-10 of a 16px frame; in its mirror
	# it lands at x=5-6. Swapping the sheets flips this assertion, which is the whole
	# point of having it.
	for sheet in SHEETS:
		var frames: SpriteFrames = load(sheet["frames"])
		for animation in ["idle_right", "walk_right"]:
			for index in frames.get_frame_count(animation):
				var centre := _frame_blush_centre_x(frames, animation, index)
				assert_gt(centre, 0.0,
					"no blush found in %s frame %d of %s; the art or the colour thresholds changed"
						% [animation, index, sheet["frames"]])
				assert_gt(centre, FRAME_CENTRE_X,
					"%s frame %d of %s faces left, not right"
						% [animation, index, sheet["frames"]])


func test_the_left_facing_frames_show_the_blush_on_the_left():
	for sheet in SHEETS:
		var frames: SpriteFrames = load(sheet["frames"])
		for animation in ["idle_left", "walk_left"]:
			for index in frames.get_frame_count(animation):
				var centre := _frame_blush_centre_x(frames, animation, index)
				assert_gt(centre, 0.0,
					"no blush found in %s frame %d of %s; the art or the colour thresholds changed"
						% [animation, index, sheet["frames"]])
				assert_lt(centre, FRAME_CENTRE_X,
					"%s frame %d of %s faces right, not left"
						% [animation, index, sheet["frames"]])
