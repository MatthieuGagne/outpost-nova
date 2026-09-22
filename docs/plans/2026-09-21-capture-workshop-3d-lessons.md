# Capture Workshop-3D Lessons Learned (Issue #140) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fold the two actionable lessons surfaced by the #131 workshop 3D migration into the project docs, so security_post (M4) does not re-hit them.

**Architecture:** Three prose edits, one per doc. Lesson 2 ("plan checkpoint test counts are a hypothesis") splits across the two plan skills — the *author* side goes in `writing-plans`, the *executor* side in `executing-plans`. Lesson 3 ("generator node keys are not stale references") lands in the README's migration-rules section, next to the existing "Migrating deletes the generator entry too" rule it complements. Lesson 1 (the 2-wide interactable footprint) needs no action — it is already captured in `scenes/poc3d/README.md` per the issue.

**Tech Stack:** Markdown prose only. No GDScript, no Godot runtime, no GUT changes.

## Open questions (must resolve before starting)

None — resolved during planning:

- **Lesson 2 in the skills or the CLAUDE.md GUT note?** The two skills. The lesson has two audiences (plan author vs executor), and the existing CLAUDE.md GUT note already covers a *different* distinction (the banner vs the `Scripts`/`Tests` count). Overloading it would blur two separate warnings.
- **Lesson 3 in the README or the security_post plan?** The README. The #132 plan does not exist yet, and the README's migration-rules section is the durable home — the rule applies to every future migration, not just M4.

---

## Batch 1 — three prose edits (the two lessons)

All three tasks edit different files, so they are fully parallel. None touches GDScript, autoloads, or GUT-covered logic — this is docs-only, per the issue's scope.

### Task 1: Fold "test counts are a hypothesis" into `writing-plans` (author side)

**Files:**
- Modify: `.claude/skills/writing-plans/SKILL.md`

**Depends on:** none
**Parallelizable with:** Task 2, Task 3 (different files — this writes only `writing-plans/SKILL.md`)

**Step 1: Insert the note**

In `.claude/skills/writing-plans/SKILL.md`, insert a new block immediately **after** the Hard Gate Sequence table (the `|5|Commit|` row) and **before** the line `Non-logic tasks (scenes, UI, docs, assets): write → verify visually in editor → commit. No test gate.`. The insertion:

```markdown

> **Test-count expectations in a plan are a hypothesis, not a contract.** When a
> plan states an expected GUT count — "holds 8 tests", "expected to fail on all
> four" — that is the author's snapshot of the *current* tree, not a requirement
> the executor must reproduce. The executor verifies against the actual
> `Scripts`/`Tests` output and treats a pre-existing green guard test as normal
> (see `executing-plans`). Don't over-specify counts in the plan; label them as
> expectations.
```

**Step 2: Verify**

Read the region around the Hard Gate Sequence table; confirm the note sits after the `|5|Commit|` row and before the `Non-logic tasks` line, and states both halves of the lesson (counts are advisory; green guard tests are normal).

**Step 3: Commit**

```powershell
git add .claude/skills/writing-plans/SKILL.md
git commit -m "docs: mark plan test-count expectations as advisory (writing-plans)"
```

### Task 2: Fold "trust actual GUT output" into `executing-plans` (executor side)

**Files:**
- Modify: `.claude/skills/executing-plans/SKILL.md`

**Depends on:** none
**Parallelizable with:** Task 1, Task 3 (different files — this writes only `executing-plans/SKILL.md`)

**Step 1: Insert the note**

In `.claude/skills/executing-plans/SKILL.md`, in **Step 3 (Execute Batch)**, insert a new block immediately **after** the line `   If any test fails, stop and fix before continuing.` (the end of item 3's "run the full test suite" block) and **before** the line `4. Run verifications as specified in the plan`. The insertion:

```markdown

**Plan test-count expectations are advisory.** A plan's stated "expected N
tests" / "expected to fail on M" is the author's snapshot of the tree, not a
contract. Verify against the *actual* `Scripts`/`Tests` counts in GUT output,
never the plan's numbers. A test the plan predicted would fail but already
passes green (a pre-existing guard) is normal, not a defect.
```

**Step 2: Verify**

Read Step 3 of the skill; confirm the note sits between the full-suite block and item 4, and instructs verifying against actual `Scripts`/`Tests` output rather than the plan's stated numbers.

**Step 3: Commit**

```powershell
git add .claude/skills/executing-plans/SKILL.md
git commit -m "docs: verify against actual GUT output, not plan-stated counts (executing-plans)"
```

### Task 3: Fold "node keys are not stale references" into the README

**Files:**
- Modify: `scenes/poc3d/README.md`

**Depends on:** none
**Parallelizable with:** Task 1, Task 2 (different files — this writes only `scenes/poc3d/README.md`)

**Step 1: Insert the rule**

In `scenes/poc3d/README.md`, insert a new subsection **immediately after** the `### Migrating deletes the generator entry too` section (it is the file's final section, ending `…stripped here too, which is what restored the tool to a runnable state.`). The insertion:

```markdown

### Generator node keys are not stale references

A stale-reference sweep after a migration must not flag `CantinaDoor` /
`CantinaBottomDoor` keys in the *still-2D* rooms' `_process_area` calls in
`tools/generate_rooms.gd`. Those keys name **doors** that lead into the migrated
area — they are not references to the deleted `res://scenes/areas/<room>.tscn`.
Distinguish node-name keys from scene-path strings: a key is only stale if it
points at a deleted scene *path*.
```

**Step 2: Verify**

Read the tail of `scenes/poc3d/README.md`; confirm the new subsection follows `### Migrating deletes the generator entry too` and states the distinction (node-name keys vs scene-path strings) with the `CantinaDoor` / `CantinaBottomDoor` example.

**Step 3: Commit**

```powershell
git add scenes/poc3d/README.md
git commit -m "docs: distinguish generator node keys from stale scene-path refs (README)"
```

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 1, Task 2, Task 3 | Different files (`writing-plans/SKILL.md`, `executing-plans/SKILL.md`, `scenes/poc3d/README.md`); each stages only its own paths; no shared state |

### Smoketest Checkpoint 1 — lessons captured in all three docs

**Note on this checkpoint:** this issue changes no game code, no autoloads, and no GUT-covered runtime logic — it is three markdown prose edits. There is no game-launch or GUT step; the "smoketest" is reviewing the diff to confirm each lesson landed in the right doc with the right wording.

**Step 1: Fetch and merge latest master**

```bash
git fetch origin && git merge origin/master
```

**Step 2: Review the diff**

```bash
git diff HEAD~3 -- .claude/skills/writing-plans/SKILL.md .claude/skills/executing-plans/SKILL.md scenes/poc3d/README.md
```

Expected: three additions — the advisory-counts note in `writing-plans`, the actual-output note in `executing-plans`, and the node-keys subsection in the README — and nothing else.

**Step 3: Confirm with user**

Tell the user: lesson 2 is captured in both plan skills (author side + executor side), lesson 3 in the README's migration rules, and lesson 1 needs no action (already documented). Wait for confirmation before finishing.
