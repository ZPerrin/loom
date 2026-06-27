---
kind: loom-config
status: living
updated: 2026-06-26
---
# warp — loom's own overrides

Orient before touching the workspace, reading progressively: `docs/roadmap.md` `## Now`
(already injected) → the skill(s) under `skills/` the work touches → their `references/` →
code. loom is flat — the skills, scripts, and hooks are the units; there are no module
READMEs yet.

- **Branch.** Issue-backed work branches off `main` as `issue/<number>-<slug>`; ad-hoc
  local work uses `feature/<slug>`.
- **Worktree.** Default to a worktree one level up at `../loom-worktrees/<branch>` — the
  path mirrors the branch (`issue/<n>-<slug>` or `feature/<slug>`).
- **Working docs (issue-backed work only).** Dated, ephemeral specs land in
  `docs/specs/<YYYY-MM-DD>-<slug>-spec.md` and plans in
  `docs/plans/<YYYY-MM-DD>-<slug>-plan.md`, slug mirroring the branch, carrying loom
  frontmatter (`kind: spec`/`plan`, a status) and reconciled by weave/weft. Ad-hoc
  `feature/<slug>` work needs none. warp never writes these — it only points the kickoff
  at the right home.
- **Kick off.** Creative or feature work starts with the brainstorming skill before code;
  a scoped fix goes straight in.
