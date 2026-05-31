# Quen — Luchador Makeover Design

**Date:** 2026-05-31
**Status:** Approved

---

## Core Concept

Quen is unchanged at the root — Maevet, 15+ years, the sealed door, the wound of the long memory. What changes is its second vocabulary. The Maevet speak in grand lyrical registers because they carry the grandeur of civilizations. Quen has grafted onto that a third tradition it discovered in Earth archives: lucha libre. Not the athletics — the *code*. The mask as sacred identity. The unmasking as the ultimate dishonor. The ring as a space governed by its own laws of dignity and respect.

For a species whose entire purpose is to witness and carry culture, encountering lucha libre was not a hobby — it was recognition. This is a culture that treats honor as structural, not personal. That resonated.

The luchador vocabulary doesn't replace the grand lyrical register — it extends it. Quen already speaks like an epic poem. Now it also cites El Santo alongside fallen empires. The wit lives in the same place: the gap between the grandeur of the register and the mundanity of the task. The gap is just wider now, and funnier, and occasionally oddly moving.

---

## Physical — The Mask

Quen wears the mask on duty. It is part of the uniform, as deliberate a choice as the security vest. Red security vest, name badge QUEN, custom luchador mask — this is what station security looks like on Outpost Nova. Visitors never stop noticing. Crew stopped years ago.

The mask is custom-fabricated to fit its central facial structure: deep crimson and gold, bilateral symmetry adapted for anatomy that isn't bilaterally symmetrical, which gives it a slightly uncanny quality up close. The craftsmanship is careful. It has never explained the provenance. No one asks anymore.

The original character note holds: the vest is a choice — "of everything it could present itself as, it chose the uniform." The mask is the same kind of choice. The vest says *I am the station's.* The mask says something alongside that, equally intentional, which Quen has also never explained. The two together constitute a complete statement.

The chromatophores still show at the edges and across the rest of its body — emotion is still readable. The mask doesn't obscure Quen. That's not what masks are for, in lucha libre. The mask *is* the identity.

**Visual:** Color tint stays teal (`Color(0.7, 0.9, 0.85)`). Mask sprite added to character — placeholder colored rectangle (crimson) for MVP, real art later.

---

## Voice — The Luchador Register

Quen's voice has two existing layers: the grand Maevet lyrical register (theatrical, formal, elaborately circumlocutious) and the flat declarative that surfaces under authority-mode or threshold situations. The luchador obsession adds a third vocabulary that operates *within* the lyrical register — not replacing it, running through it.

In practice:

- **Honor code language** bleeds into security work. Access denial isn't bureaucratic — it is about the dignity of the corridor, the integrity of the station's ring. Quen uses "honor" and "respect" with total seriousness.
- **Luchador references** appear the way a deeply read person cites their library. Not forced — Quen genuinely reaches for El Santo or Blue Demon the way it reaches for fallen empires. Both are in the same archive.
- **Spanish phrases** appear naturally, not performatively. *"La máscara es el alma"* — the mask is the soul — said once, plainly, when someone asks about the mask.
- **The threshold is unchanged.** When the sealed door comes up, the lucha libre theatricality drops with everything else. The silence is the same silence it always was.

### Sample Lines

**Corridor denial (new voice):**
> "Corridor four-beta requires authorization of standing, documentation of purpose, and — as Blue Demon himself observed about the ring — the willingness to face what waits on the other side before you cross. You have the first. You are working on the second." [beat] "I will note it."

**Asked about the mask:**
> "La máscara es el alma." [nothing else. moves on.]

**Warmth, to someone they trust:**
> "El Santo held the mask for thirty years. He revealed his face once, the day before he died. I think about that." [short. not performed.]

**Threshold (unchanged — flat):**
> "I sealed that door fifteen years ago. Whatever is coming — I knew it would come. I chose to be here for it." [short. still.]

---

## Mechanical Impact

The emotional axes (Detached / Warm / Bitter) and dialogue registration tags (`#register:curious`, `#register:warm`, `#register:detached`) are unchanged. This is a personality and voice change, not a mechanical redesign.

### Files That Change

| File | Change |
|------|--------|
| `docs/characters/quen.md` | Physical description (mask on duty), Voice section extended, Background gets luchador discovery paragraph |
| `data/dialogue/quen.yarn` | All dialogue branches rewritten in new voice: Maevet lyrical + luchador vocabulary. No new flags or branches. |
| `scenes/characters/` | Mask sprite addition (placeholder for MVP) |

### Files That Do Not Change

| File | Reason |
|------|--------|
| `scripts/characters/quen.gd` | No logic changes |
| `scripts/characters/npc_base.gd` | No logic changes |
| All other character files | Unrelated |

### What Stays Completely Unchanged

- Threshold mechanic (flat silence on sealed door / lower decks)
- All flags and branching logic in `quen.yarn`
- Relationships with Maris, Dex, Sable, Velreth, Superintendent
- Arc across Acts 1–3
- Contract with station, not Hegemony
- Emotional profile axes (Detached / Warm / Bitter)
- Color tint

---

## Background Addition (for quen.md)

One paragraph to add to Quen's background section:

> At some point in its years on the station — it does not specify when — Quen discovered Earth's archive of lucha libre. The Maevet are a witnessing culture; they do not distinguish between the grandeur of civilizations and the grandeur of a man in a mask defending his honor in a ring. What Quen found in that archive was a culture that treated honor as structural, not personal. The mask as identity, not disguise. The code as the real thing beneath the performance. For something that had watched a thousand cultures treat honor as negotiable — this was recognition. It has been a devoted student ever since.
