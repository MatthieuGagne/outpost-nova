# Finishing-a-Development-Branch Skill + Mandatory Worktree Workflow

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a `finishing-a-development-branch` skill and update `executing-plans` + `writing-plans` to enforce a mandatory git worktree workflow, giving every feature branch a clean, verified path to PR creation and cleanup.

**Architecture:** Four file-only tasks (no GDScript, no GUT coverage needed). A new skill file is created from scratch, two existing skill files receive targeted edits, and a new `docs/dev-workflow.md` is bootstrapped documenting the full dev cycle. All four tasks write to different files and are parallelizable.

**Tech Stack:** Markdown skill files, Godot 4 headless CLI, git worktrees, GitHub CLI (`gh`)

## Open questions (must resolve before starting)

- none

---

## Batch 1 — Skill files + workflow doc

### Task 1: Create `finishing-a-development-branch` skill

**Files:**
- Create: `.claude/skills/finishing-a-development-branch/SKILL.md`

**Depends on:** none
**Parallelizable with:** Task 2, Task 3, Task 4

**Step 1: Write the content**

Create `.claude/skills/finishing-a-development-branch/SKILL.md` with the following exact content:

````markdown
---
name: finishing-a-development-branch
description: Use when implementation is complete — verifies GUT tests, runs smoketest, checks docs, presents PR/keep/discard options, and cleans up the worktree
---

# Finishing a Development Branch

## Overview

Verify tests → smoketest → doc check → present options → execute choice → clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Fetch and Merge Master

```bash
git fetch origin && git merge origin/master
```

If merge conflicts occur: resolve them, commit the merge, then continue.

### Step 2: Run GUT Tests

```bash
godot --headless -s addons/gut/gut_cmdln.gd
```

If tests fail: stop, show failures. Do not proceed until they pass.

### Step 3: Smoketest

Launch the game in the background (always run this step, even when called from executing-plans):

```bash
godot scenes/main.tscn &
```

Tell the user what to look for. Then ask:

> "Does the game look correct? Please confirm before I continue."

**STOP. Wait for explicit confirmation.**

- If issues found: work with user to fix before continuing.
- If confirmed: continue to Step 4.

### Step 4: Doc Check

Check whether any skill, agent, or CLAUDE.md files were modified in this branch:

```bash
git diff origin/master --name-only
```

If any `.claude/skills/`, `.claude/agents/`, or `CLAUDE.md` files appear in the diff → update `docs/dev-workflow.md` to reflect the change. The two are co-authoritative and must agree.

If nothing matched, skip and continue to Step 5.

### Step 5: Present Options

```
Implementation complete. What would you like to do?

1. Push and create a Pull Request  ← default
2. Keep the branch as-is (I'll handle it later)
3. Discard this work

Which option?
```

**Never offer "merge to main locally"** — all work integrates via PR.

### Step 6: Execute Choice

#### Option 1: Push and Create PR

Infer issue number from branch name (e.g. `feat/issue-42-foo` → `#42`). If not inferable, ask user.

```bash
git push -u origin <feature-branch>

gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets>

## Test Plan
- [ ] GUT tests pass headlessly
- [ ] Visual smoketest confirmed

Closes #N
EOF
)"
```

After PR is created, report:

> "PR created: <URL>
> When the PR is merged, let me know and I'll clean up the worktree at `/home/mathdaman/code/worktrees/<sanitized-branch>`."

**Do NOT run Step 7 yet.** Cleanup only happens after the user confirms the merge.

#### Option 2: Keep As-Is

Report: "Keeping branch `<name>`. Worktree preserved at `/home/mathdaman/code/worktrees/<sanitized-branch>`."

**Do NOT run Step 7.**

#### Option 3: Discard

**Confirm first:**

```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at /home/mathdaman/code/worktrees/<sanitized-branch>

Type 'discard' to confirm.
```

Wait for exact confirmation. If confirmed:

```bash
git branch -D <feature-branch>
```

(Use `-D` directly — user has explicitly confirmed deletion of unmerged work. No `-d` first.)

Then run Step 7 immediately.

### Step 7: Cleanup Worktree

#### After merge confirmation (Option 1 only)

Only run after the user explicitly confirms the PR was merged — **never preemptively**.

**Step 7a: Exit EnterWorktree session if active**

If the current session was started with `EnterWorktree` and is still inside the worktree, use `ExitWorktree` first:

```
ExitWorktree(action="remove", discard_changes=true)
```

After `ExitWorktree` returns, skip to Step 7d — the worktree is already removed.

If not inside an active `EnterWorktree` session, continue to Step 7b.

**Step 7b: cd to main repo root**

Always `cd` first — if the session CWD is inside a deleted worktree, git panics with "Unable to read current working directory":

```bash
cd /home/mathdaman/code/outpost-nova
```

**Step 7c: Remove the worktree**

```bash
git worktree remove /home/mathdaman/code/worktrees/<sanitized-branch>
```

If that fails (dirty working tree):
```bash
git worktree remove --force /home/mathdaman/code/worktrees/<sanitized-branch>
# Warn: "Worktree had uncommitted changes — removed with --force."
```

If `--force` also fails (directory already deleted from disk, stale git ref):
```bash
rm -rf /home/mathdaman/code/worktrees/<sanitized-branch>
git worktree prune
# Note: "Worktree directory was already gone — pruned stale ref."
```
Skip Step 7d in this case (prune already ran).

**Step 7d: Prune stale refs**

```bash
git worktree prune
```

**Step 7e: Delete local branch**

```bash
git branch -d <feature-branch>
```

If that fails (not fully merged — e.g. squash merge):
```bash
git branch -D <feature-branch>
# Warn: "Branch was not fully merged — deleted with -D."
```

Report: "Worktree and branch cleaned up. Back on master."

#### Immediately after discard (Option 3)

Run Step 7a → 7b → 7c → 7d in sequence. Skip 7e (branch already deleted with `-D` in Step 6).

#### Option 2: Keep As-Is

**Do NOT run Step 7.**

## Worktree Path Convention

Branch names are sanitized before use as directory names: replace all `/` with `-`.

- Example: `feat/issue-19-worktree` → `/home/mathdaman/code/worktrees/feat-issue-19-worktree`

## Quick Reference

| Option | Push | Delete Branch | Cleanup Worktree |
|--------|------|--------------|-----------------|
| 1. Push and Create PR | ✓ | `git branch -d` → `-D` fallback, after merge | After merge confirmed |
| 2. Keep as-is | — | — | Never |
| 3. Discard | — | `git branch -D` (immediate) | Immediately |

## Common Mistakes

**Using bare `git merge master`**
- **Fix:** Always `git fetch origin && git merge origin/master`

**Skipping smoketest because it "already ran"**
- **Fix:** Always re-run — even when called from executing-plans (mandatory, no exceptions)

**Cleaning up worktree immediately after PR creation**
- **Fix:** After PR creation, tell user the worktree path and wait for merge confirmation

**`git worktree remove` fails with "Unable to read current working directory"**
- **Fix:** Always `cd /home/mathdaman/code/outpost-nova` before any worktree remove command (Step 7b)

**`git worktree remove --force` fails with "is not a working tree"**
- **Fix:** Fall back to `rm -rf <path> && git worktree prune` to clean up the stale ref

**Merging directly to main**
- **Fix:** Always use a PR — never `git merge` to main locally

**Forgetting the doc check**
- **Fix:** Always run `git diff origin/master --name-only` and check for skill/agent/CLAUDE.md changes

## Red Flags

**Never:**
- Commit directly to `master`
- Merge feature branch locally without a PR
- Proceed with failing GUT tests
- Skip the smoketest (always required — no exceptions)
- Delete work without typed `discard` confirmation
- Force-push without explicit request
- Clean up worktree before merge confirmation (Option 1)

**Always:**
- Work on a feature branch inside a worktree
- Integrate via PR only
- Run GUT tests headlessly before presenting options
- Run smoketest — launch `godot scenes/main.tscn &`, wait for explicit user confirmation
- Sanitize branch name (replace `/` with `-`) for worktree paths
- Infer issue number from branch name before asking
- Present exactly 3 options
- Get typed `discard` for Option 3
- Check for skill/agent/CLAUDE.md diffs and update `docs/dev-workflow.md` if needed

## Integration

**Called by:**
- **executing-plans** (Step 6) — after all batches complete and smoketest passes
- Can also be called standalone at any point
````

**Step 2: Verify**

Open `.claude/skills/finishing-a-development-branch/SKILL.md` and confirm:
- File exists
- Frontmatter name is `finishing-a-development-branch`
- Step 3 says `godot scenes/main.tscn &`
- Step 7 covers ExitWorktree → cd → worktree remove → prune → branch delete sequence

**Step 3: Commit**

```bash
git add .claude/skills/finishing-a-development-branch/SKILL.md
git commit -m "feat: add finishing-a-development-branch skill for Outpost Nova"
```

---

### Task 2: Update `executing-plans` skill — EnterWorktree Step 1, remove Step 2

**Files:**
- Modify: `.claude/skills/executing-plans/SKILL.md`

**Depends on:** none
**Parallelizable with:** Task 1, Task 3, Task 4

**Step 1: Write the content**

Replace the entire contents of `.claude/skills/executing-plans/SKILL.md` with:

````markdown
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

### Step 1: Enter Worktree

Before reading the plan or touching any file, check whether you are already inside a worktree:

```bash
pwd
git worktree list
```

If `pwd` output is already under `/home/mathdaman/code/worktrees/`, you are in a worktree — skip to Step 2.

Otherwise, determine the feature branch name from the plan (use `feat/issue-<N>-<short-description>` convention, where `<N>` is the GitHub issue number). Then use the `EnterWorktree` tool to create and enter the worktree:

- Worktree path: `/home/mathdaman/code/worktrees/<branch-name-with-slashes-as-dashes>`
- Branch: `feat/issue-<N>-<short-description>`

`EnterWorktree` creates a fresh branch off master — no separate sync step is needed.

### Step 2: Load and Review Plan

1. Read plan file
2. Review critically — identify any questions or concerns about the plan
3. If concerns: raise them with your human partner before starting
4. If no concerns: create TodoWrite tasks and proceed

### Step 3: Execute Batch

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

### Step 4: Report

When batch complete:
- Show what was implemented
- Show verification output
- Say: "Ready for feedback."

### Step 5: Continue

Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 6: Complete Development

After all tasks complete and verified, announce: "I'm using the finishing-a-development-branch skill to complete this work."

**REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch

Follow that skill to verify tests, run smoketest, present options, execute choice, and clean up.

### Step 7: Lessons Learned — HARD GATE (do not skip)

After the smoketest passes (inside finishing-a-development-branch), **before pushing or creating the PR**, explicitly ask:

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

**Return to Review (Step 2) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** — stop and ask.

## Remember
- Enter worktree FIRST before any other action (use `EnterWorktree` tool if not already under `/home/mathdaman/code/worktrees/`)
- Review plan critically before starting
- Follow plan steps exactly
- Don't skip verifications
- Between batches: just report and wait
- Stop when blocked, don't guess
- Never start implementation on master branch
- GDScript tasks: TDD cycle — failing test → implementation → passing test → refactor → commit
- Run full test suite after every GDScript task to catch regressions
- When merging (e.g. resolving conflicts): `git fetch origin && git merge origin/master`
- Parallel implementers: read `#### Parallel Execution Groups` table first; dispatch parallel groups as concurrent Agent calls (max 3); batch atomicity — if any fails, ALL discard and retry from scratch
- Parallel reviewers: fire spec + quality in one message after each implementer commit

## Integration

**Required workflow skills:**
- **superpowers:writing-plans** — creates the plan this skill executes
- **superpowers:finishing-a-development-branch** — complete development after all tasks
- **dispatching-parallel-agents** — consult before any agent dispatch decision
````

**Step 2: Verify**

Open `.claude/skills/executing-plans/SKILL.md` and confirm:
- Step 1 is "Enter Worktree" (no longer "Confirm Branch")
- Step 2 is "Load and Review Plan" (old Step 2 "Sync with master" is gone)
- Steps are numbered 1–7 (not 1–8)
- Step 6 calls `finishing-a-development-branch` (not a smoketest block)

**Step 3: Commit**

```bash
git add .claude/skills/executing-plans/SKILL.md
git commit -m "feat: use EnterWorktree in executing-plans Step 1, remove redundant sync step"
```

---

### Task 3: Update `writing-plans` skill — add worktree references

**Files:**
- Modify: `.claude/skills/writing-plans/SKILL.md`

**Depends on:** none
**Parallelizable with:** Task 1, Task 2, Task 4

**Step 1: Write the content**

Two targeted edits to `.claude/skills/writing-plans/SKILL.md`:

**Edit 1 — "Before You Begin" section:** After the `git fetch origin && git merge origin/master` block, add the following paragraph:

```markdown
**Note on worktrees:** Plan execution happens inside a git worktree, created automatically by `EnterWorktree` in executing-plans Step 1. You do not need to create the worktree here — just write the plan. Branch name convention: `feat/issue-<N>-<short-description>`.
```

**Edit 2 — "Execution Handoff" section:** After the two execution option descriptions (Subagent-Driven / Parallel Session), before the closing content, add:

```markdown
**Both execution paths work inside a git worktree.** The worktree is created at `/home/mathdaman/code/worktrees/<sanitized-branch>` by executing-plans Step 1 (`EnterWorktree`). Cleanup is handled by `finishing-a-development-branch` after the PR is merged.
```

**Step 2: Verify**

Open `.claude/skills/writing-plans/SKILL.md` and confirm:
- "Before You Begin" contains the worktree note after the git fetch block
- "Execution Handoff" contains the worktree note after the options block
- No other content was changed

**Step 3: Commit**

```bash
git add .claude/skills/writing-plans/SKILL.md
git commit -m "docs: add worktree workflow reference to writing-plans skill"
```

---

### Task 4: Bootstrap `docs/dev-workflow.md`

**Files:**
- Create: `docs/dev-workflow.md`

**Depends on:** none
**Parallelizable with:** Task 1, Task 2, Task 3

**Step 1: Write the content**

Create `docs/dev-workflow.md` with the following exact content:

```markdown
# Outpost Nova — Development Workflow

This document describes the end-to-end workflow for developing features in Outpost Nova. Every feature follows these steps in order.

---

## Step 1: Brainstorm

**When:** You have a rough idea but no concrete requirements yet.

**Skill:** `brainstorming`

Invoke the brainstorming skill in Claude Code. It explores user intent, surfaces requirements, and considers design trade-offs before anything is written down. Output is a shared understanding between you and Claude, not a document.

---

## Step 2: Create a PRD (GitHub Issue)

**When:** You have a clear idea and want to capture requirements formally.

**Skill:** `prd`

Invoke the `prd` skill. It creates a GitHub issue in MatthieuGagne/outpost-nova with:
- Goal
- Requirements (R1, R2, …)
- Acceptance Criteria (AC1, AC2, …)
- Out of Scope
- Files Impacted

The GitHub issue is the single source of truth for what the feature does. No local file is created.

---

## Step 3: Write an Implementation Plan

**When:** The GitHub issue exists and you're ready to plan the work.

**Skill:** `writing-plans`

Invoke the `writing-plans` skill with the GitHub issue URL as argument. It:
1. Pulls latest master
2. Runs the `grill-me` skill to surface edge cases and open questions
3. Writes a detailed implementation plan to `docs/plans/YYYY-MM-DD-<feature-name>.md`

Plans are broken into batches of 2–4 tasks, each ending with a smoketest checkpoint. Every GDScript task follows a TDD cycle (failing test → implementation → passing tests → commit). All tasks include exact file paths and complete code.

**Branch name convention:** `feat/issue-<N>-<short-description>` where `<N>` is the GitHub issue number.

---

## Step 4: Execute the Plan

**When:** The plan is written, reviewed, and approved.

**Skill:** `executing-plans`

Open a new Claude Code session (or use Subagent-Driven mode) and invoke the `executing-plans` skill with the plan file. It:

1. **Enters a git worktree** via `EnterWorktree` — creates a fresh branch off master at `/home/mathdaman/code/worktrees/<sanitized-branch>`. All implementation work happens here, isolated from the main repo.
2. Loads and reviews the plan critically
3. Executes tasks in batches, running GUT tests after every GDScript change:
   ```bash
   godot --headless -s addons/gut/gut_cmdln.gd
   ```
4. Reports after each batch and waits for confirmation before continuing
5. When all tasks are done, hands off to `finishing-a-development-branch`

**Worktree path convention:** `/home/mathdaman/code/worktrees/<branch-name>` where slashes in the branch name are replaced with dashes (e.g. `feat/issue-19-foo` → `feat-issue-19-foo`).

---

## Step 5: Finish the Development Branch

**When:** All plan tasks are complete and verified.

**Skill:** `finishing-a-development-branch`

Invoked automatically by `executing-plans` (or standalone). It:

1. Fetches and merges latest master
2. Runs all GUT tests headlessly — must pass before continuing
3. Launches the game for a visual smoketest:
   ```bash
   godot scenes/main.tscn &
   ```
   Waits for explicit user confirmation before proceeding.
4. Checks if any `.claude/skills/`, `.claude/agents/`, or `CLAUDE.md` files changed — if so, updates this document (`docs/dev-workflow.md`) to stay in sync
5. Presents three options:
   - **Push and create PR** (default)
   - **Keep branch as-is**
   - **Discard**
6. For Option 1: pushes branch, creates PR on GitHub with GUT + smoketest checkboxes, and waits for merge confirmation before cleaning up
7. After merge confirmed: removes worktree, prunes stale refs, deletes local branch

---

## Key Constraints

- **Never commit directly to `master`** — all work goes through a PR
- **Never skip GUT tests** — headless test run is mandatory before any PR
- **Never skip the smoketest** — visual confirmation is mandatory, even for doc-only changes
- **Worktrees are mandatory** — no fallback for working directly on a branch in the main repo
- **MVP scope is fixed** — 2 rooms, 3 characters, 3 resources, 5 recipes, 3 Cantina upgrades; no scope creep
- **TDD for all GDScript logic** — write the failing test before writing the implementation

---

## Skill Quick Reference

| Phase | Skill | Output |
|-------|-------|--------|
| Explore idea | `brainstorming` | Shared understanding |
| Capture requirements | `prd` | GitHub issue |
| Plan work | `writing-plans` | `docs/plans/*.md` |
| Implement | `executing-plans` | Committed code in worktree |
| Ship | `finishing-a-development-branch` | PR → merge → cleanup |
```

**Step 2: Verify**

Open `docs/dev-workflow.md` and confirm:
- All 5 workflow phases are present
- Each phase names its skill and describes its output
- Worktree path convention matches `/home/mathdaman/code/worktrees/<sanitized-branch>`
- Key Constraints section is present

**Step 3: Commit**

```bash
git add docs/dev-workflow.md
git commit -m "docs: bootstrap dev-workflow.md — full end-to-end dev cycle"
```

---

#### Parallel Execution Groups — Smoketest Checkpoint 1

| Group | Tasks | Notes |
|-------|-------|-------|
| A (parallel) | Task 1, Task 2, Task 3, Task 4 | All write different files with no shared symbols or dependencies |

### Smoketest Checkpoint 1 — verify all skill files and workflow doc are correct

**Step 1: Fetch and merge latest master**
```bash
git fetch origin && git merge origin/master
```

**Step 2: Run all GUT tests**
```bash
godot --headless -s addons/gut/gut_cmdln.gd
```
Expected: All tests pass, zero failures. (No new GDScript was added — this confirms no regressions.)

**Step 3: Verify files exist and read correctly**

Confirm the following files exist and match the plan:
- `.claude/skills/finishing-a-development-branch/SKILL.md` — Step 3 says `godot scenes/main.tscn &`, Step 7 covers full cleanup chain
- `.claude/skills/executing-plans/SKILL.md` — Step 1 is "Enter Worktree", 7 total steps (not 8)
- `.claude/skills/writing-plans/SKILL.md` — "Before You Begin" and "Execution Handoff" each contain a worktree note
- `docs/dev-workflow.md` — 5 phases present, Quick Reference table at bottom

**Step 4: Confirm with user**

Tell the user: "All four files are in place. Please confirm the `finishing-a-development-branch` skill, the updated `executing-plans` and `writing-plans` skills, and the new `docs/dev-workflow.md` look correct before I proceed to push."

Wait for confirmation before proceeding.
