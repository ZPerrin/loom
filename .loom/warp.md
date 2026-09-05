---
kind: loom-config
status: living
updated: 2026-09-05
---
# Warp

## Experiments

- 2026-08-29: Exercise configured hooks through `skill-hook` with required positional arguments before relying on them. The current bare `hook = "warp.sh"` invocation drops Warp's slug, forcing the prose-floor fallback even though the repository hook itself works.
- 2026-09-05: Scaffold sweep before the human gate. Session 1 shipped a python "oracle" under
  `tests/` that had finished its job the moment the awk port was proven; the operator caught it by
  diffing in the IDE. Before presenting a gate, list every file the session added with its job
  going forward — no job, no file — and carry a "kept as scaffolding, because…" line in the gate
  summary. Candidate to graduate into weave's Check step.
- 2026-09-05: Delegation shape that worked — a shared contract file plus per-delegate work
  handoffs (Objective / Scope in-out / Constraints / Acceptance / Return), paths pushed into the
  prompt, delegates in worktree isolation committing on their own branch, coordinator as single
  writer merging `--no-ff`. Zero mid-run questions across two delegates. Reuse it for session 3
  and measure whether that holds when the task is prose rather than code.
- 2026-09-05: State precedence in handoffs. My brief named the wrong rule id; the delegate trusted
  the reference implementation over my prose and was right. Handoffs should cite behavior by
  reference (file, rule, fixture), never restate it.
- 2026-09-05: Model choice per delegate. The Sonnet delegate (fixtures) used the most tool calls;
  the Fable delegate (awk port) found a real portability bug. Next well-specified delegate: run the
  same handoff on Haiku and Sonnet, compare tool calls and correctness against the suite.
- 2026-09-05: Verify, then mutate. A landing script ran `git rm` before a python step that failed
  to parse, leaving the tree briefly inconsistent. Landing edits assert first; destructive commands
  last.
- 2026-09-05: Discourse experiment — options plus a recommendation, depth on request — held for a
  full build session and the operator still caught a substantive miss, so brevity did not hide
  signal. Keep it; the gate summary is where the remaining detail must live.
- 2026-09-05: `Skill loom:weave` resolved as unknown in a Cowork-spawned session although listed
  at startup; the fallback was reading `skills/weave/SKILL.md` directly. Check plugin skill
  namespacing in this harness before relying on skill invocation in delegates.
