---
kind: readme
status: living
updated: 2026-06-23
---
# How loom's docs work

loom is a docs & context harness. Its own docs follow the convention it ships:

- **Tier 1 (frontmatter docs):** everything under `docs/config/` plus `AGENTS.md` open with `kind` / `status` / `updated` frontmatter.
- **Tier 2 (stamped READMEs):** the root `README.md` (and any module READMEs) stay frontmatter-free and instead carry a `## Overview` with an `_updated: YYYY-MM-DD_` stamp.
- **Config:** `docs/config/loom.toml` drives the linter (`kinds`/`statuses`/`docs_subdirs`) and the SessionStart slicer (`recent_commits`/`sections`/`modules`).
- **Links are routing:** one home per fact, surfaced by progressive disclosure (root map → deeper doc → code).

The design specs and plans for loom live under `docs/superpowers/` and are intentionally outside the linted `docs_subdirs`.
