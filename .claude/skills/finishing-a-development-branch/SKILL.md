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
godot_console --headless -s addons/gut/gut_cmdln.gd
```

If tests fail: stop, show failures. Do not proceed until they pass.

### Step 3: Smoketest

Launch the game in the background (always run this step, even when called from executing-plans):

```bash
Start-Process godot_console
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
> When the PR is merged, let me know and I'll clean up the worktree (Orca worktrees live under `~\orca\workspaces\<repo>\<name>`)."

**Do NOT run Step 7 yet.** Cleanup only happens after the user confirms the merge.

#### Option 2: Keep As-Is

Report: "Keeping branch `<name>`. Worktree preserved (Orca worktrees live under `~\orca\workspaces\<repo>\<name>`)."

**Do NOT run Step 7.**

#### Option 3: Discard

**Confirm first:**

```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Its worktree (Orca worktrees live under `~\orca\workspaces\<repo>\<name>`)

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

**Step 7-pre: Close linked issue**

Parse the issue number from the branch name and close the issue if found:

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" =~ feat/issue-([0-9]+)- ]]; then
  gh issue close "${BASH_REMATCH[1]}"
  echo "Closed issue #${BASH_REMATCH[1]}"
else
  echo "No issue number in branch name — skipping issue close."
fi
```

**Step 7a: Remove the worktree via Orca**

Orca-managed worktrees (under `~\orca\workspaces\<repo>\<name>`) are removed via the Orca CLI, run from the repo root:

```bash
orca worktree rm --worktree path:<absoluteWorktreePath> --force --json
```

(See the `orca-cli` skill for details.) After Orca removes the worktree, skip to Step 7d.

**Legacy fallback (non-Orca worktrees only):** if the worktree is not Orca-managed (a legacy worktree under `.worktrees/` or `.claude/worktrees/`), continue to Step 7b. If the session was started with the legacy `EnterWorktree` tool and is still inside the worktree, use `ExitWorktree` first:

```
ExitWorktree(action="remove", discard_changes=true)
```

After `ExitWorktree` returns, skip to Step 7d — the worktree is already removed.

**Step 7b: cd to main repo root**

Always `cd` first — if the session CWD is inside a deleted worktree, git panics with "Unable to read current working directory":

```bash
cd C:\Code\outpost-nova
```

**Step 7c: Remove the worktree (legacy non-Orca worktrees only)**

```bash
git worktree remove <legacy-worktree-path>
```

If that fails (dirty working tree):
```bash
git worktree remove --force <legacy-worktree-path>
# Warn: "Worktree had uncommitted changes — removed with --force."
```

If `--force` also fails (directory already deleted from disk, stale git ref):
```bash
Remove-Item -Recurse -Force <legacy-worktree-path>
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

Every worktree is an Orca worktree, living under `~\orca\workspaces\<repo>\<name>` — created and removed via the Orca CLI (`orca-cli` skill).

Legacy non-Orca worktrees (under `.worktrees/` or `.claude/worktrees/`) used sanitized branch names as directory names: replace all `/` with `-` (e.g. `feat/issue-19-worktree` → `feat-issue-19-worktree`).

## Quick Reference

| Option | Push | Close Issue | Delete Branch | Cleanup Worktree |
|--------|------|-------------|--------------|-----------------|
| 1. Push and Create PR | ✓ | After merge confirmed (if branch has issue number) | `git branch -d` → `-D` fallback, after merge | After merge confirmed |
| 2. Keep as-is | — | — | — | Never |
| 3. Discard | — | — | `git branch -D` (immediate) | Immediately |

## Common Mistakes

**Using bare `git merge master`**
- **Fix:** Always `git fetch origin && git merge origin/master`

**Skipping smoketest because it "already ran"**
- **Fix:** Always re-run — even when called from executing-plans (mandatory, no exceptions)

**Cleaning up worktree immediately after PR creation**
- **Fix:** After PR creation, tell user the worktree path and wait for merge confirmation

**`git worktree remove` fails with "Unable to read current working directory"**
- **Fix:** Always `cd C:\Code\outpost-nova` before any worktree remove command (Step 7b)

**Using raw `git worktree remove` on an Orca worktree**
- **Fix:** Orca worktrees (under `~\orca\workspaces\`) are removed via `orca worktree rm` (Step 7a); raw `git worktree` commands are for legacy `.worktrees/` / `.claude/worktrees/` only

**`git worktree remove --force` fails with "is not a working tree" (legacy worktrees only)**
- **Fix:** Fall back to `rm -rf <legacy-worktree-path> && git worktree prune` to clean up the stale ref

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
- Run smoketest — launch `godot &`, wait for explicit user confirmation
- Remove Orca worktrees via the Orca CLI (raw `git worktree` only for legacy worktrees)
- Infer issue number from branch name before asking
- Present exactly 3 options
- Get typed `discard` for Option 3
- Check for skill/agent/CLAUDE.md diffs and update `docs/dev-workflow.md` if needed

## Integration

**Called by:**
- **executing-plans** (Step 6) — after all batches complete and smoketest passes
- Can also be called standalone at any point
