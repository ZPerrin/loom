---
kind: loom-config
status: living
updated: 2026-09-05
---
# Spec

## Capabilities

A capability is a product feature at the 20,000-foot view, named by what the repo owner gets and
never by a script or a test file: `managed-docs` is every markdown file loom looks after and keeps
clean, across discovery, stamping, and the linter. A script may serve several capabilities and a
capability may span several scripts. Requirements sit at feature grain; the rules a feature
enforces are its scenarios. The token is one word in capitals. A requirement is a promise the feature makes to its users and the code keeps the how: if an equally good implementation would break the line and the owner would take that implementation, the line is a detail and stays in code.

The cut for loom, one repo spec each under `docs/specs/`:

| Capability | What the owner gets | Runtime |
|---|---|---|
| managed-docs | the markdown loom looks after, kept mechanically clean | discover.sh, doc-scan, doc-stamp, doc-linter, lint-spec.awk |
| control-plane | `loom.toml` and `.loom/<skill>.md` as the deterministic surface: grammar, defaults, the sections only skills read | parse-toml.awk, the linter's config checks |
| session-context | bearings and slices at session start and on demand | doc-slicer, hooks.json, run-hook.cmd |
| skill-hooks | a step that earned determinism runs as a repo script | skill-hook, the linter's hook-form check |

The six skills are prose; the README indexes them, and they get specs once a run can be graded.

A knob's validation lives with the capability whose code reads it; knobs only skills read belong
to control-plane. A spec absorbed within this repo is deleted, not superseded; `superseded` is
for ids that other repos or tests still name. A ruling the owner gives in the fence counts as the
owner typing it, and the report says which lines were transcribed.

## Test refs

Tests are bash scripts with assertion labels and table-driven fixtures. A test ref is
`tests/<file>#<fragment>`, where the fragment is a fixture stem or another whitespace-free string that
`grep -F` finds in that file. A ref that greps to nothing is a broken ref; a ref that greps to a
table row is resolved only if a loop asserts that row.
