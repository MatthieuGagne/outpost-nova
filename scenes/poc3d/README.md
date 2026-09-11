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
| `poc_entry.tscn` | The 480x270 `SubViewport` render target, with `hud.tscn` and `dialogue_box.tscn` as siblings above it |
| `rooms/test_room.tscn` | Greybox geometry — floor, four walls, console, crate, exit door — one directional light, the camera |
| `room_camera.tscn` | The per-room camera contract — FOV/pitch/yaw from `WorldScale` |
| `scripts/poc3d/world_scale.gd` | Every constant. 16 px = 1 world unit |

Neither the HUD nor the dialogue box may be moved inside the `SubViewport`; see the comment in `scripts/poc3d/poc_entry.gd`.

## Sprite characters (PRD 2, #102)

### Controls

The player reads `ui_left` / `ui_right` / `ui_up` / `ui_down` (Godot's default
arrow-key bindings — `project.godot` defines no overrides) via
`Input.get_axis()` in `scripts/poc3d/player3d.gd`. Input is camera-relative:
"up" moves the player away from the camera along the room's authored yaw, not
along world -Z.

That yaw is read every physics frame from the `Camera3D` actually rendering the
player (`WorldScale.camera_yaw_degrees()`), so a room that sets
`RoomCamera.use_contract_angle = false` and hand-authors its own angle gets
controls that match what is on screen. When the viewport has no camera at all —
headless tests, mainly — the yaw falls back silently to
`WorldScale.CAMERA_YAW_DEGREES` (45°).

The **sprite quad** reads the same yaw, through the same helper, every frame
(`PixelSprite3D._face_active_camera()`). Billboarding is off, so the quad is flat:
if it did not turn with the camera, a room at a different angle would see it
edge-on, and a room 180° away would see its mirrored back face (#116). In the
editor the contract angle is stamped instead, because `get_viewport()` there is
the 3D editor's own viewport and following its free camera would billboard the
sprite while a room is being composed.

There is still no camera *rotation* anywhere in the POC: the angle is authored
per room and fixed at runtime.

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
match its 12×12 floor, on top of four explicitly authored `blocked` tiles:
`(2, -1)` for `BlockB`, `(-6, -1)` and `(-6, 0)` for the `Console`, and
`(1, 1)` for the `Crate`. `BlockA` and `BlockC` were removed in #103 and their
seven tiles freed; the props that replaced them are described below.

During PRD 2, `BlockB` was moved by `(+0.5, 0, +0.5)` (from `(2, 1.5, -1)` to
`(2.5, 1.5, -0.5)`) so its footprint lands exactly on tile boundaries and
matches the authored `blocked` tile `(2, -1)`. `ReferenceSprite` moved by the same
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

The same rule applies to the kit textures under `assets/sprites/kit/` (PRD 4,
#104): they feed `StandardMaterial3D` on `BoxMesh`/`CylinderMesh`, which gets
the same "Detect 3D" VRAM-compression default — a fresh import writes
`detect_3d/compress_to=1`, so every kit PNG must be flipped to
`detect_3d/compress_to=0` (and `mipmaps/generate=false`) in its `.import`, or
its hard pixel edges soften on the next editor touch.

## Greybox room, interaction & NPC (PRD 3, #103)

This is the room the epic's **go/no-go gate** is answered in. PRD 4 (#104) does
not begin until it is.

### Room shape, and why two walls are short

The floor is 12×12 tiles centred on the origin, spanning world X and Z from
`-6` to `+6`. `border_for_floor` already generates a solid 3-unit collision ring
just outside it, on tile columns `x = -7`/`x = 6` and rows `z = -7`/`z = 6`.

**The walls added in #103 are purely visual.** Every one of their footprints was
already blocked by that ring, so no collision changed — which is also why AC1's
"stopped by all four walls" was true before the meshes existed.

`RoomCamera` looks down at the origin from the `+X`/`+Z` corner, so:

| Wall | Height | Why |
|------|--------|-----|
| `WestWall` (`−X`), `NorthWall*` (`−Z`) | 3 units | Far from the camera; they read as the room's back |
| `EastParapet` (`+X`), `SouthParapet` (`+Z`) | 0.5 units | Between camera and room. At full height they would occlude the entire interior |

All four footprints are real and grid-snapped, so PRD 4 has somewhere to drop
kit pieces on **every** side — the parapets are a mesh-height choice, not a
missing wall. The `−Z` wall is three boxes (`NorthWallLeft`, `NorthWallRight`,
`NorthWallLintel`) whose gap is the 2 × 2.5-unit door opening.

### The door does not open

The collision ring stays solid across the doorway: the player is stopped at the
threshold, and `ExitDoor`'s `Area3D` covers the two floor tiles in front of the
opening. Real area-to-area transitions are PRD 6 — this door only *reports*,
via `triggered` → `poc_entry.gd` → `HUD.show_message()`.

Two things worth not undoing:

- **The `_occupied` latch** is what makes AC4's "exactly once per entry" true.
  Physics re-emits `body_entered` while the player is pressed against the wall
  inside the zone; without the latch the banner spams.
- **The HUD wiring lives in `poc_entry.gd`, not in the room.** The HUD is
  deliberately outside the `SubViewport`, and a `NodePath` reaching across that
  boundary from inside the room would couple the room to whatever hosts it.

### The interaction contract

`scripts/poc3d/interact_scan.gd` is node-free on purpose — the same reasoning as
`SpriteFacing` above. A real `Area3D` overlap needs physics frames, so keeping
the *rule* free of nodes is what makes AC9's headless coverage possible.

It mirrors `scripts/characters/player.gd._try_interact()` exactly: bodies before
areas, first match wins, a candidate qualifies on `interactable` group membership
plus `visible`. It adds one stricter filter — `has_method("interact")` — so a
malformed prop is skipped rather than erroring. That differs from the 2D original
only in the case where 2D currently crashes.

Both interactables reach it the same way, through an `Area3D` in the
`interactable` group:

- `PocConsole` **is** that `Area3D` (`scenes/poc3d/console.tscn`).
- The NPC uses a forwarding `InteractTarget` child, because `Npc3D` is a plain
  `Node3D` — `tests/test_poc3d_npc3d.gd` asserts it is not a physics body, so it
  is invisible to the scan on its own.

The console's *solidity* is a blocked tile in `TileCollision`, authored
separately from both its mesh and its interaction volume. That separation is R3:
PRD 4 replaces the mesh and must not be able to disturb either.

### Dialogue without YarnSpinner

`PocDialogueLine.build()` hand-builds the `Dictionary` that
`dialogue_box.run_line_async()` expects. **`dialogue_box.gd` and
`dialogue_box.tscn` are completely unmodified** — they are instanced as-is.

This works because `YarnSpinner` is the **pure GDScript** helper class in
`addons/YarnSpinner-Godot/Runtime/Views/GDScriptHelper.gd`, not C#. No
`DialogueRunner`, no `.yarnproject`, no C# assembly — and therefore testable
headlessly, which is why the round-trip through `LocalizedLine.from_dictionary()`
is asserted in `tests/test_poc3d_interaction.gd` rather than eyeballed.

`Npc3D.speaker_name` must match a key of `dialogue_box.NPC_PORTRAIT_INDEX`
(`Maris`, `Dex`, `Sable`) or the portrait silently falls back to the generic one.
A test guards that for `Maris`.

Why hardcoded at all: `DialogueRunner` is set up in
`main.gd._setup_dialogue_runner()`, which this PRD deliberately does not touch.
Re-doing that wiring would prove nothing about the 3D move. The question worth
answering is whether the dialogue UI *layers correctly over the low-res
`SubViewport`* — one line answers that at a fraction of the cost.

### The dialogue box is a sibling

Same invariant as the HUD, for the same reason: anything inside the
`SubViewport` renders at 480×270 and upscales with the world, turning text to
mush. `dialogue_box.tscn` is a `CanvasLayer` at `layer = 10` against the HUD's
`layer = 1`, so as a sibling it draws above both, at full window resolution.
`tests/test_poc3d_interaction.gd` asserts it and will fail if a later PRD
reparents it.

## Production rooms: what the cantina added (#130)

`scenes/areas3d/trade_dock.tscn` established the room shape; the cantina is the
first room migrated *into* the live game with doors on every side, an NPC, and
an interactable. These are the rules it settled, so the next migration
(workshop, M3) does not re-derive them.

### Doors on a near side leave a gap, not a wall

The camera looks from `+X`/`+Z`, so those two sides are parapets (see the PRD 3
table above). A door on a parapet side is authored as a **4-unit gap in the
parapet**, split into two mesh segments either side of it — not as a full-height
wall with a doorframe, which would occlude the interior the parapet exists to
keep visible. The cantina's East parapet is two `BoxMesh(1, 0.5, 4)` pieces
leaving `Z ∈ [-2, 2]` open; the South parapet is two `BoxMesh(6, 0.5, 1)` pieces
leaving `X ∈ [-2, 2]` open.

### A wall running along Z needs a 90° yaw — on two nodes

`doorframe.tscn` and `exit_door.tscn` are both authored facing `-Z`. On a wall
that runs along Z (the West/East sides), **both** need
`rotation_degrees = (0, 90, 0)`. For the `ExitDoor` this is not cosmetic: its
collision box is `(2, 3, 1)` — 2 units wide in **local X** — so without the yaw
the trigger spans the wall instead of the doorway.

### Where the trigger and the marker go

Two different offsets, and swapping them breaks the room:

| Node | Offset from the floor edge | Why |
|------|---------------------------|-----|
| `ExitDoor` | **0.5 units inside** | Its 1-unit-deep box then covers the first *walkable* tile row. The border collision ring stays solid across the doorway, so the player is stopped at the threshold — the trigger fires, the door never "opens" |
| `EntryFrom*` marker | **2 units inside** | Clear of the exit trigger box above. A marker placed inside that box re-fires the door the instant the player arrives, bouncing them straight back |

Markers must be **direct children of the room root** — `main._find_3d_entry_marker`
searches non-recursively, so a nested marker is silently invisible and the player
falls back to `DefaultSpawn`.

### Migrating a room moves its NPC out of the 2D roster

A 3D room hosts its own NPCs in-scene as `Npc3D` instances (trade_dock hosts
Sable; the cantina hosts Maris). Migrating a room therefore means deleting its
NPC from **both** halves of the 2D roster in `main.gd` — `NPC_SPAWN_AREAS` and
the `npc_scripts` dict in `_spawn_npcs()`. Leaving it in either place spawns a
duplicate 2D NPC that is invisible everywhere.

The same commit drops that room's whole `AREA_ENTRY_POSITIONS` block (3D rooms
spawn from `EntryFrom*` markers instead), but **keeps** the surviving 2D
neighbours' keys *naming* it — those describe arrival into a 2D room from the
migrated one and stay valid.

`dialogue_box.gd` keys portraits off the Yarn **speaker** name, so an `Npc3D`
whose `dialogue_node` matches the character's name gets the right portrait with
no extra wiring.

### Interactables are `Area3D` roots

`Plot3D` (`scenes/poc3d/plot3d.tscn`) is the first production interactable. Its
root **is** the `Area3D`, like `PocConsole` and unlike `Npc3D`'s forwarding
`InteractTarget` child — so it lands directly in `Player3D`'s
`get_overlapping_areas()` scan. Its `CollisionShape3D` is `BoxShape3D(1, 2, 1)`
at `(0, 1, 0)`, the same volume `InteractTarget` uses and proven to sit inside
the player's 1.25-unit reach.

It is self-contained: the room script knows nothing about plots. A second plot
is one more instance with a different `resource_id` — the flag key is derived as
`"plot_%s_growing" % resource_id`, never written literally.
