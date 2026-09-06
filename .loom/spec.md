---
kind: loom-config
status: living
updated: 2026-09-06
---
# Spec

## Capabilities

A capability is cut at the 20,000-foot view: a script may serve several, a feature may span
several, and the rules a feature enforces are its scenarios. The token is one word in capitals.
Each spec's Purpose says what the owner gets and its Non-goals name the neighbors; the six skills
are prose and get specs once a run can be graded.

A knob's validation lives with the capability whose code reads it; knobs only skills read belong
to control-plane. A spec absorbed within this repo is deleted, not superseded; `superseded` is
for ids that other repos or tests still name. A ruling the owner gives in the fence counts as the
owner typing it, and the report says which lines were transcribed.

## Test refs

Tests are bash scripts with assertion labels and table-driven fixtures. A test ref is
`tests/<file>#<fragment>`, where the fragment is a fixture stem or another whitespace-free string
that `grep -F` finds in that file. A ref that greps to nothing is a broken ref; a ref that greps to
a table row is resolved only if a loop asserts the rule on a line naming that fixture. A scenario
asserted in more than one file names one file and reuses its fragment as the label in the others. A
fragment that matches more than one fixture stem names none of them; name one stem exactly.
