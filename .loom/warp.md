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
- Prose delegation, measured (s4, s5): a Sonnet draft of a skill from a brief citing the doc
  convention is a usable skeleton and a second reviewer; the lines that carry judgment (what the
  evidence must be, what is never written, the confirm boundary) came from the coordinator. The
  coordinator drafts, checks the draft against the last gate's misses, then a Sonnet reviewer
  briefed with those misses and the nearest sibling reads it: four real defects in six minutes
  (s5), and the gate raised none. A spec authored or reconciled by Sonnet through a skill's
  prose floor comes back lint-clean in one pass.
- Repo opinion follows the first run: `.loom/spec.md` written before its run carried a rule the
  grammar forbade; `.loom/refine-spec.md` written from the run's report held (s5).

## Discourse

Options plus a recommendation, depth on request. Four sessions in, the operator still catches
substantive misses at the gate, so brevity is not hiding signal; the gate summary carries the
remaining detail.

## Experiments

- 2026-09-05 (s2): dress's Survey prose describes doc-scan sections doc-scan no longer emits;
  Sonnet read the script source to resolve it. Fix on the next dress touch; candidate tripwire for
  weft: skill prose naming a script's output.
- 2026-09-05 (s4): The reference-load injection line in `skills/spec` and `skills/refine-spec`
  is docs-verified only: project skills enumerate at session start and a nested `claude -p`
  cannot log in. Test: a fresh session with `claude --plugin-dir <checkout>` invoking
  `/loom:spec` shows the grammar in the loaded skill. If the `!` shell lacks
  `CLAUDE_PLUGIN_ROOT`, try `${CLAUDE_SKILL_DIR}/../../` before settling on the prose floor.
- 2026-09-05 (s5): An acceptance line named a file count ("the two files in scope") where the
  skill permits writing nothing; the delegate argued with the brief and was right. Acceptance
  names the outcome set the skill allows, never a file count. Test: 6's briefs need no such
  argument in a Return.
- 2026-09-05 (s5): A Sonnet run read a test's clean expectation (a conforming fixture reports
  nothing) as no assertion and missed the one undocumented behavior with a test; refine-spec's
  Compare step now names clean expectations. Test: the next run on a repo with a conforming
  fixture reports it, or the sentence goes.
- 2026-09-05 (s5): Test-ref resolution is prose (refine-spec's Read step, `.loom/spec.md`'s
  broken-ref rule with no enforcer); the delegate did it by hand with `grep -F`. Candidate for
  determinism when 7 touches the parser: a rule that resolves every `-> ref` against the tree.
