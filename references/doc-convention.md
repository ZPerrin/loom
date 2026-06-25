---
kind: reference
status: living
updated: 2026-06-25
---
# Doc convention — what loom's docs are, and how they read

loom's skills share one editorial standard, kept here in the plugin rather than in any repo. A
repo never restates it; the skills read it from `${CLAUDE_PLUGIN_ROOT}`. The `[lint]` vocabulary
in `loom.toml` lists the allowed `kind`/`status` values; their *meaning* lives here.

## The editorial ethos

- **Documentation is a sign-post for agents and humans alike.** Docs orient; the code is the
  road. Reinforce *progressive disclosure* — a 20,000ft map first, details pulled in only as a
  task needs them.
- **Compression as a craft.** Brevity is the evidence of effort, not its absence. Dense,
  concrete, decision-useful prose — the precise noun and verb over hedging and ornament. A doc
  is done not when nothing more can be added, but when nothing more can be removed without
  losing signal.
- **Right time and place.** A fact lives where a reader would already think to look, and reads
  like it belongs there. No scavenger hunts; no index that goes stale the moment code lands.
- **Editorial before additive.** Prefer pruning, routing, and deleting over appending. No edit
  without durable signal — if nothing durable changed, write nothing.

## Links are routing

One home per fact, surfaced by progressive disclosure: **root map → deeper doc → code.** A link
points at the single home rather than restating it. Treat docs as routing and decision context,
not a running log.

## Nomenclature

Membership is discovery: a doc is loom-managed iff its frontmatter carries a `kind:` key
(`status` and `updated` too). Excluded trees (`[discovery] exclude`) are never managed;
everything else without a `kind:` is a *candidate* until adopted or excluded.

**kind** — what a doc *is*:

- `readme` — an entry point / map for a tree.
- `reference` — durable, look-it-up facts (this doc).
- `guide` — a how-to that walks a task.
- `roadmap` — where the work is headed.
- `spec` / `plan` — a design or an implementation plan; often transient.
- `design` — design notes / ideation.
- `review` — a directional review.
- `loom-config` — a per-repo skill override at `<config_dir>/<skill>.md`.

**status** — where a doc *is in its life*: `living` (current) · `hardened` (stable, rarely
changes) · `superseded` (replaced, kept for history) · `scaffolding` (temporary support
material) · `ideation` (exploratory, not yet committed).
