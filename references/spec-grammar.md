---
kind: reference
status: living
updated: 2026-09-06
---
# Spec grammar

Constrained markdown for living specs. The substrate is plain markdown, for pretrained fluency
and clean diffs; every constraint lives at the sentence and section level. `doc-linter` is the
authority: what it rejects is not a spec, however sensible the prose. Sentence rules are in
[spec-writing-rules.md](spec-writing-rules.md).

## Two modalities, one grammar

A **repo spec** says what the code does for one capability: `docs/specs/<capability>.md` or the
`[specs].repo_dir` override, committed, one per capability. A capability is a product feature named by
what its owner gets (auth-session, payments, notifications), never a code module or a script.

A **work spec** says what one unit of work will make true for one capability: dated
`yyyy-mm-dd-<slug-or-issue>.md` under `.loom/specs/` or the `[specs].work_dir` override,
committed or ignored as the owner chose. It opens with the same first line and uses the same
token as the repo spec it targets. A block carrying an existing id is that requirement's
intended replacement; a new id extends the capability's sequence. When the work lands, the
blocks replace or extend the repo spec, the repo spec's change log records the landing, and the
work spec has no further job. Work that spans capabilities is several work specs under one plan.

## Skeleton

Frontmatter, the first line, then sections in this order. `Purpose` and `Requirements` are
required; the rest are optional. Unknown `##` headings are errors.

```markdown
---
kind: spec
status: living
updated: YYYY-MM-DD
---
# Capability: <slug>

## Purpose
<= 3 sentences. What this capability is for. No requirements here.

## Invariants
- INV-1: <one sentence, always true, testable>.

## Requirements
### R-<TOKEN>-<NNN>: <Title>
<exactly one normative sentence>
#### Scenario: <slug> -> <test_ref>
- GIVEN <precondition>
- WHEN <trigger>
- THEN <observable outcome>
- AND <additional outcome>

## Non-goals
- N-1: <one sentence naming excluded scope, with its owner if one exists>.

## Change log
- YYYY-MM-DD <id>: <what changed, or what was observed> -> <disposition>
```

## Rules that make it a grammar

- **Ids are permanent.** `R-<TOKEN>-<NNN>`: TOKEN is 2–8 uppercase alphanumerics, one token per
  capability, numbers never reused. Titles may change; ids may not. `INV-<n>` and `N-<n>` follow
  the same law. The id is the join key for tests, change-log lines, work specs, and slices;
  filenames never are. A number becomes permanent when it lands in the repo spec; two work specs
  minting the same number is a merge conflict, and the later one renumbers.
- **One normative sentence per requirement.** SHALL or MUST, exactly once, within the word
  budget, in an EARS shape while `ears` is strict. Everything else is a scenario.
- **Scenarios are the test bridge.** `-> <test_ref>` names the verifying test. A scenario without
  one is a coverage gap (warning). A test asserting behavior no scenario describes is
  undocumented behavior, a reconciliation finding.
- **Write tiers.** Invariants: human-only; a machine cites them and never writes them. Change
  log: machine-appendable, the only section a reconciliation pass appends to directly.
  Everything else: edited in place by anyone, under ordinary commit review.
- **Budgets are syntax.** Purpose ≤ 3 sentences, normative sentence ≤ 30 words, ≤ 8 scenarios per
  requirement, ≤ 400 lines per file. Over budget means split, not summarize. Each number is a
  `[lint.specs]` key; these are the shipped defaults.

## Status lifecycle

Frontmatter `status` carries the document's life. `living`: iterated in place. `hardened`:
settled; an edit is rare and carries a change-log line. `superseded`: replaced; the text stays,
the status flips, and the successor's change log names each id it absorbs. There is no draft
state and no change queue. Git holds the history; the change log holds the intent.

## Why no change queue

No delta files and no change queue: one requirement is one block under a permanent id, so a git
hunk on a spec file is the requirement and the change-log line in the same diff is its why.
Parallel edits to one id surface as a conflict now, while the authors still hold the context, not
at archive time. Kept from OpenSpec: RFC-2119 modals, scenarios you could write a test for, and
the boundary test (if the implementation can change without changing externally visible behavior,
it is not spec). Dropped: RENAMED sections (ids make renames free), archive tooling, and the
two-review cadence.

## Linter surface

The rule families and their `[lint.specs]` knobs are specified requirement by requirement in
[managed-docs.md](../docs/specs/managed-docs.md), with one violation per fixture under
`tests/fixtures/spec-repo/`, named by rule. `ears` is `strict` (a shape violation fails), `warn`,
or `off` (the shape check is skipped), default `strict`; the one-modal rule holds at every setting.

## Slicing contract

The grammar guarantees addressability: a slice recipe is (capabilities, ids, sections, scenarios
on or off), and one recipe resolves to the same bytes every time, sorted by capability then id.
Spec-aware slicing beside `doc-slicer` is on the [roadmap](../docs/roadmap.md).
