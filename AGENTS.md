---
kind: readme
status: living
updated: 2026-06-26
---
# AGENTS

loom — a self-maintaining docs & context harness, packaged as a Claude Code + Codex plugin.

## Agentic Guidelines

- The harness runtime is bash 3.2 + awk, no Python/jq/node. Keep it dependency-free.
- Per-repo tuning lives in `.loom/loom.toml`, not in plugin code.
- Per-skill REPO OPINION lives in `.loom/<skill>.md` (`kind: loom-config`); the
  mechanism is documented in [repo-overrides](references/repo-overrides.md).
- Release packaging lives in `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`,
  and `.agents/plugins/marketplace.json`. Before pushing a release branch to the remote,
  keep the Claude and Codex plugin `version` fields in sync, and keep the marketplace
  `name` aligned with the install source users should select.

## Agentic Validation

- Tests: `bash tests/run`.
- Docs: `bash scripts/doc-linter`.
