# World Documentation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Write `docs/world/world.md` — a comprehensive internal world reference covering the Settled Frontier's history, living factions, species, and geo-political ripple effects of the game's events.

**Architecture:** Single living document in `docs/world/world.md`, five chapters, independently updatable sections. Pure writing task — no GDScript, no scenes, no GUT tests. Closes GitHub issue #11.

**Tech Stack:** Markdown. Cross-references `docs/plans/2026-03-16-story-bible-design.md` and `docs/characters/npcs.md` for consistency.

## Open questions (must resolve before starting)

- Names for both ancient civilizations (currently TBD — writer may invent first-draft names or leave as `[NAME TBD]` placeholders)
- Specific cultural details for the 2 new Unbound species and 2 new Sovereign species (writer invents these in Task 6)

---

## Batch 1 — Scaffold + History

### Task 1: Scaffold world.md with chapter headings

**Files:**
- Create: `docs/world/world.md`

**Depends on:** none
**Parallelizable with:** none — must come first; all subsequent tasks append to or fill this file.

**Step 1: Create the file**

Create `docs/world/world.md` with exactly this skeleton:

```markdown
# Outpost Nova — World Documentation

**Status:** Living document — sections fill in as story decisions lock.
**Last updated:** 2026-04-02
**Cross-references:** `docs/plans/2026-03-16-story-bible-design.md` (story bible), `docs/characters/npcs.md` (NPC reference)

---

## Chapter 1: History

### 1.1 The Ancient Civilizations
### 1.2 The Settled Frontier
### 1.3 First Contact with the Keth
### 1.4 The War
### 1.5 The Truce

---

## Chapter 2: Living Factions

### 2.1 The Federation
### 2.2 The Unaligned Alliance
### 2.3 The Keth (as Political Entity)
### 2.4 Hegemony Combine

---

## Chapter 3: Species Profiles

### Displaced Species
### Unbound Species
### Sovereign Species

---

## Chapter 4: Keth Deep-Dive

### 4.1 The Lie
### 4.2 Caste Structure
### 4.3 What Cracked Post-War
### 4.4 Vaen's Exile

---

## Chapter 5: Political Ripple

### 5.1 Act-by-Act Off-Screen Shifts
### 5.2 Per-Ending Faction Outcomes
```

**Step 2: Verify**

Confirm the file exists at `docs/world/world.md` and all five chapter headings are present.

**Step 3: Commit**

```bash
git add docs/world/world.md
git commit -m "docs: scaffold world documentation structure"
```

---

### Task 2: Write Chapter 1 — History

**Files:**
- Modify: `docs/world/world.md` (fill in sections 1.1–1.5)

**Depends on:** Task 1
**Parallelizable with:** none — all subsequent tasks depend on this history being established first.

**Step 1: Write section 1.1 — The Ancient Civilizations**

Cover three subsections:

**The Builders**
- An AI civilization that outgrew their organic creators. The creators are long gone before the war with the second civilization — absorbed or made obsolete by what they built.
- The ruins have no individuals: no art, no graves, no faces, no record of anyone who lived there. Not absence of culture — a *different kind of mind*. The ruins are an inventory because there were no selves to leave traces.
- Built for resource accumulation and power generation at scale. Living quarters are small, late additions. Everything else is extraction and processing infrastructure.
- The Keth did not encounter the Builders directly — they encountered the Builders' *infrastructure* at secondary sites (ancient nodes, relay stations) and incorporated geometric patterns into their sacred architecture, projecting meaning onto shapes whose origin they never understood.
- First-draft name: writer may invent here, or use `[BUILDER CIV NAME TBD]`.

**The Second Civilization**
- Biological. Deeply individualistic — almost to the point of narcissism. They documented everything: faces, names, records, art, personal histories.
- Their ruins are the structural opposite of the station: full of selves.
- Located in uncharted space, at the coordinates the weapon is aimed at.
- Completely unknown to the Keth — the Keth recognize nothing from the second civilization. That asymmetry is its own information.
- First-draft name: writer may invent here, or use `[SECOND CIV NAME TBD]`.

**The War**
- Resource-driven. The Builder AI initiated because its optimization logic flagged the second civilization's territory as containing necessary materials.
- Two incompatible ontologies: one civilization had no concept of self; the other had no concept of *other*. Neither could find a frame for the conflict that allowed for peace.
- Neither side survived. The weapon is still aimed. Whatever they were fighting over, it outlasted both of them.

**Step 2: Write section 1.2 — The Settled Frontier**

Cover the arc of human expansion:
- Corporate extraction era: humanity arrived in this region of space through corporate mining and resource operations. Infrastructure built for profit, not habitation. (Hegemony Combine's ancestor operations.)
- Colonial settlement: people followed the infrastructure. Communities formed in the margins of extraction sites. Not planned — opportunistic.
- Federation consolidation: the Federation's military absorbed, annexed, or pressured independent settlements into alignment. Called this stabilization. The people stabilized didn't always agree.
- The emerging Keth trade lanes: as the truce holds, Keth merchants are beginning to route through human-adjacent space. New lanes are valuable; Outpost Nova sits on one.

**Step 3: Write section 1.3 — First Contact with the Keth**

- First contact happened in a warzone, between frightened people with weapons. Not a formal encounter — a collision.
- It took four more years of that before anyone thought to try talking.
- The resulting truce was built on commerce because neither side trusts anything else yet.
- What happened in Keth space during and after contact is not something they discuss with humans yet.

**Step 4: Write section 1.4 — The War**

- Lasted eleven years. Nobody calls it "the War" anymore — each faction has a different name:
  - The Federation: **the Consolidation**
  - The Unaligned worlds: **the Fracture**
  - The Keth: no word for it yet in any human language
- Began as a resource conflict between human factions. Became something worse when first contact with the Keth happened in that context.
- The war is over. The wounds are not.

**Step 5: Write section 1.5 — The Truce**

- Five years old.
- Built on commerce because neither side trusts anything else yet. Trade agreements where diplomatic ones would fail.
- Fragile: the Keth's internal factions are cracking; human factions have competing interests in the new trade lanes; Hegemony profits from the uncertainty.
- The station sits at the intersection of the emerging Keth trade lane, Unaligned territory that gives it legal ambiguity, and a Hegemony extraction survey that was never published.

**Step 6: Verify**

Read `docs/plans/2026-03-16-story-bible-design.md` sections "The War" and "The Universe" to confirm no contradictions with the story bible.

**Step 7: Commit**

```bash
git add docs/world/world.md
git commit -m "docs: write Chapter 1 — history of the Settled Frontier and ancient civilizations"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 1 | No deps — must run first |
| B (sequential) | Task 2 | Depends on Task 1 — run after A completes |

### Smoketest Checkpoint 1 — Chapter 1 review

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass (this task touches no GDScript — tests should be unaffected).

**Step 3: Review Chapter 1**

Open `docs/world/world.md` and read Chapter 1 against the story bible (`docs/plans/2026-03-16-story-bible-design.md` sections "The Universe — The Settled Frontier", "The Secret", "The Weapon", "The Second Civilization"). Confirm:
- The Builders are described as an AI civ with no individuals
- The second civ is described as deeply individualistic/narcissistic with documented faces and names
- The war cause is resource-driven, two incompatible ontologies
- History timeline is consistent with the story bible's faction descriptions

**Step 4: Confirm with user**

Ask: "Does Chapter 1 match your vision for the history? Any changes before moving to factions?"

---

## Batch 2 — Living Factions + Keth Deep-Dive

### Task 3: Write Chapter 2 — Living Factions

**Files:**
- Modify: `docs/world/world.md` (fill in sections 2.1–2.4)

**Depends on:** Task 2 (needs history context for current faction states)
**Parallelizable with:** Task 4 — both write to world.md but in different chapter sections; if working solo, do sequentially. If two writers, coordinate section ownership to avoid merge conflicts.

Each faction entry covers four fields: **What they are / current state**, **What they publicly want**, **What they actually want**, **Posture toward the station (Act 1 pre-game)**.

**Step 1: Write section 2.1 — The Federation**

- **What they are:** A military that won a war and never stood down. Bureaucratic, disciplined, believes its own rhetoric about stability and order. Contains real idealists. But it consolidates, surveils, and extracts — and calls this protection.
- **Current internal state:** Post-war, they are the dominant human power but stretched. Maintaining the truce with the Keth is politically costly domestically. Hawks and doves are in tension.
- **Publicly want:** Stability, order, safe trade lanes, protection of human interests.
- **Actually want:** Continued dominance of human space; monitoring of Hegemony's increasingly independent operations; intelligence on Keth internal politics.
- **Posture toward the station:** A Federation patrol passes near Outpost Nova occasionally, asking questions that are slightly too specific for routine transit checks. They've noticed Hegemony's unusual interest in a forgotten waypoint station and are trying to understand why — without tipping their hand.

**Step 2: Write section 2.2 — The Unaligned Alliance**

- **What they are:** Less a government than a pact of refusal. Dozens of worlds that said *not our war* and held that line — blockaded and sanctioned throughout the Fracture, still standing.
- **Current internal state:** Vindicated by survival but fractured internally. Their isolationism holds them together and limits them. Post-war, some worlds want to re-engage; the old guard sees engagement as compromise.
- **Publicly want:** Local sovereignty, non-interference, fair access to emerging trade lanes.
- **Actually want:** Recognition without entanglement. They want the Federation and Keth to leave them alone while still benefiting from the trade routes the truce has opened.
- **Posture toward the station:** Outpost Nova sits in legal ambiguity near Unaligned territory. The Alliance hasn't formally claimed it, but they watch it. Any Hegemony power move on the station would be a provocation — Hegemony knows this and is moving quietly.

**Step 3: Write section 2.3 — The Keth (as Political Entity)**

- **What they are:** A spacefaring empire older than humanity's presence in the Frontier. Not a monolith — multiple internal factions with their own wounds. The face they show humans is patient, formal, meticulous. What's underneath is cracking.
- **Current internal state:** The truce is commercially driven, which suits the Merchant caste. But younger Keth who dealt with humans during the Fracture are less willing to maintain the controlled face. The trade lane opening near Outpost Nova is a source of internal tension — it's too close to sites the ruling coalition monitors closely.
- **Publicly want:** Profitable trade relationships, respect for Keth territorial claims, gradual diplomatic normalization.
- **Actually want:** (This is the ruling coalition's want, not all Keth.) Quiet monopoly over whatever intelligence the ancient sites provide; containment of any discovery that threatens the cosmological foundation of Keth society.
- **Posture toward the station:** The ruling coalition is monitoring the trade lane. The station's proximity to old signal patterns is noted. When one of their own (Vaen) goes rogue to that area, they are not entirely surprised.

**Step 4: Write section 2.4 — Hegemony Combine**

- **What they are:** Serves no flag. Has shareholders. Built half the infrastructure in the Frontier and holds the debt on the other half. Operated on all sides during the war and profits from the peace. Doesn't take sides — profits from the sides existing.
- **Current internal state:** Running a quiet acquisition play on Outpost Nova. The buried survey from the original extraction operation identified something extraordinary in the station's lower decks. Hegemony said nothing. They built a waypoint on top of it and waited. The commander's posting is not coincidental.
- **Publicly want:** Operational stability, debt repayment, access to the new Keth trade lanes.
- **Actually want:** Quiet ownership of the ancient site under the station. Whatever is down there — they want to own it, not understand it.
- **Posture toward the station:** Hegemony already has monitoring equipment on the station, watching for activation events. The commander's reports are being read very carefully. Communications from Hegemony to the commander are friendly but slightly too specific to be routine.

**Step 5: Verify**

Read `docs/plans/2026-03-16-story-bible-design.md` section "The Factions" and confirm no contradictions. The story bible is the source of truth; this document deepens it.

**Step 6: Commit**

```bash
git add docs/world/world.md
git commit -m "docs: write Chapter 2 — living factions"
```

---

### Task 4: Write Chapter 4 — Keth Deep-Dive

**Files:**
- Modify: `docs/world/world.md` (fill in sections 4.1–4.4)

**Depends on:** Task 2 (needs AI builders established as source of Keth tech)
**Parallelizable with:** Task 3 — writes to a different chapter section of world.md. If working solo, do after Task 3. If two writers, coordinate to avoid merge conflicts.

**Step 1: Write section 4.1 — The Lie**

The entire foundation of Keth society is a fabrication maintained by the ruling coalition:

- The ruling coalition (Merchant, Keeper, Sentinel castes) discovered ancient AI Builder infrastructure at secondary sites — relay nodes, processing stations — during early Keth space exploration. This technology was millennia old and far beyond Keth capability.
- Rather than disclose the discovery, the ruling castes reverse-engineered what they could, incorporated the geometric patterns and structural logic into Keth sacred architecture, and built a cosmology around it: the shapes are divine gifts, evidence of Keth cosmic significance, the foundation of their civilization's spiritual identity.
- The lie serves power: the ruling coalition has exclusive access to the technology derived from the sites, maintains that access through religious authority, and suppresses any inquiry into the shapes' external origin — because that inquiry threatens everything built on top of it.
- The lower castes (Navigator, Hearth) are true believers. They did not choose the lie. They were born into it.
- Note: the Keth have NOT encountered the station itself before the game. They've encountered other Builder sites. The station's existence — and what it actually is — is new information.

**Step 2: Write section 4.2 — Caste Structure**

| Caste | Role | Alignment | Coalition or Believer |
|-------|------|-----------|----------------------|
| **Merchant** | External relations, trade, the face shown to other species | Detached / Cynical | Coalition (ruling) |
| **Keeper** | Sacred knowledge, maintains ancient architecture | Curious / Bitter — senses there's more to know, bound by tradition | Coalition (ruling) |
| **Sentinel** | Military, security | Pre-war: Hopeful / Detached. Post-war: Cynical / Detached | Coalition (ruling) |
| **Navigator** | Pilots, mappers, range farthest from Keth space | Hopeful / Curious — most exposed to the galaxy, most changed by the war | True Believers |
| **Hearth** | Community, kin networks, domestic governance | Warm / Hopeful — hold Keth society together from inside, most conservative | True Believers |

The Navigator caste is the most destabilized post-war — they dealt with humans directly, and what they saw doesn't fit the cosmology they were handed. This is the social pressure that makes the ruling coalition nervous.

**Step 3: Write section 4.3 — What Cracked Post-War**

- The Fracture exposed Navigator and lower-caste Keth to human space in ways the ruling coalition didn't control. They saw things that raised questions.
- The ruling coalition's post-war strategy: use the Merchant caste's new commercial relationships to manage the information flow — frame everything through trade and formal protocol, keep the informal encounters contained.
- What they can't fully manage: Keth who came back from the Fracture carrying questions. Some of these Keth are in the Navigator caste. Some have started asking the Keeper caste things the Keeper caste cannot answer without unraveling the lie.
- The cracking is slow. It is not a revolution yet. But the ruling coalition knows it's happening.

**Step 4: Write section 4.4 — Vaen's Exile**

- Vaen (full name: Vaensoleth) was Merchant caste — inside the ruling coalition, with access to privileged information channels.
- During a Navigator-caste survey mission Vaen was attached to, they encountered a secondary Builder ruins site in a region the ruling coalition monitors but doesn't publicize.
- What Vaen found: the site contained Builder infrastructure in a context that made the "sacred gift" narrative impossible — the technology predated Keth civilization by millennia, showed no evidence of transfer or gifting, and had clearly been *found and reverse-engineered*, not received. The sacred shapes were load-bearing structures, not symbols.
- Vaen documented it. Then asked the Keeper caste about it.
- The Keeper caste's response was to refer the matter to the Merchant caste leadership. Vaen's documentation was suppressed. Their Merchant caste standing was revoked. They were given a choice: silence and marginalization within Keth space, or departure.
- Vaen departed. "Here" is away from Keth society. The trade lane opening near Outpost Nova was a convenient reason.
- What Vaen carries: the knowledge that the lie exists, but not its full extent. They know the shapes are external. They don't yet know the station is Builder infrastructure. When they recognize the weapon's coordinates — the target is in a region Vaen has been thinking about since the secondary site — the silence isn't surprise. It's confirmation of something they've been sitting with alone for years.

**Step 5: Verify**

Read `docs/characters/npcs.md` Vaen section and `docs/plans/2026-03-16-story-bible-design.md` "The Keth Trader" section. Confirm this deep-dive is consistent with Vaen's established profile (Hopeful / Detached / Curious, lost Merchant caste standing by asking forbidden questions).

**Step 6: Commit**

```bash
git add docs/world/world.md
git commit -m "docs: write Chapter 4 — Keth deep-dive, caste structure, and Vaen's exile"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 2

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 3, Task 4 | Different chapter sections of world.md; no shared symbols or state. Coordinate file access if working simultaneously. |

### Smoketest Checkpoint 2 — Factions and Keth review

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass.

**Step 3: Review Chapters 2 and 4**

Read Chapters 2 and 4 against `docs/plans/2026-03-16-story-bible-design.md` sections "The Factions" and "The Keth Trader". Confirm:
- Hegemony's monitoring posture is consistent with the buried survey backstory
- The Keth ruling coalition lie is internally consistent (shapes = found AI infrastructure, not divine gift)
- Vaen's exile trigger matches the established character note "lost Merchant caste standing by asking forbidden questions about ancient civ echoes"
- Caste alignment profiles feel distinct and non-redundant

**Step 4: Confirm with user**

Ask: "Do Chapters 2 and 4 feel right? Any faction or Keth details to adjust before writing species?"

---

## Batch 3 — Species Profiles

### Task 5: Write Chapter 3 — Displaced and Existing Species

**Files:**
- Modify: `docs/world/world.md` (fill in Displaced section of Chapter 3)

**Depends on:** Task 2 (Displaced species need the war/Fracture history established)
**Parallelizable with:** none — Task 6 continues this same section; must complete Task 5 first to establish the section format before Task 6 adds new species.

Each species entry covers: **Physical profile**, **Culture and society**, **What they lost or never had**, **How they navigate the Frontier now**.

**Step 1: Write the Displaced category introduction**

```
The Displaced are species whose worlds were caught between human factions or in the Keth conflict zone during the Fracture. They didn't have governments powerful enough to stay neutral or militaries strong enough to fight back. Some lost territory. Some lost everything. They exist throughout the Frontier now in communities of refugees and resettled populations, navigating jurisdictions that weren't designed with them in mind.
```

**Step 2: Write Drueth profile**

- **Physical:** Red-tinted skin, compound eyes, paired antennae that carry emotional expression. Humanoid build. The antennae are not decorative — they read pressure, humidity, and the electrical fields of nearby beings. Other species often find them unsettling to talk to for this reason.
- **Culture:** Drueth society was organized around extended kinship networks — large, multigenerational groups that shared resources, decision-making, and identity. Individual Drueth didn't make major decisions alone. They consulted the network.
- **What they lost:** Their world was caught in the early years of human expansion into the Frontier — not the Fracture specifically, but the resource extraction era that preceded it. Hegemony's operations disrupted the land systems the kinship networks depended on. By the time the Fracture started, Drueth displacement was already a generation old. They lost the network — the people are scattered now, the decision-making structure gone. Individual Drueth navigate a universe they were never designed to navigate alone.
- **How they navigate the Frontier:** Trade, brokerage, information. Skills that don't require a fixed home. Sable is representative: she connects easily because Drueth are trained from birth to read the people around them (the antennae help), and she leaves because staying in one place without a network doesn't feel like living — it feels like waiting for something that's not coming back.
- **Note on Sable's real name:** Drueth names are network-specific — they carry the kinship lineage. Sable doesn't offer it easily because it belongs to a network that no longer exists. Sharing it would be claiming a context she's not sure she can claim anymore.

**Step 3: Write Maevet profile**

- **Physical:** Cephalopod semi-humanoid. Fluid, boneless movement. Chromatophore skin that shifts color and pattern involuntarily with emotional state — they cannot fully suppress it. Pronouns: it/its (standard; some individual Maevet use others, but it/its is the default). Bilateral symmetry is approximate; their body plan is flexible enough that "left" and "right" are suggestions.
- **Culture:** Maevet are Unbound (see below) — *wait, Maevet is listed as Displaced in the NPC notes. Correct: Maevet are Unbound in the story bible's two-category system, but Quen is the specific Maevet on the station.* [Note for writer: cross-check — the story bible classifies Maevet under Unbound. Confirm before writing. If Unbound, move this entry to that section.]

> **Writer's note:** The NPC reference lists Quen (Maevet) under the Unbound category in the story bible's "Minor Species" section. If the Maevet are Unbound (never organized into empires, live in margins), this entry belongs in the Unbound section. Verify against `docs/plans/2026-03-16-story-bible-design.md` "Minor Species" before finalizing placement.

**Step 4: Write Thessari profile**

- **Physical:** Cat-people — grey-edged fur, large warm eyes. Warm-blooded, expressive faces. The grey edging to the fur is age-related; older Thessari are more fully grey. Soriel, mid-40s equivalent, has just begun to show it at the edges.
- **Culture:** Thessari culture was built around communal warmth — not in a vague sense, but literally: their architecture, their social structures, their art were all organized around shared physical and emotional closeness. They had elaborate hospitality traditions, complex systems for integrating strangers into community. They were not naive about the universe; they had a long history. The warmth was chosen, not assumed.
- **What they lost:** Their world was caught in the early years of human-Keth first contact — not a target, just in the way of two frightened species with weapons. Neither side claimed what happened. The culture is gone. The language system that Thessari and Soriel's name share phonological roots with is effectively dead — Soriel is one of the last fluent speakers, and there's no one left to speak it with.
- **How they navigate the Frontier:** There are very few Thessari left. Each one carries the culture alone, with no community to reflect it back. The warmth Soriel carries has no backing — it is sustained entirely by the decision to keep making it. This is what makes warmth-as-resistance specific and costly for Soriel: it is a moral choice against a concrete wound, not pragmatism.

**Step 5: Verify**

Cross-check Drueth and Thessari entries against `docs/characters/npcs.md` (Sable and Soriel sections). Confirm physical descriptions and cultural details match.

**Step 6: Commit**

```bash
git add docs/world/world.md
git commit -m "docs: write Chapter 3 — Displaced species profiles (Drueth, Thessari)"
```

---

### Task 6: Write Chapter 3 — New Species (Unbound + Maevet + Sovereign)

**Files:**
- Modify: `docs/world/world.md` (fill in Unbound and Sovereign sections of Chapter 3)

**Depends on:** Task 5 (establishes section format and resolves Maevet category)
**Parallelizable with:** none — writes to the same chapter section as Task 5; must run after Task 5 completes.

**Step 1: Write the Unbound category introduction**

```
The Unbound are species that were never organized into empires or governments: clans, guilds, wandering collectives. They've always lived in the margins between powers. They trade, carry information, go where the big powers don't bother to look. Several have been passing through Outpost Nova since before Hegemony bought the debt.
```

**Step 2: Write Maevet profile (if Unbound — confirm in Task 5)**

If confirmed Unbound:
- **Physical:** (as drafted in Task 5 Step 3)
- **Culture:** Maevet move in small, loose collectives — not quite families, not quite guilds. Membership is fluid; a Maevet stays with a collective as long as it serves both. The chromatophore skin means they are incapable of emotional concealment — among Maevet, this is not a vulnerability, it is the social contract. You can see exactly who you're dealing with. Among other species, this makes Maevet unsettling to negotiate with (they see everything you hide) and valuable to employ (they can't lie with their bodies even if they try).
- **What they never had:** Fixed territory, formal government, recognized legal standing. They exist in the gaps. They are very good at gaps.
- **Quen specifically:** Has been on Outpost Nova 15+ years — longer than any other current crew member. Chose to stay, which for a Maevet is significant. What Quen saw when it sealed the Derelict door is the reason it stopped asking questions. Its arc is whether the commander's investigation reopens that question.

**Step 3: Write 2 new Unbound species**

Invent two new Unbound species. Each needs: physical profile, culture/society, what they never had, how they navigate the Frontier. Guidelines:
- Neither should overlap physically or culturally with Maevet or any existing species
- Both should feel like they genuinely live in margins — not pitiable, just adapted to a different kind of life
- At least one should have an interesting relationship to information or communication (useful for the Frontier's political landscape)
- They don't need to appear in the MVP — this is world-building for writer reference

**Step 4: Write the Sovereign category introduction**

```
The Sovereign are species organized into their own independent empires, confederacies, or governing structures — too small to rival the Federation or the Keth, but too organized and established to be displaced or unbound. They survived the Fracture by not being worth fighting over, or by being too costly to fight. Post-war, they are courted by the major powers for access to their territory, trade routes, or specific knowledge.
```

**Step 5: Write 2 new Sovereign species**

Invent two new Sovereign species. Each needs: physical profile, civilization structure, what makes them politically significant (why do the major factions want access to them?), their current posture toward the truce. Guidelines:
- At least one should have territory that sits on an emerging trade route or near a resource the major powers want
- At least one should have knowledge or technology that predates human presence in the Frontier (not Builder-level ancient, but old enough to be valuable)
- Both should be genuinely independent — not satellites of any major faction, even if they trade with all of them
- Their sovereignty is maintained by being useful to multiple parties simultaneously; losing that balance is the political risk they live with

**Step 6: Verify**

Read all species entries against the story bible's "Minor Species" section. Confirm the three-category framework (Displaced / Unbound / Sovereign) is coherent and non-overlapping.

**Step 7: Commit**

```bash
git add docs/world/world.md
git commit -m "docs: write Chapter 3 — Unbound and Sovereign species profiles"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 3

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 5 | Must run first — establishes format and resolves Maevet category |
| B (sequential) | Task 6 | Depends on Task 5 — writes same section, continues it |

### Smoketest Checkpoint 3 — Species profiles review

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass.

**Step 3: Review Chapter 3**

Read all species entries. Confirm:
- Drueth, Thessari entries are consistent with Sable and Soriel in `docs/characters/npcs.md`
- Maevet entry is consistent with Quen in `docs/characters/npcs.md`
- The 2 new Unbound species feel distinctly different from Maevet and from each other
- The 2 new Sovereign species each have a clear political reason to exist (what makes them significant to the major factions)
- The three-category system (Displaced / Unbound / Sovereign) is clean — no species belongs in two categories

**Step 4: Confirm with user**

Ask: "Do the species profiles feel right? Any new species to adjust before writing the political ripple?"

---

## Batch 4 — Political Ripple + Cross-References

### Task 7: Write Chapter 5 — Political Ripple

**Files:**
- Modify: `docs/world/world.md` (fill in sections 5.1–5.2)

**Depends on:** Tasks 3, 4, 5, 6 (needs all faction and species context to write faction outcomes accurately)
**Parallelizable with:** none — this chapter synthesizes everything; all prior chapters must be complete.

**Step 1: Write section 5.1 — Act-by-Act Off-Screen Shifts**

**Act 1 — Before the weapon activates (Days 1-3)**

Off-screen, before the player knows what's under the station:
- **Hegemony:** Running a quiet acquisition play. The commander's posting is not coincidental — Hegemony has been waiting for a pretext to move on the station's lower decks. Monitoring equipment already installed on the station watches for activation events. The commander's reports are read carefully at a level above their stated supervisor.
- **Federation:** Has noticed Hegemony's unusual interest in a forgotten waypoint station. A patrol passes near the station asking questions that are slightly too specific for routine checks. They don't yet know what Hegemony is watching for — they're trying to find out without revealing that they're watching Hegemony.
- **Keth ruling coalition:** The trade lane opening near Outpost Nova is too close to old Builder signal patterns for comfort. They are monitoring through channels they don't acknowledge. When Vaen arrives at the station, the ruling coalition notes it — but Vaen has no official standing anymore, and the station is outside Keth jurisdiction. They watch and wait.
- **Unaligned Alliance:** Aware the station sits in legally ambiguous territory adjacent to their space. Watching Hegemony's interest with suspicion. Have not formally engaged because doing so would require acknowledging the station's strategic value — which they don't want to do publicly.

**Act 2 — Weapon activates, broadcast begins (Days 4-6)**

- **Hegemony:** Detects the broadcast first — their monitoring equipment was designed for this. Internal communications escalate immediately. The acquisition play shifts from "patient" to "urgent." The commander's reports become more pointed requests.
- **Keth ruling coalition:** Detects the broadcast second, through ancient-tech detection systems they don't publicly acknowledge. This is the scenario they've been quietly dreading. Internal emergency session of the coalition. Vaen's presence at the station — previously noted but not acted on — is now a serious concern.
- **Federation:** Detects the broadcast third, through conventional means. They don't understand what they're hearing — the signal doesn't match any known format. This is alarming in its own right. Intelligence assets are redirected to the station.
- **Unaligned Alliance:** Detects the broadcast through Federation-adjacent intelligence sharing. Not yet certain what it means, but certain enough that whatever is happening at the station is worth paying attention to. Their previous "watch and wait" posture shifts to active monitoring.

**Act 3 — Weapon charging, Harlan arrives (Days 7-10)**

- **Hegemony:** Harlan's arrival is the acquisition play going overt. Hegemony is done waiting. They believe they can still close this quietly — one person the commander respects, a reasonable ask, a situation that doesn't have to become a crisis.
- **Federation:** Has now identified the station as the source of an anomalous signal of unknown origin. They don't know about the ruins yet. They know Hegemony sent someone in person, which is unusual. Their patience is running out.
- **Keth ruling coalition:** Internal crisis. The weapon's orientation — toward the coordinates of the second civilization's ruins — confirms their worst-case interpretation of what the Builder sites are. They cannot claim this publicly without explaining how they knew to be alarmed. Vaen, on the station, is holding knowledge the coalition cannot safely let circulate.
- **Unaligned Alliance:** Has confirmed the signal is not Federation or Keth in origin. Is now treating the station as a significant intelligence priority. Has not yet made overt contact.

**Step 2: Write section 5.2 — Per-Ending Faction Outcomes**

Cover all five endings. For each: what each major faction does next, and where the Frontier is heading.

**Ending 1 — Deliver to Hegemony**
- Hegemony gains quiet monopoly over the station and its weapon. Harlan's arrival was worth it.
- The Federation and Unaligned Alliance don't know exactly what was handed over — but they know Hegemony got something. The power imbalance from this acquisition will take years to play out.
- The Keth ruling coalition is in an impossible position: the weapon now in Hegemony hands is aimed at coordinates they secretly recognize. They can't object without explaining why. They are caught between their lie and the consequence of it.
- The Frontier doesn't fracture immediately. But Hegemony's new position changes what's possible.

**Ending 2 — Share with the Keth**
- The weapon passes to the Keth — but which Keth? The ruling coalition wants it to cement power. Vaen, if they're trusted, wants it to break the lie open.
- If the ruling coalition receives it: the lie is temporarily stabilized, but a functioning Builder weapon in Keth hands changes the Federation's calculus completely. The truce becomes much more fraught.
- If the discovery becomes known to non-coalition Keth (through Vaen's involvement): internal Keth crisis. The cosmology built on the lie is suddenly contested. This could be the beginning of something — a Keth reformation — or it could be a collapse.
- The Federation considers the truce effectively suspended while they assess the new situation.

**Ending 3 — Keep it secret**
- The weapon is still charging. The secret is held by the commander and crew. No faction gets what they came for.
- Hegemony is frustrated but not defeated — they still hold the station's debt. This is not over.
- The Federation and Unaligned are watching a situation they don't fully understand. The anomalous signal has stopped, which is either reassuring or alarming.
- The station survives. The problem is deferred, not solved. Everything is still on the table.

**Ending 4 — Make it belong to everyone (go public)**
- The most geopolitically destabilizing outcome. Every faction now knows what the station is — and what it contains.
- Hegemony loses its quiet monopoly play and pivots to overt acquisition through legal and political mechanisms. They will not stop.
- The Federation and Unaligned are suddenly competing with each other and with Hegemony to be first to claim oversight of the discovery. The truce with the Keth becomes a secondary concern.
- The Keth ruling coalition's lie is exposed — at least in part. The sacred shapes are publicly identified as Builder infrastructure. Keth internal politics fracture publicly. The truce is in immediate jeopardy.
- The Frontier is heading toward a crisis. The station — and everyone on it — is at the center of it.

**Ending 5 — Destroy it**
- The crew that made a home inside a weapon chooses to dismantle the weapon. The station may not survive what that requires.
- The discovery still happened — the broadcast went out, the signal was detected. What was destroyed cannot be undiscovered.
- Hegemony loses its acquisition target. They are not pleased. The station's debt, previously a lever, becomes a punishment.
- The Federation and Keth know something significant happened but cannot confirm what was destroyed. This creates its own uncertainty.
- The Frontier doesn't fracture. But the question of what the Builders were — and what the second civilization was — is now open knowledge without an artifact. Every faction will spend years trying to find the next site.

**Step 3: Verify**

Read the five endings against `docs/plans/2026-03-16-story-bible-design.md` "Act 3 — The Reckoning" section. Confirm no contradictions with the established ending descriptions. The world doc should deepen the faction ripple, not contradict the story bible's framing.

**Step 4: Commit**

```bash
git add docs/world/world.md
git commit -m "docs: write Chapter 5 — political ripple, act-by-act and per-ending faction outcomes"
```

---

### Task 8: Add cross-reference to the story bible

**Files:**
- Modify: `docs/plans/2026-03-16-story-bible-design.md`

**Depends on:** Task 7 (world doc must be complete before cross-referencing it)
**Parallelizable with:** none — depends on Task 7 completing; modifies a different file but is the final cleanup step.

**Step 1: Add a pointer near the top of the story bible**

Find the section header or status block near the top of `docs/plans/2026-03-16-story-bible-design.md` and add:

```markdown
**World documentation:** For detailed history, faction profiles, species reference, and geo-political ripple, see `docs/world/world.md`.
```

Place it immediately after the existing `**Updated:**` or `**Status:**` line.

**Step 2: Verify**

Open `docs/plans/2026-03-16-story-bible-design.md` and confirm the pointer is visible near the top, correctly formatted.

**Step 3: Commit**

```bash
git add docs/plans/2026-03-16-story-bible-design.md
git commit -m "docs: add world documentation cross-reference to story bible"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 4

| Group | Tasks | Notes |
|-------|-------|-------|
| A (sequential) | Task 7 | Synthesizes all prior chapters — must run after Checkpoint 3 passes |
| B (sequential) | Task 8 | Depends on Task 7 completing; modifies a different file |

### Smoketest Checkpoint 4 — Full document review

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass.

**Step 3: Full document review**

Read `docs/world/world.md` end-to-end. Check:
- Chapter 1 history is internally consistent (AI builders → second civ → war → Frontier → First Contact → Fracture → Truce)
- Chapter 2 faction postures are consistent with Act 1 pre-game setup in the story bible
- Chapter 3 species profiles match NPC reference for Drueth (Sable), Thessari (Soriel), Maevet (Quen)
- Chapter 4 Keth lie is fully coherent — caste structure, the shapes, Vaen's exile trigger all hang together
- Chapter 5 ending outcomes are consistent with the story bible's Act 3 ending descriptions
- Cross-reference in story bible points to `docs/world/world.md`

**Step 4: Confirm with user**

Ask: "Does the full world document feel complete and consistent? Anything to revise before closing issue #11?"

If yes, close the GitHub issue:
```bash
gh issue close 11 --repo MatthieuGagne/outpost-nova --comment "World documentation complete at docs/world/world.md."
```
