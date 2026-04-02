# Outpost Nova — Toolchain Design

**Date:** 2026-03-15
**Scope:** Post-MVP art and content pipeline

---

## Summary

| Category | Tool | Location |
|----------|------|----------|
| Sprite & animation | Aseprite | `~/.local/bin/aseprite` |
| Map / room layout | Tiled + godot-tiled-importer | `/usr/bin/tiled` |
| Dialogue | Yarn Spinner (Godot plugin) | `addons/yarn_spinner/` |
| SFX | jsfxr (browser) | — |
| Music | Furnace | `~/furnace/furnace` |

---

## Sprite & Animation — Aseprite

- Draw characters as spritesheets (idle, talk, react animations)
- Export as PNG spritesheet + JSON frame data → Godot imports via `AnimatedSprite2D` or `SpriteFrames`
- Room backgrounds as single large PNGs or layered PNGs for parallax
- Tileset source images exported from Aseprite → referenced in Tiled and Godot

---

## Map / Room Layout — Tiled + godot-tiled-importer

- Design tilesets and rooms in Tiled (`/usr/bin/tiled`)
- Export as `.tmx` files into `data/maps/`
- `godot-tiled-importer` plugin (`addons/tiled_importer/`) handles import into Godot scenes
- Tilesets drawn in Aseprite, exported as PNG spritesheets, referenced in Tiled

---

## Dialogue — Yarn Spinner

- Install `YarnSpinner-Godot` plugin into `addons/yarn_spinner/`
- Dialogue lives in `.yarn` files under `data/dialogue/` — one per character:
  - `data/dialogue/cook.yarn`
  - `data/dialogue/engineer.yarn`
  - `data/dialogue/drifter.yarn`
- `GameState` flags exposed to Yarn via commands/variables
- Characters call Yarn Spinner to run their dialogue instead of returning a plain string
- Scales to 10+ characters and non-programmer dialogue authoring without rework

---

## Audio

### Sound Effects — jsfxr
- Browser-based SFX generator (free)
- Generate 8-bit SFX, export as `.wav`
- Files live in `assets/audio/sfx/`

### Music — Furnace
- Chiptune tracker at `~/furnace/furnace`
- Supports NES, SNES, Genesis and many other sound chips — good fit for cozy space station vibe
- Export tracks as `.wav` or `.ogg`
- Files live in `assets/audio/music/`
