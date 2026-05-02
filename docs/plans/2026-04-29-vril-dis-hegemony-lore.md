# Vril, Dis, and Hegemony Dual-Motivation Lore Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Document Vril (4th resource), Dis (source gas giant), and Hegemony's dual motivation across four world/design docs, closing issue #76.

**Architecture:** Pure documentation pass — no GDScript, no scenes, no tests. All four target files already exist; each task is a targeted edit. Tasks that touch different files are independent and can run in parallel.

**Tech Stack:** Markdown docs only.

## Open questions (must resolve before starting)

- **Drone Bay row placement:** Issue specifies its own row in the spine layout table (lateral attachment annotation). If you prefer to fold it into the Power Core row instead, decide before Task 3 — both options are documented below.

---

## Batch 1 — world.md and station-architecture.md

### Task 1: Update Hegemony faction entry in world.md

**Files:**
- Modify: `docs/world/world.md`

**Depends on:** none
**Parallelizable with:** Task 3 — different output files, no shared state.

**Step 1: Apply three targeted edits to `docs/world/world.md`**

**Edit A — Current internal state paragraph** (section 2.4, first paragraph under the heading):

Replace:
```
Running a quiet acquisition play on Outpost Nova. The buried survey from the original extraction operation identified an extraordinary alien structure of unknown origin and massive scale — clearly pre-dating any known civilization, clearly worth controlling. The weapon's functionality was dormant or beyond the survey team's ability to interpret. Hegemony knew they were sitting on something extraordinary. They didn't know it still worked. Hegemony said nothing. They built a waypoint on top of it and waited. The superintendent's posting is not coincidental.
```

With:
```
Running a quiet acquisition play on Outpost Nova. The buried survey from the original extraction operation identified an extraordinary alien structure of unknown origin and massive scale — clearly pre-dating any known civilization, clearly worth controlling. The same survey identified Vril — a biological colonial organism drifting in the atmosphere of the gas giant Dis below the station — as a commercially valuable universal catalyst. Hegemony filed Vril extraction rights under Frontier Resource Charter §7 and used this as the public rationale for the station. The weapon's functionality was dormant or beyond the survey team's ability to interpret. Hegemony knew they were sitting on something extraordinary. They didn't know it still worked. Hegemony said nothing. They built a waypoint on top of it and waited. The superintendent's posting is not coincidental.
```

**Edit B — Publicly want** (section 2.4):

Replace:
```
**Publicly want:** Operational stability, debt repayment, access to the new Keth trade lanes.
```

With:
```
**Publicly want:** Vril extraction monopoly. The superintendent's posting is publicly framed as Resource Operations Manager for the GL-667 Vril extraction site — extraction rights filed under Frontier Resource Charter §7, public record. Other factions can see that Hegemony found something worth extracting at Outpost Nova. They don't know what Vril does at full scale, or that it's connected to the Builder node.
```

**Edit C — Actually want** (section 2.4):

Replace:
```
**Actually want:** Quiet ownership of the ancient site under the station. Whatever is down there — they want to own it, not understand it. More specifically: Hegemony's buried survey found not just the structure, but a shutdown mechanism — a control interface the survey team documented but couldn't interpret. Hegemony has spent years quietly studying it. By Act 3, they understand it well enough to use it. This is Harlan's bargaining chip: not a threat, not institutional pressure — the only known way to stop a weapon that will otherwise destroy the station and everyone on it.
```

With:
```
**Actually want:** Control of the Builder weapon's power source. Vril's pulse frequency matches the Builder node's energy draw exactly — controlled extraction reduces the weapon's available power; full-scale extraction would starve it entirely. Hegemony's buried survey also found a shutdown mechanism — a control interface the survey team documented but couldn't interpret. They have spent years quietly studying it. By Act 3, they understand it well enough to use it. Harlan arrives in Act 3 with two levers: the shutdown mechanism (shown) and the Vril extraction throttle (held in reserve). The shutdown mechanism remains Harlan's bargaining chip: not a threat, not institutional pressure — the only known way to stop a weapon that will otherwise destroy the station and everyone on it.
```

**Step 2: Verify**

Open `docs/world/world.md`, section 2.4 (Hegemony Combine). Confirm:
- "Current internal state" mentions Vril and Dis.
- "Publicly want" leads with Vril extraction monopoly and Charter §7.
- "Actually want" leads with weapon power source control, includes both levers.
- No other section contradicts the change.

**Step 3: Commit**

```bash
git add docs/world/world.md
git commit -m "docs: update Hegemony faction entry with Vril dual-motivation (#76)"
```

---

### Task 2: Add Chapter 6 (Dis and Vril) to world.md

**Files:**
- Modify: `docs/world/world.md`

**Depends on:** Task 1 — same file; apply after Task 1's commit.
**Parallelizable with:** none — same file as Task 1; must run after Task 1 completes.

**Step 1: Append Chapter 6 to the end of `docs/world/world.md`**

The file currently ends at line 383 (`docs/story/year1.md.`). Append the following block after the last line:

```markdown

---

## Chapter 6: Dis and Vril

### 6.1 Dis — The Gas Giant

A gas giant in the outer zone of the Gliese 667 system. Named after Dante's buried city of the damned.

**Physical:** Predominantly deep purple — rich violet and dark purple cloud bands. Vivid electric argon lightning bolts crackle across the upper atmosphere, bright and intense. A spectacular spiral aurora at the magnetic pole: bright magenta vortex with long purple-pink curtains rising into space.

Scattered across the mid-atmosphere cloud band: small isolated patches of pale green bioluminescence — sparse, localized, organic light in the wrong color against the purple atmosphere. This is Vril.

*For image prompt, see `docs/world/station-architecture.md` — Image Generation Prompts: Dis.*

---

### 6.2 Vril

A colonial organism drifting in Dis's mid-atmosphere pressure bands — between the deep cloud layers below and the argon lightning layer above.

**Physical:** Translucent filaments, tens of kilometres in length. At rest: nearly invisible. When pulsing: pale green bioluminescence visible from orbit as small isolated clusters.

**Biology:** Vril evolved to bridge the Builder node's energy output with Dis's planetary core — that gradient was the most stable energy source available in the system. Its biology adapted to make that energy compatible with any substrate. When refined, this property manifests as a universal catalyst.

**Catalytic properties:** Combines with any of the three primary resource categories (Rations, Parts, Energy Cells) to produce outputs beyond normal engineering limits. *See `docs/design/resources.md` for the full economy design.*

---

### 6.3 Hegemony's Hidden Knowledge

Vril's pulse frequency matches the Builder node's energy draw exactly. This is not coincidence — Vril evolved on this gradient. The connection is ancient and structural.

Controlled extraction reduces the weapon's available power. Full-scale extraction would starve it entirely. This is Hegemony's second lever in Act 3, held in reserve behind the shutdown mechanism. Harlan arrives with both: the shutdown mechanism as the shown bargaining chip, and the Vril extraction throttle as the threat behind the threat.

Other factions can see that Hegemony filed extraction rights and found something worth harvesting at Outpost Nova. They do not know Vril is connected to the Builder node. They do not know controlled extraction is a weapon-throttle.
```

**Step 2: Verify**

Read `docs/world/world.md` from line 383 onward. Confirm:
- Chapter 6 header, three subsections (6.1, 6.2, 6.3) are present.
- Cross-reference to `station-architecture.md` image prompt is in 6.1.
- Cross-reference to `resources.md` is in 6.2.
- No trailing whitespace issues or missing section separators.

**Step 3: Commit**

```bash
git add docs/world/world.md
git commit -m "docs: add Chapter 6 (Dis and Vril) to world.md (#76)"
```

---

### Task 3: Update station-architecture.md — Drone Bay row + Dis image prompt

**Files:**
- Modify: `docs/world/station-architecture.md`

**Depends on:** none
**Parallelizable with:** Task 1 — different output file, no shared state.

**Step 1a: Add Drone Bay row to the Spine Layout table**

The spine layout table currently has 5 rows (Sensor Cap, Bearing Collar, Power Core, Lower Decks, Deep Core). Add a new row for the Drone Bay **after the Power Core row and before the Lower Decks row**.

Replace this block in the table:

```
| **Power Core** | First Builder room below the junction. Ancient power generation infrastructure. The station has been running off its residual output for years. Restoring active operation unlocks Energy Cell production. Zero gravity. |
| **Lower Decks** | Sealed Builder sections below the Power Core. Debris, old infrastructure, unexplored space. Salvage actions pull resources from Builder wreckage. Quen's sealed door is here — the threshold to the Deep Core. Zero gravity. |
```

With:

```
| **Power Core** | First Builder room below the junction. Ancient power generation infrastructure. The station has been running off its residual output for years. Restoring active operation unlocks Energy Cell production. Zero gravity. |
| **Drone Bay** *(lateral attachment, Power Core level)* | Zero-g. Mag-boots required. A lateral arm off the spine at Power Core level. Drone launch bays and telemetry equipment bolted directly onto Builder infrastructure — Hegemony's extraction equipment mounted on the very structure it unknowingly drains. Prerequisite chain: Power Core restored → Drone Bay buildable → Vril production begins. No character anchor (deferred). |
| **Lower Decks** | Sealed Builder sections below the Power Core. Debris, old infrastructure, unexplored space. Salvage actions pull resources from Builder wreckage. Quen's sealed door is here — the threshold to the Deep Core. Zero gravity. |
```

> **Note:** If you prefer to fold the Drone Bay into the Power Core row as a note rather than a separate row, that is also acceptable. The own-row treatment is recommended because it parallels how the Bearing Collar documents the Trade Dock as a lateral attachment.

**Step 1b: Add Dis image prompt to Image Generation Prompts section**

The Image Generation Prompts section currently has two subsections: "Beauty Shot" and "Schematic / Blueprint". The file ends after the Blueprint prompt (around line 168, which ends with a closing `>`). Append the following after the last line of the file:

```markdown

### Dis — The Gas Giant

> Generate an image of an Argon Lightning / Auroras giant gas planet. The planet is predominantly deep purple — rich violet and dark purple cloud bands across its surface. Vivid electric lightning bolts crackle and branch dramatically across the planet, bright and intense. A cold blue-white star is visible in the upper-right of the frame — small and sharp, like a distant stellar remnant. Scattered across the planet's mid-atmosphere cloud band, small isolated patches of pale green bioluminescence — sparse and localized, each patch clearly visible but contained, as if something organic is glowing in clusters beneath the cloud layer. The green patches are a noticeable secondary detail but the planet remains predominantly purple.
```

**Step 2: Verify**

Open `docs/world/station-architecture.md`:
- Spine layout table has 6 rows. Drone Bay row appears between Power Core and Lower Decks. Lateral attachment annotation is present.
- Image Generation Prompts section has three subsections: Beauty Shot, Schematic / Blueprint, Dis.
- Dis image prompt is the canonical text from the issue (purple planet, argon lightning, pale green bioluminescence, cold blue-white star upper-right).

**Step 3: Commit**

```bash
git add docs/world/station-architecture.md
git commit -m "docs: add Drone Bay to spine layout, Dis image prompt to station-architecture (#76)"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 1, Task 3 | Different output files — world.md and station-architecture.md |
| B (sequential) | Task 2 | Depends on Task 1 — same file (world.md); must run after Task 1 completes |

### Smoketest Checkpoint 1 — world.md and station-architecture.md

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: No GUT tests for this pass (docs only)**

Skip the GUT test run — no GDScript was modified.

**Step 3: Review docs manually**

Open both files and confirm:
- `docs/world/world.md` section 2.4: Hegemony "Publicly want" = Vril extraction monopoly; "Actually want" = weapon power source + two levers. Chapter 6 present with three subsections.
- `docs/world/station-architecture.md`: Drone Bay row present in spine table. Dis image prompt present in Image Generation Prompts.
- No broken markdown (unclosed code blocks, misaligned table pipes).

**Step 4: Confirm with user**

Ask the user: "world.md and station-architecture.md look correct? Hegemony has two levers, Drone Bay is in the spine table, Dis image prompt is added?" Wait for confirmation before proceeding.

---

## Batch 2 — resources.md and galaxy-map.md

### Task 4: Add Vril as 4th resource category to resources.md

**Files:**
- Modify: `docs/design/resources.md`

**Depends on:** none
**Parallelizable with:** Task 5 — different output file, no shared state.

**Step 1: Append Vril section to `docs/design/resources.md`**

The file currently ends after the Open Questions section (around line 117). Append the following after the last line:

```markdown

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
```

**Step 2: Verify**

Open `docs/design/resources.md`. Confirm:
- New "Vril (4th Resource Category)" section is present at the bottom.
- Sub-resource table has 3 rows with *(placeholder name)* annotations.
- Outputs table has 3 rows with *(placeholder name)* annotations.
- HUD rule, prerequisite chain, and no-quota note are present.
- Out of scope list clearly states no GDScript this pass.

**Step 3: Commit**

```bash
git add docs/design/resources.md
git commit -m "docs: add Vril as 4th resource category to resources.md (#76)"
```

---

### Task 5: Update Outpost Nova entry in galaxy-map.md

**Files:**
- Modify: `docs/world/galaxy-map.md`

**Depends on:** none
**Parallelizable with:** Task 4 — different output file, no shared state.

**Step 1: Expand the Outpost Nova entry in `docs/world/galaxy-map.md`**

Current Outpost Nova entry (in the Border Zone section):

```
**Outpost Nova** *(ring/hex, amber · Gliese 667 — K3V triple)* — The game location. A Hegemony-operated waypoint
station built on top of a buried Builder primary node. The weapon inside the station is
aimed at Vaethos. The station's legal ambiguity, Keth trade lane proximity, and
extraordinary underlying structure make it the intersection point for every faction's
agenda. See `docs/story/year1.md`.
```

Replace with:

```
**Outpost Nova** *(ring/hex, amber · Gliese 667 — K3V triple)* — The game location. A Hegemony-operated waypoint station built on top of a buried Builder primary node. The weapon inside the station is aimed at Vaethos. The station's legal ambiguity, Keth trade lane proximity, and extraordinary underlying structure make it the intersection point for every faction's agenda. See `docs/story/year1.md`.

The system's outer zone contains **Dis** — a gas giant and the source of Vril, a biological colonial organism refined into the game's fourth resource category. See `docs/design/resources.md` and `docs/world/world.md` §6.

**Gliese 667's third stellar component** is a hot subdwarf B (sdB) — a post-red-giant remnant burning helium at ~30,000K. Blue-white, roughly Earth-sized, far less luminous than a true blue giant. From Dis's wide orbit it appears small, sharp, and cold. Its UV output drives the argon lightning in Dis's upper atmosphere. *(The system entry lists `K3V triple`; the third component is the sdB, not a third main-sequence star.)*
```

**Step 2: Verify**

Open `docs/world/galaxy-map.md`. Confirm:
- Outpost Nova entry now names Dis and links to `resources.md` and `world.md §6`.
- sdB star component is documented: post-red-giant, helium-burning, ~30,000K, blue-white, Earth-sized.
- Parenthetical clarifies the "K3V triple" label vs. the sdB component.
- No other system entry was accidentally modified.

**Step 3: Commit**

```bash
git add docs/world/galaxy-map.md
git commit -m "docs: name Dis and document sdB star in galaxy-map Outpost Nova entry (#76)"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 4, Task 5 | Different output files — resources.md and galaxy-map.md |

### Smoketest Checkpoint 2 — all four docs, final consistency check

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: No GUT tests for this pass (docs only)**

Skip the GUT test run — no GDScript was modified.

**Step 3: Review all four docs for cross-reference consistency**

Check the following invariants across all four files:

| Invariant | Where to check |
|---|---|
| Vril = universal catalyst that combines with Rations/Parts/Energy Cells | world.md §6.2, resources.md Vril section |
| Hegemony's two levers: shutdown mechanism + Vril throttle | world.md §2.4 Actually want, world.md §6.3 |
| sdB star drives argon lightning in Dis's upper atmosphere | galaxy-map.md Outpost Nova entry, world.md §6.1 (atmosphere description) |
| Drone Bay prerequisite chain: Power Core → Drone Bay → Vril | station-architecture.md Drone Bay row, resources.md Vril prerequisite chain |
| Dis image prompt cross-reference | world.md §6.1 points to station-architecture.md |
| Vril resources.md cross-reference | world.md §6.2 points to resources.md; galaxy-map.md points to resources.md |

**Step 4: Confirm with user**

Ask the user: "All four docs look correct? Cross-references are consistent, Hegemony two-lever structure is coherent, Vril economy section is clear?" Wait for confirmation before finalizing.

**Step 5: Final commit (if any cleanup needed)**

If minor formatting fixes were made during review:
```bash
git add docs/world/world.md docs/world/station-architecture.md docs/design/resources.md docs/world/galaxy-map.md
git commit -m "docs: cleanup formatting across Vril/Dis lore docs (#76)"
```
