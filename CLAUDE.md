# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Outpost Nova** is a cozy indie space station-builder game targeting a 30-60 minute MVP vertical slice. Built with **Godot 4.7.1 (mono) / GDScript + C#**, Mobile renderer. The MVP implementation plan was completed and its plan files deleted (2026-04-03); work since then is tracked per-feature in `docs/plans/` and `docs/superpowers/plans/`.

`docs/index.md` catalogs the project's design, story, world, and character docs — consult it to find existing knowledge, and add a line to it for any new doc under `docs/`.

## Commands

Always invoke Godot through `tools/godot.ps1`, never the `godot` / `godot_console`
commands on PATH — those are WinGet shims and Godot fails to find its bundled
`GodotSharp\` through them, crashing with `.NET: Assemblies not found` / signal 11.
`-Console` selects the console build (stdout/stderr attached); `$env:GODOT_BIN`
overrides executable discovery.

```powershell
# Build C# assemblies (required before running — dialogue is C#)
dotnet build "Outpost Nova.csproj"

# Launch Godot editor
./tools/godot.ps1

# Launch the game
./tools/godot.ps1 --path .

# Run all GUT tests headlessly (quote any res:// arg — PowerShell splits on the colon)
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit

# GUT prints "---- All tests passed! ----" even when a test script failed to PARSE and was
# skipped entirely. Read the Scripts/Tests COUNT, never the banner: a drop between runs means
# a file silently vanished from the suite (#103 reported success at 162 tests instead of 191).
# Prefer this form, which surfaces the parse errors the banner swallows:
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit 2>&1 |
  Select-String -Pattern "SCRIPT ERROR|Failing Tests|Passing Tests|Scripts "

# `Identifier "Foo" not declared` for a class_name that plainly exists means the class cache is
# stale — after a merge, a branch switch, or adding any class_name. Rebuild it, then re-run:
./tools/godot.ps1 -Console --headless --path . --editor --quit

# Run a single test script
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gtest=res://tests/test_game_state.gd" -gexit

# Export builds
./tools/godot.ps1 -Console --headless --export-debug "Windows Desktop"
```

## Architecture

Two global **autoload singletons** (already registered in `project.godot`) are the backbone:

- `scripts/autoload/game_state.gd` — tracks 3 resource types (`rations`, `parts`, `energy_cells`) and a flag dict (e.g. `workshop_unlocked`). Emits `resource_changed(id, amount)` and `flag_changed(id, value)` signals.
- `scripts/autoload/crafting_system.gd` — `RECIPES` dict with `inputs` and `requires_flag`. Methods: `can_craft()`, `craft()`, `is_recipe_available()`. Emits `item_crafted(item_id)`.

**Signal discipline:** All UI connects to `GameState` signals and never polls state directly. Upgrade buttons call `GameState.spend_resource()` directly (not `CraftingSystem`) since upgrades are room-specific, not recipes.

**Dialogue pattern:** Each character script overrides `get_dialogue() -> String` with a plain if/elif/else chain checking `GameState.get_flag()` — no dialogue engine. Flag check order matters: more-specific flags (e.g. `workshop_unlocked`) come before general ones.

**Scene layout:**
```
scenes/
  main.tscn              # Entry point; hosts rooms + all UI layers
  rooms/                 # cantina.tscn, workshop.tscn
  characters/            # character.tscn (base), instanced 3×
  ui/                    # hud.tscn, crafting_panel.tscn, dialogue_box.tscn
scripts/
  autoload/              # game_state.gd, crafting_system.gd
  rooms/                 # cantina.gd, workshop.gd
  characters/            # character.gd (base), cook.gd, engineer.gd, drifter.gd
  ui/                    # hud.gd, crafting_panel.gd, dialogue_box.gd
data/
  resources/             # .tres resource definitions
  recipes/
tests/                   # GUT tests (extend GutTest, use before_each to call GameState.reset())
```

## Implementation Plan

Each feature has its own plan under `docs/plans/` or `docs/superpowers/plans/` — read the one for the feature you are implementing before touching code. Completed plans are deleted, so their absence means the work landed; `git log` is the record.

## Key Design Constraints

- **MVP scope is fixed:** 2 rooms, 3 characters (Cook/Maris, Engineer/Dex, Drifter/Sable), 3 resources, 5 recipes, 3 Cantina upgrades. No save system, day cycle, or relationship simulation.
- **TDD for pure logic:** Write GUT tests for `GameState` and `CraftingSystem` before implementing them. Run tests in GUT panel or headlessly.
- **Placeholder art is acceptable** — colored rectangles for MVP validation.
- Data model is designed to scale to the full game — don't treat it as throwaway.
