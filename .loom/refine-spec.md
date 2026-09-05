---
kind: loom-config
status: living
updated: 2026-09-05
---
# Refine spec

## Sampled runs

A run is `bash scripts/doc-linter` over the repo itself, or the awk checker on one fixture file
with its `-v` knobs set as `tests/test-lint-spec.sh` sets them. Both are named in the report by
the question they answered. A sweep of every fixture is the test suite's job, not a sample.
