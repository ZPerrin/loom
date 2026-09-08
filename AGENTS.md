---
kind: readme
status: living
updated: 2026-09-06
---
# AGENTS

loom is a toolkit for working with agents: six skills plus the config and state they need,
packaged as a Claude Code and Codex plugin.

See [README.md](README.md)

## Agentic Guidelines

- Approved work accumulates on `release/<major>.<minor>.<patch>`, pushed for cross-machine
  continuity. Promote to the default branch and tag the release only with explicit approval.
- The runtime is bash 3.2 and awk with no other dependency; Windows checkouts enter through
  `scripts/run-hook.cmd`.
- Everything ships to Claude Code and Codex alike; nothing host-specific sits on the critical path.
- [docs/specs](docs/specs/) says what each capability promises, one spec per capability;
  refine-spec reconciles drift.

## Agentic Validation

- Tests: `bash tests/run`.
- Docs: `bash scripts/doc-linter`.
