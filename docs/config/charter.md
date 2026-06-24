---
kind: charter
status: living
updated: 2026-06-23
---
# loom — charter

## What it is

A self-maintaining docs & context harness: a small set of tools that keep a repo's
documentation — and therefore an agent's context — accurate, lean, and navigable, with
little ongoing effort.

## The problem it solves

Keeping a project well-documented is a chore that decays: docs drift from code, the same
fact gets restated in three places, slop accumulates, and every stale line is paid for
again as wasted agent context. Loom wraps that chore. It does **not** try to be a complete
agent workflow system (it is not a superpowers competitor) — it is a focused, personal
harness for the documentation-and-context problem.

## What we believe

- **Docs are routing, not a log.** One home per fact, surfaced by progressive disclosure:
  root map → module README → deep doc → code. Git is the activity log; docs are the map.
- **Discover structure; configure behavior.** Which docs loom manages is *discovered*
  (a doc declares itself by carrying frontmatter), not enumerated in a registry that
  drifts. What loom *does* — what to slice into context, what to enforce — is configured.
- **Context is paid every session.** The SessionStart slice is an always-on tax, so it
  must earn its tokens: slice only what changes the next good action, and keep it visible
  and tunable.
- **Base suggestion plus knobs.** Loom ships sensible defaults and a clear way to tune
  them. When an edge case appears, the answer is a config knob or a frontmatter attribute —
  not a new hardcoded assumption.
- **No edit without durable signal.** Editorial before additive; compression is the craft.
  If nothing durable changed, write nothing.

## The knobs (`docs/config/loom.toml`)

The plugin ships generic code (read-only cache); each repo owns its config. Two tables:

- `[context]` — what the SessionStart hook injects: `recent_commits` (git bearings),
  `slice_headers` (which sections to lift, by header — path-free), `inject_fields`
  (frontmatter to prefix each slice with, e.g. `updated`/`kind`/`location`).
- `[lint]` — the validation vocabulary: `kinds` and `statuses` (the allowed frontmatter
  values). `kinds` is also the discovery key: a doc is managed iff it carries a `kind`.

## The tools (skills)

- **dress** — stand up or re-tune the harness on a repo.
- **weave** — reconcile the whole doc tree against the code.
- **weft** — distill a session's landed work into the durable docs, then optionally close
  out the branch.
- **warp** — session-open bookend (planned; stub).

See [docs/README.md](../README.md) for the doc model and
[the design spec](../superpowers/specs/2026-06-23-loom-discovery-frontmatter-redesign.md)
for the mechanics.
