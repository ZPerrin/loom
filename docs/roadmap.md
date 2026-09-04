---
kind: roadmap
status: living
updated: 2026-08-30
---
# Roadmap

## 0.2.0 — living specs

Temporary capture until the spec skills exist and can hold this themselves. Distilled from the
2026-08-30 living-specs design session. The bundle's linter and references port; both skills are
authored fresh — the prototype narrowed scope, it is not the draft.

Frame: loom is the portable harness — one plugin, installed into any harness, no external
dependencies, carrying the daily workflow and context tooling onto whatever repo it is dressed
onto. `.loom/` is its on-disk home: the config plane it already is (`loom.toml`, per-skill
overrides) plus a data plane for work state that the repo owner chooses to commit or ignore.
dress covers the data plane through its existing Propose step and the reference project's control
surfaces — defaults, or with the operator — not a new flow. Everything ships to Claude Code and
Codex alike; no harness-specific mechanism on the critical path.

Two spec modalities share one grammar and one authoring skill. Repo specs describe what the code
does: capability-keyed, committed, at `docs/specs/` or wherever the repo says. Keeping them in
sync with the codebase is reconciliation's main job, so orchestration can review work against the
spec separately from reviewing it against a plan. Work specs and plans are orchestration state:
dated `yyyy-mm-dd-<slug-or-issue>.md` under `.loom/specs/` and `.loom/plans/`, listings sorted by
age, usually uncommitted. A loom.toml key overrides either location; discovery stays kind-based so
placement never breaks hygiene.

Specs are single living documents iterated in place — no draft state, no changes queue; git and
a change-log section carry history, and frontmatter status carries a spec's life (living,
hardened, superseded). Ids are the join key across files, so reconciliation targets ids, never
filenames. Review is ordinary session and commit review; the machine appends to the change log
and never rewrites Invariants. No index file: the managed set is the index. The grammar is the
anti-slop device — EARS sentence shapes, RFC-2119 modals, permanent `R-<TOKEN>-<NNN>` ids as
join keys, scenarios naming their verifying tests, Non-goals fencing scope. Budgets and word-list
severities are linter config under `[lint.specs]`, defaults shipped, never hardcoded.
`doc-linter` stays the single entry point and delegates to capability-gated genre checkers — the
rail.

- [ ] `speclint` behind the `doc-linter` rail: python3-gated, one merged lint stream, budgets and
      severities from `[lint.specs]`, JSON findings keyed by rule + requirement id.
- [ ] Spec grammar and writing rules as `references/`, re-ratified for the single-document model;
      wrong/right/why form kept.
- [ ] Skill: spec authoring — draft or extend a capability spec against the grammar, lint-clean
      before presenting. References load on invoke by the most deterministic mechanism the harness
      allows; a prose read-trigger is the floor, not the plan.
- [ ] Skill: spec reconciliation — the descendant of `refine-docs`, sibling to weft (weft fights
      slop, reconciliation fights drift). Evidence order tests > code > sampled runtime; brownfield
      is reconciliation against an empty spec; findings land as change-log lines plus proposed
      edits, never silent rewrites (drifted behavior may be the bug).
- [ ] Example spec as `tests/fixtures/` lint fixtures, conforming and violating.
- [ ] Spec-aware slicing beside `doc-slicer --header`: by capability, id, section. Opt-in like all
      slicing; whoever dispatches pushes, whoever works pulls.
- [ ] Skill-authoring meta-reference: the house format (contract paragraph, control-surfaces table,
      few hard constraints, output contract, graph only where topology demands it) with
      constraints-over-steps as the maintenance rule; superpowers and Pocock technique distilled in.
      Ground the format in the ablation runs under Ideas before it hardens.
- [ ] Review the orchestrator repo piece by piece for what ports — work-handoff and working-note
      templates, the pull-first stance, a `.loom/` data-plane layout. Nothing absorbed wholesale;
      the repo likely retires into the bare `.loom` + `.git` workspace pattern.

Deferred: any dispatch mechanism beyond hand-authored handoffs, the RSI grading signal for slice
recipes, and the vendoring build that emits standalone skill directories from the one source.

## Ideas

- weft misses negative-space slop: qualifiers, retired-term ledgers, what-not-to-do lists. Evidence (shuttle taxonomy pass, 2026-07-15): after a full vocabulary rename, weft's own pass left a "retired terms" ledger and a naming-doctrine section standing in the taxonomy reference — the operator had to make the cut. The intuition weft should have owned: a reference doc records only what *is*; git history is the graveyard for what was; a clean code corpus teaches naming by example better than prose rules; every line pays context rent and earns its place only if it beats the hypothetical clean turn that never loaded it. The open problem is distillation — taste doesn't state as a rule without becoming one more line paying rent.

- encoding taste without pretending it's deterministic — four small pieces, none of which is enforcement:
  - **Procedure over property.** The ethos states properties ("docs are lean, one-home") and property-shaped prose invites pattern-matched compliance. Rewrite weft's pressure step as a question executed per line — "what does this line let the next agent *do*?" — cut on no answer. Still natural language, but shaped like an algorithm.
  - **Exemplars over rules.** Taste transmits few-shot. Embed one real before/after pair (the shuttle taxonomy doc with its ledger, and the cut version, one line of why) in the weft reference; a rules paragraph describes taste, a pair of documents transmits it.
  - **Tripwires over gates.** A doc-linter check flagging negation-density in `kind: reference` docs (retired/deprecated/never/don't/instead-of) that rejects nothing — it summons judgment: the next weft pass must justify or cut each flagged line. Style guide plus editor, not compiler.
  - **RSI retro as the grader.** Each retro that records "pass missed X, operator caught X" is a labeled datum; the exemplar gallery grows from real misses, the only place taste data comes from. The shuttle ledger miss is datum #1.
- taxonomy + rsi = powerful enough to codify into harness?

- skill-format ablation: delegate a handful of cheap runs — a small model, each house-format
  element present or absent, two or three objective tasks, `speclint` pass rate as the
  deterministic grader plus one judge rubric — to learn which scaffolding earns its lines before
  the meta-reference hardens. Then keep ablating as maintenance: delete a step or block from a
  skill, observe, let the deletion stand if nothing breaks. Keeps skills from carrying
  compensations only older models needed.

- hook enforcement / determinism. tool-call hooks (PreToolUse/PostToolUse) are the enforced cross-tool rail -> fire on every matching tool call, can block or repair, read loom.toml for policy. scope by tool-name matcher + payload inspection (skills aren't tools, so no "my-plugin-only" filter). skill-frontmatter hooks would give enforced + skill-scoped but are claude-only. for 0.1.0 we ship prose + the prose-driven skill hooks ([skill].hook); graduate specific steps to enforced hooks later, driven by observed friction.

- the rail loosens the shell-only constraint: a genre checker behind `doc-linter` may use python
  or anything present, since the entry point degrades cleanly when it is absent. Decide whether
  the bash 3.2 + awk core stays pure, or whether the rail is now the portability guarantee. The
  Windows field findings in history (`ed9f30b`, `a33fe3e`) are evidence for that decision.
