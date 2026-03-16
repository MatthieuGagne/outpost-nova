# Outpost Nova — MVP / Vertical Slice Design

**Date:** 2026-03-15
**Scope:** Private proof of concept — validate the fun, not for release

---

## Goal

One session (~30-60 min) where the player thinks: *"I want to see what's in the next room."*

---

## The World

Two spaces only:

- **The Cantina** — starting room, social heart of the station. Flickering neon, mismatched chairs, beat-up food printer.
- **The Workshop** — locked and visible from the start. Unlocked mid-session as the payoff.

No map, no sprawl. Scope is ruthlessly tight.

---

## Core Loop

```
Collect resources (2-3 source nodes near the station)
→ Craft items in the Cantina (food, drinks, station parts)
→ Spend crafted items / resources to upgrade Cantina or unlock Workshop
→ Upgrades trigger character reactions and new dialogue
→ Unlock Workshop → new crafting recipes → new character interactions
```

---

## Characters

3 settlers, hand-written, distinct personalities:

| Slot | Role | Personality | Arc Hook |
|---|---|---|---|
| Character 1 | Cook / tender | Warm, deflects with humor | Left something behind |
| Character 2 | Engineer | Blunt, secretly sentimental | Fixing more than machines |
| Character 3 | Drifter | Curious, non-committal | Deciding whether to stay |

Each character has ~5-8 lines of dialogue that shift based on build state. No simulation engine — simple flags:
- Did you upgrade the food printer?
- Did you unlock the Workshop?
- Did you craft and give them something?

Reactions make the station feel alive without requiring complex systems.

---

## Crafting System

Establish the data model that scales to the full game. Keep it simple:

**Resources (3 types):**
- Rations
- Parts
- Energy Cells

Collected passively over time or by interacting with source nodes.

**Recipes (4-5 items):**
- Hot Meal (Rations × 2)
- Decent Drink (Rations × 1 + Energy Cell × 1)
- Patch Kit (Parts × 2)
- Power Relay (Parts × 1 + Energy Cell × 2)
- [One Workshop-exclusive recipe unlocked mid-session]

**Uses:**
- Upgrade Cantina features (food printer, seating, lighting)
- Give to characters → triggers dialogue
- Spend to unlock the Workshop

**Design rule:** Every crafted item has a visible, immediate purpose. Nothing crafted goes nowhere.

---

## Data Model (Crafting Foundation)

```
Resource { id, name, icon, amount }
Recipe { id, inputs: [{ resourceId, qty }], output: ItemId }
Item { id, name, uses: [UpgradeId | CharacterId] }
Upgrade { id, room, effect, dialogue_flag }
```

This structure scales directly to the full game's crafting system.

---

## Out of Scope (Explicitly)

- Time / day cycle
- Character relationship simulation
- Procedural generation
- More than 2 rooms
- Save system (session resets are fine)
- Polished music/SFX (placeholders ok)
- Any content beyond the Cantina → Workshop unlock

---

## Success Criteria

Player (you) sits down, plays 30 minutes, and wants to keep going.

---

## Tech Stack

- **Engine:** Godot 4 (GDScript)
- **Export:** Desktop (Windows/Mac/Linux)
- **Art:** 2D pixel art, hand-drawn by developer
