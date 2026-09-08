---
kind: loom-config
status: living
updated: 2026-09-07
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
- A handoff is `.loom/handoffs/<date>-<slug>.md`, `kind: handoff`, and its Return names the report,
  `.loom/reports/<date>-<slug>.md`, `kind: report`; both are committed, since a delegate's worktree
  sees only what is committed. The brief names the runtime's scripts directory and carries the
  floor: if the tools block is absent, run `doc-slicer --tools` there first.
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
- A delegate brief explicitly includes the invoked skill's repo opinion among its instructions,
  whether the gate carries it or the skill's floor reads it.
- A reconciliation delegate is read-only and stops at Confirm: findings come back by id with a
  recommended direction, and the operator rules them at one gate. A brief names "the tests the
  scenarios name" and never enumerates evidence files; a cited file wins over the brief.

## Discourse

Options plus a recommendation, depth on request; the gate summary carries the rest. Brevity is not
hiding signal: the operator still catches substantive misses at the gate.

## Validation

A harness validation records the installed plugin revision, the native payload, and the script
count beside every claimed route, and a claim about a payload's shape is checked against the
installed binary or a live event before it changes code. Orient names the installed plugin
cache's revision against the checkout and diffs `scripts/`, `hooks/`, and `skills/` against it
before any live hook check. A validation hook logs outside the repo and records whether
`CLAUDE_PLUGIN_ROOT` was set, which tells a harness run from a floor run.
After reinstall and reload, verify installed bytes again: a version label can stay the same
while the runtime changes. For an uncommitted fix, record the changed script's digest.

## Experiments

- 2026-09-05 (s5): Test-ref resolution is prose (refine-spec's Read step, `.loom/skills/spec.md`'s
  broken-ref rule with no enforcer); a `grep -F` rule cannot see whether a loop asserts a table
  row, which s6 found is the difference between a resolved ref and an asserted one, and s8 saw a
  ref resolve inside an assertion's label rather than its needle. Candidate for determinism when a
  ref checker lands.
- 2026-09-06 (s6): The first brownfield cut came out per-script; the skills now map first from
  the front doors. Test: the next brownfield cut, on any repo, is by feature without the operator
  correcting it, or the map-first clause needs an example.
- 2026-09-06 (s6): Feature-grain drafts of a wide capability came out over the 400-line budget
  twice and needed a merge pass. Test: the next wide spec's first draft lands under budget, or
  the writing rules gain a sizing rule (scenarios per requirement, bullets per scenario).
- 2026-09-06 (s6): An Opus delegate writing tests against a spec followed the brief to the letter,
  ran the suite under bash 3.2 unprompted, and surfaced two spec ambiguities. Test: the same
  brief shape on Sonnet for the next test-writing delegation; if its Return reads the same,
  "Sonnet by default" stands for test work too.
- 2026-09-06 (s7): Two specs contradicted each other (a managed-docs scenario asserted the LINT
  findings control-plane's INV-2 forbids) with both tests passing; four delegates fenced to one
  capability each saw nothing, and the operator's ruling on one exposed it. Test: refine-spec's
  Read step checks each Non-goal's claim about a neighbor against that neighbor's requirements;
  if the next multi-spec pass catches a contradiction that way, the step stands (s8: three passes
  ran the check and found every claim borne out, so nothing to catch yet).
- 2026-09-06 (s7): The whole-set weft ran on Fable; the four reconciliations on Sonnet held. Test:
  the next whole-set weft runs on Sonnet with the same brief and a ruled list; if its flagged list
  matches this run's, "Sonnet by default" covers editorial work too.
- 2026-09-07 (s8): A read-only reconciliation delegate placed four test refs in a file where grep
  finds none of them, under the neighbor item, which asks for a location but not the evidence.
  Test: the next contract's neighbor item requires the grep line beside any claim about where an
  assertion lives; if that pass's item 4 carries no unverified location, the line moves into the
  contract template.
- 2026-09-07 (s9): The receipt design was agreed in prose, then the build grew a prose entry, an
  argument on every hook, and the prompt's text in the receipt, and the operator cut all three on
  the smell test; s8's proposal-first line did not prevent it because the proposal described the
  surface instead of showing it. Test: a proposal for a new context surface shows its literal
  bytes and its floor sentence and names every input it passes along, and the build adds nothing
  beyond them; if the next surface lands without a scope cut, the line moves into Discourse.
- 2026-09-07 (s9): Lint on write returned a document's two standing warnings as a blocking error
  on every edit, nine times in one session, and was unregistered. Test: the next deterministic
  rail runs one session as an opt-in before it enters hooks.json, and its per-turn cost is named
  in that session's weave; if it survives, the rule moves into opinion.
- 2026-09-07 (s10): Two spellings the host resolves itself, a bare Skill name and a typed
  `/warp`, reached the skill with no receipt, and the floor covered both before the matcher was
  widened. Test: the next host or version check opens by typing each spelling the host accepts
  before the matcher is trusted; if it misses none, the step moves into Validation. Codex's
  follow-up still missed the plain inline namespaced mention, since fixed and retested; repeat
  the inventory on the next host version rather than treating this as universal coverage.
- 2026-09-07 (s11): The Codex delegate's floor worked with inherited skill context; it did not
  test discovery by a fresh agent. The Claude half ran in s12 and passed: a Sonnet subagent given
  the handoff path, the repo path, and the scripts path ran `doc-slicer --tools` first and reached
  the spec by id (the probe report). Test: the same brief shape on one fresh Codex delegate; if it
  succeeds too, that shape moves into Delegation and SubagentStart stays unregistered.
- 2026-09-07 (s12): The fresh-delegate probe shared the coordinator's worktree because the work
  was uncommitted, and it saw two of the coordinator's edits land mid-run. Test: the next
  delegate on uncommitted work gets its own worktree off a WIP commit; if its report shows no
  drift, the Delegation line gains "a WIP commit first".
- 2026-09-07 (s12): A normative sentence listing four tables in its trigger failed R003, since
  the checker ends a clause at the first comma; the writing rules now say so. Test: the next spec
  sentence with a list in its trigger passes R003 first time; if it misses again, the R003
  message names the comma.
- 2026-09-07 (s12): The delegate's report ran to five times its brief; the brief named sections
  and set no budget. Test: the next brief's Return sets a line budget for Evidence; if the report
  lands within it and the coordinator misses nothing, the reference project's example Return
  names one.
- 2026-09-07 (s13): A release-notes delegate briefed with a per-capability shape returned 60
  lines where the operator wanted 20 at the 20,000-foot view. Test: the next summary brief sets
  the altitude and a line budget instead of a shape; if the draft lands usable without a rewrite,
  altitude-and-budget replaces shape in Delegation.
