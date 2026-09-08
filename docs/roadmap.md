---
kind: roadmap
status: living
updated: 2026-09-07
---
# Roadmap

## Now

0.2.0 is out. Specs are living documents, one per capability, written in a grammar the linter
grades and kept true by a reconciliation skill. Every skill opens with its repo opinion and its
hook's report, on Claude Code and Codex alike. Work state lives under `.loom/` as dated specs,
plans, handoffs, and reports, and every session opens with a tools block that says where all of
it is.

The next month is driving loom on real repos. What that teaches accumulates on `release/0.3.0`
and lands under Next.

## Next

0.3.0: orchestration patterns and experimentation.

- Orchestration: a delegate worktree carries a marker naming its handoff, and its session slice
  opens with that in place of the roadmap; the worktree-and-marker recipe becomes
  `.loom/scripts/delegate`; a delegate is a background session (`claude --bg -w`) whose id the
  handoff records; the orchestrator repo retires into the bare `.loom` + `.git` workspace.
- Skill-authoring meta-reference: the house format (contract paragraph, control-surfaces table,
  few hard constraints, output contract, a graph only where topology demands it),
  constraints-over-steps as the maintenance rule, superpowers and Pocock technique distilled in;
  the technique survey and the Pocock distillation are in `~/Downloads/living-specs-bundle`.
- Skill-format ablation: delegate a handful of cheap runs — a small model, each house-format
  element present or absent, two or three objective tasks, the spec checks' pass rate as the
  deterministic grader plus one judge rubric — to learn which scaffolding earns its lines before
  the meta-reference hardens. Then keep ablating as maintenance: delete a step or block from a
  skill, observe, let the deletion stand if nothing breaks. Keeps skills from carrying
  compensations only older models needed.

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


