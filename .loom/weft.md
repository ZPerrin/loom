---
kind: loom-config
status: living
updated: 2026-06-26
---
# weft — loom's own overrides

loom's issue-backed work leaves dated specs in `docs/specs/` and plans in `docs/plans/` — a
managed set (`kind: spec`/`plan`), reconciled here at close.

- **Close-out convention.** `feature/<slug>` merges locally `--no-ff` into `main`;
  `issue/<number>-<slug>` pushes and opens a PR against `main` via `gh`. `cleanup = "ask"` in
  `[weft]` then governs whether the merged branch + worktree are torn down.
- **Prune (DEFAULT extension):** once a session's landed work is distilled into the durable
  docs, review `docs/plans/` and `docs/specs/` and prune any plan/spec whose essence is now
  captured and whose work has shipped. Leave in-flight and directional material in place.
