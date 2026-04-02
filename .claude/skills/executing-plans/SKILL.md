---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Confirm Branch

Before reading the plan or touching any file, confirm you are on the correct feature branch (not `master`):

```bash
git branch --show-current
pwd
```

Expected: current branch is a feature branch (not `master`). If on master, create or switch to a feature branch before proceeding.

### Step 2: Sync with master

Pull and merge latest master:
```bash
git fetch origin && git merge origin/master
```
NEVER use `git merge master` alone — the local master ref may be stale. Resolve any conflicts before proceeding.

### Step 3: Load and Review Plan

1. Read plan file
2. Review critically — identify any questions or concerns about the plan
3. If concerns: raise them with your human partner before starting
4. If no concerns: create TodoWrite tasks and proceed

### Step 4: Execute Batch

**Before dispatching any task, read the parallel dispatch source of truth (priority order):**

1. **Primary:** Find the `#### Parallel Execution Groups` table for the current batch in the plan. Dispatch all tasks in a `(parallel)` group as concurrent implementer Agent calls in a **single message** (max 3).
2. **Fallback:** If no group table exists, scan each task's `**Parallelizable with:**` annotation. Batch tasks that name each other into a single message.
3. **Last resort:** If neither exists, run tasks sequentially.

**Batch atomicity rule (HARD):** If ANY implementer in a parallel group fails, halt the entire batch immediately. Passing implementers MUST discard their in-progress work — do NOT stage or commit partial results. Fix the failure, then re-dispatch the entire group from scratch.

For each task (whether parallel or sequential):
1. Mark as in_progress
2. Determine task type:
   - **GDScript task** (creates or modifies `.gd` files with logic): follow the TDD cycle — write failing GUT test, write implementation, run tests to pass, refactor checkpoint, commit.
   - **Non-logic task** (scenes, docs, assets): follow each step exactly as written in the plan.
3. After completing any GDScript task: run the full test suite to confirm no regressions:
   ```bash
   godot --headless -s addons/gut/gut_cmdln.gd
   ```
   If any test fails, stop and fix before continuing.
4. Run verifications as specified in the plan
5. Mark as completed

**Parallel reviewer rule (within each batch):**
After each task's work is committed, dispatch spec and quality reviewers as two concurrent Agent calls in a single message. Both must pass before marking the task complete.

### Step 5: Report

When batch complete:
- Show what was implemented
- Show verification output
- Say: "Ready for feedback."

### Step 6: Continue

Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 7: Complete Development

After all tasks complete and verified, run the smoketest sequence:

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass, zero failures.

**Step 3: Launch game and verify visually**
```bash
godot
```
Tell the user what to verify. Wait for confirmation before continuing.

Only after the user confirms the game looks correct:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice.

### Step 8: Lessons Learned — HARD GATE (do not skip)

After the smoketest passes, **before pushing or creating the PR**, explicitly ask:

> "Any important lessons learned from this implementation? (e.g. surprises, sharp edges, things that should update CLAUDE.md / skills / agents / memory)"

**This step is mandatory — do not skip it, even if the implementation felt smooth.**

- If **yes** or the user provides lessons: invoke the `/prd` skill to create a GitHub issue capturing the needed documentation updates. Save anything session-relevant to memory as well.
- If the user explicitly says **no lessons**: note that in your response and proceed to push/PR.

Do not push or open the PR until you have received an explicit answer to this question.

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 3) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** — stop and ask.

## Remember
- Confirm feature branch FIRST before any other action
- Review plan critically before starting
- Follow plan steps exactly
- Don't skip verifications
- Between batches: just report and wait
- Stop when blocked, don't guess
- Never start implementation on master branch
- GDScript tasks: TDD cycle — failing test → implementation → passing test → refactor → commit
- Run full test suite after every GDScript task to catch regressions
- Merge command is `git fetch origin && git merge origin/master`
- Parallel implementers: read `#### Parallel Execution Groups` table first; dispatch parallel groups as concurrent Agent calls (max 3); batch atomicity — if any fails, ALL discard and retry from scratch
- Parallel reviewers: fire spec + quality in one message after each implementer commit

## Integration

**Required workflow skills:**
- **superpowers:writing-plans** — creates the plan this skill executes
- **superpowers:finishing-a-development-branch** — complete development after all tasks
- **dispatching-parallel-agents** — consult before any agent dispatch decision
