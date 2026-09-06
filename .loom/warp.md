---
kind: loom-config
status: living
updated: 2026-09-06
---
# Warp

## Opening

The harness bases the session worktree on the checkout it is launched from, so release work is
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
  count. One names the file sweep ("you listed every file you added with its job going forward"),
  so the coordinator's sweep after merge finds content, not scaffolding. Forbidden git verbs are
  spelled out: stash, checkout, switch, reset, clean, rebase, merge, worktree, push. The
  coordinator is the single writer and merges `--no-ff`.
- An exit line that names a model's behavior fixes the fixture, the model, and the run count.
- Sonnet by default; Haiku only where a deterministic grader scores the output.
- Skill prose: the coordinator drafts and checks the draft against the last gate's misses, then a
  Sonnet reviewer briefed with those misses and the nearest sibling reads it. The lines that carry
  judgment (what the evidence must be, what is never written, the confirm boundary) are the
  coordinator's.
- An override is written after its first run, from the run's report, never before.
- A reconciliation delegate is read-only and stops at Confirm: findings come back by id with a
  recommended direction, and the operator rules them at one gate. A brief names "the tests the
  scenarios name" and never enumerates evidence files; a cited file wins over the brief.

## Discourse

Options plus a recommendation, depth on request; the gate summary carries the rest. Brevity is not
hiding signal: the operator still catches substantive misses at the gate.

## Experiments

- 2026-09-05 (s5): Test-ref resolution is prose (refine-spec's Read step, `.loom/spec.md`'s
  broken-ref rule with no enforcer); a `grep -F` rule cannot see whether a loop asserts a table
  row, which s6 found is the difference between a resolved ref and an asserted one. Candidate for
  determinism when 7 touches the parser.
- 2026-09-06 (s6): The first brownfield cut came out per-script; the skills now map first from
  the front doors. Test: the external-repo run's first cut is by feature without the owner
  correcting it, or the map-first clause needs an example.
- 2026-09-06 (s6): Feature-grain drafts of a wide capability came out over the 400-line budget
  twice and needed a merge pass. Test: the next wide spec's first draft lands under budget, or
  the writing rules gain a sizing rule (scenarios per requirement, bullets per scenario).
- 2026-09-06 (s6): An Opus delegate writing tests against a spec followed the brief to the letter,
  ran the suite under bash 3.2 unprompted, and surfaced two spec ambiguities. Test: the same
  brief shape on Sonnet for the next test-writing delegation; if its Return reads the same,
  "Sonnet by default" stands for test work too.
- 2026-09-06 (s7): The operator estimated a tenth of the markdown universe was slop or drift; a
  whole-set weft delegate cut 0.5% unprompted and 3% under a ruled block list. Test: the next
  whole-set weft opens with one sample cut agreed with the operator; if the unprompted share then
  lands within 2x of the estimate, calibration becomes weft.md's rule.
- 2026-09-06 (s7): Two specs contradicted each other (a managed-docs scenario asserted the LINT
  findings control-plane's INV-2 forbids) with both tests passing; four delegates fenced to one
  capability each saw nothing, and the operator's ruling on one exposed it. Test: refine-spec's
  Read step checks each Non-goal's claim about a neighbor against that neighbor's requirements;
  if the next multi-spec pass catches a contradiction that way, the step stands.
- 2026-09-06 (s7): The whole-set weft ran on Fable; the four reconciliations on Sonnet held. Test:
  the next whole-set weft runs on Sonnet with the same brief and a ruled list; if its flagged list
  matches this run's, "Sonnet by default" covers editorial work too.
