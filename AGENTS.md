---
kind: reference
status: living
updated: 2026-06-23
---
# AGENTS

loom — a self-maintaining docs & context harness, packaged as a Claude Code + Codex plugin.

## Agentic Guidelines

- The harness runtime is bash 3.2 + awk, no Python/jq/node. Keep it dependency-free.
- Per-repo tuning lives in `docs/config/loom.toml`, not in plugin code.

## Agentic Validation

- Tests: `bash tests/run`.
- Docs: `bash scripts/doc-linter`.
