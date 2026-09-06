# Outpost Nova — OMP project context

The shared project rules live in `CLAUDE.md` (loaded by Claude Code and, via
this import, by OMP). This file carries only what is OMP-specific.

@../CLAUDE.md

Worktrees: every worktree is an Orca worktree — create and remove via the `orca` CLI. Never raw `git worktree add`; Orca worktrees live under `~\orca\workspaces\<repo>\<name>`.

## Dispatch the specialist agents — they will not fire on their own

Claude Code auto-delegates from an agent's `description`. **OMP does not**:
dispatch is an explicit `task` call you have to decide to make, so a description
alone never fires. These are rules, not suggestions.

- **Before answering or acting on anything about Godot 4 / GDScript** — engine
  API, nodes, signals, Control (UI) nodes, GUT testing, Mobile renderer
  constraints — or implementing GDScript, dispatch `godot-expert` via `task`.
  It handles both consultation and implementation (`implement this task: …`).
- **Before working on Yarn scripts or YarnSpinner integration** — dialogue
  authoring, DialogueRunner setup, custom commands, variable storage, or
  presenters — dispatch `yarnspinner` via `task`. It is a knowledge expert; you
  still make the edit yourself unless you ask it to implement.

One consult per question is enough; do not re-dispatch the same agent for the
same fact.

## What OMP discovers on its own

- **Skills** — everything in `.claude/skills/` loads natively (the `claude`
  provider's project skills). Invoke one with `/skill:<name>`, or read
  `skill://<name>` with the `read` tool. There is no `Skill` tool.
- **Agents** — `.omp/agents/*.md`, **generated** from `.claude/agents/*.md` by
  `tools/sync_agents.py`, which `.githooks/pre-commit` runs and stages on every
  commit. The canonical file is the one under `.claude/agents/`; edit that. A
  hand-edit to a generated file is silently overwritten by the next commit.

## Hook installation

The pre-commit sync only runs once `core.hooksPath` points at `.githooks/`.
Install it once per clone:

    python tools/install_hooks.py
