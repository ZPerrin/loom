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

OpenSpec keeps every change as a delta file (ADDED, MODIFIED, REMOVED blocks) merged into the spec
on archive, for two stated reasons: a delta is diffable at a glance, and parallel changes to one
spec file stop conflicting. The grammar answers both without a queue.

- **Diffability.** One requirement is one block under a permanent id, so a git hunk on a spec
  file is a requirement, and the change-log line in the same diff is its why. The commit diff is
  the review surface; a delta file is a second copy of the same text whose only job is to be
  merged later.
- **Conflicts.** Parallel edits to different ids are different hunks and merge cleanly. Parallel
  edits to the same id are a real conflict and should surface as one, now, while the authors
  still hold the context; a queue defers that collision to archive time.
- **The proposal form survives as the work spec.** It carries only the blocks the work changes,
  in the same grammar, and dies when the work lands. Work state, not a queue: no archive step,
  no second ratification.

Kept from OpenSpec: RFC-2119 modals, scenarios you could write a test for, and the boundary test
(if the implementation can change without changing externally visible behavior, it is not spec).
Dropped: RENAMED sections (ids make renames free), archive tooling, and the two-review cadence.

## Linter surface

Rule families as `doc-linter` reports them. Fixtures under `tests/fixtures/spec-repo/` hold one
violation per file, named by rule.

| Family | Checks | `[lint.specs]` keys |
|---|---|---|
| G | first line, known sections in order, no duplicates, `Purpose` and `Requirements` present, file length (warn) | `max_file_lines` |
| P | Purpose sentence budget | `max_purpose_sentences` |
| R | header shape, one normative sentence, one SHALL/MUST, SHOULD/MAY (warn), EARS shape, word budget, one token per capability, unique ids | `ears`, `max_norm_words` |
| S | scenario header and bullets, test ref (warn), a WHEN and a THEN, scenario count (warn) | `max_scenarios` |
| L | invariant, non-goal, and change-log line shapes | |
| W | banned words (error), weak verbs (warn) | `banned`, `flagged` |

`ears` is `strict` (a shape violation fails), `warn`, or `off`; the default is `strict`. It governs
the shape check only. The one-modal rule holds at every setting: RFC-2119 is the floor that
OpenSpec and the 29148 lineage share, and the EARS shape is the stricter, less-travelled choice on
top of it. The knob exists so a repo can ablate that choice, not so a sentence can argue with it.

## Slicing contract

The grammar guarantees addressability: a slice recipe is (capabilities, ids, sections, scenarios
on or off), and one recipe resolves to the same bytes every time, sorted by capability then id.
Spec-aware slicing beside `doc-slicer` is on the [roadmap](../docs/roadmap.md).
