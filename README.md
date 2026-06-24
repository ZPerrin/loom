---
kind: readme
status: living
updated: 2026-06-23
---
# loom

## Overview

A self-maintaining **docs & context harness**, packaged as a plugin for Claude Code and Codex. Skills (`dress`, `weave`, `weft`, `warp`) keep a repo's documentation — and therefore the agent's working context — high-quality *almost autonomously*; a SessionStart hook stitches targeted doc slices into each session's opening bearings.

This is a **scratch / experimental** extraction of the doc harness grown in the `jack` repo. Nothing here is settled.

## The idea (working notes, not doctrine)

Docs are *routing, not a log* — one home per fact, surfaced by progressive disclosure
(root map → module README → deep doc → code). A SessionStart hook stitches targeted doc
slices into each session's opening context. A small family of skills keeps that layer
honest so it doesn't rot. Per-repo tuning lives in `docs/config/loom.toml`; the runtime
is bash + awk with no external dependencies.

## Naming (textile ethos)

The harness is a loom; sessions are woven on it.

| term | what it names | where |
|---|---|---|
| **loom** | the system / this repo | here |
| **dress** | stand up or re-tune the harness | `skills/dress` |
| **weave** | re-weave the whole doc tree | `skills/weave` |
| **weft** | session-*close* — distill work into docs | `skills/weft` |
| **warp** | session-*open* bookend — orient before work | `skills/warp` (stub) |
| **doc-slicer** | the per-session context the hook threads in ("Bearings") | `hooks/doc-slicer` |
| **doc-linter** | doc hygiene checks (links + frontmatter) | `scripts/doc-linter` |

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
