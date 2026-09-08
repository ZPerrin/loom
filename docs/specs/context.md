---
kind: spec
status: living
updated: 2026-09-07
---
# Capability: context

## Purpose
context is how loom gives an agent the right slice of the repo at the right time: the tools, bearings, and the configured sections of every managed doc when a session opens, then one addressable section, or one block of a spec, on demand. Slices are found by discovery and header, so an agent learns the shape of the docs and never their paths. Whoever dispatches pushes a slice and whoever works pulls the next one, which is progressive disclosure made mechanical.

## Invariants
- INV-1: Every script runs on bash 3.2 and POSIX awk with no other dependency.
- INV-2: A session start never fails on loom's account; with no config, no git, no bash, or a broken config the slice emits what it can and exits 0.
- INV-3: A slice is found by discovery and header and never by path, so moving a doc never breaks it.

## Requirements
### R-CONTEXT-001: A session opens with bearings
WHEN a session starts, the system SHALL emit the recent commits as bearings, the count taken from [context].recent_commits.
#### Scenario: bearings -> tests/test-doc-slicer.sh#Bearings
- GIVEN a repo with one commit
- WHEN the session slice runs
- THEN a Bearings heading is emitted with that commit beneath it
#### Scenario: bearings-count -> tests/test-doc-slicer.sh#bearings-count
- GIVEN three commits and recent_commits = 2
- WHEN the session slice runs
- THEN the two newest commits are emitted and the third is not

### R-CONTEXT-002: Configured sections are harvested with provenance
WHEN a session starts, the system SHALL emit every [context].slice_headers section from every managed doc, each annotated with the [context].inject_fields values.
#### Scenario: harvest -> tests/test-doc-slicer.sh#Shipping
- GIVEN slice_headers naming ## Now and ## Module Map across two managed docs
- WHEN the session slice runs
- THEN both sections' bodies are emitted under their headers
#### Scenario: provenance -> tests/test-doc-slicer.sh#path-derived
- GIVEN inject_fields naming kind and location
- WHEN the session slice runs
- THEN each slice is annotated with its doc's kind and its path
- AND location comes from the path, never from frontmatter
#### Scenario: unconfigured-header -> tests/test-doc-slicer.sh#Overview
- GIVEN a managed doc with a ## Overview section not named in slice_headers
- WHEN the session slice runs
- THEN that section is not emitted
#### Scenario: fenced-header -> tests/test-doc-slicer.sh#fenced
- GIVEN a managed doc whose only ## Now line sits inside a fenced code block
- WHEN the session slice runs
- THEN nothing from that doc is emitted under ## Now
- AND a fenced code block inside a harvested section stays in its body

### R-CONTEXT-003: The slice opens with the tools
WHEN a session starts, the system SHALL open with the scripts' directory, one line per script, and the resolved spec and work-state locations.
#### Scenario: preamble -> tests/test-doc-slicer.sh#advertises
- WHEN the session slice runs
- THEN its tools block names the header query and the spec query
#### Scenario: tools-listed -> tests/test-doc-slicer.sh#tools-listed
- WHEN the session slice runs
- THEN the block names the scripts' directory, doc-scan, doc-linter, and doc-stamp
- AND the shipped repo spec, handoff, and report locations
#### Scenario: locations-resolved -> tests/test-doc-slicer.sh#locations-resolved
- GIVEN [specs] repo_dir and [handoffs] dir set and no [reports] section
- WHEN the tools block is emitted
- THEN the configured locations are named as directories with one trailing slash
- AND reports takes its shipped default

### R-CONTEXT-004: One section on demand
WHEN a header is queried, the system SHALL emit that section from every managed doc with its provenance and none of the session dressing.
#### Scenario: exact-header -> tests/test-doc-slicer.sh#exact
- GIVEN a managed doc with a ## Overview section
- WHEN doc-slicer --header "## Overview" runs
- THEN the section body is emitted with its provenance
- AND no bearings or preamble appear
#### Scenario: bare-name -> tests/test-doc-slicer.sh#bare
- WHEN doc-slicer --header Overview runs
- THEN the ## Overview section is emitted

### R-CONTEXT-005: A query narrows by path and says when it misses
WHEN a header query names path filters, the system SHALL keep only docs whose path holds a filter and report a miss with exit 1.
#### Scenario: filter -> tests/test-doc-slicer.sh#filter
- GIVEN the ## Now section in docs/roadmap.md and nowhere else
- WHEN doc-slicer --header "## Now" docs runs
- THEN the section is emitted and the run exits 0
#### Scenario: miss -> tests/test-doc-slicer.sh#miss
- GIVEN no doc under docs with a ## Overview section
- WHEN doc-slicer --header Overview docs runs
- THEN it says no managed doc has the section and exits 1
#### Scenario: several-filters -> tests/test-doc-slicer.sh#OR-match
- GIVEN filters nope and docs, and the ## Now section under docs
- WHEN doc-slicer --header "## Now" nope docs runs
- THEN the section is emitted and the run exits 0

### R-CONTEXT-006: No config means the shipped slice
WHEN no config exists, the system SHALL harvest the shipped header with the shipped count and fields.
#### Scenario: no-config -> tests/test-doc-slicer.sh#slice-noconf
- GIVEN a repo with no .loom directory
- WHEN the session slice runs
- THEN bearings are emitted and the run exits 0
- AND the ## Now body of a managed doc is emitted under the shipped header

### R-CONTEXT-007: The slice is available at every session start
The system SHALL make the session slice available when a session starts, resumes, clears, or compacts, on every harness the plugin ships to.
#### Scenario: harness-hook
- GIVEN the plugin installed on a harness with a session-start hook
- WHEN a session starts, resumes, clears, or compacts
- THEN the slice is injected before the first turn

### R-CONTEXT-008: A query without a header is refused
IF a header query names no header, THEN the system SHALL refuse it and exit 2.
#### Scenario: no-header-name -> tests/test-doc-slicer.sh#missing
- WHEN doc-slicer --header runs with no name
- THEN it exits 2

### R-CONTEXT-009: A spec is found by its capability
WHEN a capability is queried, the system SHALL emit the spec whose first line names it, from every managed spec document that does, with provenance.
#### Scenario: spec-by-capability -> tests/test-doc-slicer.sh#spec-by-capability
- GIVEN a managed spec at an unrelated path whose first line is "# Capability: billing"
- WHEN doc-slicer --spec billing runs
- THEN the document past its frontmatter is emitted with its provenance
- AND no bearings or preamble appear
#### Scenario: spec-decoys -> tests/test-doc-slicer.sh#spec-decoys
- GIVEN a spec document that opens with any other line and a readme that opens with the Capability line
- WHEN doc-slicer --spec billing runs
- THEN neither is emitted
#### Scenario: spec-no-capability -> tests/test-doc-slicer.sh#spec-no-capability
- WHEN doc-slicer --spec names a capability no managed spec opens with
- THEN it says so and exits 1
#### Scenario: spec-usage -> tests/test-doc-slicer.sh#spec-usage
- WHEN doc-slicer --spec runs with no capability
- THEN it exits 2

### R-CONTEXT-010: One block of a spec on demand
WHEN a selector follows the capability, the system SHALL emit only the requirement, invariant, non-goal, section, or id index it names.
#### Scenario: spec-block -> tests/test-doc-slicer.sh#spec-block
- GIVEN a spec with two requirements
- WHEN doc-slicer --spec billing R-BILL-001 runs
- THEN the header, sentence, and scenarios of R-BILL-001 are emitted
- AND nothing of R-BILL-002 or the section after it is
#### Scenario: spec-line -> tests/test-doc-slicer.sh#spec-line
- GIVEN non-goals N-1 and N-10
- WHEN doc-slicer --spec billing N-1 runs
- THEN the N-1 line alone is emitted
#### Scenario: spec-section -> tests/test-doc-slicer.sh#spec-section
- WHEN doc-slicer --spec billing Non-goals runs
- THEN the Non-goals body is emitted and no invariant is
#### Scenario: spec-ids -> tests/test-doc-slicer.sh#spec-ids
- WHEN doc-slicer --spec billing ids runs
- THEN each requirement id and title is emitted on its own line and no scenario text is
#### Scenario: spec-no-block -> tests/test-doc-slicer.sh#spec-no-block
- WHEN the selector names nothing in the spec
- THEN it says so and exits 1
#### Scenario: spec-bytes -> tests/test-doc-slicer.sh#spec-bytes
- WHEN the same query runs twice
- THEN the two outputs are identical

### R-CONTEXT-011: The tools block on demand
WHEN the tools block is queried, the system SHALL emit it alone, with no bearings and no harvested section.
#### Scenario: tools-alone -> tests/test-doc-slicer.sh#tools-alone
- WHEN doc-slicer --tools runs
- THEN the block is emitted naming the scripts' directory
- AND no Bearings heading, harvested section, or slices line appears
#### Scenario: tools-bytes -> tests/test-doc-slicer.sh#tools-bytes
- WHEN doc-slicer --tools runs twice
- THEN the two outputs are identical
#### Scenario: tools-noconf -> tests/test-doc-slicer.sh#tools-noconf
- GIVEN a repo with no .loom directory
- WHEN doc-slicer --tools runs
- THEN the shipped locations are named and the run exits 0

## Non-goals
- N-1: Which documents are managed, and the exclusion knob, belong to managed-docs.
- N-3: What the slice does with a config it cannot parse is control-plane's promise; that it still exits 0 is INV-2.

## Change log
- 2026-09-06 R-CONTEXT-007: Codex loads a plugin's hooks/hooks.json behind its plugin_hooks flag; the release smoke test verifies the slice arrives there, and until then warp pulls it when the opening context lacks one -> open
