# Quen Luchador Makeover Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Layer a luchador culture obsession onto Quen's existing character — updating the doc, rewriting dialogue in the new voice, and adding a mask sprite placeholder.

**Architecture:** Three independent file changes: character doc update, dialogue rewrite (no logic changes), GDScript tweak for sprite. No new systems, flags, or branches. The Maevet grand lyrical register and luchador vocabulary run together — both formal, ceremonial, taking mundane things with epic gravity.

**Tech Stack:** GDScript (Godot 4.6), YarnSpinner `.yarn` dialogue, Markdown docs.

---

## File Map

| File | Change |
|------|--------|
| `docs/characters/quen.md` | Add luchador background paragraph; update physical (mask on duty); extend voice section |
| `data/dialogue/quen.yarn` | Full rewrite in new voice — same flags, same register tags, same branching logic |
| `scripts/characters/quen.gd` | Fix wrong color tint (lavender → teal); add crimson `ColorRect` mask placeholder |

---

### Task 1: Update quen.md character doc

**Files:**
- Modify: `docs/characters/quen.md`

- [ ] **Step 1: Add the luchador background paragraph**

Open `docs/characters/quen.md`. At the end of the `## Background` section (after "Quen stopped. Outpost Nova is its fixed point."), add:

```markdown
At some point in its years on the station — it does not specify when — Quen discovered Earth's archive of lucha libre. The Maevet are a witnessing culture; they do not distinguish between the grandeur of civilizations and the grandeur of a man in a mask defending his honor in a ring. What Quen found in that archive was a culture that treated honor as structural, not personal. The mask as identity, not disguise. The code as the real thing beneath the performance. For something that had watched a thousand cultures treat honor as negotiable — this was recognition. It has been a devoted student ever since.
```

- [ ] **Step 2: Update the physical description**

In `## Physical Description`, replace the paragraph about the vest:

Old:
```markdown
Wears a standard-issue red security vest. Name badge: QUEN. The vest is not a concession — it is a choice. Of everything it could present itself as, it chose the uniform. The vest says: *I am the station's.* It means that.
```

New:
```markdown
Wears a standard-issue red security vest and a custom luchador mask. Name badge: QUEN. Neither is a concession — both are choices. The vest says: *I am the station's.* The mask says something alongside that, equally intentional, which Quen has never explained. The two together constitute a complete statement. Visitors never stop noticing. Crew stopped years ago.

The mask is custom-fabricated to fit its central facial structure: deep crimson and gold, bilateral symmetry adapted for anatomy that isn't bilaterally symmetrical, which gives it a slightly uncanny quality up close. The craftsmanship is careful. It has never explained the provenance. No one asks anymore.
```

- [ ] **Step 3: Extend the Voice section**

In `## Voice`, after the opening paragraph ("Quen is theatrical about the unimportant..."), add a new paragraph before the `**The threshold:**` line:

```markdown
The luchador vocabulary runs through the lyrical register, not alongside it. Quen cites El Santo and Blue Demon the way it cites fallen empires — both are in the same archive, both treated with the same weight. Honor code language bleeds into security work: access denial is about the dignity of the corridor, the integrity of the station's ring. Spanish phrases appear naturally, not performatively. *"La máscara es el alma"* — the mask is the soul — said once, plainly, when someone asks about the mask. The wit lives in the same gap it always did: between the grandeur of the register and the mundanity of the task. The gap is just wider now, and funnier, and occasionally oddly moving.
```

- [ ] **Step 4: Update sample lines**

In `## Voice`, replace the existing sample lines block with:

```markdown
**Sample lines:**
- [Theatrical, mundane] "Access to corridor seven-alpha requires authorization from an officer of standing, documentation of purpose, and — as Blue Demon himself observed about the ring — the willingness to face what waits on the other side before you cross. You have the first. You are working on the second." [beat] "I will note it."
- [Wit] "Hegemony has sent another form. I have filed it in the appropriate location." [beat] "Which is to say I have acknowledged its existence and declined to be changed by it. El Santo would have understood."
- [Asked about the mask] "La máscara es el alma." [nothing else. moves on.]
- [Warmth, to someone trusted] "El Santo held the mask for thirty years. He revealed his face once, the day before he died. I think about that." [short. not performed.]
- [Threshold crossed — flat] "I sealed that door fifteen years ago. Whatever is coming — I knew it would come. I chose to be here for it." [short. still.]
- [Asked directly about the lower decks:] "No." [nothing else]
```

- [ ] **Step 5: Commit**

```bash
git add docs/characters/quen.md
git commit -m "docs: add luchador makeover to Quen character reference"
```

---

### Task 2: Rewrite quen.yarn in the new voice

**Files:**
- Modify: `data/dialogue/quen.yarn`

No logic changes — same node titles, same flags (`met_quen`), same register tags (`#register:curious`, `#register:warm`, `#register:detached`), same `<<log_action>>` and `<<flag>>` commands. Only the prose changes.

- [ ] **Step 1: Replace the full file contents**

Replace `data/dialogue/quen.yarn` with:

```yarn
title: Quen
---
<<if get_flag("met_quen")>>
    <<jump Quen_Casual>>
<<else>>
    <<jump Quen_FirstMeeting>>
<<endif>>
===

title: Quen_FirstMeeting
---
Quen: So. The station has been assigned a superintendent.
Quen: I have stood at this post through three such appointments. Each arrived with a mandate, a certainty, and a thorough unfamiliarity with what this place actually is. El Santo himself could not have prepared them.
Quen: What Hegemony has given you, Superintendent, is a report. What I carry is fifteen years of what the report did not include. The ring, as they say, does not lie.
-> Tell me more. #register:curious
    <<register curious>>
    Quen: In time. There is an order to these things — a proper sequence, as in any good match. You are not ready for more. I say that with neither condescension nor comfort. Simply fact.
-> We'll figure it out together. #register:warm
    <<register warm>>
    Quen: A generous sentiment. Blue Demon would have approved. [beat] I will remember you said it.
-> Fine. #register:detached
    <<register detached>>
    Quen: [beat] Yes. That is often how it begins. Even the greatest luchadores started somewhere.
-> Fifteen years. They've been carrying this alone. #inner_voice #register:warm
    <<register warm>>
<<log_action "Spoke with Quen">>
<<flag met_quen>>
===

title: Quen_Casual
---
Quen: The corridors remain as I left them. The ring, intact.
-> What do you think of Dex? #pair:dex_quen
    Quen: The engineer. Competent. Cautious in the way of someone who has seen something go wrong once and has not forgotten it. Whether that caution is wisdom or fear — a luchador would say the two are not always different things.
-> That mask — what does it mean to you? #register:curious
    <<register curious>>
    Quen: La máscara es el alma.
===
```

- [ ] **Step 2: Verify structure is intact**

Open the file and confirm:
- `met_quen` flag check at top is unchanged
- All four `#register:` tags are present in `Quen_FirstMeeting`
- `<<log_action "Spoke with Quen">>` is present
- `<<flag met_quen>>` is present
- `#pair:dex_quen` tag is present in casual branch

- [ ] **Step 3: Run the game and talk to Quen**

```
godot
```

Open the game, navigate to the security post, interact with Quen. Verify:
- First meeting dialogue fires with new lines
- All four response options are present
- After responding, `met_quen` flag is set (second interaction goes to Quen_Casual)
- Casual branch shows new Dex opinion line and mask question option

- [ ] **Step 4: Commit**

```bash
git add data/dialogue/quen.yarn
git commit -m "dialogue: rewrite Quen in luchador voice"
```

---

### Task 3: Fix color tint and add mask placeholder sprite

**Files:**
- Modify: `scripts/characters/quen.gd`

Note: The current file uses `Color(0.85, 0.75, 1.0)` (lavender — Velreth's color). This is a pre-existing bug. Fix it to teal while we're here.

- [ ] **Step 1: Rewrite quen.gd**

Replace the full contents of `scripts/characters/quen.gd` with:

```gdscript
extends "res://scripts/characters/npc_base.gd"

func _ready() -> void:
	super()
	npc_id = "quen"
	display_name = "Quen"
	$AnimatedSprite2D.modulate = Color(0.7, 0.9, 0.85)  # teal
	_add_mask_placeholder()

func get_dialogue_node() -> String:
	return "Quen"

func _add_mask_placeholder() -> void:
	var mask := ColorRect.new()
	mask.name = "MaskPlaceholder"
	mask.color = Color(0.7, 0.1, 0.1)  # crimson
	mask.size = Vector2(12, 8)
	mask.position = Vector2(-6, -14)
	add_child(mask)
```

- [ ] **Step 2: Run the game and verify Quen's appearance**

```
godot
```

Navigate to the security post. Confirm:
- Quen's body modulate is teal (blue-green tint), not lavender
- A small crimson rectangle appears near the top of the character sprite (the mask placeholder)
- Quen still wanders and responds to interaction normally

If the mask position looks wrong (too high, too low), adjust `mask.position` — the Y offset depends on the sprite's pixel dimensions. `Vector2(-6, -14)` places it roughly at head-height for a ~32px tall sprite. Tweak as needed.

- [ ] **Step 3: Commit**

```bash
git add scripts/characters/quen.gd
git commit -m "feat: add Quen luchador mask placeholder, fix tint color"
```
