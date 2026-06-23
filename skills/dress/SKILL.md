---
name: dress
description: Stand up (or re-tune) the loom doc harness on a repo — negotiate the root README identity and doc location, scaffold the coherent doc structure (module READMEs, docs/README.md, roadmap) plus a minimal docs/config/loom.toml, and prove it lint-clean. Also the place to re-tune loom.toml's context slices and lint rules as the repo drifts. Use when adopting loom on a repo or adjusting what it tracks.
---

Dress the loom: stand up the doc harness conversationally — explaining each artifact as it lands and letting the operator pivot — so the result is a *coherent* harness, not just files. The endstate definition of what docs mean lives in `docs/README.md`; everything else implements it. The harness's runtime (the SessionStart slicer and the linter) ships with the plugin and runs from `${CLAUDE_PLUGIN_ROOT}`; what this skill writes into the repo is the **docs** and a small **`docs/config/loom.toml`** that drives them. Stage; never commit.

## Foundation first (invest the conversation here)

Everything derives from a few decisions — settle them before generating:

1. **Project identity** — the root `README.md` `## Overview` (what it is) and `## Module Map` (what exists), derived from the actual top-level code dirs.
2. **Doc location & organization** — where `docs/` lives and how it is structured, captured as `docs/README.md`. This *is* the source of truth; lock it, then generate downstream.
3. **The config** — `docs/config/loom.toml`: the module set, the SessionStart context slices, and the lint rules. Seed it from [templates/loom.toml](templates/loom.toml) and fill it from the chosen structure.

## Detect-and-adapt

- **Blank repo:** write the canonical templates with guiding placeholder prose under each canonical header; prompt for the identity one-liner, module list, charter-or-not.
- **Existing repo:** inventory what exists and **map content into canonical homes** rather than overwrite — fold an existing README intro into `## Overview`, derive `## Module Map` from real top-level dirs, fill module `## Overview`s cheaply from code where obvious, and **flag gaps** ("backend has no Setup section — fill via /weft") instead of inventing detail. Never clobber existing prose silently.

## Canonical layout to produce

- `README.md` — `## Overview` (stamped) · `## Module Map` · `## Getting Started`; frontmatter-free.
- `AGENTS.md` (with `CLAUDE.md` symlink) — router + GLOBAL `## Agentic Guidelines` / `## Agentic Validation` only.
- `<module>/README.md` — `## Overview` (stamped) · `## Setup` · `## Structure` · `## Agentic Guidelines` · `## Agentic Validation`.
- `docs/README.md` — how docs work (taxonomy / lifecycle / nomenclature / ethos): the source of truth.
- `docs/config/` — `roadmap.md` (required) · `loom.toml` (required) · `charter.md` (optional).
- `docs/{specs,plans,design,diagrams}/` — scaffolding + assets.

## The config: `docs/config/loom.toml`

`loom.toml` is what the plugin's runtime reads — there is no per-repo Python to edit. It is a small TOML subset: `[table]` headers, `key = scalar`, and single-line `key = ["arrays"]` (trailing `#` comments fine). Three tables:

- `[modules] dirs = [...]` — the module set. Drives both the linter's stamped-README list and the slicer's per-module Overview slices.
- `[context]` — what the SessionStart hook injects: `recent_commits` (git bearings), `sections` (each `"file > ## Header"`, e.g. the roadmap `## Now`), and `include_modules`. Start maximal, then trim *down* — the slice is paid every session, so cut to what changes the next action.
- `[lint]` — `kinds` / `statuses` (frontmatter enums) and `docs_subdirs` (which `docs/` dirs carry frontmatter), mirroring the "Nomenclature" + "Module Map" in `docs/README.md`. The linter is a literal encoding of `docs/README.md`; keep them in agreement.

**Re-tune (the facilitator loop)** — to adjust what loads or what the linter enforces:
1. Render the live context: `bash "${CLAUDE_PLUGIN_ROOT}/hooks/doc-slicer"` from the repo root, and show the operator the actual output with a rough per-slice line/token cost so the always-on tax is visible.
2. Tune `[context]` / `[modules]` / `[lint]` in `loom.toml` with the operator — add/drop/reorder slices, add/remove modules, adjust enums to match `docs/README.md`. Re-render, re-show. Loop until it lands.
3. If a sliced header is missing, the slicer emits nothing for it — fix the doc with `/weft`, not by working around it here.

## Cohesion (the binding invariant)

Generate every dependent artifact *from* `docs/README.md` so a pivot propagates: module READMEs, `loom.toml`'s module set / enums, the slice list. Offer pivots (charter in/out, which dirs are modules, keep/drop `docs/design` + `docs/diagrams`, the `docs/` location) and recommend a core — but never leave a reference pointing at the old shape.

## Self-check

End by running `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"` — the scaffold is born lint-clean, which also proves the cross-reference web is coherent.

## Output

Report what was scaffolded vs. mapped from existing content, the pivots chosen, the `loom.toml` written, gaps flagged for `/weft`, and the clean lint run.
