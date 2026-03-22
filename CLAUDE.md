# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Outpost Nova** is a cozy indie space station-builder game targeting a 30-60 minute MVP vertical slice. Built with **Godot 4.6.1 / GDScript**, Mobile renderer. Task 1 (project setup, GUT install, autoload config) is complete — see `docs/plans/2026-03-15-mvp-implementation.md` for the full plan and current status.

## Commands

```bash
# Launch Godot editor (binary at ~/.local/bin/godot)
godot

# Run all GUT tests headlessly
godot --headless -s addons/gut/gut_cmdln.gd

# Run a single test script
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_game_state.gd

# Export builds
godot --headless --export-debug "Linux/X11"
godot --headless --export-debug "Windows Desktop"
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

Follow `docs/plans/2026-03-15-mvp-implementation.md` in order. That file contains full code for every task — read it before implementing anything.

## Key Design Constraints

- **MVP scope is fixed:** 2 rooms, 3 characters (Cook/Maris, Engineer/Dex, Drifter/Sable), 3 resources, 5 recipes, 3 Cantina upgrades. No save system, day cycle, or relationship simulation.
- **TDD for pure logic:** Write GUT tests for `GameState` and `CraftingSystem` before implementing them. Run tests in GUT panel or headlessly.
- **Placeholder art is acceptable** — colored rectangles for MVP validation.
- Data model is designed to scale to the full game — don't treat it as throwaway.
