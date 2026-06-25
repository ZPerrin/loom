---
name: warp
description: Use when opening a unit of work — naming the branch, setting up a worktree, pulling in ticket/PR context so a session boots oriented. The session-open complement to weft. Status — stub; reports that it is not yet implemented.
---

**Status: stub — not yet implemented.** `warp` is the session-*open* bookend, the complement to `/weft` (session close). Where `weft` distills landed work into docs and closes out the branch, `warp` will *open* a unit of work.

Intended scope (deliberately nebulous — warp is likely the first skill that's *mostly* REPO OPINION):

- Name the work and create/checkout the branch under a consistent convention.
- Optionally set up an isolated worktree.
- Pull in ticket / issue / PR context (e.g. GitHub or Jira) so the session boots oriented.

Each of those is a repo's call, so once built `warp` reads `docs/config/loom/warp.md` and is shaped by it — branch convention, worktree policy, ticket source (see [repo-overrides](../../references/repo-overrides.md)). Until then, if invoked, explain that `warp` is a placeholder and point at `/weft` for closing out work and `/dress` for standing up or tuning the harness.
