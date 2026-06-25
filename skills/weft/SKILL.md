---
name: weft
description: Use when wrapping up a work session — distill landed changes into the durable docs and optionally close out the branch (gate, commit, merge). Invoke as "weft into <branch>" to name the merge target up front.
---

Distill this session's landed work into the durable docs. Scope is the session delta, not the whole tree. Follow [doc-convention](../../references/doc-convention.md): editorial before additive, compression as craft, no edit without durable signal.

After distilling, **weft always asks whether to close out the branch** — sync the docs, then offer to finish the work by merging. Two invocations:

- **`/weft`** — distill + stage the doc diff, then ask "close out this branch by merging? into which branch?". If no, stop with the diff staged and **never commit** — the operator reviews and commits. If yes, run close-out into the chosen branch.
- **`/weft into <branch>`** — the same distill, but the target is named: skip the question and run close-out straight into `<branch>`.

**MUST:** the close-out **gate** — lint clean *and* the untracked/missing check both pass before any merge; the merge is always `--no-ff` with a written commit; commit only on close-out opt-in (plain `/weft` stages, never commits); run the linter. What to distill and where, and what to prune, are **DEFAULT** — shaped by the repo.

## Load the repo's opinion first

Read `docs/loom/weft.md` if it exists; it shapes *what* you distill and *where*, and names the branch/close-out convention. It never relaxes the gate. See [repo-overrides](../../references/repo-overrides.md).

## Distill (both modes)

1. Scope the delta: `git log --oneline` and `git diff` against the last doc-sync commit or the branch base. Name what landed and any direction abandoned.
2. **Surface uncommitted docs early.** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-scan"` and `git status --porcelain -- '*.md'`. New/uncommitted (`??`/`A`) managed docs and `# candidate` files created this session are easy to miss — name them and confirm whether each should be distilled, adopted, or left. Anything you decide not to track, add to `[discovery] exclude` so it stops surfacing.
3. **(DEFAULT)** Distill from the code, not the spec. For each landed feature, refresh the touched module README's frontmatter `updated` and `## Overview`, and record any durable build or infrastructure decision in that module's `## Agentic Guidelines`. If a result earns its own doc — a schema, a subsystem, a diagram — add it under `docs/` and link it from the module README. Most features stop at an Overview paragraph; if nothing durable changed, write nothing.
4. **(DEFAULT)** Move the roadmap only on milestone events: update `## Now`/`## Next`, check off `## Milestones` in `docs/roadmap.md`. No per-session entry — git is the activity log.
5. **(DEFAULT)** weft does not assume any spec/plan workflow. A repo that has one opts in via its `docs/loom/weft.md` addendum — e.g. "as a final step, once the work is captured above, prune implemented plans under `docs/plans/`." Such trees are typically `[discovery] exclude`d (untracked, still committed); weft acts on them directly because the addendum says to, not because discovery surfaces them.
6. **(DEFAULT)** Sync `AGENTS.md` or the root `README.md` only if a durable fact changed.
7. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"` and fix what it flags; `git add` the doc changes.

Then **ask whether to close out**: "Close out this branch by merging? Into which branch?" (skip when invoked as `/weft into <branch>` — the target is given). If the operator declines, stop here: report and leave the diff staged. If they choose a target, continue.

## Close out (on operator opt-in)

8. **The gate (MUST) — the work does not merge until both pass:**
   - **Lint clean:** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"` exits 0.
   - **Untracked / missing check:** `git status --porcelain`. Surface every untracked (`??`) and deleted/missing (` D`) path; stage what belongs in the sync, remove or explain what doesn't.

   **Never merge through a failing gate. No exceptions** — not "it's a trivial doc change," not "lint is almost clean, I'll fix after the merge," not "the stray file is unrelated." If either check fails, stop and report.
9. **Commit the sync** on the work branch: `git commit -m "docs(weft): <what was distilled>"` (project trailer per the repo's commit convention).
10. **Merge with an explicit commit, as the last step:** `git checkout <branch>` then `git merge --no-ff <work-branch>` with a written merge-commit message naming the work. `--no-ff` always — never a fast-forward. Re-run the linter on the merged result.
11. **Optionally clean up** — on operator confirmation, delete the merged branch (`git branch -d <work-branch>`) and `git worktree prune` if applicable. Skip if they want it kept.

## Red flags

| Thought | Reality |
|---|---|
| "It's a trivial doc change — skip the gate." | The gate has no size exemption. Lint + clean tree, every time. |
| "Lint is almost clean; merge and fix after." | Never merge through a failing gate. Fix first, then merge. |
| "A fast-forward is cleaner here." | Always `--no-ff`. The explicit merge commit is the record. |
| "Plain `/weft`, but I'll commit to be helpful." | Plain `/weft` stages only. Committing is the operator's opt-in. |

## Output

Report files touched with one-line rationales, what was pruned, and whether the roadmap moved and why; when nothing durable changed, say so and make no edit. In close-out mode, also report the gate result, the sync commit, the merge commit, and whether the branch was cleaned up.
