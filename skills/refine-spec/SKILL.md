---
name: refine-spec
description: Use when the user asks whether a spec is still accurate, suspects spec drift, wants a capability's behavior captured before or after a change, or names code that has no spec. Reconciles one capability's loom spec against its tests and code and reports drift by requirement id.
---

## Refine spec

Hold one capability's living spec against the code that claims to implement it. Read what the tests and code do, compare it with what the spec says by id, put each divergence to the owner with a recommended direction, and land only what the owner rules. Drift runs both ways: a spec that lags the code and code that broke the spec look the same until the owner says which is the bug.

Two entry states:

- **No repo spec:** every behavior the evidence shows is undocumented. The findings are the fence, and `spec` writes the first repo spec from it.
- **Repo spec exists:** compare by id. Findings land as change-log lines, as in-place edits through `spec`, or as blocks in a work spec.

## Refine Spec Control Surfaces

These are the surfaces `refine-spec` reads or writes directly. The full `.loom/loom.toml` key map lives in the reference project.

| Surface | Refine spec uses it for |
|---|---|
| `[specs].repo_dir` | where the capability's repo spec is looked for (default `docs/specs`) |
| `[specs].work_dir` | where a proposal with text lands, as a work spec `spec` writes (default `.loom/specs`) |
| `.loom/spec.md` | repo opinion shared with `spec`: capability boundaries and the form a test ref is resolved by |
| `.loom/refine-spec.md` | optional repo opinion: how to sample a run, refs known to be stale, where a sweep costs too much |
| `doc-linter` | the gate on every file touched |
| `doc-stamp` | `updated=<today>` on the repo spec a line was appended to |
| `spec` | writes every requirement block: a first repo spec, an in-place extension, a work spec |
| tests, code, a sampled run | the evidence, in that order of authority |

## Hard constraints

- **Evidence in order, named.** Every finding names its evidence: the test first, the code it exercises where no test speaks, a sampled run only where both are silent. A sample answers one named question; it is never a sweep.
- **Findings carry an id.** A finding is keyed by the id it contradicts, the id it extends, or the id `spec` mints for it. A file or a line number is a locator, never a key.
- **Never a silent rewrite.** This skill edits no requirement, scenario, invariant, or non-goal. What it writes to the repo spec is the change-log line the writing rules allow a reconciliation pass, and the stamp. Recommend a direction for each finding, and write only what the owner ruled.
- **Confirm before writing.** Present the whole set of findings before any file changes. An invocation that fixes a direction for every finding kind, such as leaving all of them open, is a confirmed set, which is how a brief drives this skill with no owner present.
- **Writing is spec's.** New blocks, replacement blocks, and a first repo spec go through `spec`, handed the fence in its own terms: capability, token, boundary, and every decision and invariant the owner gave, so its Confirm needs no second round. Where the harness cannot invoke a skill from a skill, read [spec](../spec/SKILL.md) and follow it.
- **One capability.** The scope is the capability named or the one the diff touched. Behavior that belongs to a neighbor is a finding for the neighbor's spec, reported and not chased.

## Workflow

### 1. Read

When no capability is named, or the name is a script, a module, or a test file, map first: list the product's features from the front doors (README, roadmap, the skills' descriptions), put the cut to the owner as features at the 20,000-foot view, and read no test until one is chosen. Evidence is walked inside a fence, never to find one.

The repo spec if one exists, `.loom/spec.md`, the tests the scenarios name and the tests that cover the capability, then the code they exercise. Resolve every test ref by the repo's form; a ref that resolves to nothing is a finding. Where a sampled run is called for, write down what was run.

### 2. Compare

Walk the spec by id: for each requirement and scenario, what the evidence says. Then walk the evidence for what the spec does not say: every assertion a test makes, a clean expectation included, and every branch the code takes. Classify each divergence:

- **Undocumented:** behavior the evidence asserts and no id covers.
- **Drift:** the evidence contradicts a requirement or scenario; either side may be the bug.
- **Unverified:** a scenario without a test ref, a ref that resolves to nothing, or a requirement without a scenario.
- **Dead:** no test and no code path exercises the requirement.
- **Detail:** the evidence pins how the code does something rather than what the feature promises; it is named in the report and never logged, and a test that pins the how gets no scenario.

An existing change-log line that already records the observation under the id is a finding already open: cite it, do not log it again. A finding `doc-linter` already reports by id is carried in the report from the lint output, not logged; the change log holds what only this pass observed.

### 3. Confirm

Present the findings by id, each with its kind, its evidence, and your recommended direction: the spec follows the code (for a dead requirement, the block goes and its id retires), the code is the bug, or open. Rounds as needed; wait for the owner between them. With no repo spec, present the fence in `spec`'s terms plus the behaviors found, the test each names, and the neighbors the evidence touched.

### 4. Land

- **Left open:** append the change-log line to the repo spec. Where there is text to propose, `spec` writes it as a work spec carrying only those blocks.
- **Ruled:** the owner has closed the finding. Hand the ruling to `spec`, which makes the edit or logs the code as the bug under the disposition the owner named. Lines this skill writes itself end `open`.
- **No repo spec:** `spec` writes the first repo spec from the fence.

Stamp the repo spec with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-stamp" <file> updated=<today>` when a line was appended. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"`; a finding on a line this skill wrote sends it back here.

## Output

Report the capability and the evidence read, with any sampled run and the question it answered; each finding on one line with its id, kind, evidence, and the direction ruled or left open; the change-log lines appended and the open lines cited instead; the file `spec` wrote, or that it wrote nothing; the refs that resolved to nothing; behavior handed to a neighbor's spec; and the lint result. If the spec and the evidence agree, say so and write nothing.

## References

The grammar and the writing rules the findings and the change-log lines obey:

!`cat "${CLAUDE_PLUGIN_ROOT}/references/spec-grammar.md" "${CLAUDE_PLUGIN_ROOT}/references/spec-writing-rules.md" 2>/dev/null || true`

If the line above shows a command instead of the grammar, read [spec-grammar.md](../../references/spec-grammar.md) and [spec-writing-rules.md](../../references/spec-writing-rules.md) before comparing.
