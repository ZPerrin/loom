---
kind: loom-config
status: living
updated: 2026-09-05
---
# Spec

## Capabilities

A capability is what a runtime script does for the repo owner, not the script: `spec-lint` is
the `kind: spec` checks wherever `doc-linter` runs them. The token is the slug in capitals
without the hyphen.

## Test refs

Tests are bash scripts with assertion labels and table-driven fixtures. A test ref is
`tests/<file>#<fragment>`, where the fragment is a fixture stem or a run of label words that
`grep -F` finds in that file. A ref that greps to nothing is a broken ref.
