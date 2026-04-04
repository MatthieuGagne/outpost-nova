# Character Creation Screen: Layout Fix and Keyboard Navigation

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the character creation screen to fit the 480×270 viewport and add full keyboard navigation (Tab/Arrow/Enter).

**Architecture:** Pure scene + script changes — no new autoload logic. A new Theme `.tres` adds the m5x7 font and a Button focus StyleBox; the scene gets revised VBox offsets, reduced separation, theme assignment, and declarative `focus_neighbor_*` wiring on all buttons; the script gains one `text_submitted` connection on `NameInput`.

**Tech Stack:** Godot 4.6.1 / GDScript. No GUT tests required (no autoload logic changes).

## Open questions (must resolve before starting)

- None.

---

## Batch 1 — Theme, Script, and Scene

### Task 1: Create `data/themes/character_creation_theme.tres`

**Files:**
- Create: `data/themes/character_creation_theme.tres`

**Depends on:** none — creates a new file with no dependencies
**Parallelizable with:** Task 2 — writes a different file; no shared state

**Step 1: Write the file**

Create `data/themes/character_creation_theme.tres` with this exact content:

```
[gd_resource type="Theme" load_steps=3 format=3]

[ext_resource type="FontFile" path="res://data/fonts/m5x7.tres" id="1"]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_1"]
bg_color = Color(0, 0, 0, 0)
draw_center = false
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(1, 1, 1, 1)

[resource]
Button/fonts/font = ExtResource("1")
Label/fonts/font = ExtResource("1")
Button/styles/focus = SubResource("StyleBoxFlat_1")
```

**Step 2: Verify**

Open Godot editor. In the FileSystem dock, confirm `data/themes/character_creation_theme.tres` appears and shows type "Theme". Double-click it — the Theme editor should open and show:
- Under **Button → Fonts → font**: m5x7
- Under **Button → Styles → focus**: a StyleBoxFlat
- Under **Label → Fonts → font**: m5x7

If Godot reports a parse error, re-check the file content exactly matches the template above.

**Step 3: Commit**

```bash
git add data/themes/character_creation_theme.tres
git commit -m "feat: add character creation Theme with m5x7 font and focus ring"
```

---

### Task 2: Connect `text_submitted` in `scripts/ui/character_creation.gd`

**Files:**
- Modify: `scripts/ui/character_creation.gd`

**Depends on:** none — modifies a different file from Task 1
**Parallelizable with:** Task 1 — different output file, no shared state

**Step 1: Add the signal connection**

In `_ready()`, add one line after the existing `start_btn.pressed.connect(_on_start)`:

```gdscript
func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	name_input.text_submitted.connect(_on_start.unbind(1))
	for i in appearance_picker.get_child_count():
		appearance_picker.get_child(i).pressed.connect(_set_appearance.bind(i))
	for i in background_picker.get_child_count():
		background_picker.get_child(i).pressed.connect(_set_background.bind(i))
```

The `.unbind(1)` discards the `new_text: String` argument that `text_submitted` emits — `_on_start` reads `name_input.text` directly, so it doesn't need the passed value.

**Step 2: Verify**

No automated test needed. Verification happens at Smoketest Checkpoint 1 (press Enter in NameInput → game starts).

**Step 3: Commit**

```bash
git add scripts/ui/character_creation.gd
git commit -m "feat: submit character creation form with Enter in NameInput"
```

---

### Task 3: Update `scenes/character_creation.tscn` — layout, theme, focus neighbors

**Files:**
- Modify: `scenes/character_creation.tscn`

**Depends on:** Task 1 — references `character_creation_theme.tres` as an `ext_resource`
**Parallelizable with:** none — must run after Task 1 completes so the theme file exists before Godot resolves the reference

Replace the entire contents of `scenes/character_creation.tscn` with:

```
[gd_scene format=3 uid="uid://d1egurn6jhlow"]

[ext_resource type="Script" uid="uid://cnm3hfp72i82p" path="res://scripts/ui/character_creation.gd" id="1"]
[ext_resource type="Theme" path="res://data/themes/character_creation_theme.tres" id="2"]

[node name="CharacterCreation" type="Control" unique_id=1216842655]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = 1.0
offset_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
theme = ExtResource("2")

[node name="VBoxContainer" type="VBoxContainer" parent="." unique_id=37817519]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -150.0
offset_top = -130.0
offset_right = 150.0
offset_bottom = 130.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 6

[node name="TitleLabel" type="Label" parent="VBoxContainer" unique_id=1288604451]
layout_mode = 2
text = "Outpost Nova"
horizontal_alignment = 1

[node name="NameInput" type="LineEdit" parent="VBoxContainer" unique_id=1680166273]
layout_mode = 2
placeholder_text = "Your name..."

[node name="AppearanceLabel" type="Label" parent="VBoxContainer" unique_id=886582674]
layout_mode = 2
text = "Appearance"

[node name="AppearancePicker" type="HBoxContainer" parent="VBoxContainer" unique_id=1003301982]
layout_mode = 2

[node name="Appearance0" type="Button" parent="VBoxContainer/AppearancePicker" unique_id=600960377]
layout_mode = 2
text = "A"
focus_neighbor_right = NodePath("../Appearance1")

[node name="Appearance1" type="Button" parent="VBoxContainer/AppearancePicker" unique_id=98444489]
layout_mode = 2
text = "B"
focus_neighbor_left = NodePath("../Appearance0")
focus_neighbor_right = NodePath("../Appearance2")

[node name="Appearance2" type="Button" parent="VBoxContainer/AppearancePicker" unique_id=1684006321]
layout_mode = 2
text = "C"
focus_neighbor_left = NodePath("../Appearance1")

[node name="BackgroundLabel" type="Label" parent="VBoxContainer" unique_id=1635339208]
layout_mode = 2
text = "Background"

[node name="BackgroundPicker" type="VBoxContainer" parent="VBoxContainer" unique_id=1542873528]
layout_mode = 2
theme_override_constants/separation = 4

[node name="Engineer" type="Button" parent="VBoxContainer/BackgroundPicker" unique_id=574058161]
layout_mode = 2
text = "Engineer (starts with Parts)"
focus_neighbor_bottom = NodePath("../Medic")

[node name="Medic" type="Button" parent="VBoxContainer/BackgroundPicker" unique_id=395805715]
layout_mode = 2
text = "Medic (starts with Rations)"
focus_neighbor_top = NodePath("../Engineer")
focus_neighbor_bottom = NodePath("../Drifter")

[node name="Drifter" type="Button" parent="VBoxContainer/BackgroundPicker" unique_id=684165331]
layout_mode = 2
text = "Drifter (starts with Energy Cells)"
focus_neighbor_top = NodePath("../Medic")

[node name="StartBtn" type="Button" parent="VBoxContainer" unique_id=67328775]
layout_mode = 2
text = "Begin"
```

**Changes from original:**
- Added `ext_resource id="2"` for the theme
- Added `theme = ExtResource("2")` on `CharacterCreation`
- `VBoxContainer`: `offset_top` -180 → -130, `offset_bottom` 180 → 130, `separation` 12 → 6
- `BackgroundPicker`: added `theme_override_constants/separation = 4`
- `Appearance0/1/2`: added `focus_neighbor_left/right` to wire Left/Right arrows within group (edges stop)
- `Engineer/Medic/Drifter`: added `focus_neighbor_top/bottom` to wire Up/Down arrows within group (edges stop)

**Step 2: Verify**

Open Godot editor and check:
1. No red errors in the Output panel on scene load
2. The `CharacterCreation` node's Inspector shows the Theme assigned
3. Open `character_creation.tscn` in the 2D viewport — all UI elements should be visible within the blue 480×270 viewport rect, nothing clipped at the bottom

> **If content overflows the viewport:** Reduce `VBoxContainer` `theme_override_constants/separation` to 4 and `BackgroundPicker` `theme_override_constants/separation` to 2, then re-check.

**Step 3: Commit**

```bash
git add scenes/character_creation.tscn
git commit -m "feat: fix character creation layout and wire keyboard focus navigation"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 1, Task 2 | Different output files (`character_creation_theme.tres`, `character_creation.gd`); no shared state |
| B (sequential) | Task 3 | Depends on Task 1 — scene references the theme by path; must run after Task 1 commits |

---

### Smoketest Checkpoint 1 — full character creation screen end-to-end

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All existing tests pass, zero failures.

**Step 3: Launch game and verify visually**
```bash
godot
```

Confirm all of the following in the running game:

| # | What to check |
|---|---------------|
| AC1 | Full character creation form visible — no elements cut off at the bottom of the 270px screen |
| AC2 | All labels and button text render in the m5x7 pixel font (blocky, no anti-aliasing) |
| AC3 | Tab moves focus: NameInput → Appearance0 → Appearance1 → Appearance2 → Engineer → Medic → Drifter → StartBtn |
| AC4 | With Appearance0 focused, Right arrow moves to Appearance1; Left on Appearance0 does nothing; Right on Appearance2 does nothing |
| AC4 | With Engineer focused, Down arrow moves to Medic; Up on Engineer does nothing; Down on Drifter does nothing |
| AC5 | Pressing Enter while NameInput is focused starts the game (transitions to main scene) |
| AC5 | Pressing Enter or Space while StartBtn is focused starts the game |
| AC6 | Mouse clicks on all appearance/background buttons and Begin work as before |
| AC7 | A white focus border is visible on the currently focused button |

**Step 4: Confirm with user**

Wait for the user to confirm all AC items above pass before closing the branch.
