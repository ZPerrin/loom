---
kind: reference
status: living
updated: 2026-09-05
---
# Spec writing rules

Distilled from EARS (Mavin et al., Rolls-Royce, RE'09), the INCOSE Guide for Writing
Requirements, and ISO/IEC/IEEE 29148, plus the failure modes agent-facing spec tools have
surfaced since. Read before drafting any normative sentence. The linter enforces the mechanical
subset; these rules carry the intent. Structure is in [spec-grammar.md](spec-grammar.md).

## The five EARS shapes

Every normative sentence fits one shape, or a combination with clauses in the order WHERE,
WHILE, WHEN/IF. The shape is the anti-slop device: there is no slot for hedging.

| Shape | Template | Example |
|---|---|---|
| Ubiquitous | The system SHALL `<response>`. | The system SHALL store timestamps in UTC. |
| Event | WHEN `<trigger>`, the system SHALL `<response>`. | WHEN a session is idle for 15 minutes, the system SHALL invalidate it. |
| State | WHILE `<state>`, the system SHALL `<response>`. | WHILE offline, the system SHALL queue outbound writes. |
| Unwanted | IF `<condition>`, THEN the system SHALL `<response>`. | IF token validation fails, THEN the system SHALL return 401 within 200 ms. |
| Optional | WHERE `<feature>`, the system SHALL `<response>`. | WHERE SSO is enabled, the system SHALL skip the password form. |

Under `ears = warn` or `off` the shape is advice and the modal is still law: one SHALL or MUST
per requirement, the system as subject.

Quality bar (29148): each requirement is singular, verifiable, unambiguous, implementation-free,
and necessary. If you cannot name the test, it is not yet a requirement.

## Rules

**One behavior per requirement.**
Wrong: The system SHALL rotate refresh tokens and log rotation events and alert on reuse.
Right: three requirements, three ids.
Why: compound requirements produce compound tests and untraceable drift.

**Name the trigger.**
Wrong: The system SHALL invalidate stale sessions.
Right: WHEN a session is idle for 15 minutes, the system SHALL invalidate it.
Why: "stale" is a judgment; a trigger is an observation.

**Numbers, not adjectives.**
Wrong: The system SHALL respond quickly to login attempts.
Right: The system SHALL respond to login attempts within 300 ms at p95.
Why: adjectives are unverifiable; every banned word hides a missing number.

**The system is the subject, active voice.**
Wrong: Sessions will be invalidated when idle.
Right: WHEN a session is idle for 15 minutes, the system SHALL invalidate it.
Why: passive voice loses the actor; "will" states a prediction, not an obligation.

**No escape clauses.**
Wrong: The system SHALL retry failed webhooks where feasible.
Right: IF a webhook delivery fails, THEN the system SHALL retry 3 times with exponential backoff.
Why: an escape clause makes the requirement unfalsifiable.

**No open-ended lists.**
Wrong: The system SHALL validate inputs including but not limited to email and phone.
Right: The system SHALL reject signup input that fails the schema in signup.schema.json.
Why: open lists cannot be covered by tests; point at a closed set.

**Behavior, not design.**
Wrong: The system SHALL use Redis to cache session lookups.
Right: The system SHALL serve repeat session lookups within 5 ms at p95.
Why: if the implementation can change without changing externally visible behavior, it is not
spec; specs outlive implementations.

**Promise, not mechanism.**
Wrong: WHEN the repo is not a git checkout, the system SHALL find markdown with a bounded find that skips .git and node_modules.
Right: WHEN the repo is not a git checkout, the system SHALL still find its markdown files.
Why: the skip list is taste; a different one breaks no promise the owner made, and a line that pins it forbids the better solution. A requirement states what the feature promises the people and skills that use it; the code keeps the how, and a test that pins the how gets no scenario.

**Weak verbs hide the behavior.**
Wrong: The system SHALL support exporting reports.
Right: WHEN a user requests export, the system SHALL produce a CSV of the current report within 10 s.
Why: "support," "handle," "manage," "ensure" assert existence, not behavior.

**Cut words, never the shape.**
Wrong: Idle 15 min: invalidate.
Right: WHEN a session is idle for 15 minutes, the system SHALL invalidate it.
Why: a fragment has no modal and no subject, so nothing can check it or trace it; concision is a
shorter sentence, not a broken one.

**No placeholders.**
Wrong: The system SHALL handle errors appropriately (TBD, similar to R-AUTH-003).
Right: the sentence you can defend, or no requirement yet and a change-log line ending `-> open`.
Why: the next agent reads a placeholder as a requirement and implements it as one.

**Rationale never rides in the requirement.**
Wrong: WHEN load exceeds 80%, the system SHALL shed batch jobs because interactive traffic matters more.
Right: the sentence stops at "shed batch jobs."; the because-clause is the change-log line for that id.
Why: rationale in normative lines bloats every future slice of the spec.

**Scenarios cover the failure path.**
Wrong: one scenario, valid-login.
Right: valid-login under issuance, and bad-token under the requirement that owns the 401.
Why: agents implement the scenarios they can see; an unwritten failure path is an unimplemented one.

**Exclusions are content.**
When scope is cut, write the Non-goal line in the same edit. Undocumented exclusions are
re-proposed by the next agent that cannot see them.

## Change-log lines

`- YYYY-MM-DD <id>: <text> -> <disposition>`. The text is the observation or the edit. The
disposition is `edited` (the spec changed in this diff), `kept` (the spec stands and the code is
the bug), or `open` (a human decides). A reconciliation pass only ever writes `open`; a human
closes it. Rationale lives here, not in the requirement.

## Word lists

The lists live in the BEGIN block of [lint-spec.awk](../scripts/lib/lint-spec.awk);
`[lint.specs].banned` and `.flagged` append to them. Errors are vague or unverifiable terms
(appropriate, robust, seamless, quickly, as needed, including but not limited to). Warnings are
weak verbs (support, handle, manage, ensure). Do not argue with the list in a spec file; if a
flagged word is genuinely right, the sentence almost always still has a missing number or
trigger.
