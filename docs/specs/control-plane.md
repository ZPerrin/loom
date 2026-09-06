---
kind: spec
status: living
updated: 2026-09-06
---
# Capability: control-plane

## Purpose
control-plane is how a repo owner molds loom to a workflow: one TOML file of settings loom enforces the same way on every run, plus one opinion file per skill for the guidance that has not yet earned determinism. The config is parsed, validated, and applied by the scripts; the opinion is read by the skills as a floor beneath the config, and its content is never checked. A step observed working the same way graduates from opinion to config or to a hook, so the prose shrinks as the harness hardens.

## Invariants
- INV-1: Every script runs on bash 3.2 and POSIX awk with no other dependency.
- INV-2: An absent config file or an absent section is never an error; loom demands no configuration to run.
- INV-3: .loom/ is loom's one home in a repo, and nothing relocates it.

## Requirements
### R-CONFIG-001: The config is a small TOML subset
The system SHALL read tables, scalars, and single-line arrays from the config and refuse any other construct naming the offending line.
#### Scenario: values-arrive-intact -> tests/test-parse-toml.sh#sample.toml
- GIVEN tables holding an integer, a boolean, and an array whose strings contain spaces
- WHEN the config is parsed
- THEN every value arrives intact and each array element arrives on its own
#### Scenario: unsupported-construct -> tests/test-parse-toml.sh#aot.toml
- GIVEN an array of tables
- WHEN the config is parsed
- THEN the file is refused and the line is named
- AND an inline table or a multiline array is refused the same way

### R-CONFIG-002: The file is read as written
The system SHALL ignore comments outside quoted strings and accept CRLF line endings.
#### Scenario: comments -> tests/test-parse-toml.sh#comments.toml
- GIVEN a trailing comment after an array and a hash inside a quoted value
- WHEN the config is parsed
- THEN the comment is dropped and the quoted hash survives
#### Scenario: crlf -> tests/test-parse-toml.sh#crlf
- GIVEN a config saved with CRLF line endings
- WHEN the config is parsed
- THEN every value arrives intact

### R-CONFIG-003: No config means shipped defaults
WHEN no config file exists, the system SHALL run every consumer on the shipped defaults with no finding.
#### Scenario: session-start-without-config -> tests/test-doc-slicer.sh#slice-noconf
- GIVEN a repo with no .loom directory
- WHEN the session slice runs
- THEN the bearings are emitted and the run exits 0
#### Scenario: lint-without-config -> tests/test-doc-linter.sh#noconf-repo
- GIVEN a repo with no .loom directory
- WHEN doc-linter runs
- THEN documents are checked against the shipped vocabulary with no LINT finding

### R-CONFIG-004: An absent key takes its own default
WHEN a key is absent from a present config, the system SHALL use that key's shipped default and leave every set key in force.
#### Scenario: partial-config -> tests/test-doc-linter.sh#lint-config-repo
- GIVEN a config holding [discovery] and no [lint] section
- WHEN doc-linter runs
- THEN the exclude applies and kind and status are checked against the shipped lists

### R-CONFIG-005: A broken config is refused or ignored whole
IF the config cannot be parsed, THEN the system SHALL refuse the run or run on the shipped defaults and never act on part of the file.
#### Scenario: gate-refuses -> tests/test-doc-linter.sh#gate-refuses
- GIVEN a config holding an inline table
- WHEN doc-linter runs
- THEN it names the bad file and exits 2 without linting
#### Scenario: session-start-degrades -> tests/test-doc-slicer.sh#session-start-degrades
- GIVEN the same config
- WHEN the session slice runs
- THEN it runs on the shipped defaults and exits 0
#### Scenario: no-partial-effect -> tests/test-skill-hook.sh#no-partial-effect
- GIVEN a config whose exclude and hook lines precede the bad line
- WHEN the hook runner and discovery read it
- THEN neither the hook nor the exclude takes effect

### R-CONFIG-006: Locations stay inside the repo
WHEN a [specs] or [plans] location is set, the system SHALL accept only a relative path inside the repo and report LAYOUT otherwise.
#### Scenario: relative-accepted -> tests/test-doc-linter.sh#documentation/specs
- GIVEN repo_dir, work_dir, and dir set to relative paths that need not exist yet
- WHEN doc-linter runs
- THEN no LAYOUT finding is reported
#### Scenario: escaping-rejected -> tests/test-doc-linter.sh#/srv/specs
- GIVEN an absolute repo_dir, a parent-escaping work_dir, and a plans dir with an embedded ..
- WHEN doc-linter runs
- THEN it reports LAYOUT naming each key and value and exits 1

### R-CONFIG-007: A present warp section is whole
WHEN a [warp] section is present, the system SHALL require branch_convention, source_repo, and a worktree value from its set and report WARP otherwise.
#### Scenario: valid-warp -> tests/test-doc-linter.sh#warp-repo
- GIVEN branch_convention, source_repo, and worktree = "never"
- WHEN doc-linter runs
- THEN no WARP finding is reported
#### Scenario: missing-knob -> tests/test-doc-linter.sh#worktree
- GIVEN a [warp] section without worktree
- WHEN doc-linter runs
- THEN it reports WARP naming worktree and exits 1
#### Scenario: invalid-value -> tests/test-doc-linter.sh#sometimes
- GIVEN worktree = "sometimes"
- WHEN doc-linter runs
- THEN it reports WARP naming the value
#### Scenario: absent-section -> tests/test-doc-linter.sh#warp-repo
- GIVEN no [warp] section
- WHEN doc-linter runs
- THEN no WARP finding is reported and the run exits 0

### R-CONFIG-008: A present weave section is whole
WHEN a [weave] section is present, the system SHALL require a cleanup value from its set and accept an optional rsi value from its set, reporting WEAVE otherwise.
#### Scenario: valid-weave -> tests/test-doc-linter.sh#weave-repo
- GIVEN cleanup = "always"
- WHEN doc-linter runs
- THEN no WEAVE finding is reported
#### Scenario: empty-section -> tests/test-doc-linter.sh#cleanup
- GIVEN a [weave] section with no keys
- WHEN doc-linter runs
- THEN it reports WEAVE naming cleanup and exits 1
#### Scenario: invalid-cleanup -> tests/test-doc-linter.sh#sometimes
- GIVEN cleanup = "sometimes"
- WHEN doc-linter runs
- THEN it reports WEAVE naming the value
#### Scenario: invalid-rsi -> tests/test-doc-linter.sh#rsi=sometimes
- GIVEN rsi = "sometimes"
- WHEN doc-linter runs
- THEN it reports WEAVE naming the value

## Non-goals
- N-1: The [discovery], [lint], and [lint.specs] keys belong to managed-docs, and the [context] keys belong to session-context.
- N-2: The scripts_dir key, the hook keys, their executable-form check, and hook execution belong to skill-hooks.
- N-3: What a skill does with its knob values, and the content of its opinion file, is that skill's own prose.
- N-4: Where an opinion file must sit is checked by managed-docs.

## Change log
- 2026-09-05 R-CONFIG-005: the hook runner and discovery act on the lines parsed before the failing line, so a hook ran and an exclude applied from a refused file in a sampled run -> kept
- 2026-09-05 INV-3: the config_dir key was retired; it moved the placement check and nothing else, and could never move the file it lived in -> edited
- 2026-09-06 R-CONFIG-005: the hook runner refuses and discovery ignores a refused config whole, so the promise now holds in code -> kept
