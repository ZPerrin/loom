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
  key). It enumerates no files or modules. A `[discovery] exclude` list keeps chosen trees
  (e.g. `tests/fixtures`) out of the managed set.
- **Links are routing:** one home per fact, surfaced by progressive disclosure (root map →
  deeper doc → code).

The design specs and plans under `docs/superpowers/`, and the skill `SKILL.md` files (whose
frontmatter carries no `kind`), are intentionally unmanaged scaffolding — discovery surfaces
them as candidates rather than treating them as durable docs.
