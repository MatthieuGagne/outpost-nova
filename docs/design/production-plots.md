# Outpost Nova — Production Plots

**Status:** Design locked 2026-05-01
**Cross-references:** `docs/design/resources.md` (sub-resource catalog, seed selection, barter), `docs/design/game-loop.md` (time costs, cohesion penalty, upgrade queue), `docs/world/station-architecture.md` (room layout)

---

## Overview

Production plots are the spatially-placed, interactable objects in each resource room that drive the material loop. The player walks up to a plot and presses interact — there is no panel or menu. Each room contains 2 plots at Day 1, growing to a maximum of ~4 as the room is upgraded. Plots have distinct visual states that communicate cycle progress at a glance.

The Start/Tend/Collect cycle, time costs, sub-resource selection, and cohesion effects are specified in `docs/design/game-loop.md` and `docs/design/resources.md`. This document covers plot count, spatial interaction model, visual state design per room, and how upgrades add plots.

---

## Plot Count

| Room | Day 1 Plots | Max Plots | Notes |
|------|-------------|-----------|-------|
| Cantina | 2 | ~4 | +1 per Cantina upgrade level |
| Workshop | 2 | ~4 | +1 per Workshop upgrade level |
| Power Core | 2 | ~4 | +1 per Power Core upgrade level — out of scope for MVP |
| Drone Bay | 2 | ~4 | +1 per Drone Bay upgrade level — out of scope for MVP |

---

## Spatial Interaction Model

Plots are spatially placed in each room. The player walks up to a plot and presses interact — there is no room management panel or menu. Each plot is a distinct interactive object visible in the room scene. The player can see at a glance which plots are ready, which are growing, and which need attention.

---

## Plot State Machine

| State | Description | Player Action Available |
|-------|-------------|------------------------|
| **Empty** | Plot slot exists, nothing started | Start |
| **Installing** | Added by room upgrade; not yet available | None (available next day) |
| **Growing** | Start committed, sub-resource chosen, cycle running | None |
| **Needs Tending** | Cycle has reached the Tend phase | Tend |
| **Paused** | Tend was missed; cycle paused, yield preserved | Tend (resumes cycle) |
| **Ready to Collect** | Cycle complete | Collect |

> **Installing state:** When an upgrade completes and a new plot is added to the room, the plot appears immediately with an "installing" visual (crates nearby, partially assembled). It becomes available to Start on the following day. This gives upgrade completion visual weight without adding a separate time-cost mechanic.

> **Paused state:** Specified in `docs/design/game-loop.md` — "Missing a Tend pauses the cycle. The cycle resumes the next time the player tends — yield is never lost."

---

## Per-Room Design

### Cantina — Rations (Maris)

**Theme:** Hydroponic trays with grow-lights. Organic, warm, lived-in. Maris's domain — the plots feel tended with care.

| State | Visual |
|-------|--------|
| Empty | Bare tray, soil or substrate visible, grow-light off |
| Installing | Half-assembled tray frame, tools on the counter nearby |
| Growing | Small seedlings or culture medium, grow-light on (warm amber) |
| Needs Tending | Slightly overgrown or dry-looking, grow-light blinking |
| Paused | Wilting, drooping plants, grow-light dim |
| Ready to Collect | Full, lush growth, grow-light bright |

Sub-resources: Hydro Greens (3d), Protein Culture (5d), Synthetic Spice (7d — Cantina L2 + Maris relationship).

---

### Workshop — Parts (Dex)

**Theme:** Fabrication bays — workbenches with parts and in-progress components. Industrial, practical, Dex's organized chaos.

| State | Visual |
|-------|--------|
| Empty | Clean workbench surface, tools racked |
| Installing | Bench half-bolted, components in crates on the floor |
| Growing | Parts laid out, work clearly in progress |
| Needs Tending | Tool icon or blinking indicator — needs a calibration pass |
| Paused | Dust settling, components covered with a cloth |
| Ready to Collect | Finished components stacked neatly, indicator light green |

Sub-resources: Scrap Bundle (3d), Fabricated Component (5d — Workshop L1), Builder Alloy (7d — Dex relationship + Lower Decks).

---

### Power Core — Energy Cells *(out of scope for MVP)*

**Theme:** Crew-rigged coupling points — Hegemony-standard grey metal brackets bolted directly onto Builder wall surfaces. Green light pulses from the alien geometry underneath. Jury-rigged quality: cables running across alien ridges, tape marks, handwritten labels on the racks.

| State | Visual |
|-------|--------|
| Empty | Bracket mounted, rack empty, Builder green light steady |
| Installing | Bracket being mounted, cables draped over alien ridges, tape marks |
| Growing | Rack partially filled, green light flickering at coupling point |
| Needs Tending | Calibration indicator (human gauge bolted onto alien surface) blinking red |
| Paused | Light dim, rack cells partially drained |
| Ready to Collect | Rack full, cells glowing faintly green |

Sub-resources: Standard Cell (5d), Dense Cell (8d — Power Core L1), Resonant Cell (12d — weapon revelation arc).

> **Narrative note:** The visual arc mirrors the sub-resource design intent — Standard Cell = "learning to use the machine," Resonant Cell = "realizing the machine is doing something not fully understood." The deeper the tier, the more clearly the Builder geometry is driving the process; the human equipment is along for the ride.

---

### Drone Bay — Vril *(out of scope for MVP)*

**Theme:** Extraction cradles — zero-g mounting frames on the Drone Bay walls where drones dock and offload harvested Vril gas in pressurized canisters. Zero-gravity; mag-boots required.

| State | Visual |
|-------|--------|
| Empty | Cradle frame empty, canister rack clear |
| Installing | Cradle being bolted to Builder surface, drone diagnostic running |
| Growing | Drone absent (deployed to Dis), canister slowly filling with purple-tinted gas |
| Needs Tending | Drone docked, telemetry blinking — needs re-tasking |
| Paused | Drone idle in cradle, canister half-full, no activity |
| Ready to Collect | Canister sealed and full, indicator green |

Sub-resources: Surface Extract (3d), Mid-layer Extract (6d — Drone Bay L1), Deep Extract (10d — weapon revelation arc).

---

## Out of Scope

- GDScript implementation (PlotState, PlotNode, GameState changes) — separate PRD
- Exact spatial positioning of plots within room scenes — implementation plan
- NPC auto-tending / NPC assist upgrades — future design pass
- Sub-resource yield amounts — balancing pass
- Energy Cells and Vril plot implementation — out of scope for MVP
- Plot UI interactions (sub-resource selection menu, yield preview) — separate implementation pass
