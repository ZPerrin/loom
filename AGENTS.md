---
kind: readme
status: living
updated: 2026-07-06
---
# AGENTS

loom — a docs & context harness, packaged as a Claude Code + Codex plugin.

## Agentic Guidelines

- The harness runtime is bash 3.2 + awk, no Python/jq/node. Keep it dependency-free.
- Per-repo tuning lives in `.loom/loom.toml`, not in plugin code.
- Per-skill REPO OPINION lives in `.loom/<skill>.md` (`kind: loom-config`); the
  mechanism is documented in [repo-overrides](references/repo-overrides.md).
- Release packaging lives in `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`,
  `.codex-plugin/plugin.json`, and `.agents/plugins/marketplace.json`. Before pushing a release
  branch to the remote, keep the two plugin `version` fields in sync, and keep both marketplace
  `name` fields set to `loom` so the install source stays `loom@loom`.

## Agentic Validation

- Tests: `bash tests/run`.
- Docs: `bash scripts/doc-linter`.
