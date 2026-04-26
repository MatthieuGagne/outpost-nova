# Resource Sub-Types Design Docs — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Document the 9-sub-resource economy design (issue #63) in `docs/design/resources.md` and update `docs/design/game-loop.md` to cross-reference it.

**Architecture:** Two doc-only tasks — one new file, one minimal edit. No code changes. No GUT tests required.

**Tech Stack:** Markdown.

## Open questions (must resolve before starting)

- none

---

### Task 1: Create `docs/design/resources.md`

**Files:**
- Create: `docs/design/resources.md`

**Depends on:** none
**Parallelizable with:** Task 2 — different output files, no shared state; cross-reference text is already fixed.

**Step 1: Write the content**

Create `docs/design/resources.md` with exactly this content:

```markdown
# Outpost Nova — Resource Economy

**Status:** Design locked 2026-04-26
**Supersedes:** PRD #45 (production loop) resource definitions
**Cross-references:** `docs/design/game-loop.md` (production cycle steps, cohesion penalty), `docs/world/station-architecture.md` (room layout), `docs/characters/sable.md` (barter narrative)

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
```

**Step 2: Verify**

Open `docs/design/resources.md` and confirm:
- Sub-resource catalog table renders correctly (9 rows across 3 categories)
- Energy Cells rows are marked "MVP: out of scope"
- Open Questions section is present

**Step 3: Commit**

```bash
git add docs/design/resources.md
git commit -m "docs: add resource economy design doc (issue #63)"
```

---

### Task 2: Update `docs/design/game-loop.md`

**Files:**
- Modify: `docs/design/game-loop.md`

**Depends on:** none
**Parallelizable with:** Task 1 — different output files, no shared state.

**Step 1: Write the content**

Two edits to `docs/design/game-loop.md`:

**Edit A — header cross-reference:** Add `docs/design/resources.md` to the Cross-references line:

Old:
```
**Cross-references:** `docs/design/station-expansion.md` (room layout, upgrade costs), `docs/characters/npcs.md` (NPC roster), `docs/story/year1.md` (arc episode schedule)
```

New:
```
**Cross-references:** `docs/design/station-expansion.md` (room layout, upgrade costs), `docs/design/resources.md` (sub-resource catalog, seed selection, barter), `docs/characters/npcs.md` (NPC roster), `docs/story/year1.md` (arc episode schedule)
```

**Edit B — Material Loop section:** Add a seed-selection sentence after the cycle description. Find this block:

```
- **Missing a Tend pauses the cycle** (PAUSED state). The cycle resumes the next time the player tends — yield is never lost.
- Outputs are **fully predictable** in the slot menu before committing.
```

Replace with:

```
- **Missing a Tend pauses the cycle** (PAUSED state). The cycle resumes the next time the player tends — yield is never lost.
- At **Start**, the player chooses which sub-resource to produce from a menu of unlocked options for that room — see `docs/design/resources.md` for the full catalog and unlock gates.
- Outputs are **fully predictable** in the slot menu before committing.
```

**Step 2: Verify**

Open `docs/design/game-loop.md` and confirm:
- Cross-references line includes `docs/design/resources.md`
- Material Loop section contains the new seed-selection bullet

**Step 3: Commit**

```bash
git add docs/design/game-loop.md
git commit -m "docs: cross-reference resource economy doc in game-loop (issue #63)"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 1, Task 2 | Different output files, no shared state |

### Smoketest Checkpoint 1 — verify both docs are consistent and cross-linked

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass, zero failures (doc-only changes; tests should be unaffected).

**Step 3: Verify docs visually**

Open both files and confirm:
- `docs/design/resources.md` exists, renders the 9-row catalog table, Energy Cells rows marked out of scope, Open Questions section present
- `docs/design/game-loop.md` header cross-references `docs/design/resources.md`, Material Loop section contains the seed-selection bullet

**Step 4: Confirm with user**

Ask: "Does `resources.md` look complete? Does the game-loop update read naturally?" Wait for confirmation before closing the branch.
