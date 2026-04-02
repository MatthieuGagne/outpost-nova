# Outpost Nova — Evolved Design

**Date:** 2026-03-15
**Status:** Approved

## Vision

Top-down 16-bit pixel art RPG set on a decaying space station. The player moves freely through interconnected areas à la Stardew Valley, talks to NPCs, gathers resources, and crafts — but 2-3 weighted story beats per day push time forward with Citizen Sleeper's narrative weight. A roguelite combat zone (the Derelict Section, inspired by Cult of the Lamb) is core to the main story arc and a source of rare resources and recruitable survivors.

**Inspirations:** Citizen Sleeper (atmosphere, story choices, tone), Stardew Valley (movement, daily loop, world feel), Disco Elysium (dialogue emotional registers), Cult of the Lamb (roguelite combat rooms).

---

## Core Loop

1. Wake up. No timer, no stamina bar. Roam the station freely.
2. Collect resources from physical nodes (walk up, interact, cooldown).
3. Talk to NPCs freely. Some conversations carry a story beat indicator.
4. Triggering a story beat presents a weighted choice. Each day has 2-3 beats.
5. Once all beats are triggered, a "Rest when ready" prompt appears.
6. Craft at the workbench in Engineering before sleeping.
7. Sleep → day advances → repeat.

Daily stakes vary: some days a system is failing (resource crisis), some days a character is in trouble, some days an event arrives. The player doesn't always know which kind of day it is at the start.

---

## Player Character

**Character creation:**
- Name (free text)
- Appearance (sprite selection)
- Background — determines starting resources and inner voice:
  - **Engineer** — starts with Parts; inner voice is *The Head* (logical, analytical)
  - **Medic** — starts with Rations; inner voice is *The Heart* (empathetic, perceptive)
  - **Drifter** — starts with Energy Cells; inner voice is *The Edge* (instinctive, blunt)

---

## Dialogue System

Every significant conversation offers 2-4 choices. Each is tagged with an emotional register: *Hopeful*, *Cynical*, *Curious*, *Detached*, *Warm*, *Sharp*.

Your background's inner voice occasionally surfaces as a bonus option — styled distinctly (italicised, different color). It doesn't gate content; it colors it.

No stat checks. No failure states. Character emerges through the pattern of choices made across the arc.

GameState tracks emotional register history and flag history per NPC. Endings reflect the character you became, not just the final decision.

---

## The Station (World Structure)

Connected walkable areas navigated by passing through doors.

**Areas (MVP vertical slice):**
- **Cantina** — social hub, food/ration nodes, Maris and Sable's territory
- **Engineering Bay** — parts nodes, crafting workbench, Dex's territory
- **Medbay** — medical supplies, the new character's territory; people come to them, they rarely seek others
- **Quarters** — player bunk (end day), bulletin board (day hints/summary), background crew housing
- **Derelict Entrance** — sealed lower-deck door; opens partway through the arc

**Main NPCs:** Maris (Cook), Dex (Engineer), Sable (Drifter), Soriel (Medic — Thessari, Displaced). They wander their areas on loose schedules and react to player flag history — not a friendship meter, just accumulated choices.

**Background crew** populate the station over time as survivors are recruited from the Derelict. The station feels emptier early and more alive later.

**Resource nodes** are physical world objects with cooldowns. Crafting requires walking to the workbench in Engineering.

---

## The Derelict Section (Roguelite)

**Premise:** The lower decks were sealed after an incident nobody talks about. The main arc forces you in. What you find recontextualizes the station's history.

**Structure:** Procedurally assembled rooms from hand-crafted tile pools. Each run goes floor by floor, deeper. Real-time Stardew-style combat: move, swing, dodge. Enemies are station hazards made physical — malfunctioning drones, feral scavengers, worse things deeper down.

**Resources:** Rare crafting materials only found here. Some station upgrades and story-critical items require Derelict resources.

**Recruitment:** Some rooms contain survivors — people trapped when the lower decks sealed. Brief mid-run dialogue exchange + a choice. They follow you out if you survive. A few are story characters with full arcs (critical to the main plot). Others become background crew.

**Death:** Lose resources gathered on that run. Keep everything already returned to the station. Calculated risk — go deeper for rarer materials, know when to leave.

**Arc integration:** Reaching specific depths at specific story moments is required — a person to find, a secret to uncover, something that recontextualizes what happened.

**MVP scope:** 3-4 floors, 2-3 recruitable survivors, 1 story-critical revelation.

---

## Main Story Arc

**Premise:** You arrive at Outpost Nova as a newcomer. The station is understaffed and barely functioning. Nobody says why.

**Shape (7-10 in-game days):**

- **Days 1-3 (Settling in):** Learn the station, meet the crew, establish the loop. The Derelict door is sealed, mentioned in passing. Small daily stakes — a broken conduit, tension between Maris and Dex.
- **Days 4-6 (Something's wrong):** Story beats intensify. A survivor is found. The Derelict opens. First runs surface fragments of what happened. The crew reacts to accumulated player choices.
- **Days 7-10 (The reckoning):** The secret surfaces. A hard choice — who to protect, what to sacrifice, whether to expose the truth or bury it. Multiple endings shaped by accumulated choices, not a single late binary. Tone: bittersweet by default.

**Episodic DLCs:** The main arc ends but the station continues. Each DLC is a self-contained story arc layered on top of the existing world.

---

## Architecture

### Autoloads (kept, extended)

- `GameState` — existing resource/flag system unchanged; add `current_day`, `story_beats_completed`, `player_name`, `player_background`, `player_appearance`, NPC flag history per character.
- `CraftingSystem` — unchanged; recipes expand to include Derelict materials.
- `DayManager` *(new)* — tracks beats available today, fires `day_ended` signal, handles sleep transition.
- `DialogueManager` *(new)* — manages conversation state, tracks emotional register history, surfaces inner voice options, fires story beat signals.

### New Systems

- `PlayerCharacter` scene — top-down sprite, 8-directional movement, interaction radius, inner voice component.
- `NPCCharacter` scene — base scene extended per character; wander behavior, interaction trigger, flag-driven dialogue script.
- `DerelictRun` — separate scene/mode; procedurally assembled rooms, depth tracking, enemy scenes, survivor encounters; returns to station on exit or death.

### Scene Layout (revised)

```
scenes/
  main.tscn                    # Station hub; switches between areas
  areas/
    cantina.tscn
    engineering.tscn
    medbay.tscn
    quarters.tscn
    derelict_entrance.tscn
  characters/
    player.tscn
    npc_base.tscn              # Extended per character
  derelict/
    run.tscn                   # Roguelite mode entry
    rooms/                     # Hand-crafted room templates
    enemies/
  ui/
    hud.tscn
    dialogue_box.tscn
    crafting_panel.tscn
    day_summary.tscn
    character_creation.tscn
scripts/
  autoload/
    game_state.gd
    crafting_system.gd
    day_manager.gd             # New
    dialogue_manager.gd        # New
  areas/
  characters/
    player.gd
    npc_base.gd
    maris.gd / dex.gd / sable.gd / soriel.gd
  derelict/
    run.gd
    room_generator.gd
    enemy_base.gd
  ui/
```

### MVP Vertical Slice Scope

- Cantina + Engineering + Medbay + Quarters + Derelict (3-4 floors)
- Four main NPCs (Maris, Dex, Sable, Soriel)
- 2-3 recruitable survivors from the Derelict
- 7-day arc with a real ending
- Character creation with 3 backgrounds
- Dialogue system with emotional registers + inner voice
