# Trade Dock Area Scene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `scenes/areas/trade_dock.tscn` (with `scripts/areas/trade_dock.gd`) using `station.tres` for correct wall physics, then fix `scripts/main.gd` to load the proper scene so navigation between trade dock ↔ cantina and trade dock ↔ security_post works.

**Architecture:** Copy the tile layout from the YATI-auto-imported `.godot/imported/trade_dock.tmx-*.tscn` (which has the correct 30×16 tile arrangement with left/right door openings at rows 6–9) but reference `station.tres` as the TileSet — this gives correct physics on wall tiles. Add Area2D door triggers at left (x=8, y=128) and right (x=472, y=128) walls, wired via a new `trade_dock.gd` that follows the same lambda-connect pattern as all other area scripts.

**Tech Stack:** Godot 4.6 GDScript, station.tres tileset (uid://djyq0exhut65y), TileMapLayer, Area2D

---

## File Structure

| Action | Path | Purpose |
|--------|------|---------|
| Create | `scripts/areas/trade_dock.gd` | Door navigation — connects CantinaExitDoor and SecurityPostDoor to `main.go_to_area()` |
| Create | `scenes/areas/trade_dock.tscn` | 30×16 tile map with station.tres, two door Area2Ds, SableSpawn Node2D |
| Modify | `scripts/main.gd:5` | Change `.tmx` path to `.tscn` so scene uses station.tres physics |

---

### Task 1: Create `scripts/areas/trade_dock.gd`

**Files:**
- Create: `scripts/areas/trade_dock.gd`

- [ ] **Step 1: Write the script**

```gdscript
# scripts/areas/trade_dock.gd
extends Node2D

@onready var cantina_door: Area2D = $CantinaExitDoor
@onready var security_post_door: Area2D = $SecurityPostDoor

func _ready() -> void:
	var main := get_tree().get_root().get_node("Main")
	cantina_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			main.go_to_area("cantina")
	)
	security_post_door.body_entered.connect(func(body):
		if body.is_in_group("player"):
			main.go_to_area("security_post")
	)
```

---

### Task 2: Create `scenes/areas/trade_dock.tscn`

**Files:**
- Create: `scenes/areas/trade_dock.tscn`

The tile_map_data is taken verbatim from the YATI-auto-imported scene at `.godot/imported/trade_dock.tmx-c2fe13424ce373b95aefc88146fae4a3.tscn`. It encodes a 30×16 grid using only atlas coords (18,15) = floor and (25,15) = wall at source ID 0 — both defined in station.tres with the same atlas layout and separation Vector2i(1,1). The tile data is therefore bit-for-bit compatible with station.tres, and station.tres adds the physics polygon on (25,15) wall tiles that the YATI TileSet lacked.

Door openings are at rows 6–9 on the left column (x=0) and right column (x=29) — both left and right wall edges are floor tiles at those rows, matching the TMX layout.

- [ ] **Step 1: Write the scene file**

```
[gd_scene format=4]

[ext_resource type="Script" path="res://scripts/areas/trade_dock.gd" id="1_script"]
[ext_resource type="TileSet" uid="uid://djyq0exhut65y" path="res://data/tilesets/station.tres" id="2_ts"]

[sub_resource type="RectangleShape2D" id="1"]
size = Vector2(16, 48)

[sub_resource type="RectangleShape2D" id="2"]
size = Vector2(16, 48)

[node name="TradeDock" type="Node2D"]
script = ExtResource("1_script")

[node name="TileMapLayer" type="TileMapLayer" parent="."]
tile_map_data = PackedByteArray("AAAAAAAAAAAZAA8AAAABAAAAAAAZAA8AAAACAAAAAAAZAA8AAAADAAAAAAAZAA8AAAAEAAAAAAAZAA8AAAAFAAAAAAAZAA8AAAAGAAAAAAAZAA8AAAAHAAAAAAAZAA8AAAAIAAAAAAAZAA8AAAAJAAAAAAAZAA8AAAAKAAAAAAAZAA8AAAALAAAAAAAZAA8AAAAMAAAAAAAZAA8AAAANAAAAAAAZAA8AAAAOAAAAAAAZAA8AAAAPAAAAAAAZAA8AAAAQAAAAAAAZAA8AAAARAAAAAAAZAA8AAAASAAAAAAAZAA8AAAATAAAAAAAZAA8AAAAUAAAAAAAZAA8AAAAVAAAAAAAZAA8AAAAWAAAAAAAZAA8AAAAXAAAAAAAZAA8AAAAYAAAAAAAZAA8AAAAZAAAAAAAZAA8AAAAaAAAAAAAZAA8AAAAbAAAAAAAZAA8AAAAcAAAAAAAZAA8AAAAdAAAAAAAZAA8AAAAAAAEAAAAZAA8AAAABAAEAAAASAA8AAAACAAEAAAASAA8AAAADAAEAAAASAA8AAAAEAAEAAAASAA8AAAAFAAEAAAASAA8AAAAGAAEAAAASAA8AAAAHAAEAAAASAA8AAAAIAAEAAAASAA8AAAAJAAEAAAASAA8AAAAKAAEAAAASAA8AAAALAAEAAAASAA8AAAAMAAEAAAASAA8AAAANAAEAAAASAA8AAAAOAAEAAAASAA8AAAAPAAEAAAASAA8AAAAQAAEAAAASAA8AAAARAAEAAAASAA8AAAASAAEAAAASAA8AAAATAAEAAAASAA8AAAAUAAEAAAASAA8AAAAVAAEAAAASAA8AAAAWAAEAAAASAA8AAAAXAAEAAAASAA8AAAAYAAEAAAASAA8AAAAZAAEAAAASAA8AAAAaAAEAAAASAA8AAAAbAAEAAAASAA8AAAAcAAEAAAASAA8AAAAdAAEAAAAZAA8AAAAAAAIAAAAZAA8AAAABAAIAAAASAA8AAAACAAIAAAASAA8AAAADAAIAAAASAA8AAAAEAAIAAAASAA8AAAAFAAIAAAASAA8AAAAGAAIAAAASAA8AAAAHAAIAAAASAA8AAAAIAAIAAAASAA8AAAAJAAIAAAASAA8AAAAKAAIAAAASAA8AAAALAAIAAAASAA8AAAAMAAIAAAASAA8AAAANAAIAAAASAA8AAAAOAAIAAAASAA8AAAAPAAIAAAASAA8AAAAQAAIAAAASAA8AAAARAAIAAAASAA8AAAASAAIAAAASAA8AAAATAAIAAAASAA8AAAAUAAIAAAASAA8AAAAVAAIAAAASAA8AAAAWAAIAAAASAA8AAAAXAAIAAAASAA8AAAAYAAIAAAASAA8AAAAZAAIAAAASAA8AAAAaAAIAAAASAA8AAAAbAAIAAAASAA8AAAAcAAIAAAASAA8AAAAdAAIAAAAZAA8AAAAAAAMAAAAZAA8AAAABAAMAAAASAA8AAAACAAMAAAASAA8AAAADAAMAAAASAA8AAAAEAAMAAAASAA8AAAAFAAMAAAASAA8AAAAGAAMAAAASAA8AAAAHAAMAAAASAA8AAAAIAAMAAAASAA8AAAAJAAMAAAASAA8AAAAKAAMAAAASAA8AAAALAAMAAAASAA8AAAAMAAMAAAASAA8AAAANAAMAAAASAA8AAAAOAAMAAAASAA8AAAAPAAMAAAASAA8AAAAQAAMAAAASAA8AAAARAAMAAAASAA8AAAASAAMAAAASAA8AAAATAAMAAAASAA8AAAAUAAMAAAASAA8AAAAVAAMAAAASAA8AAAAWAAMAAAASAA8AAAAXAAMAAAASAA8AAAAYAAMAAAASAA8AAAAZAAMAAAASAA8AAAAaAAMAAAASAA8AAAAbAAMAAAASAA8AAAAcAAMAAAASAA8AAAAdAAMAAAAZAA8AAAAAAAQAAAAZAA8AAAABAAQAAAASAA8AAAACAAQAAAASAA8AAAADAAQAAAASAA8AAAAEAAQAAAASAA8AAAAFAAQAAAASAA8AAAAGAAQAAAASAA8AAAAHAAQAAAASAA8AAAAIAAQAAAASAA8AAAAJAAQAAAASAA8AAAAKAAQAAAASAA8AAAALAAQAAAASAA8AAAAMAAQAAAASAA8AAAANAAQAAAASAA8AAAAOAAQAAAASAA8AAAAPAAQAAAASAA8AAAAQAAQAAAASAA8AAAARAAQAAAASAA8AAAASAAQAAAASAA8AAAATAAQAAAASAA8AAAAUAAQAAAASAA8AAAAVAAQAAAASAA8AAAAWAAQAAAASAA8AAAAXAAQAAAASAA8AAAAYAAQAAAASAA8AAAAZAAQAAAASAA8AAAAaAAQAAAASAA8AAAAbAAQAAAASAA8AAAAcAAQAAAASAA8AAAAdAAQAAAAZAA8AAAAAAAUAAAAZAA8AAAABAAUAAAASAA8AAAACAAUAAAASAA8AAAADAAUAAAASAA8AAAAEAAUAAAASAA8AAAAFAAUAAAASAA8AAAAGAAUAAAASAA8AAAAHAAUAAAASAA8AAAAIAAUAAAASAA8AAAAJAAUAAAASAA8AAAAKAAUAAAASAA8AAAALAAUAAAASAA8AAAAMAAUAAAASAA8AAAANAAUAAAASAA8AAAAOAAUAAAASAA8AAAAPAAUAAAASAA8AAAAQAAUAAAASAA8AAAARAAUAAAASAA8AAAASAAUAAAASAA8AAAATAAUAAAASAA8AAAAUAAUAAAASAA8AAAAVAAUAAAASAA8AAAAWAAUAAAASAA8AAAAXAAUAAAASAA8AAAAYAAUAAAASAA8AAAAZAAUAAAASAA8AAAAaAAUAAAASAA8AAAAbAAUAAAASAA8AAAAcAAUAAAASAA8AAAAdAAUAAAAZAA8AAAAAAAYAAAASAA8AAAABAAYAAAASAA8AAAACAAYAAAASAA8AAAADAAYAAAASAA8AAAAEAAYAAAASAA8AAAAFAAYAAAASAA8AAAAGAAYAAAASAA8AAAAHAAYAAAASAA8AAAAIAAYAAAASAA8AAAAJAAYAAAASAA8AAAAKAAYAAAASAA8AAAALAAYAAAASAA8AAAAMAAYAAAASAA8AAAANAAYAAAASAA8AAAAOAAYAAAASAA8AAAAPAAYAAAASAA8AAAAQAAYAAAASAA8AAAARAAYAAAASAA8AAAASAAYAAAASAA8AAAATAAYAAAASAA8AAAAUAAYAAAASAA8AAAAVAAYAAAASAA8AAAAWAAYAAAASAA8AAAAXAAYAAAASAA8AAAAYAAYAAAASAA8AAAAZAAYAAAASAA8AAAAaAAYAAAASAA8AAAAbAAYAAAASAA8AAAAcAAYAAAASAA8AAAAdAAYAAAASAA8AAAAAAAcAAAASAA8AAAABAAcAAAASAA8AAAACAAcAAAASAA8AAAADAAcAAAASAA8AAAAEAAcAAAASAA8AAAAFAAcAAAASAA8AAAAGAAcAAAASAA8AAAAHAAcAAAASAA8AAAAIAAcAAAASAA8AAAAJAAcAAAASAA8AAAAKAAcAAAASAA8AAAALAAcAAAASAA8AAAAMAAcAAAASAA8AAAANAAcAAAASAA8AAAAOAAcAAAASAA8AAAAPAAcAAAASAA8AAAAQAAcAAAASAA8AAAARAAcAAAASAA8AAAASAAcAAAASAA8AAAATAAcAAAASAA8AAAAUAAcAAAASAA8AAAAVAAcAAAASAA8AAAAWAAcAAAASAA8AAAAXAAcAAAASAA8AAAAYAAcAAAASAA8AAAAZAAcAAAASAA8AAAAaAAcAAAASAA8AAAAbAAcAAAASAA8AAAAcAAcAAAASAA8AAAAdAAcAAAASAA8AAAAAAAgAAAASAA8AAAABAAgAAAASAA8AAAACAAgAAAASAA8AAAADAAgAAAASAA8AAAAEAAgAAAASAA8AAAAFAAgAAAASAA8AAAAGAAgAAAASAA8AAAAHAAgAAAASAA8AAAAIAAgAAAASAA8AAAAJAAgAAAASAA8AAAAKAAgAAAASAA8AAAALAAgAAAASAA8AAAAMAAgAAAASAA8AAAANAAgAAAASAA8AAAAOAAgAAAASAA8AAAAPAAgAAAASAA8AAAAQAAgAAAASAA8AAAARAAgAAAASAA8AAAASAAgAAAASAA8AAAATAAgAAAASAA8AAAAUAAgAAAASAA8AAAAVAAgAAAASAA8AAAAWAAgAAAASAA8AAAAXAAgAAAASAA8AAAAYAAgAAAASAA8AAAAZAAgAAAASAA8AAAAaAAgAAAASAA8AAAAbAAgAAAASAA8AAAAcAAgAAAASAA8AAAAdAAgAAAASAA8AAAAAAAkAAAASAA8AAAABAAkAAAASAA8AAAACAAkAAAASAA8AAAADAAkAAAASAA8AAAAEAAkAAAASAA8AAAAFAAkAAAASAA8AAAAGAAkAAAASAA8AAAAHAAkAAAASAA8AAAAIAAkAAAASAA8AAAAJAAkAAAASAA8AAAAKAAkAAAASAA8AAAALAAkAAAASAA8AAAAMAAkAAAASAA8AAAANAAkAAAASAA8AAAAOAAkAAAASAA8AAAAPAAkAAAASAA8AAAAQAAkAAAASAA8AAAARAAkAAAASAA8AAAASAAkAAAASAA8AAAATAAkAAAASAA8AAAAUAAkAAAASAA8AAAAVAAkAAAASAA8AAAAWAAkAAAASAA8AAAAXAAkAAAASAA8AAAAYAAkAAAASAA8AAAAZAAkAAAASAA8AAAAaAAkAAAASAA8AAAAbAAkAAAASAA8AAAAcAAkAAAASAA8AAAAdAAkAAAASAA8AAAAAAAoAAAAZAA8AAAABAAoAAAASAA8AAAACAAoAAAASAA8AAAADAAoAAAASAA8AAAAEAAoAAAASAA8AAAAFAAoAAAASAA8AAAAGAAoAAAASAA8AAAAHAAoAAAASAA8AAAAIAAoAAAASAA8AAAAJAAoAAAASAA8AAAAKAAoAAAASAA8AAAALAAoAAAASAA8AAAAMAAoAAAASAA8AAAANAAoAAAASAA8AAAAOAAoAAAASAA8AAAAPAAoAAAASAA8AAAAQAAoAAAASAA8AAAARAAoAAAASAA8AAAASAAoAAAASAA8AAAATAAoAAAASAA8AAAAUAAoAAAASAA8AAAAVAAoAAAASAA8AAAAWAAoAAAASAA8AAAAXAAoAAAASAA8AAAAYAAoAAAASAA8AAAAZAAoAAAASAA8AAAAaAAoAAAASAA8AAAAbAAoAAAASAA8AAAAcAAoAAAASAA8AAAAdAAoAAAAZAA8AAAAAAAsAAAAZAA8AAAABAAsAAAASAA8AAAACAAsAAAASAA8AAAADAAsAAAASAA8AAAAEAAsAAAASAA8AAAAFAAsAAAASAA8AAAAGAAsAAAASAA8AAAAHAAsAAAASAA8AAAAIAAsAAAASAA8AAAAJAAsAAAASAA8AAAAKAAsAAAASAA8AAAALAAsAAAASAA8AAAAMAAsAAAASAA8AAAANAAsAAAASAA8AAAAOAAsAAAASAA8AAAAPAAsAAAASAA8AAAAQAAsAAAASAA8AAAARAAsAAAASAA8AAAASAAsAAAASAA8AAAATAAsAAAASAA8AAAAUAAsAAAASAA8AAAAVAAsAAAASAA8AAAAWAAsAAAASAA8AAAAXAAsAAAASAA8AAAAYAAsAAAASAA8AAAAZAAsAAAASAA8AAAAaAAsAAAASAA8AAAAbAAsAAAASAA8AAAAcAAsAAAASAA8AAAAdAAsAAAAZAA8AAAAAAAwAAAAZAA8AAAABAAwAAAASAA8AAAACAAwAAAASAA8AAAADAAwAAAASAA8AAAAEAAwAAAASAA8AAAAFAAwAAAASAA8AAAAGAAwAAAASAA8AAAAHAAwAAAASAA8AAAAIAAwAAAASAA8AAAAJAAwAAAASAA8AAAAKAAwAAAASAA8AAAALAAwAAAASAA8AAAAMAAwAAAASAA8AAAANAAwAAAASAA8AAAAOAAwAAAASAA8AAAAPAAwAAAASAA8AAAAQAAwAAAASAA8AAAARAAwAAAASAA8AAAASAAwAAAASAA8AAAATAAwAAAASAA8AAAAUAAwAAAASAA8AAAAVAAwAAAASAA8AAAAWAAwAAAASAA8AAAAXAAwAAAASAA8AAAAYAAwAAAASAA8AAAAZAAwAAAASAA8AAAAaAAwAAAASAA8AAAAbAAwAAAASAA8AAAAcAAwAAAASAA8AAAAdAAwAAAAZAA8AAAAAAA0AAAAZAA8AAAABAA0AAAASAA8AAAACAA0AAAASAA8AAAADAA0AAAASAA8AAAAEAA0AAAASAA8AAAAFAA0AAAASAA8AAAAGAA0AAAASAA8AAAAHAA0AAAASAA8AAAAIAA0AAAASAA8AAAAJAA0AAAASAA8AAAAKAA0AAAASAA8AAAALAA0AAAASAA8AAAAMAA0AAAASAA8AAAANAA0AAAASAA8AAAAOAA0AAAASAA8AAAAPAA0AAAASAA8AAAAQAA0AAAASAA8AAAARAA0AAAASAA8AAAASAA0AAAASAA8AAAATAA0AAAASAA8AAAAUAA0AAAASAA8AAAAVAA0AAAASAA8AAAAWAA0AAAASAA8AAAAXAA0AAAASAA8AAAAYAA0AAAASAA8AAAAZAA0AAAASAA8AAAAaAA0AAAASAA8AAAAbAA0AAAASAA8AAAAcAA0AAAASAA8AAAAdAA0AAAAZAA8AAAAAAA4AAAAZAA8AAAABAA4AAAASAA8AAAACAA4AAAASAA8AAAADAA4AAAASAA8AAAAEAA4AAAASAA8AAAAFAA4AAAASAA8AAAAGAA4AAAASAA8AAAAHAA4AAAASAA8AAAAIAA4AAAASAA8AAAAJAA4AAAASAA8AAAAKAA4AAAASAA8AAAALAA4AAAASAA8AAAAMAA4AAAASAA8AAAANAA4AAAASAA8AAAAOAA4AAAASAA8AAAAPAA4AAAASAA8AAAAQAA4AAAASAA8AAAARAA4AAAASAA8AAAASAA4AAAASAA8AAAATAA4AAAASAA8AAAAUAA4AAAASAA8AAAAVAA4AAAASAA8AAAAWAA4AAAASAA8AAAAXAA4AAAASAA8AAAAYAA4AAAASAA8AAAAZAA4AAAASAA8AAAAaAA4AAAASAA8AAAAbAA4AAAASAA8AAAAcAA4AAAASAA8AAAAdAA4AAAAZAA8AAAAAAA8AAAAZAA8AAAABAA8AAAAZAA8AAAACAA8AAAAZAA8AAAADAA8AAAAZAA8AAAAEAA8AAAAZAA8AAAAFAA8AAAAZAA8AAAAGAA8AAAAZAA8AAAAHAA8AAAAZAA8AAAAIAA8AAAAZAA8AAAAJAA8AAAAZAA8AAAAKAA8AAAAZAA8AAAALAA8AAAAZAA8AAAAMAA8AAAAZAA8AAAANAA8AAAAZAA8AAAAOAA8AAAAZAA8AAAAPAA8AAAAZAA8AAAAQAA8AAAAZAA8AAAARAA8AAAAZAA8AAAASAA8AAAAZAA8AAAATAA8AAAAZAA8AAAAUAA8AAAAZAA8AAAAVAA8AAAAZAA8AAAAWAA8AAAAZAA8AAAAXAA8AAAAZAA8AAAAYAA8AAAAZAA8AAAAZAA8AAAAZAA8AAAAaAA8AAAAZAA8AAAAbAA8AAAAZAA8AAAAcAA8AAAAZAA8AAAAdAA8AAAAZAA8AAAA=")
tile_set = ExtResource("2_ts")

[node name="SableSpawn" type="Node2D" parent="."]
position = Vector2(240, 128)

[node name="CantinaExitDoor" type="Area2D" parent="."]
position = Vector2(8, 128)

[node name="CollisionShape2D" type="CollisionShape2D" parent="CantinaExitDoor"]
shape = SubResource("1")

[node name="SecurityPostDoor" type="Area2D" parent="."]
position = Vector2(472, 128)

[node name="CollisionShape2D" type="CollisionShape2D" parent="SecurityPostDoor"]
shape = SubResource("2")
```

**Tile data explained:** The PackedByteArray stores 8 bytes per tile as (x int16 LE, y int16 LE, source_id int16 LE, atlas_x uint8, atlas_y uint8). Every tile uses source_id=0 and either atlas (25,15) = wall (base64 suffix `ZAA8`) or atlas (18,15) = floor (base64 suffix `SAA8`). Rows 6–9 have floor at x=0 and x=29 (left/right door openings); all other edge cells are wall.

The tile_map_data is taken verbatim from `.godot/imported/trade_dock.tmx-c2fe13424ce373b95aefc88146fae4a3.tscn` (the YATI auto-import). The only change is the TileSet reference — station.tres instead of the YATI-local TileSet — which adds the physics collision polygon to the (25,15) wall tiles.

- [ ] **Step 2: Verify the file was written**

```powershell
(Get-Content "scenes/areas/trade_dock.tscn" | Measure-Object -Line).Lines
```

Expected: 43 lines.

---

### Task 3: Fix `scripts/main.gd:5`

**Files:**
- Modify: `scripts/main.gd:5`

The current line loads the raw TMX (YATI-imported, no wall physics). Change it to the new proper scene.

- [ ] **Step 1: Edit the line**

In `scripts/main.gd`, change line 5 from:

```gdscript
	"trade_dock":        "res://data/maps/trade_dock.tmx",
```

to:

```gdscript
	"trade_dock":        "res://scenes/areas/trade_dock.tscn",
```

- [ ] **Step 2: Verify the change**

```powershell
Select-String -Path "scripts/main.gd" -Pattern "trade_dock"
```

Expected output — the `trade_dock` line should show `.tscn`, not `.tmx`:
```
scripts/main.gd:5:	"trade_dock":        "res://scenes/areas/trade_dock.tscn",
```

---

### Task 4: Verify in the editor

**Files:** none (read-only verification)

- [ ] **Step 1: Open the project in Godot**

Launch Godot and open the project. The import system will scan `scenes/areas/trade_dock.tscn` and add it to the resource cache. Wait for the import to finish (bottom status bar shows no activity).

Expected: Output panel shows zero `TileSetAtlasSource has no tile at (5[789])` errors (the OOB tiles are already removed by PR #94's tileset fix).

- [ ] **Step 2: Run the game (F5)**

The game starts in trade_dock (see `main.gd:78`: `go_to_area("trade_dock")`). Verify:

- Trade dock tiles render: dark floor tiles in the middle, wall tiles on the border
- Left wall has a 4-tile-tall opening at rows 6–9 (y ≈ 96–160), right wall has the same
- Sable is NOT visible (requires `sable_arrived` flag — correct for initial state)
- Output panel shows no errors

- [ ] **Step 3: Navigate left → cantina**

Walk the player left into the door opening on the left wall. The player should enter the Area2D `CantinaExitDoor` at x=8, triggering `go_to_area("cantina")`.

Expected: fade out → fade in → cantina scene loads, player spawns at `Vector2(240, 224)` (bottom center, matching `AREA_ENTRY_POSITIONS["cantina"]["trade_dock"]`).

- [ ] **Step 4: Navigate cantina → trade_dock**

From cantina, walk the player down into the bottom wall door opening (the `TradeDockDoor` Area2D at y=248).

Expected: fade out → fade in → trade_dock loads, player spawns at `Vector2(32, 128)` (left side, matching `AREA_ENTRY_POSITIONS["trade_dock"]["cantina"]`).

- [ ] **Step 5: Navigate right → security_post**

Walk the player right into the right wall door opening. The `SecurityPostDoor` Area2D at x=472 triggers `go_to_area("security_post")`.

Expected: fade out → fade in → security_post loads, player spawns at `Vector2(240, 224)` (bottom center, matching `AREA_ENTRY_POSITIONS["security_post"]["trade_dock"]`).

- [ ] **Step 6: Navigate security_post → trade_dock**

From security_post, walk the player down into the `TradeDockDoor` Area2D at y=248.

Expected: fade out → fade in → trade_dock loads, player spawns at `Vector2(448, 128)` (right side, matching `AREA_ENTRY_POSITIONS["trade_dock"]["security_post"]`).

- [ ] **Step 7: Verify wall collision**

In trade_dock, walk the player toward the top wall, bottom wall, and any closed part of the left/right walls (above row 6 or below row 9). The player should stop at the wall boundary.

Expected: player cannot walk through walls anywhere except the door openings.

---

### Task 5: Commit

**Files:**
- `scripts/areas/trade_dock.gd`
- `scenes/areas/trade_dock.tscn`
- `scripts/main.gd`

- [ ] **Step 1: Stage and commit**

```powershell
git add scripts/areas/trade_dock.gd scenes/areas/trade_dock.tscn scripts/main.gd
git commit -m "feat: add trade_dock.tscn area scene with station.tres physics

Creates scenes/areas/trade_dock.tscn (left+right door openings, station.tres
tileset for correct wall collision) and scripts/areas/trade_dock.gd (lambda
door connections to cantina and security_post). Fixes main.gd to load the
proper .tscn instead of the YATI-auto-imported .tmx which had no wall physics.

Completes PR #94 test criteria: trade dock renders correctly, navigation
between trade dock ↔ cantina and trade dock ↔ security_post works."
```

---

## Self-Review

**Spec coverage (PR #94 test plan):**
- ✅ "Launch game — Output panel shows zero TileSetAtlasSource errors" — OOB tile fix from PR already done; no new tile errors introduced (tile data only uses valid atlas coords 25:15 and 18:15)
- ✅ "Trade dock renders with correct wall/floor tiles matching the other area scenes" → Task 2 (station.tres, same atlas tiles)
- ✅ "Door openings on left (cantina) and right (security post) walls are visually visible" → Task 2 (rows 6–9 are floor on left/right columns)
- ✅ "Navigation between trade dock and cantina / security post works" → Tasks 1–3 + existing cantina.gd/security_post.gd `TradeDockDoor` connections

**No placeholders:** All steps include exact file content, exact commands, and exact expected output.

**Type consistency:**
- `trade_dock.gd` uses `$CantinaExitDoor` and `$SecurityPostDoor` — these match the node names in `trade_dock.tscn` exactly
- `main.gd` `AREA_ENTRY_POSITIONS["trade_dock"]` already defined with correct spawn offsets for cantina, security_post, derelict_entrance
- `main.gd` `_spawn_npcs()` calls `find_child("SableSpawn", true, false)` — `SableSpawn` node is at root level in trade_dock.tscn, recursive find will locate it
