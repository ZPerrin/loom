---
kind: reference
status: living
updated: 2026-07-03
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
- **Determinism over prose.** If determinism can carry it, prose shouldn't — and prose is where
  guidance lives only until it earns determinism. A step observed working the same way graduates
  into a `hook` (a script or command named in `loom.toml`); the prose that described it drops to
  a floor beneath it. Reserve prose for what can't yet execute.
- **No meta-documentation.** A repo doc never takes the doc system as its subject: no harness
  references ("the convention ships with the plugin"), no topology narration ("the WHY lives one
  level up"), no lifecycle mechanics in reader-facing prose. If the harness enforces it, don't
  restate it; if the structure shows it, don't narrate it. Writer-facing policy belongs in
  `<config_dir>/<skill>.md`, read at the moment it applies. A thin doc is healthy — the reflex to
  fill it with system orientation is the tell, and the linter's `meta_denylist` trips on the
  common phrasings.

## Links are routing

One home per fact, surfaced by progressive disclosure: **root map → deeper doc → code.** A link
points at the single home rather than restating it. Treat docs as routing and decision context,
not a running log.

## Nomenclature

Membership is discovery: a doc is loom-managed iff its frontmatter carries a `kind:` key
(`status` and `updated` too). Excluded trees (`[discovery] exclude`) are never managed;
everything else without a `kind:` is a *candidate* until adopted or excluded.

**kind** — what a doc *is*. These are the shipped defaults; a repo adds the kinds it
actually keeps in `loom.toml [lint] kinds` (loom itself adds `roadmap`):

- `readme` — the **front door** of a tree: it orients and routes (the map). Positional, not a
  content flavor — it points at where durable detail lives rather than holding it.
- `reference` — durable, look-it-up facts (this doc): the destination a `readme` routes to.
- `spec` / `plan` — a design or an implementation plan; often transient.
- `design` — design notes / ideation.
- `review` — a directional review.
- `loom-config` — a per-repo skill override at `<config_dir>/<skill>.md`.

**status** — where a doc *is in its life*: `living` (current) · `hardened` (stable, rarely
changes) · `superseded` (replaced, kept for history) · `scaffolding` (temporary support
material) · `ideation` (exploratory, not yet committed).
