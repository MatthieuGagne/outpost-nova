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
3. Creates a git worktree via `EnterWorktree` — the plan file lives on the feature branch from day one
4. Writes a detailed implementation plan to `docs/plans/YYYY-MM-DD-<feature-name>.md` inside the worktree

Plans are broken into batches of 2–4 tasks, each ending with a smoketest checkpoint. Every GDScript task follows a TDD cycle (failing test → implementation → passing tests → commit). All tasks include exact file paths and complete code.

**Branch name convention:** `feat/issue-<N>-<short-description>` where `<N>` is the GitHub issue number.

---

## Step 4: Execute the Plan

**When:** The plan is written, reviewed, and approved.

**Skill:** `executing-plans`

Open a new Claude Code session (or use Subagent-Driven mode) and invoke the `executing-plans` skill with the plan file. It:

1. **Checks for an existing worktree** — `writing-plans` creates the worktree before saving the plan, so the session may already be inside it. If not, `EnterWorktree` creates it now. All implementation work happens in the worktree, isolated from the main repo.
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
   godot &
   ```
   Waits for explicit user confirmation before proceeding.
4. Checks if any `.claude/skills/`, `.claude/agents/`, or `CLAUDE.md` files changed — if so, updates this document (`docs/dev-workflow.md`) to stay in sync
5. Presents three options:
   - **Push and create PR** (default)
   - **Keep branch as-is**
   - **Discard**
6. For Option 1: pushes branch, creates PR on GitHub with GUT + smoketest checkboxes, and waits for merge confirmation before cleaning up
7. After merge confirmed: closes the linked GitHub issue (if issue number is in the branch name), removes worktree, prunes stale refs, deletes local branch

**Automatic issue close:** A GitHub Actions workflow (`.github/workflows/close-issue-on-merge.yml`) also closes the linked issue on PR merge by parsing the issue number from `feat/issue-<N>-...` branch names — this is the primary mechanism; the `finishing-a-development-branch` call above is belt-and-suspenders.

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
