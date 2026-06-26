---
kind: loom-config
status: living
updated: 2026-06-25
---
# weft — loom's own overrides

loom plans its own work with the superpowers spec/plan workflow under `docs/superpowers/`,
which is `[discovery] exclude`d (untracked by loom, still committed to git).

- **Final step (DEFAULT extension):** once a session's landed work is distilled into the durable
  docs, review `docs/superpowers/plans/` and `docs/superpowers/specs/` and prune any plan/spec
  whose essence is now captured and whose work has shipped. Leave in-flight and directional
  (`kind: review`) material in place.
