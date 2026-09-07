---
kind: roadmap
status: living
updated: 2026-09-07
---
# Roadmap

## Now

0.2.0 is living specs. Repo specs say what the code does, one per capability, kept in sync by
reconciliation so work is reviewed against the spec apart from the plan; work specs and plans are
dated orchestration state under `.loom/`. The design is the
[spec grammar](../references/spec-grammar.md) and its
[writing rules](../references/spec-writing-rules.md); the order of work is the
[plan](../.loom/plans/2026-08-30-0.2.0-living-specs.md).

Landed: spec checks in `doc-linter`, the grammar and writing rules, the `spec` and `refine-spec`
skills, the lint fixtures, four repo specs on loom itself reconciled against the code twice, spec
slicing by capability and id, the skill cohesion pass, and the harness hooks: the skill gate and
its receipt on every route a host reports and as each skill's own first step where a host reports
none, a hook by name under `.loom/scripts/`, and a tracer for learning what a host fires. Each
host's native routes and what each ran are in the
[Codex](../.loom/reports/2026-09-07-codex-hooks-validation.md) and
[Claude](../.loom/reports/2026-09-07-claude-hooks-validation.md) validation reports. Left, in order:

- [ ] The data plane, whole: `.loom/handoffs/` and `.loom/reports/` beside `specs/` and
      `plans/`, as kinds the linter accepts and the reference project shows, the handoff's shape
      distilled from warp's delegation opinion. Dispatch itself is the 0.3 idea below.
- [ ] Skill-authoring meta-reference: the house format (contract paragraph, control-surfaces
      table, few hard constraints, output contract, a graph only where topology demands it) with
      constraints-over-steps as the maintenance rule; superpowers and Pocock technique distilled
      in. Ground it in the ablations before it hardens.
- [ ] Release: weft cohesion pass, smoke-test the install on Claude Code and Codex, promote and
      tag only with explicit approval.

## Later

- Dispatch beyond hand-authored handoffs; an RSI grading signal for slice recipes; a vendoring
  build that emits standalone skill directories from the one source.
- Skill-scoped hooks: SKILL.md frontmatter hooks are enforced for the rest of the session and are
  Claude-only; a candidate once the tool-call rail has run.
- Windows portability debt from the shell-only choice; the field findings are in `ed9f30b` and
  `a33fe3e`.

## Ideas

- weft misses negative-space slop: qualifiers, retired-term ledgers, what-not-to-do lists. Evidence (shuttle taxonomy pass, 2026-07-15): after a full vocabulary rename, weft's own pass left a "retired terms" ledger and a naming-doctrine section standing in the taxonomy reference — the operator had to make the cut. The intuition weft should have owned: a reference doc records only what *is*; git history is the graveyard for what was; a clean code corpus teaches naming by example better than prose rules; every line pays context rent and earns its place only if it beats the hypothetical clean turn that never loaded it. The open problem is distillation — taste doesn't state as a rule without becoming one more line paying rent.

- encoding taste without pretending it's deterministic — four small pieces, none of which is enforcement:
  - **Procedure over property.** The ethos states properties ("docs are lean, one-home") and property-shaped prose invites pattern-matched compliance. Rewrite weft's pressure step as a question executed per line — "what does this line let the next agent *do*?" — cut on no answer. Still natural language, but shaped like an algorithm.
  - **Exemplars over rules.** Taste transmits few-shot. Embed one real before/after pair (the shuttle taxonomy doc with its ledger, and the cut version, one line of why) in the weft reference; a rules paragraph describes taste, a pair of documents transmits it.
  - **Tripwires over gates.** A doc-linter check flagging negation-density in `kind: reference` docs (retired/deprecated/never/don't/instead-of) that rejects nothing — it summons judgment: the next weft pass must justify or cut each flagged line. Style guide plus editor, not compiler.
  - **RSI retro as the grader.** Each retro that records "pass missed X, operator caught X" is a labeled datum; the exemplar gallery grows from real misses, the only place taste data comes from. The shuttle ledger miss is datum #1.
- taxonomy + rsi = powerful enough to codify into loom?

- 0.3, orchestration: a delegate worktree carries a marker naming its handoff and its session
  slice opens with that in place of the roadmap; the worktree-and-marker recipe graduates to
  `.loom/scripts/delegate`; a delegate is a background session (`claude --bg -w`) whose id the
  handoff records; the orchestrator repo retires into the bare `.loom` + `.git` workspace
  pattern. Moved out of 0.2.0 on 2026-09-07.

- skill-format ablation: delegate a handful of cheap runs — a small model, each house-format
  element present or absent, two or three objective tasks, the spec checks' pass rate as the
  deterministic grader plus one judge rubric — to learn which scaffolding earns its lines before
  the meta-reference hardens. Then keep ablating as maintenance: delete a step or block from a
  skill, observe, let the deletion stand if nothing breaks. Keeps skills from carrying
  compensations only older models needed.
