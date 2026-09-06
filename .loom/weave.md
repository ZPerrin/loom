---
kind: loom-config
status: living
updated: 2026-09-06
---
# Weave

## Check

Scaffold sweep before the gate: list every file the session added with its job going forward; no
job, no file. A delegate scoped to conform does not see scaffolding as its job, so the sweep is
the coordinator's, after merge. The gate summary carries a "kept as scaffolding, because…" line
for anything that stays.

## Landing

One mutation per command, asserting before mutating: `git merge --no-ff <branch> -m "<msg>"`
(never `-F -` with a heredoc), confirm the merge landed, then clean up. Session branches land on
the release branch from its own worktree, then the release branch is pushed. Delegate worktrees
the coordinator made are removed once their branch has merged; the harness's session worktree is
left to the harness, detached so its branch can go.
