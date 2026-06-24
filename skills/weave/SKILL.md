---
name: weave
description: Holistically reconcile the whole documentation tree against the current code and realign it to docs/README.md. Use periodically when docs have drifted after many sessions, milestones, or reviews.
---

Reconcile the entire documentation tree, re-derived from the current code, into a small durable navigation layer aligned to `docs/README.md`. Same ethos as `/weft`, but whole-tree in scope rather than the session delta. Treat docs as routing and decision context, not a running log: keep guidance that changes the next good action; prune or relocate text that is stale, duplicated, task-local, or merely ornamental. Stage changes; never commit.

## Workflow

1. Enumerate the managed set deterministically with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-scan"` (frontmatter discovery over tracked + uncommitted markdown) rather than agentic globbing. Inspect by progressive disclosure: start at `AGENTS.md`, follow the root `README.md` `## Module Map`, scan headings before bodies; read only the docs and code the reconciliation touches.
2. **Surface omissions and uncommitted work.** `doc-scan`'s candidate list is markdown lacking frontmatter — surface it and ask whether any should be adopted as managed docs. Skill `SKILL.md` files and the `docs/superpowers/` specs/plans are intentionally unmanaged scaffolding (frontmatter without a `kind`, or none) — don't pester about those. Then run `git status --porcelain -- '*.md'`: surface new/uncommitted (`??`/`A`) and deleted (` D`) managed docs and ask whether to distill/adopt or drop them — don't assume.
3. Identify stale, duplicated, misplaced, or low-leverage text. Preserve durable guidance; remove ordinary status, history, and task-local state (git holds it).
4. Move each fact to its smallest stable home and collapse duplication to one home plus links. Module `README.md` files own their `## Overview`, setup, and commands; the root README `## Module Map` links to them rather than restating them.
5. Normalize product, module, workflow, command, heading, and concept names unless a local term is intentionally different.
6. Rewrite survivors as compressed, durable prose (the conventions' craft standard): signal per sentence, no ornament. Apply the brevity gate; verify every surviving line helps a future agent choose a better next action. If no durable update is justified, make none.
7. Run the bundled linter `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"` and fix what it flags. Stage; do not commit.

## Output

Report docs reviewed, files changed with one-line rationales, validation performed, and why nothing changed where nothing did.
