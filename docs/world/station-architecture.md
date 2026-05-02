# Outpost Nova — Station Architecture

**Status:** Design locked 2026-04-12
**Cross-references:** `docs/world/world.md` (Builder/Hegemony lore), `docs/characters/npcs.md` (NPC roster)

---

## Overview

Outpost Nova has two visually and structurally distinct components that contrast sharply: an ancient alien spine built by a long-extinct AI civilization, and a C-shaped rotating habitat arc assembled by Hegemony Combine. The spine is the original structure. Everything else is bolted on.

From a distance the station commands attention. First-time visitors don't say "that's a waypoint station." They say "what *is* that?"

---

## The Builder Spine

The dominant structural element — a massive vertical column built by the Builder AI civilization millennia before human spaceflight. The Builders had no biological members: no art, no windows, no living quarters, no decoration. The spine's aesthetic reflects this. Pure infrastructure, built for resource extraction and power generation at civilizational scale.

**Visual language:** Mathematically precise geometry. Interlocking angular forms and massive structural ridges. Surfaces that absorb light rather than reflect it — dark, slightly iridescent, hard to estimate distance or age from. Nothing about it looks like anything humans would build. The surface has geometric ridges and recesses whose original purpose is unknown; the crew has repurposed them as handholds and ladder rungs.

**The spine does not rotate.** It is static. The habitat arc spins around it.

**Scale:** The spine is enormous relative to the human construction clamped around its midsection. It dominates the station's silhouette. The Hegemony arc looks like a campsite bolted onto a cathedral.

### Spine Layout (top to bottom)

| Section | Notes |
|---------|-------|
| **Sensor Cap** | Top of spine, above the arc. Navigation equipment and sensor arrays installed by Hegemony. Maintained by Dex. Unknown to him: this is the weapon's targeting and firing mechanism. On activation, it reconfigures into the gun chamber — pointed at its target. |
| **Bearing Collar** | Midpoint. Clamped around the spine — the static mechanical interface that the C-arc rotates around. Purely mechanical; no pressurized space or berths. The Trade Dock connects laterally from the collar into the C-arc — the only passage between the two. |
| **Power Core** | First Builder room below the junction. Ancient power generation infrastructure. The station has been running off its residual output for years. Restoring active operation unlocks Energy Cell production. Zero gravity. *Production: Energy Cell plots (out of scope for MVP) — see `docs/design/production-plots.md`.* |
| **Drone Bay** *(lateral attachment, Power Core level)* | Zero-g. Mag-boots required. A lateral arm off the spine at Power Core level. Drone launch bays and telemetry equipment bolted directly onto Builder infrastructure — Hegemony's extraction equipment mounted on the very structure it unknowingly drains. Prerequisite chain: Power Core restored → Drone Bay buildable → Vril production begins. No character anchor (deferred). *Production: Vril extraction cradles (out of scope for MVP) — see `docs/design/production-plots.md`.* |
| **Lower Decks** | Sealed Builder sections below the Power Core. Debris, old infrastructure, unexplored space. Salvage actions pull resources from Builder wreckage. Quen's sealed door is here — the threshold to the Deep Core. Zero gravity. |
| **Deep Core** | Bottom of the spine. Fully unmodified Builder structure. Zero gravity. The weapon's mechanism. Does not obviously read as a weapon — the geometry is massive, precise, and intentional, but its purpose is not legible until context (logs, Vaen's artifact) reveals it. The Act 3 chambers branch laterally from here. |

**Gravity note:** The entire spine is zero gravity. Power Core, Lower Decks, and Deep Core all require mag-boots. The Builder ridges serve as natural grip points. Movement through the spine is practiced and deliberate — the long-timers (especially Quen) handle it instinctively; new arrivals have to learn.

**The weapon:** The spine is a gun, hidden. It was built to fire at a specific target. Nothing about its exterior reads as a weapon until activation. When the weapon activates, the sensor cap at the top reconfigures — something structural changes, and what looked like navigation equipment reveals itself as the firing mechanism. Dex has been maintaining it for years without knowing.

---

## The Habitat Arc

A C-shaped rotating ring assembled by Hegemony Combine — a powerful interstellar corporation — and clamped around the spine's midsection. Hegemony's aesthetic is contractor-grade industrial: grey and off-white metal panels, visible seams and bolts, modular prefab sections assembled over time. Functional lighting strips. Faded corporate markings. It looks like a profitable company solved a problem with the budget they were given.

**The arc rotates** around the static spine to generate artificial gravity. It is the only part of the station with gravity.

**The C-shape:** The arc wraps around the spine on three sides. The fourth side — the open mouth of the C — faces the trade lane. Ships approach from this direction and dock at the Trade Dock's berths. The Trade Dock is the only way into the arc.

### Arc Layout

```
[Workshop] — [Cantina] — [door] — [Security Post] — [Med Bay]
                     \                /
                      [Trade Dock]
                           |
                        [COLLAR]
```

- **Trade Dock** (Sable): A single integrated module — berth face, Sable's space, arc face. Two docking berths on the outward face receive arriving ships. The outer ring of each berth is static; the inner ring is on rails and spins with the station — the airlock waits for alignment before opening. Gravity hits the moment you step through. Two exits branch into the arc — left to the Cantina, right to Security Post. Sable has sightlines to both from her post.
- **Center triangle** (Trade Dock + Cantina + Security Post): The oldest Hegemony modules. The operational and social heart of the station. Cantina and Security Post share a direct closeable door. *Cantina production: 2 Rations plots at Day 1 — see `docs/design/production-plots.md`.*
- **Workshop** (dead end): Only reachable through the Cantina. Left tip of the arc. *Production: 2 Parts plots at Day 1 — see `docs/design/production-plots.md`.*
- **Med Bay** (dead end): Only reachable through Security Post. Right tip of the arc.

**Arm tips:** The arms extend beyond the current rooms. At the current edge of each pressurized section: a sealed airlock. From outside, skeletal scaffolding marks where the next modules will go. Building a new room means constructing and pressurizing the next section — filling in the skeleton. The station genuinely grows; it doesn't just reveal what was already there.

**Crew quarters:** Tucked between functional rooms in the arc arms — not a dedicated player-accessible space. Bunks in close proximity. The station is small enough that you can't avoid each other.

**Population:** ~30 at station start. Grows toward ~100 as wings are built out. Adding a person is a real logistical event. The station is a lifeboat before it becomes a community.

---

## The Junction — Trade Dock

The sole passage between the bearing collar and the C-arc. Sable's domain. Every visitor passes through it.

The sequence on arrival: ship docks at the Trade Dock's berths (outer ring static, zero-g on the ship side) → inner airlock aligns with the spinning station → step through → gravity hits immediately → you are inside. The Trade Dock is berth, airlock, and passage in one module.

The Trade Dock is the only way in and the only way out of the arc. From here, two exits branch into the arc — left to the Cantina, right to Security Post. Sable has sightlines to both from her post. You can also cross back through the collar and descend the spine into zero-g. The crew barely notices the gravity transition anymore. New arrivals find it disorienting — gravity arriving all at once as you step through.

---

## Act 3 Wing

Accessed from within the Deep Core — lateral chambers branching off from the weapon's mechanism, not deeper into the spine. Sealed behind Builder architecture that requires specific story progress to open.

Year 1: one room accessible (Deep Core Access). A second room remains sealed until Year 2.

These chambers contain what the weapon was built *for* — the records, the logic, the civilization behind it. The weapon points outward. The Act 3 rooms point inward.

---

## Sensory Notes

**The arc** smells lived-in: food, recycled air, machine oil, the specific smell of a place people have made home despite themselves. The Cantina dominates. First-time visitors often remark it smells better than expected. That's Maris, deliberately.

**The spine** smells like nothing. Not stale, not cold — an absence of smell the human brain reads as wrong. No organic history. No decay. Nothing biological ever lived there. The absence is its own kind of uncanny.

---

## Image Generation Prompts

### Beauty Shot

> Station layout for reference:
> ```
> [Workshop] — [Cantina] — [door] — [Security Post] — [Med Bay]
>                      \                /
>                       [Trade Dock]
>                            |
>                         [COLLAR]
> ```
>
> A space station in deep space. The station has two visually distinct components that contrast sharply.
>
> The dominant element is an ancient alien structure forming the central vertical spine — built by a long-extinct AI civilization that had no biological members, only machines optimizing for resource extraction and power generation at civilizational scale. The spine is tall, narrow, and elongated — thin relative to its length, like a needle or obelisk, extending well above and below the human construction clamped to its midsection. It does not look manufactured. It looks grown — crystalline or rock-like forms, with surfaces that resemble dark mineral or obsidian fused with geometric lattices. The geometry is wrong in a way that is hard to articulate: angles that almost follow a pattern, structures that suggest purpose without revealing it. Vivid green light glows from within the cracks and seams of the spine — intense, unnatural, deeply wrong in color and quality. Not soft, not ambient: it pulses with the logic of something still active, still running, after millennia. The green casts harsh shadows on the human modules clamped nearby. It does not look like a power indicator or a status light. It looks like the structure itself is alive. The overall effect is geological and alien: less like a machine, more like a spire that was built. It extends far beyond the C-arc in both directions — the human construction occupies only the middle third of its total length. It predates human spaceflight by millennia.
>
> Wrapped around the spine's midsection is a single C-shaped habitat arm — NOT a full ring, NOT two rings. One continuous tube of human prefab modules that curves around three sides of the spine and leaves the fourth side open. Think of the letter C: two arms curving toward each other but not meeting. Built by Hegemony Combine — a powerful interstellar corporation, not a government. Their aesthetic is contractor-grade industrial: grey and off-white metal panels, visible seams and bolts, modular prefab sections assembled over time. Functional lighting strips. Corporate markings, faded. This single C-shaped tube connects to a bearing collar clamped around the spine's midsection — the sole mechanical interface between the rotating arc and the static spine. The Trade Dock IS the connecting arm between the collar and the C-arc — not a room at the end of a corridor, but the arm itself. A single short straight perpendicular module extending directly from the collar outward to meet the C-arc at its midpoint. Sable's domain. The threshold every visitor crosses. No other bridge or tube connects the collar to the arc anywhere else. It is collar-attached: it starts at the collar and reaches out to the C, visually distinct from the arc's curve — a straight arm jutting inward toward the spine. A pressurized rotating bearing allows the entire C-arm and Trade Dock to spin slowly around the static spine and collar, generating artificial gravity. The rotation is visible: the arc turns, the spine does not. Two docking berths extend from the Trade Dock's outward face, facing incoming ships on the trade lane. A sensor array cap at the top of the spine. Scaffolding extensions at the arm tips where future modules will be built.
>
> The overall impression: a campsite bolted onto something ancient and not entirely understood. The alien spine blazes vivid green from within — wrong, alive, unsettling. The human construction is functional and improvised, clinging to something far older than it. Hard sci-fi, cinematic lighting, deep space. Awe-inspiring, eerie, lonely, beautiful.

### Schematic / Blueprint

> Hard sci-fi technical blueprint, white and pale blue lines on dark navy background. Clean label lines, no decorative elements.
>
> ---
>
> DIAGRAM 1 — SPINE SIDE VIEW (tall, left side of page):
>
> The main subject is the spine. A single tall narrow vertical column — its width is roughly 1/10th of its height. Crystalline, mineral texture. Vivid green light blazing from internal cracks. The spine does NOT move — no rotation arrows.
>
> Divide it into three equal vertical zones with dashed horizontal lines:
> - TOP THIRD: label "SENSOR CAP" at the very top. Small Hegemony sensor arrays and antennae shown mounted on the alien surface.
> - MIDDLE THIRD: a ring or band is drawn encircling the spine at this zone. This ring represents the BEARING COLLAR — the mechanical interface between the static spine and the rotating C-arc. The collar wraps tightly around the spine with a visible gap between collar and spine surface indicating the bearing mechanism. Label the ring "BEARING COLLAR (C-arc rotates around this)". On the right side of the collar, a single perpendicular arm extends outward — this IS the TRADE DOCK (Sable's room). It is not a tube that leads to the Trade Dock; it is the Trade Dock itself. The Trade Dock is the connecting arm: berth face on one end, arc connection on the other, Sable's space in the middle. Label it "TRADE DOCK — berth + passage + arc connection". On the trade-lane-facing side of the TRADE DOCK arm (not the collar, not the spine), draw two outward-facing docking berth protrusions labeled "2 DOCKING BERTHS — ships attach here (outer ring static, inner ring spins with station)". Do NOT draw berths on the collar.
> - BOTTOM THIRD: three stacked sections labeled top to bottom — "POWER CORE", "LOWER DECKS", "DEEP CORE". Deep Core is at the very bottom tip.
>
> ---
>
> DIAGRAM 2 — C-ARC SIDE VIEW (same height as Diagram 1, placed next to it):
>
> The main subject is the C-shaped habitat arc. The C opens to the RIGHT. It is a single continuous tube — NOT a full ring, NOT two separate pieces. The tube runs from top-left, curves around the left side, and ends at bottom-left, leaving the right side completely open. The vertical height of the C matches exactly the MIDDLE THIRD of the spine in Diagram 1.
>
> In the center of the C — in the empty space inside the curve — draw a small circle representing the spine in cross-section. The spine circle is surrounded by a slightly larger ring representing the BEARING COLLAR. Label the inner circle "SPINE (static)". Label the surrounding ring "BEARING COLLAR". Draw a visible gap between the spine circle and the collar ring to indicate the bearing mechanism — the collar grips the spine but rotates freely around it. Do NOT draw docking berths on the collar — the collar is purely mechanical.
>
> From the outer edge of the bearing collar, a SINGLE perpendicular arm extends rightward to meet the C-arc. This arm IS the TRADE DOCK — it is not a corridor that leads to the Trade Dock, it is the Trade Dock itself. The Trade Dock is berth, airlock, and passage in one module: collar-attached on one end, arc connection on the other. Label it "TRADE DOCK (Sable) — berth + passage + arc connection, collar-attached, sole entry point". On the trade-lane-facing side of the Trade Dock arm, draw two docking berth protrusions labeled "2 DOCKING BERTHS (outer ring static / inner ring spins)". No other arm, tube, bridge, or connection exists between the collar and the C-arc anywhere else.
>
> Rotation arrows shown on the arc, Trade Dock, and collar — they all spin together around the static spine circle.
>
> Arc room layout for reference:
> ```
> [Workshop] — [Cantina] — [door] — [Security Post] — [Med Bay]
>                      \                /
>                       [Trade Dock]
>                            |
>                         [COLLAR]
> ```
>
> Label the C-arc sections:
> - Top-left end of the C-tube (top tip): "WORKSHOP (dead end)"
> - Upper-left curve of the C-tube: "CANTINA"
> - Left-center of the C-tube (Trade Dock connection point): "TRADE DOCK (Sable) — sole entry point between collar and arc"
> - Lower-left curve of the C-tube: "SECURITY POST"
> - Bottom-left end of the C-tube (bottom tip): "MED BAY (dead end)"
> - Between CANTINA and SECURITY POST, draw a dashed cross-connection labeled "CLOSEABLE DOOR"
> - Top-right open end (pointing right): skeletal scaffolding, labeled "FUTURE CONSTRUCTION"
> - Bottom-right open end (pointing right): skeletal scaffolding, labeled "FUTURE CONSTRUCTION"
>

### Dis — The Gas Giant

> Generate an image of an Argon Lightning / Auroras giant gas planet. The planet is predominantly deep purple — rich violet and dark purple cloud bands across its surface. Vivid electric lightning bolts crackle and branch dramatically across the planet, bright and intense. A cold blue-white star is visible in the upper-right of the frame — small and sharp, like a distant stellar remnant. Scattered across the planet's mid-atmosphere cloud band, small isolated patches of pale green bioluminescence — sparse and localized, each patch clearly visible but contained, as if something organic is glowing in clusters beneath the cloud layer. The green patches are a noticeable secondary detail but the planet remains predominantly purple.
