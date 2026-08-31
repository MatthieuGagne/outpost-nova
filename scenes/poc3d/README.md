# 3D presentation POC

Standalone proof-of-concept for epic #100 (Xenogears-style presentation). Nothing here is reachable from the 2D game: `main.tscn`, `go_to_area()` and the seven existing areas are untouched, and `project.godot` still boots `scenes/character_creation.tscn`.

## Running it

```powershell
./tools/godot.ps1 --path . "res://scenes/poc3d/poc_entry.tscn"
```

Quote the `res://` argument — PowerShell splits an unquoted one on the colon.

To also see renderer warnings on the console:

```powershell
./tools/godot.ps1 -Console --path . "res://scenes/poc3d/poc_entry.tscn"
```

Opening `scenes/poc3d/poc_entry.tscn` in the editor and pressing F6 also works.

## Shape

| File | Role |
|------|------|
| `poc_entry.tscn` | The 480x270 `SubViewport` render target, with `hud.tscn` as a sibling above it |
| `rooms/test_room.tscn` | Greybox geometry, one directional light, the camera |
| `room_camera.tscn` | The per-room camera contract — FOV/pitch/yaw from `WorldScale` |
| `scripts/poc3d/world_scale.gd` | Every constant. 16 px = 1 world unit |

The HUD must never be moved inside the `SubViewport`; see the comment in `scripts/poc3d/poc_entry.gd`.

## Sprite characters (PRD 2, #102)

### Controls

The player reads `ui_left` / `ui_right` / `ui_up` / `ui_down` (Godot's default
arrow-key bindings — `project.godot` defines no overrides) via
`Input.get_axis()` in `scripts/poc3d/player3d.gd`. Input is camera-relative:
"up" moves the player away from the camera along the room's authored yaw, not
along world -Z. There is no camera rotation anywhere in the POC — every room
inherits the fixed yaw from `WorldScale.CAMERA_YAW_DEGREES` (45°) — so
camera-relative and room-relative currently mean the same thing.

### The two-function facing contract

`scripts/poc3d/sprite_facing.gd` is deliberately split into two pure,
node-free functions:

- `from_input(input: Vector2) -> String` resolves the animation suffix
  (`up`/`down`/`left`/`right`) directly from the **raw, camera-space** input
  vector. It needs no rotation because the input is already screen-relative.
- `input_to_world(input: Vector2, yaw_degrees: float) -> Vector3` rotates that
  same input vector into a **world-space** XZ direction by the camera yaw, for
  `velocity`.

`Player3D._physics_process()` calls `input_to_world()` to build `velocity`
and separately calls `from_input()` (via `_update_animation()`) on the same
raw `input` — never on `velocity` — to pick the sprite. Folding the two
together (deriving facing from the already-rotated velocity) is the specific
failure mode this split prevents: it would show the "up" sprite while the
character visibly slides diagonally across the screen, because the world-space
rotated vector no longer lines up with the screen axes the facing suffixes are
named after.

### Collision is authored in 2D

`scripts/poc3d/tile_collision.gd` (`TileCollision`, on the `Collision` node in
`rooms/test_room.tscn`) authors collision as a flat 2D tile grid on the XZ
plane, like a tilemap — one tile is one world unit, matching `TileFloor`, and
tile `(i, j)` covers world X in `[i, i+1)` and Z in `[j, j+1)`. At `_ready()`
it compiles the grid into a single `StaticBody3D` of full-height `BoxShape3D`
children so `CharacterBody3D.move_and_slide()` has real physics bodies to
collide with.

The boundary ring around the floor is not hand-listed: setting
`border_for_floor` to the floor's tile dimensions derives the ring via
`TileCollision.border_tiles()` and appends it to the authored `blocked` array
at build time. `test_room.tscn` sets `border_for_floor = Vector2i(12, 12)` to
match its 12×12 floor, on top of eight explicitly authored `blocked` tiles
covering `BlockA`, `BlockB`, and `BlockC`.

During this PRD, `BlockB` and `BlockC` were moved by `(+0.5, 0, +0.5)` (from
`(2, 1.5, -1)` / `(1, 1.0, 3)` to `(2.5, 1.5, -0.5)` / `(1.5, 1, 3.5)`) so
their footprints land exactly on tile boundaries and match the authored
`blocked` tiles `(2, -1)` and `(0, 3)`/`(1, 3)`/`(2, 3)`. `BlockA` was already
grid-aligned and did not need to move. `ReferenceSprite` moved by the same
`(+0.5, 0, +0.5)` delta (to `(2.5, 0, 0.1)`) to preserve PRD 1's framing: its
billboard quad intersects `BlockB`'s new footprint, and that intersection is
what produces the deliberate partial occlusion `ReferenceSprite` demonstrates.

### Detect 3D

Any texture read by a `Sprite3D`/`AnimatedSprite3D` node gets Godot's "Detect
3D" reimport treatment by default, which VRAM-compresses it and destroys the
sprite's hard pixel edges. Every PNG in `assets/sprites/characters/` has
`detect_3d/compress_to=0` set in its `.import` file to opt out. Any **new**
character PNG added for 3D use needs the same setting, or it will silently
reimport with VRAM compression and look softer than its neighbours the next
time the editor touches it.
