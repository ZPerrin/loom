---
kind: roadmap
status: living
updated: 2026-09-06
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
skills, the lint fixtures, and four repo specs on loom itself, reconciled against the code. Left:

- [ ] Dogfood on an external repo with the owner at the fence, then the skill-format ablations
      under Ideas.
- [ ] Spec-aware slicing beside `doc-slicer --header`: by capability, id, section. Opt-in like all
      slicing; whoever dispatches pushes, whoever works pulls.
- [ ] Skill-authoring meta-reference: the house format (contract paragraph, control-surfaces
      table, few hard constraints, output contract, a graph only where topology demands it) with
      constraints-over-steps as the maintenance rule; superpowers and Pocock technique distilled
      in. Ground it in the ablations before it hardens.
- [ ] Review the orchestrator repo piece by piece for what ports: handoff and working-note
      templates, the pull-first stance, a `.loom/` data-plane layout. Nothing absorbed wholesale;
      the repo likely retires into the bare `.loom` + `.git` workspace pattern, and delegate
      handoffs and returns are the first candidate for a third data-plane directory.
- [ ] Release: weft cohesion pass, smoke-test the install on Claude Code and Codex, promote and
      tag only with explicit approval.

## Later

- Dispatch beyond hand-authored handoffs; an RSI grading signal for slice recipes; a vendoring
  build that emits standalone skill directories from the one source.
- Hook enforcement. Tool-call hooks (PreToolUse/PostToolUse) are the enforced cross-tool rail:
  they fire on every matching tool call, can block or repair, and can read `loom.toml` for policy,
  scoped by tool-name matcher plus payload inspection. Skill-frontmatter hooks would be enforced
  and skill-scoped but are Claude-only. Graduate specific steps as friction shows. Before adding a
  hook, name what survives the child process: effects on disk do, environment does not.
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

- skill-format ablation: delegate a handful of cheap runs — a small model, each house-format
  element present or absent, two or three objective tasks, the spec checks' pass rate as the
  deterministic grader plus one judge rubric — to learn which scaffolding earns its lines before
  the meta-reference hardens. Then keep ablating as maintenance: delete a step or block from a
  skill, observe, let the deletion stand if nothing breaks. Keeps skills from carrying
  compensations only older models needed.
