# Outpost Nova — Core Game Loop

**Status:** Design locked 2026-04-25
**Supersedes:** PRD #43 (daily slot system), PRD #45 (production loop) where they conflict.
**Cross-references:** `docs/design/station-expansion.md` (room layout, upgrade costs), `docs/characters/npcs.md` (NPC roster), `docs/story/year1.md` (arc episode schedule)

---

## Overview

Two interlocking systems — material production and community cohesion — create the day-to-day tension. The player's clock choices always live between them: tend the plots or tend the people. Neither system is optional. They reinforce or erode each other.

---

## Time Economy

### The Clock

- Day runs **06:00–22:00**.
- Clock ticks slowly while idle or navigating between rooms.
- Clock **jumps forward visibly** when the player commits an action.
- Room transitions cost **zero time**.
- Player can end the day manually or the day ends automatically at 22:00.
- Clock and calendar day are **always visible in the HUD**.

### Action Time Costs

| Action | Time Cost | Notes |
|--------|-----------|-------|
| Talk | ~30 min | Surfaces pair state tags, enables advocacy |
| Tend / Collect | 1 hr | Material loop maintenance |
| Start plot | 1.5 hr | Begins a new production cycle |
| Mediate | 2 hr | Only available when prerequisites met |
| Host Crew Meal | 3 hr | Cantina Level 1 unlock; ~3-day cooldown |
| Arc episode beat | 3–4 hr | Auto-fires at authored time; remaining hours available after |

> **Design note:** Talk costs time (supersedes "Talk is free" from station expansion design). The cost is low (~30 min) — the intent is that a Talk-heavy day and a production-heavy day feel meaningfully different in total clock spend, not that talk is scarce.

---

## Material Loop

### Production Cycle

Each resource plot follows a 3-step cycle, each step costing one clock action:

```
Start → Tend → Collect
```

- **Missing a Tend pauses the cycle** (PAUSED state). The cycle resumes the next time the player tends — yield is never lost.
- Outputs are **fully predictable** in the slot menu before committing.

### Cohesion Penalty

- When community cohesion falls **below 30%**, Collect yields are visibly reduced.
- The reduction is shown in the slot menu before the player commits.

### Upgrade Queue

- Room upgrades and section construction cost **resources only**.
- Upgrades run as a **background queue** over N calendar days — no daily time cost.
- Only **one upgrade/construction project** active in the queue at a time. Initiating a second is blocked or prompts replacement.
- New plots are available **immediately the same day** an upgrade completes.
- Upgrade completion: NPC authored idle line (primary) + HUD notification (secondary).

---

## Social Loop (Community Building)

### NPC Pair Graph

A small authored social graph of **4–5 NPC pairs**, each with a relationship state:

```
Tension → Neutral → Collegial → Bonded
```

- Pair states are visible as **tags in relevant dialogue** — not as a numerical score.
- Pair states **only regress** when a stress event (arc episode) explicitly triggers regression. They never decay passively from neglect.
- The cohesion aggregate number is **not displayed** to the player.

### Talk Action

- Surfaces pair state tags for any pair involving that NPC.
- Enables **NPC advocacy** (one NPC speaking for another).
- Plants the conditions for Mediate to become available.

### Mediate Action

- Appears in an NPC's room action list when **both** conditions are met:
  1. Player has a relationship with both NPCs in the pair.
  2. The tension was explicitly **acknowledged via Talk**.
- Costs 2 hours. Advances a pair toward Neutral or Collegial.

### Host Crew Meal

- Unlocked at **Cantina Level 1**.
- Costs rations + ~3-day cooldown before it can be used again.
- Nudges **multiple pairs shallowly** — not a targeted relationship tool.
- Raises **background crew cohesion**.
- Does **not** advance individual NPC relationship tiers (Talk still gates character episodes).

### Background Crew Cohesion

- ~26 unnamed background crew have their own cohesion stat.
- Moved by station-wide events (arc episodes, Host Crew Meal, resource crises).
- The specific inputs beyond station-wide events are a **design pass TBD**.

---

## Community Cohesion

- **Community cohesion = weighted aggregate of authored pair states + background crew cohesion.**
- The aggregate is **never displayed directly**. It is felt through production yields and dialogue texture.

| Cohesion Level | Effect |
|----------------|--------|
| Above 70% | Production bonuses on Collect |
| 30%–70% | No modifier |
| Below 30% | Collect yields visibly reduced |

---

## Station Upgrades (social dimension)

Each room upgrade unlocks new **social actions** anchored to that NPC:

| Upgrade | Unlocked Action |
|---------|----------------|
| Cantina Level 1 | Host Crew Meal |
| Med Bay Level 1 | Wellness Check (TBD) |

Upgrade completion is communicated via **NPC idle line** (primary) and **HUD notification** (secondary). See `docs/design/station-expansion.md` for full upgrade costs and capacity tables.

---

## Arc Episodes

- Arc episodes fire at an **authored time of day** (analogous to Stardew Valley festivals).
- When an arc episode fires, it plays out as a scene with player choices.
- The **clock resumes after** with remaining hours available.
- Arc episodes are the primary trigger for **pair state regression**.

---

## Culminating Moments

- When a key NPC pair reaches **Bonded**, an ambient witnessed scene fires automatically.
- The player walks in and catches an authored exchange between the two NPCs.
- **No player input. No announcement.** The moment is witnessed, not staged.

---

## NPC Presence

- NPCs are **primarily present in their anchored room**.
- Absences are **authored** and tied to story beats or arc events — not a daily simulation.

---

## Player Goals (HUD)

Two visible goal indicators are **always present in the HUD** during play:

1. **Station viability** — resource and capacity metric (exact UI form TBD: resource list, capacity bar, or composite)
2. **Community** — pair state tags + cohesion feel (not a number)

---

## Open Questions

- Station viability HUD form: resource stocks list, capacity bar, or composite?
- Background crew cohesion: specific inputs beyond station-wide events (design pass)
- Exact arc episode schedule and regression triggers for each pair (Year 1 story pass)
- Research track tier thresholds and what unlocks at each (balancing pass)
- Exact upgrade resource costs (balancing pass)
