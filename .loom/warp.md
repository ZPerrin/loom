---
kind: loom-config
status: living
updated: 2026-09-06
---
# Warp

## Opening

The harness bases the session worktree on the checkout it is launched from; release work is
launched from the release worktree. An input a plan depends on lives at the durable path the plan
names.

## Delegation

One shape, no mid-run questions:

- A shared contract file (invocation, output shape, portability floor) plus one handoff per
  delegate — Objective, Scope in and out, Constraints, Acceptance, Return — with every path pushed
  into the prompt. Handoffs cite behavior by reference (file, section, rule, fixture) and never
  restate it; a delegate trusts the reference over the brief.
- The brief names the base commit and the delegate verifies it before its first edit. The
  coordinator makes the delegate's worktree off the session commit (`git worktree add -b <branch>
  <path> <sha>`); harness worktree isolation bases on the main checkout, which under a release
  branch is every commit behind.
- Acceptance lines are the delegate's own actions ("you ran `bash tests/run` and it printed ALL
  TESTS PASSED"), never a repo state, and they name the outcome set the skill allows, never a file
  count. Forbidden git verbs are spelled out: stash, checkout, switch, reset, clean, rebase, merge,
  worktree, push. The coordinator is the single writer and merges `--no-ff`.
- Acceptance names the file sweep ("you listed every file you added with its job going forward"),
  so the coordinator's sweep after merge finds content, not scaffolding.
- An exit line that names a model's behavior fixes the fixture, the model, and the run count.
- Sonnet by default; Haiku only where a deterministic grader scores the output.
- Skill prose: the coordinator drafts and checks the draft against the last gate's misses, then a
  Sonnet reviewer briefed with those misses and the nearest sibling reads it. The lines that carry
  judgment (what the evidence must be, what is never written, the confirm boundary) are the
  coordinator's. A spec authored or reconciled by Sonnet through a skill's prose floor comes back
  lint-clean in one pass.
- Repo opinion follows the first run: an override written before its run carried a rule the
  grammar forbade; one written from the run's report held.

## Discourse

Options plus a recommendation, depth on request; the gate summary carries the rest. Brevity is not
hiding signal: the operator still catches substantive misses at the gate.

## Experiments

- 2026-09-05 (s2): dress's Survey prose describes doc-scan sections doc-scan no longer emits;
  Sonnet read the script source to resolve it. Fix on the next dress touch; candidate tripwire for
  weft: skill prose naming a script's output.
- 2026-09-05 (s5): An acceptance line named a file count where the skill permits writing nothing;
  the delegate argued with the brief and was right. Test: 6's briefs need no such argument in a
  Return.
- 2026-09-05 (s5): Test-ref resolution is prose (refine-spec's Read step, `.loom/spec.md`'s
  broken-ref rule with no enforcer); a `grep -F` rule cannot see whether a loop asserts a table
  row, which s6 found is the difference between a resolved ref and an asserted one. Candidate for
  determinism when 7 touches the parser.
