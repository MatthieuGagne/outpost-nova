# Asset Directory Consolidation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Merge `art/placeholder/` game-ready exports into a clean `assets/` tree, update all `res://` path references, and leave `art/` as a source-files-only workspace.

**Architecture:** Pure filesystem refactor — no GDScript logic changes. Move PNG/TTF files, delete stale `.import` files (Godot regenerates them on next editor open), and do text find-and-replace on `res://art/placeholder/...` paths in five affected files. Single atomic commit.

**Tech Stack:** Bash (`mv`, `rm`, `sed`), Godot 4.6.1 (reimport on open)

## Open questions (must resolve before starting)

- None — all decisions captured in GitHub issue #60.

---

## Batch 1: Full Asset Migration (Tasks 1–4)

> **Note:** This batch cannot be subdivided into independently smoke-testable sub-batches. Moving files without updating `res://` paths leaves the project with broken resource references, and updating paths before moving files produces the same result. All four tasks must be completed before the smoketest.

---

### Task 1: Remove unreferenced portrait and create target directories

**Files:**
- Delete: `assets/portraits/portraits.png`
- Delete: `assets/portraits/portraits.png.import`
- Create dirs: `assets/sprites/characters/`, `assets/sprites/tiles/`, `assets/fonts/`

**Depends on:** none
**Parallelizable with:** Task 2 — writes different files, no shared state

**Step 1: Delete unreferenced portrait**

```bash
rm assets/portraits/portraits.png assets/portraits/portraits.png.import
```

**Step 2: Create target directories**

```bash
mkdir -p assets/sprites/characters assets/sprites/tiles assets/fonts
```

**Step 3: Verify**

```bash
ls assets/sprites/characters assets/sprites/tiles assets/fonts
# Expected: three empty directories listed with no error
ls assets/portraits/portraits.png 2>&1
# Expected: "No such file or directory"
```

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove unreferenced portraits.png, scaffold assets/ subdirs"
```

---

### Task 2: Update all res:// path references

**Files:**
- Modify: `data/sprites/player_frames.tres`
- Modify: `data/sprites/npc_frames.tres`
- Modify: `data/fonts/m5x7.tres`
- Modify: `data/tilesets/station.tres`
- Modify: `scripts/ui/dialogue_box.gd`

**Depends on:** none
**Parallelizable with:** Task 1 — touches only text files, no dependency on physical file locations

**Step 1: Replace character sprite paths**

```bash
sed -i 's|res://art/placeholder/characters/|res://assets/sprites/characters/|g' \
  data/sprites/player_frames.tres \
  data/sprites/npc_frames.tres
```

**Step 2: Replace font path**

```bash
sed -i 's|res://art/placeholder/fonts/|res://assets/fonts/|g' \
  data/fonts/m5x7.tres
```

**Step 3: Replace tileset path**

```bash
sed -i 's|res://art/placeholder/tiles/|res://assets/sprites/tiles/|g' \
  data/tilesets/station.tres
```

**Step 4: Replace portrait path (includes rename IMG_5371.png → portrait_sheet.png)**

```bash
sed -i 's|res://art/placeholder/portraits/IMG_5371\.png|res://assets/portraits/portrait_sheet.png|g' \
  scripts/ui/dialogue_box.gd
```

**Step 5: Verify no res://art references remain in main branch files**

```bash
grep -r "res://art" data/ scripts/ --include="*.tres" --include="*.tscn" --include="*.gd"
# Expected: no output
```

**Step 6: Commit**

```bash
git add data/sprites/player_frames.tres data/sprites/npc_frames.tres \
        data/fonts/m5x7.tres data/tilesets/station.tres \
        scripts/ui/dialogue_box.gd
git commit -m "chore: update res:// paths from art/placeholder/ to assets/"
```

---

### Task 3: Move game-ready files from art/placeholder/ to assets/

**Files:**
- Move: `art/placeholder/characters/*.png` → `assets/sprites/characters/`
- Move: `art/placeholder/tiles/roguelikeSheet_transparent.png` → `assets/sprites/tiles/`
- Move: `art/placeholder/fonts/m5x7.ttf` → `assets/fonts/`
- Move+rename: `art/placeholder/portraits/IMG_5371.png` → `assets/portraits/portrait_sheet.png`

**Depends on:** Task 1 (target directories must exist)
**Parallelizable with:** none — depends on Task 1; also conceptually sequential after Task 2 so path updates can be verified against real file locations

**Step 1: Move character sprites (PNG only — leave .xcf source files in art/)**

```bash
mv art/placeholder/characters/*.png assets/sprites/characters/
```

**Step 2: Move tileset**

```bash
mv art/placeholder/tiles/roguelikeSheet_transparent.png assets/sprites/tiles/
```

**Step 3: Move font**

```bash
mv art/placeholder/fonts/m5x7.ttf assets/fonts/
```

**Step 4: Move and rename portrait**

```bash
mv art/placeholder/portraits/IMG_5371.png assets/portraits/portrait_sheet.png
```

**Step 5: Verify files are in new locations**

```bash
ls assets/sprites/characters/
# Expected: dex.png dex_left.png maris.png maris_left.png player.png player_left.png
#           sable.png sable_left.png  "16x32 Walk-Sheet.png"

ls assets/sprites/tiles/ assets/fonts/ assets/portraits/
# Expected: roguelikeSheet_transparent.png / m5x7.ttf / portrait_sheet.png

ls art/placeholder/characters/
# Expected: characters.xcf  dex.xcf  (source files only — no .png)
```

**Step 6: Commit**

```bash
git add -A
git commit -m "chore: move game-ready art exports to assets/"
```

---

### Task 4: Delete stale .import files and Zone.Identifier artifacts from art/

**Files:**
- Delete: all `*.import` files under `art/placeholder/`
- Delete: all `*:Zone.Identifier` files under `art/placeholder/`

**Depends on:** Task 3 (files must already be moved so we're not deleting imports for assets still in art/)
**Parallelizable with:** none — must run after Task 3

**Step 1: Delete stale imports and Windows artifacts**

```bash
find art/placeholder -name "*.import" -delete
find art/placeholder -name "*:Zone.Identifier" -delete
```

**Step 2: Verify no imports remain under art/**

```bash
find art/ -name "*.import"
# Expected: no output
```

**Step 3: Commit**

```bash
git add -A
git commit -m "chore: remove stale .import files from art/ after migration"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 1, Task 2 | Different output files, no shared state |
| B (sequential) | Task 3 | Depends on Task 1 (target dirs must exist); run after Group A |
| C (sequential) | Task 4 | Depends on Task 3 (files must be moved first) |

---

### Smoketest Checkpoint 1 — No missing resources, GUT green

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass, zero failures.

**Step 3: Open the Godot editor and check for errors**
```bash
godot
```
In the editor:
- Open the **FileSystem** dock — confirm `assets/sprites/characters/`, `assets/sprites/tiles/`, `assets/fonts/`, `assets/portraits/` all appear and are populated.
- Check the **Output** panel for any `ERROR: Failed to load resource` lines — there should be none.
- Open `scenes/main.tscn` — confirm no pink/missing-texture nodes.
- Open `scenes/ui/dialogue_box.tscn` — confirm no missing portrait resource.

**Step 4: Confirm with user**
Ask: "Do you see any missing-resource errors in the editor, and does the game scene load cleanly?"

Wait for confirmation before proceeding.
