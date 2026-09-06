---
kind: spec
status: living
updated: 2026-09-06
---
# Capability: context

## Purpose
context is how loom gives an agent the right slice of the repo at the right time: bearings and the configured sections of every managed doc when a session opens, then one addressable section on demand. Slices are found by discovery and header, so an agent learns the shape of the docs and never their paths. Whoever dispatches pushes a slice and whoever works pulls the next one, which is progressive disclosure made mechanical.

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

### R-CONTEXT-003: The slice names the next ring
WHEN a session starts, the system SHALL tell the agent how to pull one more section on demand.
#### Scenario: preamble -> tests/test-doc-slicer.sh#advertises
- WHEN the session slice runs
- THEN its preamble names the header query

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

## Non-goals
- N-1: Which documents are managed, and the exclusion knob, belong to managed-docs.
- N-2: Slicing a spec by capability, id, or section is item 7 of the 0.2.0 plan and is not promised here.

## Change log
- 2026-09-06 R-CONTEXT-007: both harnesses document the same SessionStart hook loaded from hooks/hooks.json at the plugin root, but a closed Codex issue reported plugin hooks not loading at runtime; verify on Codex at the release smoke test, and until then warp pulls the slice when the opening context lacks one -> open
- 2026-09-06 R-CONTEXT-002: a ## Now inside a fenced code block was harvested as a section, so the reference project's template roadmap opened every session; a fence is body -> edited
- 2026-09-06 R-CONTEXT-001: the fixture had one commit, so the count could not be told from a constant; a three-commit repo with recent_commits = 2 now pins it -> asserted
- 2026-09-06 R-CONTEXT-005: several filters OR-match in code and the sentence says filters; the test passed one -> asserted
- 2026-09-06 R-CONTEXT-006: the no-config fixture had no managed doc, so the shipped header was never shown harvested -> asserted
- 2026-09-06 R-CONTEXT-008: a query with no header name exited 2 in the test and no id named it -> edited
