---
name: weave
description: Use when docs have drifted after many sessions, milestones, or reviews and the whole tree needs reconciling against the current code. The whole-tree complement to weft's session-delta distill.
---

Reconcile the entire documentation tree, re-derived from the current code, into a small durable navigation layer aligned to [doc-convention](../../references/doc-convention.md). Same ethos as `/weft`, but whole-tree in scope rather than the session delta. Treat docs as routing and decision context, not a running log: keep guidance that changes the next good action; prune or relocate text that is stale, duplicated, task-local, or merely ornamental.

**MUST:** enumerate the managed set with `doc-scan`, not agentic globbing — membership must be deterministic; run the linter and fix what it flags; stage, never commit. The editorial judgment between is **DEFAULT**, shapeable per repo.

## Load the repo's opinion first

Read `.loom/weave.md` if it exists and let it shape the DEFAULT heuristics below — what this repo treats as low-leverage, how aggressively to collapse, which terms are intentionally local. It never relaxes a MUST. See [repo-overrides](../../references/repo-overrides.md).

## Workflow

1. **Enumerate (MUST).** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-scan"` — frontmatter discovery over tracked + uncommitted markdown, never agentic globbing. Then inspect by progressive disclosure: start at `AGENTS.md`, follow the root `README.md` `## Module Map`, scan headings before bodies — `bash "${CLAUDE_PLUGIN_ROOT}/hooks/doc-slicer" --header "<name>"` reads one section across the whole set without opening files ([tooling](../../references/tooling.md)) — and read only the docs and code the reconciliation touches.
2. **Surface omissions and uncommitted work.** `doc-scan` prints `# candidates` (markdown with no `kind`). Ask whether each should be adopted as a managed doc or added to `[discovery] exclude`; a candidate keeps surfacing until one or the other. Then run `git status --porcelain -- '*.md'`: surface new/uncommitted (`??`/`A`) and deleted (` D`) managed docs and ask whether to distill/adopt or drop them — don't assume.
3. Identify stale, duplicated, misplaced, or low-leverage text. Preserve durable guidance; remove ordinary status, history, and task-local state (git holds it). Where a behavior has graduated into a `[warp]`/`[weft] hook`, treat the matching `.loom/<skill>.md` prose as the **floor**: trim it to its judgment-residue — the *why/when* a reader still needs — and never re-pad it with the mechanism the hook now owns.
4. Move each fact to its smallest stable home and collapse duplication to one home plus links. Module `README.md` files own their `## Overview`, setup, and commands; the root README `## Module Map` links to them rather than restating.
5. Normalize product, module, workflow, command, heading, and concept names unless a local term is intentionally different.
6. Rewrite survivors as compressed, durable prose (the conventions' craft standard): signal per sentence, no ornament. Apply the brevity gate; verify every surviving line helps a future agent choose a better next action. If no durable update is justified, make none.
7. **Lint (MUST).** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"` and fix what it flags. Stage; do not commit.

## Red flags

| Thought | Reality |
|---|---|
| "Globbing the docs is faster than `doc-scan`." | Membership must be deterministic and discovery-driven; a glob drifts from the managed set. |
| "I'll adopt this stray markdown to be safe." | Ask once: adopt it (give it `kind:` frontmatter) or `[discovery] exclude` it. Don't silently adopt. |
| "The hook and the `.loom` prose say the same thing — I'll keep both for completeness." | The prose is the floor beneath the hook, not a copy of it. Trim it to the judgment the hook can't carry; determinism owns the mechanism. |

## Output

Report docs reviewed, files changed with one-line rationales, validation performed, and why nothing changed where nothing did.
