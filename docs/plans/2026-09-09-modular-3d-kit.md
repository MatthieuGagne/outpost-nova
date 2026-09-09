# Modular 3D Environment Kit & Art Pipeline Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the POC room's greybox geometry with a reusable seven-piece modular 3D kit, establishing the texture/mesh conventions every later room reuses.

**Architecture:** The kit is authored entirely from Godot primitive meshes (boxes + one cylinder) — no Blender, no `.glb`. Each piece is a self-contained scene under `scenes/poc3d/kit/` (a `MeshInstance3D` with a `BoxMesh`/`CylinderMesh` and a `StandardMaterial3D`), each with one pixel-art texture under `assets/sprites/kit/` authored at 16 texels per world unit. The `test_room.tscn` greybox is rebuilt by instancing these scenes; collision, floor, lights, camera, player, NPC, exit door, and interactables are untouched.

**Tech Stack:** Godot 4.7.1 (mono), GDScript scenes, `StandardMaterial3D` + `BoxMesh`/`CylinderMesh`, GUT (headless), pixel-art PNG textures.

## Open questions (must resolve before starting)

- **Piece count is 6, not 7.** R1 says "seven-piece" but names exactly six: `wall_segment`, `doorframe`, `console`, `table`, `crate`, `pipe`. The "7 pieces not 9" note appears to be a stale count from brainstorming. **Recommendation:** proceed with the six named pieces; the floor is `TileFloor` (pre-existing) and corners are junctions. If a seventh piece is intended, name it before Task 1 — it would slot in as another box alongside the existing six.

---

## Texture-density rule (applies to every texture task)

A texture is authored at **16 texels per world unit**: its pixel dimensions equal 16 × the piece's canonical face dimensions in world units. Concretely, a 1×3-unit wall segment → 16×48 px; a 1×2-unit console → 16×32 px; a 2×1-unit table → 32×16 px.

**Caveat (accepted):** a `BoxMesh` maps the whole texture onto every face, so small faces (wall top/end, prop ends) render the texture over a shorter span — over-dense. This is accepted for now (AC3: verify visually, and only escalate to a custom per-face-UV `ArrayMesh` — as `TileFloor` already does — if it reads wrong).

**AC1 hard rule:** no file may be added under `scripts/` in any task. Texture authoring is done with a throwaway tool/script (e.g. a Python/Pillow snippet run in `eval`, ImageMagick, or Aseprite), never a committed script. `git diff --stat scripts/` must be empty at the end.

---

## Batch 1 — Kit textures

All three tasks write **different files** (no shared state), so they are fully parallel. Each texture must import with `detect_3d/compress_to=0` and `mipmaps/generate=false` (the 3D-material analog of the existing sprite rule — default "Detect 3D" VRAM-compression softens pixel edges).

### Task 1: Author `wall_segment.png` and `doorframe_lintel.png`

**Files:**
- Create: `assets/sprites/kit/wall_segment.png` (16×48 px)
- Create: `assets/sprites/kit/doorframe_lintel.png` (64×8 px)

**Depends on:** none
**Parallelizable with:** Task 2, Task 3 (different files)

**Step 1: Author the textures**

`wall_segment.png` — 16 wide × 48 tall. A single wall panel: flat grey fill (`#595E66`), a 1px darker border (`#4A4F55`) on all four edges, and 2–3 vertical 1px groove lines at roughly columns 5 and 11 to read as panel seams. Keep the fill uniform — no gradients, no dithering (nearest filtering will show everything).

`doorframe_lintel.png` — 64 wide × 8 tall (4×0.5 units × 16). A horizontal lintel bar: same grey fill and border as the wall, plus a 1px darker line along the bottom edge so it reads as a beam over the opening.

Author with any tool that doesn't add a repo file. A throwaway Pillow snippet (run in `eval`, never committed) is fine — e.g. create an `Image.new("RGB", (16, 48), (0x59, 0x5E, 0x66))`, draw the border and groove lines with `ImageDraw`, `save()` to the path above.

**Step 2: Import and set the 3D settings**

Place both files under `assets/sprites/kit/`, then trigger a headless import to generate the `.import` files:

```powershell
./tools/godot.ps1 -Console --headless --path . --editor --quit 2>&1
```

Then set the opt-out on both generated `.import` files (mirror `assets/sprites/characters/player.png.import`): ensure `detect_3d/compress_to=0` and `mipmaps/generate=false` appear in the `[params]` block. Easiest path: in the Godot editor Import dock select each texture → "Detect 3D" → "Compress To" = **Disabled**, "Mipmaps" = **Disable**. Re-import after.

**Step 3: Verify**

```powershell
grep -A30 '\[params\]' assets/sprites/kit/wall_segment.png.import assets/sprites/kit/doorframe_lintel.png.import
```
Expected: both show `detect_3d/compress_to=0` and `mipmaps/generate=false`, and no `SCRIPT ERROR` / import warning in the Step 2 output.

**Step 4: Commit**

```bash
git add assets/sprites/kit/wall_segment.png assets/sprites/kit/wall_segment.png.import assets/sprites/kit/doorframe_lintel.png assets/sprites/kit/doorframe_lintel.png.import
git commit -m "feat(kit): add wall segment and doorframe lintel textures"
```

### Task 2: Author `console.png` and `crate.png`

**Files:**
- Create: `assets/sprites/kit/console.png` (16×32 px)
- Create: `assets/sprites/kit/crate.png` (16×16 px)

**Depends on:** none
**Parallelizable with:** Task 1, Task 3 (different files)

**Step 1: Author the textures**

`console.png` — 16 wide × 32 tall (1×2 units). Teal fill (`#3D6F7E`) with a 1px darker border, plus a few lighter 1px "screen" rectangles (`#5A8FA0`) in the upper half to suggest a readout panel.

`crate.png` — 16×16 (1×1 unit). Tan fill (`#8B7252`) with a 1px darker border and a diagonal 1px brace line corner-to-corner (or an X brace) so it reads as a crate.

**Step 2: Import and set the 3D settings** — identical to Task 1 Step 2 (both files, `compress_to=0`, `mipmaps/generate=false`).

**Step 3: Verify** — `grep -A30 '\[params\]' assets/sprites/kit/console.png.import assets/sprites/kit/crate.png.import`; expect `detect_3d/compress_to=0`, `mipmaps/generate=false`, no warnings.

**Step 4: Commit**

```bash
git add assets/sprites/kit/console.png assets/sprites/kit/console.png.import assets/sprites/kit/crate.png assets/sprites/kit/crate.png.import
git commit -m "feat(kit): add console and crate textures"
```

### Task 3: Author `table.png` and `pipe.png`

**Files:**
- Create: `assets/sprites/kit/table.png` (32×16 px)
- Create: `assets/sprites/kit/pipe.png` (16×48 px)

**Depends on:** none
**Parallelizable with:** Task 1, Task 2 (different files)

**Step 1: Author the textures**

`table.png` — 32 wide × 16 tall (2×1 units). Tan fill (`#8B7252`, matching crate) with a 1px darker border; add a horizontal 1px darker line near the top so the top surface reads as a tabletop distinct from the body.

`pipe.png` — 16 wide × 48 tall (the cylinder wraps it; 48 px = 3-unit height × 16). Darker grey fill (`#4C5059`) with two 1px lighter horizontal bands near top and bottom to read as pipe rims.

**Step 2: Import and set the 3D settings** — identical to Task 1 Step 2 (both files, `compress_to=0`, `mipmaps/generate=false`).

**Step 3: Verify** — `grep -A30 '\[params\]' assets/sprites/kit/table.png.import assets/sprites/kit/pipe.png.import`; expect `detect_3d/compress_to=0`, `mipmaps/generate=false`, no warnings.

**Step 4: Commit**

```bash
git add assets/sprites/kit/table.png assets/sprites/kit/table.png.import assets/sprites/kit/pipe.png assets/sprites/kit/pipe.png.import
git commit -m "feat(kit): add table and pipe textures"
```

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 1, Task 2, Task 3 | Each writes distinct PNG + `.import` files under `assets/sprites/kit/`; no shared state |

### Smoketest Checkpoint 1 — textures import cleanly at correct density

**Step 1: Fetch and merge latest master**

```bash
git fetch origin && git merge origin/master
```

**Step 2: Re-import headless and check for warnings**

```powershell
./tools/godot.ps1 -Console --headless --path . --editor --quit 2>&1
```
Expected: no import warnings or `SCRIPT ERROR` lines referencing the kit textures.

**Step 3: Confirm opt-outs and density (AC4/AC5)**

```bash
grep -c "detect_3d/compress_to=0" assets/sprites/kit/*.import   # expect 6
```
Expected: 6. Spot-check the pixel sizes with the `read` tool (or an image editor): `wall_segment` 16×48, `doorframe_lintel` 64×8, `console` 16×32, `crate` 16×16, `table` 32×16, `pipe` 16×48. No texture exceeds 16 texels per world unit (AC4).

**Step 4: Confirm with user** — the six textures exist and import without VRAM compression. Wait for confirmation before Batch 2.

---

## Batch 2 — Kit scenes

Scenes reference Batch 1 textures (dependency), but the three scene tasks write **different files** and are parallel with each other.

### Task 4: Create `wall_segment.tscn` and `doorframe.tscn`

**Files:**
- Create: `scenes/poc3d/kit/wall_segment.tscn`
- Create: `scenes/poc3d/kit/doorframe.tscn`

**Depends on:** Task 1 (textures)
**Parallelizable with:** Task 5, Task 6 (different files)

**Step 1: Write `wall_segment.tscn`**

```text
[gd_scene load_steps=4 format=3]

[ext_resource type="Texture2D" path="res://assets/sprites/kit/wall_segment.png" id="1"]

[sub_resource type="BoxMesh" id="1"]
size = Vector3(1, 3, 1)

[sub_resource type="StandardMaterial3D" id="2"]
texture_filter = 0
metallic_specular = 0
albedo_texture = ExtResource("1")

[node name="WallSegment" type="MeshInstance3D"]
mesh = SubResource("1")
material_override = SubResource("2")
```

`texture_filter = 0` is `TEXTURE_FILTER_NEAREST`; `metallic_specular = 0` gives zero specular (R5); the default `shading_mode` is per-pixel (shaded, not unshaded — leave it).

**Step 2: Write `doorframe.tscn`**

```text
[gd_scene load_steps=5 format=3]

[ext_resource type="Texture2D" path="res://assets/sprites/kit/wall_segment.png" id="1"]
[ext_resource type="Texture2D" path="res://assets/sprites/kit/doorframe_lintel.png" id="2"]

[sub_resource type="BoxMesh" id="1"]
size = Vector3(1, 3, 1)

[sub_resource type="StandardMaterial3D" id="2"]
texture_filter = 0
metallic_specular = 0
albedo_texture = ExtResource("1")

[sub_resource type="BoxMesh" id="3"]
size = Vector3(4, 0.5, 1)

[sub_resource type="StandardMaterial3D" id="4"]
texture_filter = 0
metallic_specular = 0
albedo_texture = ExtResource("2")

[node name="Doorframe" type="Node3D"]

[node name="LeftJamb" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.5, 1.5, 0)
mesh = SubResource("1")
material_override = SubResource("2")

[node name="RightJamb" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.5, 1.5, 0)
mesh = SubResource("1")
material_override = SubResource("2")

[node name="Lintel" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.75, 0)
mesh = SubResource("3")
material_override = SubResource("4")
```

Footprint 4×3×1 units: jambs at x = ±1.5 (spanning x = −2…−1 and +1…+2), lintel spanning x = −2…+2 at y = 2.5…3.0. The opening is exactly **2 units wide × 2.5 units tall** (x = −1…+1, y = 0…2.5) — the same as the existing greybox door.

**Step 3: Verify** — open each scene in the Godot editor; confirm the mesh is a 1×3×1 box (wall) / 4-wide frame with a 2×2.5 opening (doorframe), the material shows the texture with nearest (pixelated) filtering, no specular highlight, and the surface is lit (not unshaded).

**Step 4: Commit**

```bash
git add scenes/poc3d/kit/wall_segment.tscn scenes/poc3d/kit/doorframe.tscn
git commit -m "feat(kit): add wall segment and doorframe scenes"
```

### Task 5: Create `console.tscn` and `crate.tscn`

**Files:**
- Create: `scenes/poc3d/kit/console.tscn`
- Create: `scenes/poc3d/kit/crate.tscn`

**Depends on:** Task 2 (textures)
**Parallelizable with:** Task 4, Task 6 (different files)

**Step 1: Write `console.tscn`** — `MeshInstance3D` `Console` with `BoxMesh` size `Vector3(1, 1, 2)`, material `StandardMaterial3D` with `texture_filter = 0`, `metallic_specular = 0`, `albedo_texture = res://assets/sprites/kit/console.png`.

**Step 2: Write `crate.tscn`** — `MeshInstance3D` `Crate` with `BoxMesh` size `Vector3(1, 1, 1)`, material `StandardMaterial3D` with `texture_filter = 0`, `metallic_specular = 0`, `albedo_texture = res://assets/sprites/kit/crate.png`.

(Note: this `scenes/poc3d/kit/console.tscn` is the **mesh-only** prop — distinct from the existing `scenes/poc3d/console.tscn`, which is the `Area3D` interactable. Do not confuse them.)

**Step 3: Verify** — open each in the editor; confirm correct mesh dimensions and nearest-filtered textured material.

**Step 4: Commit**

```bash
git add scenes/poc3d/kit/console.tscn scenes/poc3d/kit/crate.tscn
git commit -m "feat(kit): add console and crate scenes"
```

### Task 6: Create `table.tscn` and `pipe.tscn`

**Files:**
- Create: `scenes/poc3d/kit/table.tscn`
- Create: `scenes/poc3d/kit/pipe.tscn`

**Depends on:** Task 3 (textures)
**Parallelizable with:** Task 4, Task 5 (different files)

**Step 1: Write `table.tscn`** — `MeshInstance3D` `Table` with `BoxMesh` size `Vector3(2, 1, 1)`, material with `texture_filter = 0`, `metallic_specular = 0`, `albedo_texture = res://assets/sprites/kit/table.png`.

**Step 2: Write `pipe.tscn`** — `MeshInstance3D` `Pipe` with `CylinderMesh` (`top_radius = 0.5`, `bottom_radius = 0.5`, `height = 3.0`), material with `texture_filter = 0`, `metallic_specular = 0`, `albedo_texture = res://assets/sprites/kit/pipe.png`. This is the kit's single cylinder piece.

**Step 3: Verify** — open each in the editor; confirm table is a 2×1×1 box and pipe is a 0.5-radius, 3-tall cylinder, both nearest-filtered and lit.

**Step 4: Commit**

```bash
git add scenes/poc3d/kit/table.tscn scenes/poc3d/kit/pipe.tscn
git commit -m "feat(kit): add table and pipe scenes"
```

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 4, Task 5, Task 6 | Each writes distinct scene files; all depend only on Batch 1 textures (already committed) |

### Smoketest Checkpoint 2 — all six kit scenes render

**Step 1: Fetch and merge latest master**

```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests (sanity — nothing should have changed)**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit 2>&1
```
Expected: all existing tests still pass (the kit scenes are unreferenced so far; no test touches them).

**Step 3: Open each kit scene and confirm visually**

Open `scenes/poc3d/kit/*.tscn` in the Godot editor and confirm: textured, nearest-filtered, lit, correct dimensions, and — for `doorframe.tscn` — a clean 2×2.5 opening.

**Step 4: Confirm with user** — six kit scenes present and rendering. Wait for confirmation before Batch 3.

---

## Batch 3 — Rebuild the POC room

Tasks 7 and 8 both edit `scenes/poc3d/rooms/test_room.tscn` (same file), so they are **sequential**. Task 9 (test suite) depends on both.

### Task 7: Rebuild the walls with `wall_segment` + `doorframe`

**Files:**
- Modify: `scenes/poc3d/rooms/test_room.tscn`

**Depends on:** Task 4 (wall_segment + doorframe scenes)
**Parallelizable with:** none — writes the same file as Task 8

**Step 1: Replace `WestWall`**

Delete the single `Walls/WestWall` `MeshInstance3D` (greybox `BoxMesh` size `(1, 3, 14)` at `(-6.5, 1.5, 0)`) and replace with a `Node3D` container `WestWall` holding **14** instances of `scenes/poc3d/kit/wall_segment.tscn`, each at `x = -6.5`, `y = 1.5`, `z = -6.5 + k` for `k` in `0..13` (i.e. z from −6.5 to +6.5, reproducing the original 14-unit span exactly).

**Step 2: Replace the North wall door**

Delete `NorthWallLeft` (5×3×1 at `(-3.5, 1.5, -6.5)`), `NorthWallRight` (5×3×1 at `(3.5, 1.5, -6.5)`), and `NorthWallLintel` (2×0.5×1 at `(0, 2.75, -6.5)`). Replace with, under `Walls`:

- A `Node3D` container `NorthWallLeft` holding **4** `wall_segment` instances at `z = -6.5`, `y = 1.5`, `x = -5.5, -4.5, -3.5, -2.5`.
- One `doorframe` instance at `(0, 0, -6.5)` (the doorframe's own root is at ground level; its jambs/lintel already carry the y offsets).
- A `Node3D` container `NorthWallRight` holding **4** `wall_segment` instances at `z = -6.5`, `y = 1.5`, `x = +2.5, +3.5, +4.5, +5.5`.

This reproduces the greybox exactly: 4 segments + 4-wide doorframe + 4 segments = 12 units across, door opening 2×2.5 at the centre.

**Step 3: Leave the parapets alone** — `EastParapet` (1×0.5×14) and `SouthParapet` (12×0.5×1) stay as-is: they are flat-colour room staging, not kit vocabulary (per the resolved design decision).

**Step 4: Verify** — open `test_room.tscn` in the editor; confirm the west wall is 14 textured segments, the north wall shows the doorframe with its opening, and the parapets are unchanged. Confirm no geometry overlaps or gaps at the corners.

**Step 5: Commit**

```bash
git add scenes/poc3d/rooms/test_room.tscn
git commit -m "feat(kit): rebuild POC walls from wall_segment and doorframe"
```

### Task 8: Rebuild `BlockB`, `Console`, and `Crate` from kit props

**Files:**
- Modify: `scenes/poc3d/rooms/test_room.tscn`

**Depends on:** Task 5 (console/crate scenes), Task 7 (same file)
**Parallelizable with:** none — writes the same file as Task 7

**Step 1: Replace `BlockB`** — the 1×3×1 pillar at `(2.5, 1.5, -0.5)` becomes a `wall_segment` instance at the same transform (a free-standing pillar — the same piece used as a wall and a column).

**Step 2: Replace the console mesh** — `Blocks/Console` `MeshInstance3D` (greybox `BoxMesh` `(1, 1, 2)` at `(-5.5, 0.5, 0)`) becomes a `scenes/poc3d/kit/console.tscn` instance at `(-5.5, 0.5, 0)`. **Keep the `Interact` child** (the `scenes/poc3d/console.tscn` `Area3D`) exactly where it is — it is the interaction volume and is untouched.

**Step 3: Replace `Crate`** — the 1×1×1 mesh at `(1.5, 0.5, 1.5)` becomes a `scenes/poc3d/kit/crate.tscn` instance at the same transform.

**Step 4: Verify** — open `test_room.tscn`; confirm the three props now use textured kit meshes, the `Interact` child still sits under the console, and the `Collision` node (TileCollision: `blocked` tiles + `border_for_floor = Vector2i(12, 12)`) is byte-for-byte unchanged. The `Floor`, `Sun`, `Env`, `RoomCamera`, `Player3D`, `NPC3D`, `ExitDoor`, and `ReferenceSprite` nodes are all unchanged.

**Step 5: Commit**

```bash
git add scenes/poc3d/rooms/test_room.tscn
git commit -m "feat(kit): replace POC props with kit console, crate, and pillar"
```

### Task 9: Verify the full suite and AC1

**Files:**
- None (verification only)

**Depends on:** Task 7, Task 8
**Parallelizable with:** none — must run after the room is fully rebuilt

**Step 1: Run the full GUT suite (AC2)**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit 2>&1 |
  Select-String -Pattern "SCRIPT ERROR|Failing Tests|Passing Tests|Scripts "
```
Expected: zero `SCRIPT ERROR`, `Failing Tests: 0`, and the same `Passing Tests`/`Scripts` count as on `master` (the `test_poc3d_*` tests — especially `test_poc3d_pipeline.gd`, which asserts the `Floor` node, exactly one `Light3D`, nearest-filtered floor, `RoomCamera` contract angle, and `ReferenceSprite` — stay green). This is the scene gate: no game state, signals, or story-beat triggers were touched, and this confirms it.

**Step 2: Confirm AC1 (no script changes)**

```bash
git diff --stat origin/master -- scripts/
```
Expected: empty output — nothing under `scripts/` changed.

**Step 3: Commit** (nothing to commit if AC1 holds; if the `.tscn` files were already committed in Tasks 7–8, this is a no-op — move on).

#### Parallel Execution Groups — Smoketest Checkpoint 3

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 7 | Rebuilds walls in test_room.tscn |
| B (sequential) | Task 8 | Rebuilds props in test_room.tscn — must follow Task 7 (same file) |
| C (sequential) | Task 9 | Runs the suite + AC1 check — must follow Tasks 7 & 8 |

### Smoketest Checkpoint 3 — the POC room reads correctly

**Step 1: Fetch and merge latest master**

```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests** — same command as Task 9 Step 1; expected all green.

**Step 3: Launch the POC and verify visually (AC2/AC3)**

```powershell
./tools/godot.ps1 --path . "res://scenes/poc3d/poc_entry.tscn"
```
Verify with the user: the room looks the same shape as before (same walls, door opening, props, collision — walking is unchanged, AC2), and the wall/console/crate surfaces now read at the same texel density as the character sprites — watch the top/end faces of wall segments; if any face reads noticeably higher-res than the 16-texel-per-unit sprites, note it (AC3 escalation point).

**Step 4: Confirm with user** — the POC room is visually correct and collision is unchanged. Wait for confirmation before Batch 4.

---

## Batch 4 — Second room demonstrating reusability (AC6/AC7)

### Task 10: Build `workshop.tscn` exercising `table` and `pipe`

**Files:**
- Create: `scenes/poc3d/rooms/workshop.tscn`

**Depends on:** Task 4, Task 5, Task 6 (all kit scenes)
**Parallelizable with:** none — new room, and its smoke test (Task 11) must follow it

**Step 1: Author the room skeleton** (mirror `test_room.tscn`'s non-geometry nodes)

- `Floor` (`MeshInstance3D` with `tile_floor.gd`), `tiles = Vector2i(10, 8)`, a different `tile_col`/`tile_row` from the POC room so it visibly reads as a different room.
- `Collision` (`Node3D` with `tile_collision.gd`), `border_for_floor = Vector2i(10, 8)` (matching the floor), plus blocked tiles authored for the table and pipe footprints.
- `Sun` (`DirectionalLight3D`), `Env` (`WorldEnvironment` — copy the environment sub-resource from `test_room.tscn`), `RoomCamera` (instance `scenes/poc3d/room_camera.tscn`).

**Step 2: Enclose and furnish with kit pieces** — a different layout from the POC room. Requirements: it must exercise **`table`** and **`pipe`** (which the POC room does not use), and it must use **only** the kit scenes (`wall_segment`, `doorframe`, `console`, `table`, `crate`, `pipe`) plus the pre-existing `Floor`. No player/NPC/interactables — this is a static demonstration of reusability.

**Step 3: Verify** — open `workshop.tscn` in the editor; confirm it renders, the `table` and `pipe` are present and textured, and no texture is missing (no magenta/error material).

**Step 4: Commit**

```bash
git add scenes/poc3d/rooms/workshop.tscn
git commit -m "feat(kit): add second room demonstrating kit reusability"
```

### Task 11: Verify the second room and frame time

**Files:**
- None (verification only)

**Depends on:** Task 10
**Parallelizable with:** none — verifies Task 10's output

**Step 1: Launch the second room and verify (AC6)**

```powershell
./tools/godot.ps1 --path . "res://scenes/poc3d/rooms/workshop.tscn"
```
Expected: a complete, textured room assembled entirely from the kit, visibly using `table` and `pipe`, distinct from the POC room's layout.

**Step 2: Check frame time (AC7)**

With the room running on the Mobile renderer, compare frame time against the greybox POC (both are hundreds of triangles — a small `DirectionalLight3D` plus flat primitive meshes; expect no measurable regression). Enable Godot's performance monitor (Debugger → Monitors) or observe the FPS counter; confirm it is unchanged or better versus the greybox.

**Step 3: Final full-suite run**

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit 2>&1 |
  Select-String -Pattern "SCRIPT ERROR|Failing Tests|Passing Tests|Scripts "
```
Expected: all green, count unchanged.

#### Parallel Execution Groups — Smoketest Checkpoint 4

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 10 | Builds workshop.tscn |
| B (sequential) | Task 11 | Verifies it + frame time + full suite — must follow Task 10 |

### Smoketest Checkpoint 4 — reusability demonstrated

**Step 1: Fetch and merge latest master**

```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests** — all green (count unchanged from `master`).

**Step 3: Launch both rooms and confirm**

```powershell
./tools/godot.ps1 --path . "res://scenes/poc3d/poc_entry.tscn"
./tools/godot.ps1 --path . "res://scenes/poc3d/rooms/workshop.tscn"
```

**Step 4: Confirm with user** — the POC room still looks correct, and the second room is assembled from the same kit using `table` and `pipe`. After this, AC1–AC7 are verifiable: `git diff --stat origin/master -- scripts/` is empty (AC1); collision identical (AC2, via green suite); texel density consistent (AC3); no texture exceeds 16/unit (AC4); imports clean with `compress_to=0` (AC5); second room exercises `table`/`pipe` (AC6); frame time unchanged (AC7).

---

## Completion notes for the implementer

- **AC1 is the load-bearing constraint** — no file under `scripts/` may change. If any task tempted you to add a helper script (texture generation, geometry math), it was done throwaway and deleted.
- **`test_poc3d_pipeline.gd` invariants** survive because: the floor stays named `Floor`, kit pieces add no lights (exactly one `DirectionalLight3D`), and the floor material's nearest filtering is untouched.
- **The `Interact` Area3D and `ExitDoor` Area3D** are PRD-3 interaction/collision surfaces — leave them exactly as-is; only the greybox *meshes* are replaced.
