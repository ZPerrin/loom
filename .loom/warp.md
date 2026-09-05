---
kind: loom-config
status: living
updated: 2026-09-05
---
# Warp

## Opening

The harness bases the session worktree on the checkout it is launched from; release work is
launched from the release worktree.

## Delegation

Three sessions of one shape, zero mid-run questions:

- A shared contract file (invocation, output shape, portability floor) plus one handoff per
  delegate — Objective, Scope in and out, Constraints, Acceptance, Return — with every path pushed
  into the prompt. Handoffs cite behavior by reference (file, section, rule, fixture) and never
  restate it; a delegate trusts the reference over the brief.
- The brief names the base commit and the delegate verifies it before its first edit. The
  coordinator makes the delegate's worktree off the session commit (`git worktree add -b <branch>
  <path> <sha>`); harness worktree isolation bases on the main checkout, which under a release
  branch is every commit behind.
- Acceptance lines are the delegate's own actions ("you ran `bash tests/run` and it printed ALL
  TESTS PASSED"), never a repo state. Forbidden git verbs are spelled out: stash, checkout, switch,
  reset, clean, rebase, merge, worktree, push. The coordinator is the single writer and merges
  `--no-ff`.
- Sonnet by default; Haiku only where a deterministic grader scores the output.

## Discourse

Options plus a recommendation, depth on request. Three sessions in, the operator still catches
substantive misses, so brevity is not hiding signal; the gate summary carries the remaining detail.

## Experiments

- 2026-09-05 (s2): An exit line that reads "skill X proposes Y" needs the fixture, the model, and
  the run count fixed in the plan. A dressed fixture reads as a retune and pulls every model toward
  the minimum; test greenfield adoption on an undressed one. Apply at the next plan edit.
- 2026-09-05 (s2): dress's Survey prose describes doc-scan sections doc-scan no longer emits;
  Sonnet read the script source to resolve it. Fix on the next dress touch; candidate tripwire for
  weft: skill prose naming a script's output.
- 2026-09-05 (s3): Prose delegation is still unmeasured; the coordinator wrote both references.
  Next prose task: hand one document to a Sonnet delegate from a brief that cites the doc
  convention, and compare it against the coordinator's own draft.
- 2026-09-05 (s3): An input the plan depends on gets a durable path the moment it exists. The
  research survey lived only in a prior session's scratchpad and had to be hunted. Test: session 4
  opens without a hunt.
- 2026-09-05 (s3): A delegate scoped to "conform to X" does not see scaffolding as its job; the
  session-1 guards survived γ's pass and the coordinator swept them after merge. Try naming the
  sweep in the brief's Acceptance and see whether the coordinator's own sweep then finds nothing.
