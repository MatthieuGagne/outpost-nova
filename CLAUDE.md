# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Outpost Nova** is a cozy indie space station-builder game targeting a 30-60 minute MVP vertical slice. Built with **Godot 4 / GDScript**. Currently in pre-implementation (design docs only — no source code yet).

## Commands

```bash
# Launch Godot editor (binary at ~/.local/bin/godot — Godot 4.6.1)
godot

# Run tests headlessly via GUT
godot --headless -s addons/gut/gut_cmdln.gd

# Export builds
godot --headless --export-debug "Linux/X11"
godot --headless --export-debug "Windows Desktop"
```

## Architecture

Two global **autoload singletons** are the backbone:

- `scripts/autoload/game_state.gd` — tracks 3 resource types (Rations, Parts, Energy Cells) and a flag dict (e.g. `workshop_unlocked`). Emits `resource_changed` and `flag_changed` signals.
- `scripts/autoload/crafting_system.gd` — recipe definitions with costs and `requires_flag`. Methods: `can_craft()`, `craft()`, `is_recipe_available()`.

All UI reacts to `GameState` signals — never polls state directly. Characters check `GameState` flags in an if/else chain to return dialogue lines (no dialogue engine).

**Scene layout:**
```
scenes/
  main.tscn
  rooms/         # cantina.tscn, workshop.tscn
  characters/    # character.tscn (base), instanced 3x
  ui/            # hud.tscn, crafting_panel.tscn, dialogue_box.tscn
scripts/
  autoload/      # game_state.gd, crafting_system.gd
  rooms/
  characters/    # character.gd (base), cook.gd, engineer.gd, drifter.gd
  ui/
data/            # .tres resource definitions
tests/           # GUT tests (test_game_state.gd, test_crafting_system.gd)
```

## Implementation Plan

Follow `docs/plans/2026-03-15-mvp-implementation.md` in order:

1. Godot project setup + GUT install + autoload config
2. `GameState` autoload (TDD first)
3. `CraftingSystem` autoload (TDD first)
4. Resource collection nodes (clickable, cooldown timer)
5. Dialogue system (flag-driven character reactions)
6. Character scripts (Cook/Maris, Engineer/Dex, Drifter/Sable)
7. Cantina room scene
8. Crafting panel UI
9. HUD resource display
10. Main scene wiring

## Key Design Constraints

- **MVP scope is fixed:** 2 rooms, 3 characters (5-8 dialogue lines each), 3 resources, 5 recipes, 3 Cantina upgrades. No save system, day cycle, or relationship simulation.
- **Placeholder art is acceptable** — colored rectangles for MVP validation.
- **TDD for pure logic:** Write GUT tests for `GameState` and `CraftingSystem` before implementing them.
- Data model is designed to scale to the full game — don't treat it as throwaway.
