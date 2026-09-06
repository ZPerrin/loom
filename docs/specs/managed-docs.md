---
kind: spec
status: living
updated: 2026-09-06
---
# Capability: managed-docs

## Purpose
managed-docs is how loom knows which markdown files in a repo it looks after and keeps them mechanically clean. Membership comes from frontmatter, hygiene comes from doc-linter, and a document whose kind carries a grammar is graded against that grammar as well. Every check reads the repo and writes nothing; only a stamp the owner asked for changes a file.

## Invariants
- INV-1: Every script runs on bash 3.2 and POSIX awk with no other dependency.
- INV-2: The managed set is discovered from the working tree on every run and never from an index file.
- INV-3: A warning prints and never changes a run's exit status.
- INV-4: Hygiene checks read documents and never write them.

## Requirements
### R-DOCS-001: A document is managed by its frontmatter kind
WHEN a markdown file's frontmatter block carries a kind key, the system SHALL include the file in the managed set.
#### Scenario: managed-by-kind -> tests/test-discover.sh#frontmatter-less
- GIVEN a.md and sub/c.md with kind frontmatter and b.md with none
- WHEN managed_docs lists the repo
- THEN a.md and sub/c.md are listed
- AND b.md is not
#### Scenario: kind-from-frontmatter -> tests/test-discover.sh#frontmatter_field
- GIVEN a.md with kind: readme in its frontmatter
- WHEN the kind is read
- THEN it is readme

### R-DOCS-002: The universe is the working tree's markdown
The system SHALL take the universe from the working tree's markdown files with gitignored files and symbolic links left out.
#### Scenario: git-universe -> tests/test-discover.sh#untracked.md
- GIVEN a committed doc, an untracked doc, and a gitignored doc
- WHEN doc_universe lists the repo
- THEN the committed and untracked docs are listed
- AND the gitignored doc is not
#### Scenario: symlink-skipped -> tests/test-discover.sh#link.md
- GIVEN link.md pointing at a.md
- WHEN doc_universe lists the repo
- THEN a.md is listed
- AND link.md is not
#### Scenario: no-git-fallback -> tests/test-discover.sh#no-git-fallback
- WHEN doc_universe lists a directory that is not a git checkout
- THEN its markdown files are still found

### R-DOCS-003: Exclusion prefixes narrow the universe
WHERE [discovery].exclude names path prefixes, the system SHALL omit every universe path equal to a prefix or beneath it.
#### Scenario: excluded-subtree -> tests/test-discover.sh#exclude
- GIVEN exclude = ["sub"] in .loom/loom.toml
- WHEN managed_docs lists the repo
- THEN sub/c.md is not listed
- AND a.md still is
#### Scenario: excluded-from-lint -> tests/test-doc-linter.sh#ignored.md
- GIVEN docs/archive excluded and a doc with bad frontmatter beneath it
- WHEN doc-linter runs
- THEN no finding names that doc

### R-DOCS-004: Frontmatter-less markdown is a candidate
WHEN a universe file has no frontmatter kind key, the system SHALL list it as a candidate and not as managed.
#### Scenario: candidate-listed -> tests/test-discover.sh#candidates
- GIVEN b.md with no frontmatter
- WHEN omission_candidates lists the repo
- THEN b.md is listed
- AND a.md is not
#### Scenario: doc-scan-report -> tests/test-doc-scan.sh#doc-scan-report
- WHEN doc-scan runs in a repo
- THEN the managed docs and the candidates are listed apart

### R-DOCS-005: Stamping writes lifecycle fields and touches nothing else
WHEN doc-stamp sets lifecycle fields on a file, the system SHALL write them into its frontmatter and change nothing else.
#### Scenario: stamp-bare -> tests/test-doc-stamp.sh#stamp-bare
- GIVEN a file with no frontmatter
- WHEN doc-stamp sets kind, status, and updated
- THEN the file gains a frontmatter block holding those three keys
- AND its content is unchanged
#### Scenario: stamp-existing -> tests/test-doc-stamp.sh#stamp-existing
- GIVEN frontmatter holding kind and status and no updated key
- WHEN doc-stamp sets status and updated
- THEN status carries the new value and updated is added
- AND every other line is unchanged
#### Scenario: stamp-twice -> tests/test-doc-stamp.sh#stamp-twice
- GIVEN a file stamped once
- WHEN the same doc-stamp command runs again
- THEN the file is unchanged

### R-DOCS-006: A relative link must resolve
WHEN a managed document links to a relative path that does not exist, the system SHALL report BROKEN naming the document and the path.
#### Scenario: broken-link -> tests/test-doc-linter.sh#nope/missing.md
- GIVEN a README linking to nope/missing.md
- WHEN doc-linter runs
- THEN it reports BROKEN naming nope/missing.md
#### Scenario: skipped-links -> tests/test-doc-linter.sh#skipped-links
- GIVEN an external link, a link that is only a fragment, and a link inside a fenced code block
- WHEN doc-linter runs
- THEN none of them is reported

### R-DOCS-007: Link text is plain and listed paths are links
WHEN link text sits in backticks or a list item names an existing path in backticks with no link, the system SHALL report CODELINK or MISSING naming it.
#### Scenario: code-link -> tests/test-doc-linter.sh#CODELINK
- GIVEN a link whose text is run in backticks
- WHEN doc-linter runs
- THEN it reports CODELINK for that link
#### Scenario: unlinked-path -> tests/test-doc-linter.sh#MISSING
- GIVEN a list item naming mod/README.md in backticks followed by an em dash and no link
- WHEN doc-linter runs
- THEN it reports MISSING naming mod/README.md
- AND a listed path that is gitignored or absent produces no finding

### R-DOCS-008: Frontmatter values are vocabulary-checked
WHEN a managed document's kind or status is outside the configured vocabulary or its updated value is not an ISO date, the system SHALL report FRONTMATTER naming the value.
#### Scenario: bad-kind -> tests/test-doc-linter.sh#spaced-dir
- GIVEN a README with kind: bogus
- WHEN doc-linter runs
- THEN it reports FRONTMATTER for that document naming kind=bogus
#### Scenario: bad-status -> tests/test-doc-linter.sh#status=frozen
- GIVEN a doc with status: frozen and a vocabulary without frozen
- WHEN doc-linter runs
- THEN it reports FRONTMATTER naming status=frozen
#### Scenario: bad-date -> tests/test-doc-linter.sh#updated=2026-9-6
- GIVEN a doc whose updated value is not YYYY-MM-DD
- WHEN doc-linter runs
- THEN it reports FRONTMATTER naming the value

### R-DOCS-009: The vocabulary comes from the lint section with shipped defaults
The system SHALL check kind and status against [lint] kinds and statuses when set and against the shipped lists otherwise.
#### Scenario: configured-vocab -> tests/test-doc-linter.sh#kind=playbook
- GIVEN [lint] kinds = ["readme", "playbook"] and a doc with kind: playbook
- WHEN doc-linter runs
- THEN it reports clean
- AND with kinds = ["readme"] it reports FRONTMATTER naming kind=playbook
#### Scenario: missing-vocab -> tests/test-doc-linter.sh#lint-config-repo
- GIVEN .loom/loom.toml with no [lint] section
- WHEN doc-linter runs
- THEN no LINT finding is reported and the shipped vocabulary applies
- AND a readme with status living is not reported
#### Scenario: no-config -> tests/test-doc-linter.sh#no-loom-toml
- GIVEN no .loom/loom.toml at all
- WHEN doc-linter runs
- THEN values are checked against the shipped lists with no LINT finding

### R-DOCS-010: A loom-config document sits where its skill looks
WHEN a document of kind loom-config lies outside .loom/ or its basename is not a plugin skill, the system SHALL report PLACEMENT naming the document.
#### Scenario: misplaced-override -> tests/test-doc-linter.sh#outside
- GIVEN docs/loom-overrides/weave.md with kind: loom-config
- WHEN doc-linter runs
- THEN it reports PLACEMENT saying the document is outside .loom/
#### Scenario: unknown-skill -> tests/test-doc-linter.sh#non-skill
- GIVEN .loom/notaskill.md with kind: loom-config
- WHEN doc-linter runs
- THEN it reports PLACEMENT saying no skill is named notaskill

### R-DOCS-011: The run's verdict is its exit status
WHEN a run ends, the system SHALL exit 0 with a clean line if no error finding exists and exit 1 otherwise, warnings never changing the verdict.
#### Scenario: clean-repo -> tests/test-doc-linter.sh#repo-clean
- GIVEN managed docs with valid frontmatter, no links, and a correctly placed override
- WHEN doc-linter runs
- THEN it prints doc-linter: clean and exits 0
#### Scenario: prose-is-not-checked -> tests/test-doc-linter.sh#meta-repo
- GIVEN a README whose prose mentions the doc convention and the plugin
- WHEN doc-linter runs
- THEN it prints doc-linter: clean and exits 0
#### Scenario: dirty-repo -> tests/test-doc-linter.sh#repo-dirty
- GIVEN a repo with link, frontmatter, and placement findings
- WHEN doc-linter runs
- THEN every finding is printed and it exits 1
#### Scenario: warnings-only -> tests/test-lint-spec.sh#spec-repo-ears
- GIVEN a repo whose only finding is a SPECWARN
- WHEN doc-linter runs
- THEN the SPECWARN line is printed
- AND it exits 0

### R-DOCS-012: Link checks run ahead of adoption
WHEN doc-linter runs with --links, the system SHALL run only the link checks over the named files or the whole universe with no frontmatter required.
#### Scenario: links-mode -> tests/test-doc-linter.sh#links-mode
- GIVEN a markdown file with no frontmatter and a broken relative link
- WHEN doc-linter --links names that file
- THEN it reports BROKEN for the link
- AND a run with no link finding prints doc-linter --links: clean
#### Scenario: links-missing-file -> tests/test-doc-linter.sh#links-missing-file
- WHEN doc-linter --links names a path that does not exist
- THEN it reports INPUT naming the path
- AND exits 1

### R-DOCS-013: Spec documents are graded against the grammar
WHEN a managed document's kind is spec, the system SHALL grade it against the spec grammar and report each finding as SPEC or SPECWARN by severity.
#### Scenario: spec-dispatch -> tests/test-lint-spec.sh#spec-repo
- GIVEN a repo whose spec docs each carry one grammar violation
- WHEN doc-linter runs
- THEN it prints a SPEC line naming each rule

### R-DOCS-014: A spec document keeps the skeleton
WHEN a spec document breaks the skeleton in its first line or its sections, the system SHALL report the matching G rule at that line.
#### Scenario: bad-first-line -> tests/test-lint-spec.sh#G001
- GIVEN a first content line reading Demo capability or Delta: demo
- WHEN doc-linter runs
- THEN it reports SPEC G001 at that line
#### Scenario: unknown-section -> tests/test-lint-spec.sh#g002-unknown-section.md
- GIVEN a ## Background heading
- WHEN doc-linter runs
- THEN it reports SPEC G002 at that heading
#### Scenario: out-of-order -> tests/test-lint-spec.sh#g003-out-of-order.md
- GIVEN ## Purpose after ## Requirements
- WHEN doc-linter runs
- THEN it reports SPEC G003 at the out-of-place heading
#### Scenario: duplicate-section -> tests/test-lint-spec.sh#g004-duplicate-section.md
- GIVEN two ## Purpose headings
- WHEN doc-linter runs
- THEN it reports SPEC G004 at the second
#### Scenario: missing-required -> tests/test-lint-spec.sh#g006-missing-purpose.md
- GIVEN a document without ## Purpose
- WHEN doc-linter runs
- THEN it reports SPEC G006 at the first content line
- AND a document without ## Requirements is reported the same way
#### Scenario: over-length -> tests/test-lint-spec.sh#spec-repo-overlength
- GIVEN more lines than max_file_lines
- WHEN doc-linter runs
- THEN it reports SPECWARN G005 at the last line

### R-DOCS-015: Purpose stays within its sentence budget
WHEN a spec document's Purpose exceeds max_purpose_sentences sentences, the system SHALL report P001 at the section's first body line.
#### Scenario: purpose-too-long -> tests/test-lint-spec.sh#p001-purpose-too-long.md
- GIVEN a Purpose of four sentences at the default budget of three
- WHEN doc-linter runs
- THEN it reports SPEC P001 at the first body line

### R-DOCS-016: Requirement ids are well-formed, single-token, and unique
WHEN a requirement header breaks the id shape or a document mixes tokens or repeats an id, the system SHALL report R001 or R009 or R010 at that line.
#### Scenario: bad-requirement-header -> tests/test-lint-spec.sh#r001-bad-requirement-header.md
- GIVEN a ### Example behavior without an ID header
- WHEN doc-linter runs
- THEN it reports SPEC R001 at that header
#### Scenario: mixed-tokens -> tests/test-lint-spec.sh#r009-mixed-tokens.md
- GIVEN requirements R-DEMO-001 and R-OTHER-001 in one document
- WHEN doc-linter runs
- THEN it reports SPEC R009 naming both tokens
#### Scenario: duplicate-id -> tests/test-lint-spec.sh#r010-duplicate-requirement-id.md
- GIVEN two ### R-DEMO-001 headers
- WHEN doc-linter runs
- THEN it reports SPEC R010 at the second naming the first's line

### R-DOCS-017: Each requirement carries one normative sentence
WHEN a requirement's body before its first scenario is empty or longer than one line, the system SHALL report R002 or R006 at that requirement.
#### Scenario: missing-normative -> tests/test-lint-spec.sh#r002-missing-normative.md
- GIVEN a header followed directly by a #### Scenario line
- WHEN doc-linter runs
- THEN it reports SPEC R002 at the header
#### Scenario: extra-body-line -> tests/test-lint-spec.sh#r006-extra-body-line.md
- GIVEN a second body line before any scenario
- WHEN doc-linter runs
- THEN it reports SPEC R006 at the second line

### R-DOCS-018: The normative sentence fits the EARS shape with one binding modal
WHEN a normative sentence breaks the EARS shape or the one-modal rule or the word budget, the system SHALL report the matching R rule at that line.
#### Scenario: bad-ears-strict -> tests/test-lint-spec.sh#r003-bad-ears-shape.md
- GIVEN a sentence with no EARS clause at the default ears=strict
- WHEN doc-linter runs
- THEN it reports SPEC R003 at that line
#### Scenario: bad-ears-warn -> tests/test-lint-spec.sh#spec-repo-ears
- GIVEN the same sentence under [lint.specs] ears = "warn"
- WHEN doc-linter runs
- THEN it reports SPECWARN R003 and exits 0
#### Scenario: bad-ears-off -> tests/test-lint-spec.sh#ears=off
- GIVEN the same sentence checked with ears=off
- WHEN the checker runs
- THEN it reports no R003
#### Scenario: two-modals -> tests/test-lint-spec.sh#r004-two-modals.md
- GIVEN a sentence holding both SHALL and MUST
- WHEN doc-linter runs
- THEN it reports SPEC R004 at that line
#### Scenario: should-may -> tests/test-lint-spec.sh#r005-should-may.md
- GIVEN a sentence holding MAY
- WHEN doc-linter runs
- THEN it reports SPECWARN R005 at that line
#### Scenario: over-budget -> tests/test-lint-spec.sh#r008-normative-too-long.md
- GIVEN a sentence of more than 30 words at the default budget
- WHEN doc-linter runs
- THEN it reports SPEC R008 at that line
#### Scenario: tuned-budget -> tests/test-lint-spec.sh#TUNED_MNW
- GIVEN a 23-word sentence
- WHEN the checker runs at max_norm_words=30 and again at max_norm_words=12
- THEN the first run is clean
- AND the second reports R008

### R-DOCS-019: Scenarios keep their shape and name a test
WHEN a scenario departs from the scenario shape or the scenario rules, the system SHALL report the matching S rule at that line.
#### Scenario: bad-scenario-header -> tests/test-lint-spec.sh#s001-bad-scenario-header.md
- GIVEN a #### Not a scenario header line
- WHEN doc-linter runs
- THEN it reports SPEC S001 at that line
#### Scenario: bad-bullet -> tests/test-lint-spec.sh#s001-bad-bullet-keyword.md
- GIVEN a bullet opening with none of GIVEN, WHEN, THEN, or AND
- WHEN doc-linter runs
- THEN it reports SPEC S001 at that bullet
#### Scenario: bullet-opens-with-and -> tests/test-lint-spec.sh#s001-bad-bullet-opens-with-and.md
- GIVEN a scenario whose first bullet is AND
- WHEN doc-linter runs
- THEN it reports SPEC S001 at that bullet
#### Scenario: no-test-ref -> tests/test-lint-spec.sh#s002-no-test-ref.md
- GIVEN a scenario header with no -> test_ref part
- WHEN doc-linter runs
- THEN it reports SPECWARN S002 at that header
#### Scenario: missing-when-then -> tests/test-lint-spec.sh#s003-missing-when-then.md
- GIVEN a scenario with only GIVEN and AND bullets
- WHEN doc-linter runs
- THEN it reports SPEC S003 at the scenario header
#### Scenario: too-many-scenarios -> tests/test-lint-spec.sh#s004-too-many-scenarios.md
- GIVEN nine scenarios under one requirement at the default max_scenarios of eight
- WHEN doc-linter runs
- THEN it reports SPECWARN S004 at the requirement header

### R-DOCS-020: Invariant, non-goal, and change-log lines keep their shape
WHEN a line under Invariants or Non-goals or Change log departs from that section's line shape, the system SHALL report L001 at that line.
#### Scenario: bad-invariant -> tests/test-lint-spec.sh#l001-bad-invariant-shape.md
- GIVEN an Invariants line with no colon after the id
- WHEN doc-linter runs
- THEN it reports SPEC L001 at that line
#### Scenario: bad-nongoal -> tests/test-lint-spec.sh#l001-bad-nongoal-shape.md
- GIVEN a Non-goals line with no colon after the id
- WHEN doc-linter runs
- THEN it reports SPEC L001 at that line
#### Scenario: bad-changelog -> tests/test-lint-spec.sh#l001-bad-changelog-line.md
- GIVEN a Change log line with no leading date and id
- WHEN doc-linter runs
- THEN it reports SPEC L001 at that line

### R-DOCS-021: Word lists are enforced on checked lines
WHEN a checked spec line contains a word from the banned or flagged list, the system SHALL report W001 or W002 naming the word at that line.
#### Scenario: banned-word -> tests/test-lint-spec.sh#w001-banned-word.md
- GIVEN a Purpose sentence holding a banned adjective
- WHEN doc-linter runs
- THEN it reports SPEC W001 naming the word at that line
- AND the same check covers requirement titles, normative sentences, invariant and non-goal lines, and scenario bullets
#### Scenario: flagged-word -> tests/test-lint-spec.sh#w002-flagged-word.md
- GIVEN an Invariants line holding a flagged verb
- WHEN doc-linter runs
- THEN it reports SPECWARN W002 naming the verb at that line
- AND Purpose text, requirement titles, and scenario bullets are not checked for flagged words
#### Scenario: custom-lists -> tests/test-lint-spec.sh#spec-repo-wordlists
- GIVEN [lint.specs] banned = ["widget-flow"] and flagged = ["juggle"] and lines holding each word
- WHEN doc-linter runs
- THEN it reports SPEC W001 naming widget-flow and SPECWARN W002 naming juggle

### R-DOCS-022: Invalid spec lint knobs are reported and fall back
WHEN a [lint.specs] key holds an invalid value, the system SHALL report LINT naming the key and run the checker at the shipped default.
#### Scenario: ears-invalid -> tests/test-lint-spec.sh#spec-repo-badears
- GIVEN [lint.specs] ears = "loud"
- WHEN doc-linter runs
- THEN it reports LINT reading ears=loud not strict|warn|off and exits 1
#### Scenario: budget-invalid-falls-back -> tests/test-lint-spec.sh#spec-repo-badbudget
- GIVEN [lint.specs] max_norm_words = 0 and a 26-word normative sentence
- WHEN doc-linter runs
- THEN it reports LINT reading max_norm_words=0 not a positive integer
- AND reports no R008 for the sentence

### R-DOCS-023: A conforming document yields no finding
WHEN a spec document satisfies every grammar rule, the system SHALL report no SPEC or SPECWARN line for it.
#### Scenario: conforming-fixture -> tests/test-lint-spec.sh#auth-session.md
- GIVEN the conforming fixture auth-session.md at the shipped budgets
- WHEN doc-linter runs over the spec-repo fixture
- THEN no lint line names auth-session.md

### R-DOCS-024: Invariant and non-goal ids are unique
WHEN a document repeats an INV or N id, the system SHALL report R010 at the second line naming the first.
#### Scenario: duplicate-inv-id -> tests/test-lint-spec.sh#r010-duplicate-inv-id.md
- GIVEN two INV-1 lines under Invariants
- WHEN doc-linter runs
- THEN it reports SPEC R010 at the second line

### R-DOCS-025: Findings are available as JSON
WHERE the spec checker runs with json set, the system SHALL emit each finding as one JSON object carrying file, severity, rule, line, and id.
#### Scenario: json-findings -> tests/test-lint-spec.sh#json=1
- GIVEN a spec with one S002 warning
- WHEN the checker runs with json set
- THEN one JSON object is emitted carrying the file, severity, rule, line, and id

## Non-goals
- N-1: The config grammar, its shipped defaults, the sections only skills read, and each consumer's behavior on an unparseable config belong to control-plane.
- N-2: Session slices and the on-demand header query belong to context.
- N-3: Hook execution and the executable-form check on hook values belong to hooks.
- N-4: Editorial judgment on prose is weft's pass and never a check here.
- N-5: Which documents a repo adopts, excludes, or seeds is dress's decision; this capability lists and grades what it finds.

## Change log
- 2026-09-05 R-DOCS-016: the grammar says INV-n and N-n ids follow the same uniqueness law; the checker tests only R ids -> open
- 2026-09-05 R-DOCS-022: an invalid [lint.specs] budget reports LINT yet still reaches the checker, where a non-numeric value disables that budget and a zero, negative, or partly numeric one trips it on every sentence -> open
- 2026-09-05 R-DOCS-023: the test table lists auth-session.md as clean but the loop skips clean rows, so no assertion covers this scenario -> open
- 2026-09-05 R-DOCS-016: INV and N uniqueness is now checked under R-DOCS-024 -> edited
- 2026-09-05 R-DOCS-022: an invalid value reports LINT and the checker runs at the shipped default; work spec 2026-09-05-managed-docs landed -> edited
- 2026-09-05 R-DOCS-023: the spec-repo loop asserts clean rows, so the scenario's test now asserts it -> edited
- 2026-09-06 R-DOCS-007: the MISSING check tests that a path exists and is not ignored, never that git tracks it, so tracked left the sentence -> edited
- 2026-09-06 R-DOCS-009: the missing-vocab scenario asserted two LINT findings that INV-2 of control-plane forbids; the linter now takes the shipped vocabulary silently and the scenario says so -> edited
- 2026-09-06 R-DOCS-019: the bad-bullet ref matched two fixture rows; each fixture now has its own scenario -> edited
- 2026-09-06 R-DOCS-020: the Non-goals half of the line-shape rule had no fixture -> asserted
- 2026-09-06 R-DOCS-025: the checker's json output had no requirement and no test -> edited
- 2026-09-06 N-2: the neighbors are named context and hooks, as their specs are; N-3 the same -> edited
