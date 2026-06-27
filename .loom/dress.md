---
kind: loom-config
status: living
updated: 2026-06-26
---
# dress — loom's own overrides

loom's `README.md` is first-person and owner-staked; it does not use the seed's
`## Overview` / `## Module Map` / `## Getting Started`. Treat its real shape as canonical and
do not re-impose the seed.

- Root `README.md` headers: `## Why this project exists` · `## Core Principles` ·
  `## How it works` · `## Naming (textile ethos)` · `## Try it (local, for iteration)`.
- This repo is flat — no module READMEs yet; the scripts, hooks, and skills are the units.
- Excluded from discovery (`[discovery] exclude`): `tests/fixtures` and the plugin's `skills/`
  — never tracked or nagged. Dated specs/plans are a managed set (`kind: spec`/`plan`) under
  `docs/specs/` and `docs/plans/`, reconciled by weave/weft.
