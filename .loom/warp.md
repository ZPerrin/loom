---
kind: loom-config
status: living
updated: 2026-09-05
---
# Warp

## Opening

The harness bases the session worktree on the checkout it is launched from; release work is
launched from the release worktree. An input a plan depends on lives at the durable path the plan
names; session 4 opened without a hunt.

## Delegation

Four sessions of one shape, zero mid-run questions:

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
- Acceptance names the file sweep ("you listed every file you added with its job going forward");
  the coordinator's sweep after merge then finds content, not scaffolding.
- An exit line that names a model's behavior fixes the fixture, the model, and the run count.
- Sonnet by default; Haiku only where a deterministic grader scores the output.
- Prose delegation, measured (s4): a Sonnet draft of a skill from a brief citing the doc
  convention is a usable skeleton and a second reviewer; the lines that carry judgment (what the
  evidence must be, what is never written, the confirm boundary) came from the coordinator. Use a
  delegate for the second draft or the review, not the first draft. A spec authored by Sonnet
  through the skill's prose floor came back lint-clean in one pass.

## Discourse

Options plus a recommendation, depth on request. Four sessions in, the operator still catches
substantive misses at the gate, so brevity is not hiding signal; the gate summary carries the
remaining detail.

## Experiments

- 2026-09-05 (s2): dress's Survey prose describes doc-scan sections doc-scan no longer emits;
  Sonnet read the script source to resolve it. Fix on the next dress touch; candidate tripwire for
  weft: skill prose naming a script's output.
- 2026-09-05 (s4): The reference-load injection line in `skills/spec` is docs-verified only:
  project skills enumerate at session start and a nested `claude -p` cannot log in. Test: a fresh
  session with `claude --plugin-dir <checkout>` invoking `/loom:spec` shows the grammar in the
  loaded skill. If the `!` shell lacks `CLAUDE_PLUGIN_ROOT`, try `${CLAUDE_SKILL_DIR}/../../`
  before settling on the prose floor.
- 2026-09-05 (s4): The operator's gate caught three skill-prose misses the coordinator's review
  passed: a contract narrating the skill about itself with a roadmap note in it, a sibling
  skill's rule leaking in, and no propose-confirm boundary before durable text is written. Check
  the next skill draft (5) against those three before the gate; test: the gate finds none.
- 2026-09-05 (s4): Repo opinion written before its first run is a hypothesis: `.loom/spec.md`'s
  test-ref rule allowed spaces the grammar forbids, and the delegate caught it. Write the opinion
  after the first run, or stamp it provisional; test: 5's opinion survives its first run unchanged.
