# Vaen Character File + Keth Physical Description Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create `docs/characters/vaen.md`, update the Keth physical description in `docs/world/world.md`, and slim the Vaen entry in `docs/characters/npcs.md` to quick-ref + pointer format.

**Architecture:** Three documentation files touched. `vaen.md` is a new full character reference following the `dex.md` format. `world.md` gets a new section 4.0 (Keth physical) added before the existing 4.1. `npcs.md` gets the Vaen entry slimmed to quick-ref, the Keth Species Reference blurb updated, and resolved deferred items removed.

**Tech Stack:** Markdown only. No GDScript, no scenes, no tests.

## Open questions (must resolve before starting)

- None.

---

## Batch 1 — Create vaen.md + update world.md + slim npcs.md

---

### Task 1: Create docs/characters/vaen.md

**Files:**
- Create: `docs/characters/vaen.md`

**Depends on:** none
**Parallelizable with:** Task 2. Different output files, no shared state.

**Step 1: Write the file**

Create `docs/characters/vaen.md` with the following content:

```markdown
# Vaen — Character Reference

**Last updated:** 2026-04-08
**Cross-references:** `docs/characters/npcs.md` (roster), `docs/world/world.md` (Keth species + society deep-dive), `docs/story/years2-5.md` (arc context)

---

## Basic Facts

**Full name:** Vaensoleth (Merchant caste registry name, shed)
**Age:** Late 30s (Keth equivalent)
**Species:** Keth
**Pronouns:** She/her
**Emotional profile:** Hopeful / Detached / Curious
**Role:** Trader (cover); Builder-signal investigator (actual)
**On station:** Act 2 arrival

---

## Physical Description

Blue-violet iridescent. The body feathering is deep — reads as near-black in low light. Under direct light, at the right angle, the iridescence resolves: blue shifting into violet, catching differently depending on where the light hits. The quill-spines carry the full vivid palette. She doesn't hold them still. When something interests her they lift. When she finds something that matters they fan.

Slightly unkempt by caste standards. Not dirty — unperformed. The quill-spines aren't groomed into controlled stillness. She stopped doing that. The suppression training still exists but hasn't been practiced in years — she can pull the quill-spines flat when stakes are genuinely high, but it costs more than it used to and she doesn't bother unless it does.

*For the Keth physical baseline — body plan, quill-spines, beak, color system — see `docs/world/world.md` Chapter 4.*

---

## Background

Merchant caste, formally trained. Competent at the role — good at other-species interaction, social intelligence, enough discipline to learn the suppression. But the explorer temperament was always a poor fit. She bent the Merchant role toward exploration at every opportunity: Navigator caste contacts cultivated deliberately, trade missions to frontier regions volunteered for, diplomatic liaison positions used as doors into survey operations. She went through every door that opened.

She was attached to a Navigator survey mission mapping a region the ruling coalition monitors but doesn't publicize. The secondary Builder ruins site wasn't on any chart she'd been given. She found it. Documented it thoroughly, completely, with the deep satisfaction of finding something real. The horror arrived while she was writing — in the gap between what she was describing and what she'd been told her whole life.

She asked the Keeper caste because that's what you do when you find something that touches sacred knowledge. She thought they would want to know.

The Keeper caste referred the matter upward. The speed of the response told her everything. Her documentation was seized. Her caste standing was revoked. She was given a choice: silence and managed marginalization within Keth space, or departure.

She chose departure. She kept the artifact.

---

## Exile

The early period was practical difficulty and quiet fury in roughly equal measure. She rebuilt a trade operation from nothing in human-adjacent commercial law, with skills that translated but a reputation that didn't carry. Real trade, legitimate work — she needed the income and she had the skills. Over time the fury settled into focus.

The artifact she carried from the ruins stayed unreadable. Builder notation — the geometric structure matched what she'd seen at the site — but it described something in relative terms she couldn't resolve without context she didn't have. She kept it anyway. She'd found it. It meant something.

She built a way to track Builder emission patterns. Sensor data pieced together from trade stops, Navigator contacts, equipment modified slowly and quietly over years. The monitoring system is the thing she's most proud of that no one knows about.

The ship fund she accumulated without a specific destination in mind. The point was never the destination — it was independence. The freedom to follow a thread wherever it led without asking permission. She was close enough to feel it when the spike hit.

Builder emissions, concentrated, from a station she'd registered as low-signal background. She redirected immediately. The trade business on the new lane is real. It's secondary. She arrived at Outpost Nova presenting herself as a trader. She has been watching since she arrived.

---

## The Artifact

A fragment of something larger. Clearly broken from a structure at the ruins site — edges irregular, the notation impressed into material that was never meant to leave. It looks like a piece of something much bigger. The notation is incomplete because the object is incomplete.

Builder notation, describing a target in relative geometric terms. She's been sitting with it for years. Unreadable without context she hasn't had.

The weapon's architecture is the decoder ring. When she encounters the weapon's structure, the artifact resolves — the notation suddenly makes sense. The recognition is not of coordinates but of the artifact finally being readable. Working out what location it resolves to happens privately. What she does with that knowledge, and when she shares it with the commander, is a key Act 2-3 beat.

---

## Psychological Profile

**Hopeful — private engine + stubbornness.** Doesn't announce itself. You see it in the fact that she's still here, still following the question. Her orientation is always forward — what the next piece might mean, where the signal might lead. When someone implies the question isn't worth pursuing she doesn't argue. She just doesn't agree, and moves on. The disagreement is quiet and total.

The hope is load-bearing and she knows it, which means she doesn't put weight on it in front of other people. Years alone with an unreadable artifact has worn at it. The station changed the calculation — the thing she was saving the freedom to find is sitting in the lower decks. She hasn't fully processed what that means for the hope.

**Detached — deflection.** Personal questions get rerouted to the work. The reroutes are not hostile and not random — she gives you something real, just the thing she actually cares about rather than the thing you asked about. The redirect is honest. It tells you what she cares about even as it avoids what you asked.

She connects over ideas. When the deflection fails — when something lands and she doesn't redirect, just goes still — that's different, and rare, and means something.

**Curious — joyful.** The axis that catches people off guard. When something genuinely interests her the quill-spines lift before she decides whether to show it. She asks questions directly — not deflecting, actually asking — because the curiosity overrides the deflection. The joy is specific: mechanism, pattern, the moment when something resolves.

She would have documented the ruins even knowing what it cost. Because you find something extraordinary and you document it. The joy and the stubbornness are connected.

---

## Voice

**Default mode.** Terse. One true thing, then she waits to see what you do with it. Short sentences, observational, no filler. She's reading the room and doesn't hide that she's reading it. Skips small talk — not rudely, just doesn't start there and doesn't wait for you to finish it either.

**Excited mode.** The contrast is the point. When something genuinely interests her the whole register breaks open — more words, faster, she interrupts herself to add another connection before she's finished the first one. The quill-spines go up. She moves toward the thing physically without noticing she's doing it. There's so much of it suddenly. The joy was always large. The controlled presentation is what takes effort.

**The gap between them.** You can feel the effort when she's holding it flat. Something interests her and you see the almost-lift before the control reasserts. When she doesn't reassert — those are the tells. When she goes quiet instead of deflecting — those mean something else entirely.

**Humor.** Dry, observational, delivered flat. Something that takes a second to land and then she doesn't wait to see if it did.

---

## Arc

Arrives watching. First real conversation: professional, deflecting, taking inventory. The moment the commander describes the lower decks — the quill-spines lift before she decides.

Working in the Derelict: most herself. The explorer fully present, the deflection gone because nothing personal is being asked. They're just looking at something extraordinary together.

The artifact resolving is private. She doesn't tell the commander immediately. She needs to understand it before deciding what to do with knowing.

Trust develops in the negative space. Deflections get shorter. She gives the commander things that aren't about the work — small, unannounced. Eventually she talks about the ruins discovery directly, without redirecting.

What she wants, which she doesn't fully acknowledge until it's happening: someone to hold the question with. She's been doing it alone for years.

---

## Relationships

**Commander:** Neither of them planned the alliance. She came for the station's signal; the commander came for Hegemony. What they end up holding — knowledge neither of them is supposed to have, cut off from institutions that might claim it — is something that happened to them. The trust develops in the negative space of shorter deflections and things given without announcement. Fragile and real.

**Quen:** Mutual wariness, layered. Species-wariness on Quen's part first. Then Quen sensing something that doesn't match the trade cover. Then Vaen recognizing that Quen has been inside the question for a very long time and chose silence. One overture (Vaen's), one clean shutdown (Quen's). Both keep watching. Both understood more from that exchange than was said.

**Sable:** Bridge on Curious — that's the connection. Opposites on the other two axes: Vaen is Hopeful where Sable is Cynical; Vaen is Detached where Sable is Warm. Sable gives warmth easily and has given up on futures. Vaen believes in the future but stopped giving warmth easily. They meet on what they find interesting and have to work toward everything else.

**Dex:** Federation distrust first — a Keth trader on the new lane reads as institution before individual. The distrust fades when they actually engage with the weapon's architecture together. Reluctant intellectual partnership. Both are curious about mechanism. That's enough.

**Velreth:** The exile clarified Keth culpability in Thessari displacement. Vaen arrives having done the work, carrying more than the Merchant caste version of events. She knows what to be ashamed of. What she doesn't know is whether Velreth wants that acknowledged or wants something else. The decision Velreth thought they'd resolved — the Keth are the other half of what destroyed their world, arriving in person.

**Maris:** Cautious welcome becoming genuine. Both understand what institutional failure costs. Neither has to explain the shape of it to the other.

**Nadia:** Uncanny mirror — both arrived with cover stories over real purposes, both are watching things they're not supposed to know about. The specific collision scene is deferred to Year 2.

---

## What She Knows About the Derelict

She detected the Builder emissions spike when the commander first went deep into the lower decks. She knows something activated. She doesn't know exactly what — she came to find out. She presents as a trader on the new lane. She does not immediately reveal why she came.

She carries an artifact she can't yet read. The weapon is the decoder ring. She doesn't know this when she arrives.

---

## Warzone Discovery Context (locked 2026-04-04)

Both the Federation and the Keth ruling coalition independently found Others ruins in the Fracture warzone. Vaen does not know about the Keth coalition's discovery — she was exiled before the ruling coalition's inner leadership acted on it. Vaen's artifact predates the warzone discovery; she found it at a secondary Builder site, not an Others site. The artifact's connection to the Others (via the weapon's targeting logic) is something Vaen works out in Act 2-3, not something she arrived with.

---

## The Ruling Coalition

Vaen suspects the lie calcified somewhere in the middle — that it may have started with genuine uncertainty, early Keth reaching for meaning around something they couldn't explain, but that at some point someone understood the truth and chose power over honesty. She can't prove it. The uncertainty makes her angrier, not less.

She also suspects she's being monitored — operating near a Builder-signal site as an exiled Keth is not invisible. She's cautious generally, but she came because the spike was worth it. She may have underestimated the specific scrutiny here.

---

## Post-Act 3 Hook

Vaen's accumulated ship fund and the now-readable artifact pointing to the second civilization's ruins are a concrete next chapter depending on the ending. The weapon pointed somewhere for millennia. Someone might finally go.

---

## For Writers

Vaen is terse by default and theatrical by nature. The contrast is the design — the controlled presentation is what takes effort, not the other way around. When the explorer breaks through, it reads like a different person almost. Let it.

The deflection is honest. She's not hiding — she's redirecting to what she actually cares about. Where she redirects TO is always a tell. You can learn Vaen by watching where the reroutes go.

The quill-spines give her away. She's been out of practice on suppression long enough that you can sometimes see the effort when she tries to hold them flat. The almost-lift before control reasserts. The fan when she stops bothering.

Joy first, horror second. This is how she encounters most things. She finds something extraordinary and responds to the extraordinary before she processes the implications. It's the same trait that got her exiled.

She shed the name Vaensoleth. The full name belongs to a version of her life that was supposed to work. She doesn't mourn it loudly. She just goes by Vaen.
```

**Step 2: Verify**

Open `docs/characters/vaen.md` and confirm:
- All sections present (Basic Facts through For Writers)
- Pronouns she/her present in Basic Facts
- Physical description references world.md Chapter 4
- Artifact section describes fragment, not self-contained object
- For Writers section present and matches voice design

**Step 3: Commit**

```bash
git add docs/characters/vaen.md
git commit -m "docs: add Vaen character reference file"
```

---

### Task 2: Update Keth physical description in world.md

**Files:**
- Modify: `docs/world/world.md`

**Depends on:** none
**Parallelizable with:** Task 1. Different output files, no shared state.

**Step 1: Add Keth physical description section**

In `docs/world/world.md`, locate Chapter 4 heading `## Chapter 4: Keth Deep-Dive` and the first subsection `### 4.1 The Lie`. Insert a new section **before** `### 4.1 The Lie`:

```markdown
### 4.0 Physical Description

Bipedal, digitigrade — they stand and move on the forward part of the foot, like a theropod. Roughly human height. No wings; forelimbs evolved fully into arms over millennia of tool use. Three long fingers plus a dewclaw, dexterous enough for fine manipulation. A short feathered tail, structural not decorative — a counterweight that shifts when they move.

**Face.** Forward-facing eyes with a heavy expressive brow ridge. A strong short beak — built for cracking and tearing before it was built for speech, adapted over millennia for language but visibly not a human mouth.

**Quill-spines.** A crest of modified display feathers runs from crown to nape, with secondary clusters at the shoulders. These respond to emotional state: curiosity lifts them slightly, excitement fans them, fear or aggression flares them fully. Keth caste training — Merchant and Keeper especially — teaches deliberate stillness of the quill-spines. It is a learned skill. It is effortful. A trained Keth in formal mode holds them flat regardless of what they're feeling.

**Color.** Individual and fixed — no two Keth have the same palette, and the range across the species is extraordinary. The quill-spines carry the most saturated expression of the individual's palette; the body feathering runs the same color family at slightly lower intensity. A Keth whose quill-spines are held flat still has their color. They're just not showing the brightest part of themselves.

**Temperament.** Naturally gregarious, quick, physically expressive, comfortable in close quarters. The quill-spine display evolved for a highly social species — a continuous social broadcast. A Keth in natural expression is large: kinetic, immediate, emotionally visible. The Merchant caste trains this down into controlled stillness. What breaks through when the training slips is genuinely surprising in scale.

---

```

**Step 2: Verify**

Open `docs/world/world.md` and confirm:
- Section 4.0 appears immediately before section 4.1
- Five sub-sections present: body plan paragraph, Face, Quill-spines, Color, Temperament
- No mention of corvid or heron anywhere in Chapter 4
- Existing sections 4.1 through 4.4 are untouched

**Step 3: Commit**

```bash
git add docs/world/world.md
git commit -m "docs: add Keth physical description to world.md Chapter 4"
```

---

### Task 3: Slim Vaen entry and update Keth blurb in npcs.md

**Files:**
- Modify: `docs/characters/npcs.md`

**Depends on:** Task 1 (pointer to vaen.md), Task 2 (consistent Keth physical language)
**Parallelizable with:** none. Depends on both Task 1 and Task 2 completing first.

**Step 1: Replace the Vaen entry**

In `docs/characters/npcs.md`, locate the full Vaen block under `## Act 2 Arrival` (from `### Vaen — The Keth Trader` through the end of the `**Post-Act 3 hook:**` paragraph). Replace the entire block with:

```markdown
### Vaen — The Keth Trader

**Age:** Late 30s (Keth equivalent) | **Species:** Keth | **Pronouns:** She/her | **Profile:** Hopeful / Detached / Curious | **On station:** Act 2 arrival

Merchant caste exile, explorer by temperament. Has been monitoring Builder signal patterns for years; redirected to this station when the commander triggered the weapon's charging sequence. Carries a physical artifact from a secondary Builder ruins site — unreadable until the weapon's structure resolves it. Presents as a trader. Does not immediately say why she came.

→ Full reference: `docs/characters/vaen.md`

```

**Step 2: Replace the Keth Species Reference blurb**

In `docs/characters/npcs.md`, locate the `### Keth` entry in the `## Species Reference` section. Replace from `### Keth` through the end of the non-bold paragraph (stopping before `**Ancestry retcon`) with:

```markdown
### Keth
Feathered theropod. Bipedal, digitigrade. Three-fingered hands, no wings. Individual color palettes across the full spectrum — quill-spines along the crown and shoulders carry the most vivid expression. A spacefaring empire older than humanity's presence in the Frontier, organized by function-based caste assessed in youth. Naturally gregarious and theatrically expressive; the Merchant caste's formal trade face is trained suppression of this — a learned skill, not a natural state. Post-war pressure has fractured Keth society between caste traditionalists and a reform faction. The Keth half-remember the first ancient civilization through shapes in their oldest sacred architecture — echoes they never identified as external. *Full physical description: `docs/world/world.md` Chapter 4.*

```

Leave the `**Ancestry retcon (locked 2026-04-04):**` paragraph immediately after, unchanged.

**Step 3: Update the Deferred section**

In `docs/characters/npcs.md`, locate the `## Deferred` section at the bottom. Remove these two lines:

```
- **Vaen's full backstory** — pending Keth society development session
- **Vaen's emotional profile details** — pending same
```

**Step 4: Verify**

Open `docs/characters/npcs.md` and confirm:
- Vaen entry is 3 lines (stats, quick-ref, pointer) — no appearance block, no dramatic function prose
- Pointer reads `→ Full reference: docs/characters/vaen.md`
- Keth Species Reference blurb says "Feathered theropod" — no mention of corvid
- Ancestry retcon paragraph is untouched
- Deferred section no longer contains the two Vaen lines

**Step 5: Commit**

```bash
git add docs/characters/npcs.md
git commit -m "docs: slim Vaen npcs.md entry to quick-ref + pointer; update Keth species blurb"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 1, Task 2 | Different output files — vaen.md and world.md — no shared state |
| B (sequential) | Task 3 | Depends on Group A — needs vaen.md path confirmed and world.md Keth language settled |

---

### Smoketest Checkpoint 1 — all three files correct and consistent

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass, zero failures. (Docs-only change — no GDScript touched, tests should be unaffected.)

**Step 3: Human review**

Open the three files and confirm cross-consistency:

- `docs/characters/vaen.md` — physical description references world.md Chapter 4; artifact described as fragment; all sections present
- `docs/world/world.md` — section 4.0 present before 4.1; no corvid language anywhere in Chapter 4; five sub-headings in 4.0
- `docs/characters/npcs.md` — Vaen entry is slim (stats + 2 sentences + pointer); Keth blurb says "Feathered theropod"; Deferred section has no Vaen backstory lines

Confirm the Keth physical language is consistent between world.md 4.0 and the npcs.md blurb (blurb is a condensed version, not contradictory).

**Step 4: Confirm with user**

Tell the user: "Three files updated. Vaen.md is the full reference. World.md has the Keth physical baseline. Npcs.md is slimmed. Does everything read correctly?"

Wait for confirmation before proceeding.
