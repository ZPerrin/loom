---
kind: spec
status: living
updated: 2026-09-05
---
# Capability: spec-lint

## Purpose
spec-lint is the set of checks doc-linter runs against every managed document whose frontmatter
names kind: spec. It grades the document's structure, its requirements' shape, its scenarios'
shape, and its word choice against the spec grammar, and it reports each violation as a failing
SPEC error or a printed, non-failing SPECWARN. The [specs] keys tell the spec skill where to
write a document, not where spec-lint looks.

## Requirements
### R-SPECLINT-001: First line names the capability (G001)
WHEN a spec document's first content line does not read '# Capability: <slug>', the system SHALL report finding G001 at that line.
#### Scenario: bad-first-line -> tests/test-lint-spec.sh#docs/specs/g001-bad-first-line.md
- GIVEN a spec document whose first content line reads 'Demo capability'
- WHEN doc-linter lints the document
- THEN it reports SPEC G001 at that line
#### Scenario: legacy-delta-heading -> tests/test-lint-spec.sh#docs/specs/g001-delta-first-line.md
- GIVEN a spec document whose first content line reads 'Delta: demo'
- WHEN doc-linter lints the document
- THEN it reports SPEC G001 at that line

### R-SPECLINT-002: Sections must be known (G002)
WHEN a '##' heading does not name one of the five known sections, the system SHALL report finding G002 at that heading.
#### Scenario: unknown-section -> tests/test-lint-spec.sh#docs/specs/g002-unknown-section.md
- GIVEN a spec document with a '## Background' heading
- WHEN doc-linter lints the document
- THEN it reports SPEC G002 at that heading

### R-SPECLINT-003: Known sections stay in order (G003)
WHEN a known section appears out of the skeleton's fixed order, the system SHALL report finding G003 at that heading.
#### Scenario: out-of-order -> tests/test-lint-spec.sh#docs/specs/g003-out-of-order.md
- GIVEN a spec document whose '## Purpose' heading follows '## Requirements'
- WHEN doc-linter lints the document
- THEN it reports SPEC G003 at the out-of-place heading

### R-SPECLINT-004: No section repeats (G004)
WHEN a section name repeats as a second '##' heading, the system SHALL report finding G004 at the second heading.
#### Scenario: duplicate-purpose -> tests/test-lint-spec.sh#docs/specs/g004-duplicate-section.md
- GIVEN a spec document with two '## Purpose' headings
- WHEN doc-linter lints the document
- THEN it reports SPEC G004 at the second heading

### R-SPECLINT-005: File length budget (G005)
WHEN a spec document's line count exceeds max_file_lines, the system SHALL report finding G005 at the file's last line.
#### Scenario: over-length
- GIVEN a spec document with more lines than the configured max_file_lines
- WHEN doc-linter lints the document
- THEN it reports SPECWARN G005 at the file's last line

### R-SPECLINT-006: Purpose and Requirements are required (G006)
WHEN a spec document omits its Purpose section or its Requirements section, the system SHALL report finding G006 at the document's first content line.
#### Scenario: missing-purpose -> tests/test-lint-spec.sh#docs/specs/g006-missing-purpose.md
- GIVEN a spec document with a '## Requirements' section and no '## Purpose' section
- WHEN doc-linter lints the document
- THEN it reports SPEC G006 at the document's first content line
#### Scenario: missing-requirements
- GIVEN a spec document with a '## Purpose' section and no '## Requirements' section
- WHEN doc-linter lints the document
- THEN it reports SPEC G006 at the document's first content line

### R-SPECLINT-007: Purpose sentence budget (P001)
WHEN the Purpose section's text exceeds max_purpose_sentences sentences, the system SHALL report finding P001 at the section's first body line.
#### Scenario: purpose-too-long -> tests/test-lint-spec.sh#docs/specs/p001-purpose-too-long.md
- GIVEN a Purpose section with four sentences and a default budget of three
- WHEN doc-linter lints the document
- THEN it reports SPEC P001 at the section's first body line

### R-SPECLINT-008: Requirement header names a token and a number (R001)
WHEN a '###' requirement header does not read '### R-<TOKEN>-<NNN>: <Title>' with a two-to-eight-character TOKEN, the system SHALL report finding R001 at that header.
#### Scenario: bad-requirement-header -> tests/test-lint-spec.sh#docs/specs/r001-bad-requirement-header.md
- GIVEN a '### Example behavior without an ID' header
- WHEN doc-linter lints the document
- THEN it reports SPEC R001 at that header

### R-SPECLINT-009: A requirement needs a normative sentence (R002)
WHEN a requirement's body has no line before its first scenario, the system SHALL report finding R002 at the requirement header.
#### Scenario: missing-normative -> tests/test-lint-spec.sh#docs/specs/r002-missing-normative.md
- GIVEN a requirement whose header is followed directly by a '#### Scenario' line
- WHEN doc-linter lints the document
- THEN it reports SPEC R002 at the requirement header

### R-SPECLINT-010: EARS clause shape, graded by the ears knob (R003)
WHERE ears is not off, WHEN a normative sentence does not fit the EARS clause shape, the system SHALL report finding R003.
#### Scenario: bad-ears-shape-strict -> tests/test-lint-spec.sh#docs/specs/r003-bad-ears-shape.md
- GIVEN a normative sentence 'Sessions SHALL be invalidated after the configured timeout.' and the default ears=strict
- WHEN doc-linter lints the document
- THEN it reports SPEC R003 at that line
#### Scenario: bad-ears-shape-warn -> tests/test-lint-spec.sh#fixtures/spec-repo-ears
- GIVEN the same shape violation under a repo with [lint.specs] ears=warn
- WHEN doc-linter lints the document
- THEN it reports SPECWARN R003 at that line
- AND the run still exits 0
#### Scenario: bad-ears-shape-off -> tests/test-lint-spec.sh#docs/specs/r003-bad-ears-shape.md
- GIVEN the same shape violation checked directly with ears=off
- WHEN the checker runs
- THEN it reports no R003 finding

### R-SPECLINT-011: Exactly one SHALL or MUST (R004)
WHEN a normative sentence's modal count is not exactly one, the system SHALL report finding R004 at that line.
#### Scenario: two-modals -> tests/test-lint-spec.sh#docs/specs/r004-two-modals.md
- GIVEN a normative sentence with both SHALL and MUST
- WHEN doc-linter lints the document
- THEN it reports SPEC R004 at that line

### R-SPECLINT-012: SHOULD or MAY is non-binding (R005)
WHEN a normative sentence contains a non-binding modal, the system SHALL report finding R005 at that line.
#### Scenario: should-may -> tests/test-lint-spec.sh#docs/specs/r005-should-may.md
- GIVEN a normative sentence 'WHEN a session ends, the system SHALL log the event; administrators MAY review the log.'
- WHEN doc-linter lints the document
- THEN it reports SPECWARN R005 at that line

### R-SPECLINT-013: One normative sentence per requirement (R006)
WHEN a requirement's body has more than one line before its first scenario, the system SHALL report finding R006 at the second line.
#### Scenario: extra-body-line -> tests/test-lint-spec.sh#docs/specs/r006-extra-body-line.md
- GIVEN a requirement whose normative sentence is followed by a second body line before any scenario
- WHEN doc-linter lints the document
- THEN it reports SPEC R006 at the second line

### R-SPECLINT-014: Normative sentence word budget (R008)
WHEN a normative sentence's word count exceeds max_norm_words, the system SHALL report finding R008 at that line.
#### Scenario: over-default-budget -> tests/test-lint-spec.sh#docs/specs/r008-normative-too-long.md
- GIVEN a normative sentence of more than 30 words and the default max_norm_words
- WHEN doc-linter lints the document
- THEN it reports SPEC R008 at that line
#### Scenario: tuned-budget -> tests/test-lint-spec.sh#docs/specs/reset-flow.md
- GIVEN reset-flow.md's 23-word normative sentence
- WHEN doc-linter lints it once at the default max_norm_words=30 and again at a configured max_norm_words=12
- THEN the default run is clean
- AND the tuned run reports SPEC R008 at that line

### R-SPECLINT-015: One token per capability (R009)
WHEN a document's requirements use more than one TOKEN, the system SHALL report finding R009 at the document's first content line.
#### Scenario: mixed-tokens -> tests/test-lint-spec.sh#docs/specs/r009-mixed-tokens.md
- GIVEN a document with requirements R-DEMO-001 and R-OTHER-001
- WHEN doc-linter lints the document
- THEN it reports SPEC R009 naming both tokens

### R-SPECLINT-016: Ids are unique (R010)
WHEN two requirements share one id, the system SHALL report finding R010 at the second header.
#### Scenario: duplicate-id
- GIVEN two '### R-DEMO-001' headers in one document
- WHEN doc-linter lints the document
- THEN it reports SPEC R010 at the second header naming the first header's line

### R-SPECLINT-017: Scenario header and bullet shape (S001)
WHEN a scenario's header or a scenario's bullet line does not fit the scenario shape, the system SHALL report finding S001 at that line.
#### Scenario: bad-scenario-header -> tests/test-lint-spec.sh#docs/specs/s001-bad-scenario-header.md
- GIVEN a '#### Not a scenario header' line
- WHEN doc-linter lints the document
- THEN it reports SPEC S001 at that line
#### Scenario: bad-bullet-prefix
- GIVEN a scenario bullet that opens with neither GIVEN nor WHEN nor THEN nor AND
- WHEN doc-linter lints the document
- THEN it reports SPEC S001 at that bullet
#### Scenario: scenario-opens-with-and
- GIVEN a scenario whose first bullet is an AND line
- WHEN doc-linter lints the document
- THEN it reports SPEC S001 at that bullet

### R-SPECLINT-018: Scenarios should name their test (S002)
WHEN a scenario header has no test_ref, the system SHALL report finding S002 at that header.
#### Scenario: no-test-ref -> tests/test-lint-spec.sh#docs/specs/s002-no-test-ref.md
- GIVEN a '#### Scenario: basic' header with no '-> test_ref' part
- WHEN doc-linter lints the document
- THEN it reports SPECWARN S002 at that header

### R-SPECLINT-019: A scenario needs a WHEN and a THEN (S003)
WHEN a scenario's bullets include no WHEN bullet or no THEN bullet, the system SHALL report finding S003 at the scenario header.
#### Scenario: missing-when-then -> tests/test-lint-spec.sh#docs/specs/s003-missing-when-then.md
- GIVEN a scenario with only GIVEN and AND bullets
- WHEN doc-linter lints the document
- THEN it reports SPEC S003 at the scenario header

### R-SPECLINT-020: Scenario count budget (S004)
WHEN a requirement's scenario count exceeds max_scenarios, the system SHALL report finding S004 at the requirement header.
#### Scenario: too-many-scenarios -> tests/test-lint-spec.sh#docs/specs/s004-too-many-scenarios.md
- GIVEN a requirement with nine scenarios and the default max_scenarios of eight
- WHEN doc-linter lints the document
- THEN it reports SPECWARN S004 at the requirement header

### R-SPECLINT-021: Invariant, non-goal, and change-log line shape (L001)
WHEN a line under Invariants or Non-goals or Change log does not fit that section's line shape, the system SHALL report finding L001 at that line.
#### Scenario: bad-invariant-shape -> tests/test-lint-spec.sh#docs/specs/l001-bad-invariant-shape.md
- GIVEN an Invariants line with no colon after the id
- WHEN doc-linter lints the document
- THEN it reports SPEC L001 at that line
#### Scenario: bad-non-goal-shape
- GIVEN a Non-goals line with no colon after the id
- WHEN doc-linter lints the document
- THEN it reports SPEC L001 at that line
#### Scenario: bad-changelog-shape -> tests/test-lint-spec.sh#docs/specs/l001-bad-changelog-line.md
- GIVEN a Change log line with no leading date and id
- WHEN doc-linter lints the document
- THEN it reports SPEC L001 at that line

### R-SPECLINT-022: Banned words fail the line (W001)
WHEN checked prose contains a banned word, the system SHALL report finding W001 at that line.
#### Scenario: banned-word-in-purpose -> tests/test-lint-spec.sh#docs/specs/w001-banned-word.md
- GIVEN w001-banned-word.md's Purpose sentence, which contains a banned adjective
- WHEN doc-linter lints the document
- THEN it reports SPEC W001 naming the banned word at that line
#### Scenario: banned-word-in-normative-sentence
- GIVEN a normative sentence that contains a banned word
- WHEN doc-linter lints the document
- THEN it reports SPEC W001 naming that word at that line
- AND the same check runs on a requirement title, an invariant line, a non-goal line, and a scenario bullet

### R-SPECLINT-023: Flagged words warn on the line (W002)
WHEN a normative sentence or an invariant line or a non-goal line contains a flagged word, the system SHALL report finding W002 at that line.
#### Scenario: flagged-word-in-invariant -> tests/test-lint-spec.sh#docs/specs/w002-flagged-word.md
- GIVEN w002-flagged-word.md's Invariants line, which contains a flagged verb
- WHEN doc-linter lints the document
- THEN it reports SPECWARN W002 naming that verb at that line
- AND Purpose text, a requirement title, and a scenario bullet are not checked for flagged words

### R-SPECLINT-024: Budget knobs must be positive integers (LINT)
WHEN a configured max_norm_words or max_purpose_sentences or max_scenarios or max_file_lines is not a positive integer, the system SHALL report a LINT finding naming the key.
#### Scenario: budget-key-not-a-positive-integer
- GIVEN '[lint.specs] max_norm_words = "abc"' in loom.toml
- WHEN doc-linter runs
- THEN it reports a LINT finding reading 'max_norm_words=abc not a positive integer'

### R-SPECLINT-025: The ears knob must be strict, warn, or off (LINT)
WHEN a configured ears value is not strict or warn or off, the system SHALL report a LINT finding naming the value and the allowed set.
#### Scenario: ears-invalid-value -> tests/test-lint-spec.sh#fixtures/spec-repo-badears
- GIVEN '[lint.specs] ears = "loud"' in loom.toml
- WHEN doc-linter runs
- THEN it reports a LINT finding reading 'ears=loud not strict|warn|off'
- AND the run exits 1

### R-SPECLINT-026: Custom banned and flagged words extend the built-in lists
WHEN loom.toml lists a word under [lint.specs].banned or [lint.specs].flagged, the system SHALL check spec text for that word under W001 or W002 respectively.
#### Scenario: custom-banned-word
- GIVEN '[lint.specs] banned = ["widget-flow"]' in loom.toml and Purpose text containing 'widget-flow'
- WHEN doc-linter runs
- THEN it reports SPEC W001 naming 'widget-flow' at that line

### R-SPECLINT-027: Error-severity findings become SPEC and fail the run
WHEN any kind: spec finding has error severity, the system SHALL classify it as SPEC and exit the run with status 1.
#### Scenario: spec-repo-fails -> tests/test-lint-spec.sh#fixtures/spec-repo
- GIVEN a repo whose spec documents carry error-severity findings such as G001 or R002
- WHEN doc-linter runs
- THEN each is printed as a SPEC line
- AND the run exits 1

### R-SPECLINT-028: Warn-severity findings become SPECWARN and do not fail the run
WHEN a kind: spec finding has warn severity, the system SHALL classify it as SPECWARN without changing the run's exit status.
#### Scenario: ears-repo-warns-without-failing -> tests/test-lint-spec.sh#fixtures/spec-repo-ears
- GIVEN a repo whose only spec finding is the warn-severity R003 downgrade
- WHEN doc-linter runs
- THEN it prints a SPECWARN line naming R003
- AND the run exits 0

## Non-goals
- N-1: BROKEN/CODELINK/MISSING link checks, FRONTMATTER and PLACEMENT checks, and the non-spec loom.toml section checks (LINT's own [lint] kinds and statuses, LAYOUT, WARP, WEAVE, HOOK) belong to doc-linter's other capabilities.

## Change log
- 2026-09-05 R-SPECLINT-024: an invalid [lint.specs] budget reports a LINT finding yet still reaches the checker, where a non-numeric value disables that budget's check and a zero, negative, or partly numeric one trips it on every sentence -> open
- 2026-09-05 R-SPECLINT-016: the grammar says INV-n and N-n ids follow the same uniqueness law; the checker tests only R ids -> open
