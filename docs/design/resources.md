# Outpost Nova — Resource Economy

**Status:** Design locked 2026-04-26
**Supersedes:** PRD #45 (production loop) resource definitions
**Cross-references:** `docs/design/game-loop.md` (production cycle steps, cohesion penalty), `docs/design/production-plots.md` (plot count, visual states, per-room design), `docs/world/station-architecture.md` (room layout), `docs/characters/sable.md` (barter narrative)

---

## Overview

The three resource categories (Rations, Parts, Energy Cells) each contain three sub-resources with distinct cycle lengths, unlock gates, and narrative weight. Players choose which sub-resource to produce at each plot Start — a "seed selection" moment. Most recipes accept any sub-resource of the correct type; a small set of special unlocks require a specific sub-resource.

---

## Sub-Resource Catalog

| Category | Sub-Resource | Cycle Length | Unlock |
|----------|-------------|--------------|--------|
| **Rations** | Hydro Greens | 3d | Day 1 (always) |
| | Protein Culture | 5d | Day 1 (always) |
| | Synthetic Spice | 7d | Cantina Level 2 + Maris relationship tier |
| **Parts** | Scrap Bundle | 3d | Day 1 (always) |
| | Fabricated Component | 5d | Workshop Level 1 |
| | Builder Alloy | 7d | Dex relationship tier + Lower Decks access (story gate) |
| **Energy Cells** *(MVP: out of scope)* | Standard Cell | 5d | Power Core restored |
| | Dense Cell | 8d | Power Core Level 1 |
| | Resonant Cell | 12d | Story beat: weapon revelation arc |

---

## Seed Selection

When the player initiates a **Start** action on a production plot, a menu appears showing all unlocked sub-resources for that room's category. Each option displays:

- Sub-resource name
- Cycle length
- Yield amount (exact amounts: balancing pass TBD)

The player commits to one choice. Outputs are fully predictable before committing.

---

## Recipe Resolution

Recipe and upgrade ingredients support two forms:

| Form | Example | Resolution |
|------|---------|------------|
| **Generic** | `{ type: "rations", amount: 2 }` | Sums all sub-resource stocks of that category |
| **Specific** | `{ sub_resource: "protein_culture", amount: 1 }` | Exact sub-resource id match only |

**Base upgrades and standard recipes** use the generic form — any Rations, any Parts.
**Special unlocks** (Host Crew Meal, higher-tier construction, trade deals) use the specific form.

---

## HUD Display

- HUD shows **3 category totals only** (Rations / Parts / Energy Cells).
- Individual sub-resource breakdown display is a **separate UI pass**.

---

## Barter (Sable's Trade Dock)

- Sable's stock is a **small authored list (3–5 offers)** that resets on ship arrival.
- Each offer: player gives one sub-resource, receives another (resource-for-resource only, no currency).
- Ship arrival schedule: ~every 3–5 days (exact cadence: balancing pass TBD).
- Stock generation: authored vs. procedural is an **open question** (see below).

---

## Acquisition Paths

| Path | Notes |
|------|-------|
| Production plots (Start/Tend/Collect) | Primary loop; player chooses sub-resource at Start |
| Arc episode cycle bonuses | Already designed; fires at authored story beats |
| Sable barter (Trade Dock) | Refreshes on ship arrival; resource-for-resource |
| Spine salvage (Lower Decks) | **Out of scope** — future pass when Lower Decks is scoped |

---

## Narrative Hooks

| Sub-Resource | Narrative Texture |
|-------------|------------------|
| Hydro Greens | Everyday sustenance; the station's baseline |
| Protein Culture | Maris cooking for the crew; community ritual |
| Synthetic Spice | Maris's craft reaching its ceiling; personal arc beat |
| Scrap Bundle | Dex's daily salvage hustle |
| Fabricated Component | Skilled craft; competence made visible |
| Builder Alloy | Dex learning to work with alien material; personal arc beat |
| Standard Cell *(MVP: out of scope)* | Learning to use the machine |
| Dense Cell *(MVP: out of scope)* | Getting comfortable with it |
| Resonant Cell *(MVP: out of scope)* | Realizing the machine is doing something not fully understood |

---

## Out of Scope

- Energy Cells sub-resources (Power Core not in MVP)
- Sub-resource breakdown HUD (separate UI pass)
- Storage caps / overflow signals (balancing pass)
- Spine salvage acquisition path (Lower Decks scoping pass)
- Visitor ship event-driven resource drops
- Currency / credits system (barter only)

---

## Open Questions

- Exact sub-resource yield amounts per cycle (balancing pass)
- Barter stock: authored offers vs. procedurally generated from a pool?
- Ship arrival event: authored schedule or randomized within a range?
- Builder Alloy unlock: does Lower Decks access require a story beat or just a resource gate?

---

## Vril (4th Resource Category)

> **Status:** Lore and economy design locked (issue #76). GDScript implementation out of scope for this pass — no GameState changes, no CraftingSystem changes, no GUT tests.

### Sub-Resources

| Sub-Resource | Cycle | Unlock |
|---|---|---|
| Surface Extract *(placeholder name)* | 3d | Drone Bay built |
| Mid-layer Extract *(placeholder name)* | 6d | Drone Bay Level 1 |
| Deep Extract *(placeholder name)* | 10d | Story gate: weapon revelation arc |

### Outputs

| Output | Recipe | Description |
|---|---|---|
| Lattice *(placeholder name)* | Vril + Parts | Structural components beyond normal engineering limits; Builder-compatible interface material |
| Compound *(placeholder name)* | Vril + Rations | Biological synthesis with accelerated healing and unexplained cognitive effects |
| Charged Cells *(placeholder name)* | Vril + Energy Cells | Power output an order of magnitude above baseline; Builder infrastructure responds to charged cells differently |

### HUD Behavior

Vril appears as a 4th HUD category **only after Drone Bay is built**. Zero HUD presence before that point.

### Prerequisite Chain

Power Core restored → Drone Bay buildable → Vril production begins

### No Quota Mechanic

Vril has no extraction quota or cap. Production is gated by cycle length and unlock tier only.

### Out of Scope (this pass)

- GDScript implementation (GameState, CraftingSystem)
- Drone Bay scene / room
- Crafting recipe implementation (Lattice, Compound, Charged Cells)
- GUT tests for Vril logic
- Drone Bay NPC / character anchor
- Exact yield amounts (balancing pass)
- Sub-resource and output naming pass (all names marked as placeholders)
