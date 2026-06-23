# loom

A self-maintaining **docs & context harness**. The aim: keep a repo's documentation —
and therefore the agent's working context — high-quality *almost autonomously*.

This is a **scratch / experimental** extraction of the doc harness grown in the `jack`
repo. Nothing here is settled. It exists so the harness can be installed, iterated on, and
eventually grow into its real home.

## The idea (working notes, not doctrine)

Docs are *routing, not a log* — one home per fact, surfaced by progressive disclosure
(root map → module README → deep doc → code). A SessionStart hook stitches targeted doc
slices into each session's opening context. A small family of skills keeps that layer
honest so it doesn't rot.

## Naming (textile ethos)

The harness is a loom; sessions are woven on it. Vocabulary we're drawing from — some
banked, some aspirational:

| term | what it names | status |
|---|---|---|
| **loom** | the system / this repo | here |
| **warp** | session-*open* bookend — orient before work | not built yet |
| **wrap** | session-*close* — distill work into docs | exists (`skills/wrap`) |
| **weave** | re-weave the whole doc tree | exists (`skills/refine-docs`) |
| **weft** | the per-session context the hook threads in ("Bearings") | exists (hook) |
| **selvage** | the edge that keeps the fabric from unravelling | exists (the linter) |
| **dress** | dressing the loom — first-time scaffold | exists (`skills/init-docs`) |

Skills keep their current literal names for now; the textile terms are direction, not a
rename mandate.

## Try it (local, for iteration)

Claude Code — add this checkout as a local marketplace, then install:

```
/plugin marketplace add /Users/zebulonperrin/IdeaProjects/loom
/plugin install loom@loom-dev
```

Codex — add the local marketplace root, then install:

```
codex plugin marketplace add /Users/zebulonperrin/IdeaProjects/loom
codex plugin install loom
```

See [NOTES.md](NOTES.md) for open questions and known rough edges.
