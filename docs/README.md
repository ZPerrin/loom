---
kind: readme
status: living
updated: 2026-06-23
---
# How loom's docs work

loom is a docs & context harness. Its own docs follow the convention it ships:

- **Membership is discovery, not enumeration.** A doc is loom-managed iff it opens with
  YAML frontmatter carrying a `kind:` key (`status` and `updated` too). loom finds the
  managed set with git (`scripts/doc-scan`) — tracked, staged, and uncommitted markdown,
  with gitignored paths excluded. No registry of paths to maintain.
- **One frontmatter rule for every doc.** READMEs included — there is no separate
  "stamped, frontmatter-free" tier. Freshness lives in the `updated` field.
- **Config drives behavior, not membership.** `docs/config/loom.toml` carries `[context]`
  (`recent_commits` / `slice_headers` / `inject_fields` for the SessionStart slicer) and
  `[lint]` (`kinds` / `statuses` — the validation vocabulary, and `kinds` is the discovery
  key). It enumerates no files or modules. `[discovery]` keeps chosen trees out of the managed
  set (`exclude`) or surfaced-but-unmanaged (`scaffolding`); `[skills] config_dir` locates the
  per-skill override docs (`kind: loom-config`) that carry a repo's own opinions — see
  [repo-overrides](../references/repo-overrides.md).
- **Links are routing:** one home per fact, surfaced by progressive disclosure (root map →
  deeper doc → code).

Markdown that looks like a doc but isn't loom's to manage is *scaffolding*: `doc-scan` surfaces
it under its own heading and the skills never pester about adopting it. loom's own scaffolding
is the design specs/plans under `docs/superpowers/` and the plugin's `skills/`.
