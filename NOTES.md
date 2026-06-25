# loom — scratch notes

Loose pile of thoughts. Not authoritative. Prune as things settle.

## Open questions

- **warp** — the session-*open* bookend — is still a stub. It's the next real skill.
- **Manifests** — Claude (`.claude-plugin/`) and Codex (`.codex-plugin/` + `.agents/`)
  are hand-maintained. Generate from one core only once it hurts. Watch the Codex
  local-marketplace `source.path: "./"` (may be rejected — confirm at smoke-test).
- **Invisible README frontmatter** — GitHub renders a metadata table atop READMEs.
  Accepted for now; an HTML-comment carrier is a possible future option.

## Status

- Core scripts (parser, discovery, linter, slicer, hook wiring) built and green.
- Membership is discovery (frontmatter with a `kind:` key), not enumeration; one unified
  frontmatter tier. `[discovery] exclude` drops trees from the managed set entirely;
  per-skill REPO OPINION lives in `docs/loom/<skill>.md`.
- Not yet smoke-tested as an installed plugin (Claude + Codex).
