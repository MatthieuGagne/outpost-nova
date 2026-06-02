# Card System — Design Spec

**Date:** 2026-06-01
**Status:** Approved (conceptual)
**Scope:** Social hand system for NPC interactions — no combos in this pass.

---

## Overview

The card system gives the player a visible social hand that accumulates through play. Cards are social modifiers earned (and lost) through dialogue choices, relationship milestones, story beats, and material actions. Positive cards are optional leverage the player can spend in conversation. Negative cards are unavoidable — they surface as forced dialogue content and must be dealt with.

This system replaces nothing in the existing architecture. It layers on top of `GameState` and the YarnSpinner dialogue runner.

---

## Data Model

Each card is defined by:

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique key, e.g. `"maris_confided"`, `"lied_to_dex"` |
| `type` | `"advantage"` \| `"liability"` | Optional leverage vs. forced baggage |
| `label` | String | Player-facing name: "Maris's Confidence", "The Lie" |
| `description` | String | What using it does in a conversation |
| `npc_scope` | Array[String] | Which NPCs this card is relevant to — empty = universal |
| `consumed` | bool | Whether it has been played |

Card **definitions** (label, description, scope) live as a static dictionary in `CardSystem`. `GameState` holds only which card IDs the player currently holds (for save-state purposes when saves are added).

---

## CardSystem Autoload

A new autoload singleton: `scripts/autoload/card_system.gd`

### Public API

```gdscript
func give_card(id: String) -> void       # Add card; no-op if already held
func remove_card(id: String) -> void     # Discard without playing (story-driven loss)
func has_card(id: String) -> bool        # Query — used by Yarn conditions
func play_card(id: String) -> void       # Consume and emit card_played signal
func get_hand(npc_id: String) -> Array  # Unconsumed cards relevant to this NPC
```

### Signal

```gdscript
signal card_played(card_id: String)
```

### Yarn Commands (registered in npc_base.gd alongside existing commands)

```
<<give_card "id">>
<<play_card "id">>
```

---

## Card Sources

### Dialogue choices
The most common source. A Yarn command fires after a player choice:
```yarn
<<give_card "lied_to_dex">>
```
The card definition is authored once in `CardSystem`; Yarn writers just call the command.

### NPC relationship milestones
`CardSystem` listens to `GameState.pair_state_changed`. When a pair reaches Collegial or Bonded, a matching card is automatically minted — no manual Yarn wiring needed.

Example: `maris_velreth` reaching Bonded → player receives `"witnessed_maris_velreth_bond"`.

### Arc episode beats
Major story moments call `CardSystem.give_card()` from GDScript arc event handlers. Authored case-by-case.

### Material actions
Crafting for an NPC, room upgrades, resource gifts — the relevant GDScript handlers (workbench, upgrade completion, etc.) call `give_card()`.

---

## Card Loss

Two mechanisms:

- **`play_card(id)`** — consumed when the player uses an advantage in dialogue, or when a liability's forced branch completes.
- **`remove_card(id)`** — story-driven removal. Used when a bridge is burned by a story event regardless of whether the player acted on the card.

---

## Dialogue Integration

### Advantage cards — optional, gated options

```yarn
-> [if CardSystem.has_card("maris_confided")] I know what happened to your partner.
    <<play_card "maris_confided">>
    // candid branch...
-> Say nothing.
```

The option is visible (and highlighted) only if the card is held. Playing it consumes it.

### Liability cards — forced at conversation start

```yarn
title: Dex
---
<<if CardSystem.has_card("lied_to_dex")>>
    <<play_card "lied_to_dex">>
    // confrontation branch — Dex addresses the lie
<<else>>
    // normal greeting
<<endif>>
```

The liability resolves once. After the confrontation, the card is consumed and won't re-trigger unless a new event re-issues it.

### Scope filtering

`get_hand(npc_id)` returns only unconsumed cards relevant to a given NPC (matching `npc_scope` or universal). Used by the hand UI to show contextually relevant cards before or during a conversation.

---

## What's Deferred

- **Combos** — intentionally out of scope for this pass. Card interactions with each other are a future design session.
- **Hand UI** — display design (where the hand appears, how cards are presented) is a separate UI pass.
- **Card catalog** — the full list of authored cards is a writing/design pass, not part of this spec.
- **Persistence** — no save system exists yet; when it's added, `CardSystem` state should be included.
