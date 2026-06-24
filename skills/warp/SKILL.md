---
name: warp
description: (Planned, not yet implemented) Session-open bookend — kick off a unit of work: name and create the branch, set up a worktree, and wire in any ticket/PR context, so a session starts oriented. The open complement to /weft (the close-out). Invoking it today reports that it is a stub.
---

**Status: stub — not yet implemented.** `warp` is the session-*open* bookend, the complement to `/weft` (session close). Where `weft` distills landed work into docs and closes out the branch, `warp` will *open* a unit of work.

Intended scope (deliberately nebulous; meant to be shaped per-repo by the operator):

- Name the work and create/checkout the branch under a consistent convention.
- Optionally set up an isolated worktree.
- Pull in ticket / issue / PR context (e.g. GitHub or Jira) so the session boots oriented.

If invoked now, explain that `warp` is a placeholder and point at `/weft` for closing out work and `/dress` for standing up or tuning the harness.
