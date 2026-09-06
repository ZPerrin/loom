---
kind: loom-config
status: living
updated: 2026-09-06
---
# Spec

## Capabilities

A capability is a product feature at the 20,000-foot view, named by what the repo owner gets and
never by a script or a test file; a script may serve several, and a feature may span several.
Requirements sit at that altitude: a requirement is a promise the feature makes to the people and
skills that use it, and the code keeps the how. If an equally good implementation would break a
line and the owner would take that implementation, the line is a detail and stays in code. The
rules a feature enforces are its scenarios. The token is one word in capitals.

The managed set is the index: each spec's Purpose says what the owner gets and its Non-goals name
the neighbors. The six skills are prose; the README indexes them, and they get specs once a run
can be graded.

A knob's validation lives with the capability whose code reads it; knobs only skills read belong
to control-plane. A spec absorbed within this repo is deleted, not superseded; `superseded` is
for ids that other repos or tests still name. A ruling the owner gives in the fence counts as the
owner typing it, and the report says which lines were transcribed.

## Test refs

Tests are bash scripts with assertion labels and table-driven fixtures. A test ref is
`tests/<file>#<fragment>`, where the fragment is a fixture stem or another whitespace-free string that
`grep -F` finds in that file. A ref that greps to nothing is a broken ref; a ref that greps to a
table row is resolved only if a loop asserts that row.
