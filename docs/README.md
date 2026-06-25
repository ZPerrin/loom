---
kind: readme
status: living
updated: 2026-06-24
---
# How loom's docs work

loom is a docs & context harness. Its own docs follow the convention it ships:

- **Membership is discovery, not enumeration.** A doc is loom-managed iff it opens with
  YAML frontmatter carrying a `kind:` key (`status` and `updated` too). loom finds the
  managed set with git (`scripts/doc-scan`) — tracked, staged, and uncommitted markdown,
  with gitignored paths excluded. No registry of paths to maintain.
- **One frontmatter rule for every doc.** READMEs included — there is no separate
  "stamped, frontmatter-free" tier. Freshness lives in the `updated` field.
- **Config drives behavior, not membership.** `docs/loom/loom.toml` carries `[context]`
  (`recent_commits` / `slice_headers` / `inject_fields` for the SessionStart slicer) and
  `[lint]` (`kinds` / `statuses` — the validation vocabulary, and `kinds` is the discovery
  key). It enumerates no files or modules. `[discovery] exclude` keeps chosen trees out of the
  managed set; `[skills] config_dir` locates the per-skill override docs (`kind: loom-config`)
  that carry a repo's own opinions — see [repo-overrides](../references/repo-overrides.md).
- **Links are routing:** one home per fact, surfaced by progressive disclosure (root map →
  deeper doc → code).
