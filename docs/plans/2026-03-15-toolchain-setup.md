# Toolchain Setup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Install and wire up Yarn Spinner + Tiled importer plugins, create stub dialogue files, and scaffold audio/map asset directories.

**Architecture:** Two Godot plugins added to `addons/`. Yarn Spinner replaces the planned GDScript if/elif dialogue pattern — characters call the `DialogueRunner` node instead of returning strings. Tiled maps are imported from `.tmx` files in `data/maps/` via the importer plugin. Audio assets live under `assets/audio/`.

**Tech Stack:** Godot 4.6.1 (GDScript), YarnSpinner-Godot (official Godot 4 plugin), Tiled Map Importer (Godot 4 fork), Yarn scripting language.

---

## Task 1: Install Yarn Spinner plugin

**Files:**
- Create: `addons/yarn_spinner/` (plugin files)
- Modify: `project.godot` (enable plugin)

**Step 1: Download the plugin**

Go to: https://github.com/YarnSpinnerTool/YarnSpinner-Godot/releases

Download the latest release ZIP. Extract the `addons/yarnspinner` folder into your project so it becomes:
```
addons/yarnspinner/plugin.cfg
addons/yarnspinner/...
```

> Note: the folder name in the repo is `yarnspinner` (no underscore) — keep it as-is.

**Step 2: Enable the plugin in Godot**

Open Godot editor → Project → Project Settings → Plugins tab → find "Yarn Spinner for Godot" → click Enable.

This auto-adds it to `project.godot`:
```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/gut/plugin.cfg", "res://addons/yarnspinner/plugin.cfg")
```

**Step 3: Verify**

In the Godot editor, confirm no errors in the Output panel. You should see a new "Yarn Spinner" dock or no errors on load.

**Step 4: Commit**

```bash
git add addons/yarnspinner/ project.godot
git commit -m "feat: add Yarn Spinner plugin"
```

---

## Task 2: Install Tiled Map Importer plugin

**Files:**
- Create: `addons/tiled_importer/` (plugin files)
- Modify: `project.godot` (enable plugin)

**Step 1: Download the plugin**

For Godot 4, use the Godot Asset Library or this repo:
https://github.com/victordeleau/godot-tiled-importer

> Alternative: search "Tiled" in Godot's built-in Asset Library (AssetLib tab in editor) — install directly from there. Look for one marked Godot 4 compatible.

Extract or install so you have:
```
addons/tiled_importer/plugin.cfg
addons/tiled_importer/...
```

**Step 2: Enable the plugin**

Project → Project Settings → Plugins → enable "Tiled Map Importer".

`project.godot` should now include it:
```ini
enabled=PackedStringArray("res://addons/gut/plugin.cfg", "res://addons/yarnspinner/plugin.cfg", "res://addons/tiled_importer/plugin.cfg")
```

**Step 3: Verify**

Open Godot editor. In the FileSystem dock, `.tmx` files should now show an import icon. No errors in Output panel.

**Step 4: Commit**

```bash
git add addons/tiled_importer/ project.godot
git commit -m "feat: add Tiled map importer plugin"
```

---

## Task 3: Create stub Yarn dialogue files

**Files:**
- Create: `data/dialogue/cook.yarn`
- Create: `data/dialogue/engineer.yarn`
- Create: `data/dialogue/drifter.yarn`

**Step 1: Create data/dialogue/ and stub files**

`data/dialogue/cook.yarn`:
```yarn
title: Cook_Default
---
Maris: Hey. Food printer's running. You hungry?
===

title: Cook_WorkshopUnlocked
---
Maris: Workshop's open now. Dex'll be insufferable about it.
===
```

`data/dialogue/engineer.yarn`:
```yarn
title: Engineer_Default
---
Dex: Don't touch the conduit panel. I just fixed it.
===

title: Engineer_WorkshopUnlocked
---
Dex: Finally. I can actually do my job in there.
===
```

`data/dialogue/drifter.yarn`:
```yarn
title: Drifter_Default
---
Sable: Nice place. Might stick around a while.
===

title: Drifter_WorkshopUnlocked
---
Sable: A workshop. This station's getting serious.
===
```

> These are stubs only — real dialogue goes here in a later task. The `title:` headers are how Yarn Spinner identifies which node to run. One title per gameplay state per character.

**Step 2: Create a Yarn Project resource**

In the Godot editor: right-click `data/dialogue/` → New Resource → search "YarnProject" → save as `data/dialogue/dialogue.yarnproject`.

In the Inspector, add all three `.yarn` files to the project's source list.

**Step 3: Verify**

In Godot Output panel: no parse errors from Yarn Spinner on the stub files.

**Step 4: Commit**

```bash
git add data/dialogue/
git commit -m "feat: add stub Yarn dialogue files for all 3 characters"
```

---

## Task 4: Scaffold asset directories

**Files:**
- Create: `data/maps/.gitkeep`
- Create: `assets/audio/sfx/.gitkeep`
- Create: `assets/audio/music/.gitkeep`
- Create: `assets/sprites/.gitkeep`

**Step 1: Create directories with gitkeep files**

```bash
mkdir -p data/maps assets/audio/sfx assets/audio/music assets/sprites
touch data/maps/.gitkeep assets/audio/sfx/.gitkeep assets/audio/music/.gitkeep assets/sprites/.gitkeep
```

**Step 2: Commit**

```bash
git add data/maps/ assets/
git commit -m "chore: scaffold asset directories for maps, audio, sprites"
```

---

## Task 5: Wire Yarn Spinner to GameState

**Files:**
- Modify: `scripts/ui/dialogue_box.gd` (add DialogueRunner + Yarn calls)
- Modify: `scripts/characters/character.gd` (remove get_dialogue string return, call Yarn instead)

> **Note:** Tasks 5 and 6 of the MVP implementation plan (Dialogue System, Base Character) are not yet done. Complete MVP Tasks 2–5 first, then return here to wire Yarn Spinner. This task is a placeholder — the exact integration pattern depends on how `dialogue_box.gd` is implemented.

**When ready, the pattern is:**

`scripts/ui/dialogue_box.gd`:
```gdscript
@onready var dialogue_runner = $DialogueRunner

func show_dialogue(character_id: String) -> void:
    var node_title = _get_node_title(character_id)
    dialogue_runner.start_dialogue_from_node(node_title)

func _get_node_title(character_id: String) -> String:
    if GameState.get_flag("workshop_unlocked"):
        return character_id.capitalize() + "_WorkshopUnlocked"
    return character_id.capitalize() + "_Default"
```

`DialogueRunner` node setup in `dialogue_box.tscn`:
- Add child node of type `YarnSpinnerDialogueRunner` (or equivalent from plugin)
- Assign `data/dialogue/dialogue.yarnproject` to its `yarn_project` property
- Connect `dialogue_finished` signal to hide the dialogue box

**Step: Commit when wired**

```bash
git add scenes/ui/dialogue_box.tscn scripts/ui/dialogue_box.gd scripts/characters/character.gd
git commit -m "feat: wire Yarn Spinner DialogueRunner to dialogue box and characters"
```
