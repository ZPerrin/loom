# loom — scratch notes

Loose pile of thoughts. Not authoritative. Prune as things settle.

## Open questions

- **Path references.** The skills (and the hook) were written for an in-tree `.claude/`
  layout — they reference `../../../docs/README.md`, `.claude/skills/...`, etc. As an
  *installed* plugin those break. Need to split "harness's own files" (→ `${CLAUDE_PLUGIN_ROOT}`
  / `$PLUGIN_ROOT`) from "target repo's docs" (→ the working cwd). This is the main porting work.
- **One repo, two manifests.** Claude (`.claude-plugin/`) and Codex (`.codex-plugin/`) are
  near-mirrors. Hand-maintain both, or generate them from one shared core? Lean: hand-maintain
  while small; generate once it hurts.
- **Two hooks.json** only because the plugin-root env var differs (`${CLAUDE_PLUGIN_ROOT}`
  vs `$PLUGIN_ROOT`). Otherwise identical. Candidate to collapse later.
- **warp** — the session-*open* bookend of `wrap` — isn't built yet. It's the next real skill.
- **Renaming** to textile terms (selvage/weave/dress/...) is deferred; current literal names
  stay until the vocabulary earns its keep.

## Status

- Skeleton only. Skills copied verbatim from `jack`; expect broken relative links until the
  path-reference pass.
- Marketplace + plugin manifests present for both tools so install can be exercised locally.
