---
kind: report
status: living
updated: 2026-09-07
---
# Fresh delegate probe

The Claude half of the s11 experiment: a delegate that receives only its handoff path and the
runtime pointer, with no session slice, finds loom's tools and the context its task needs. Run
against the [data-plane handoff](../handoffs/2026-09-07-0.2-data-plane-context.md)'s acceptance
line for one small useful delegated task with hooks absent, on the uncommitted s12 work.

## Setup

Claude Code 2.1.261, the desktop app, the Agent tool with Sonnet and the general-purpose type;
SubagentStart is unregistered, so no slice reached the delegate. The brief, whole: "You are a
delegate. Your handoff is at `<scratchpad>/2026-09-07-tools-block-probe.md`; read it and do what
it says. The repo is at `<worktree>`. loom's runtime scripts are at `<worktree>/scripts`." The
handoff, 2,536 bytes in the reference project's shape, asked it to verify that every scenario
under R-CONTEXT-003 and R-CONTEXT-011 names a fragment `grep -F` finds in
`tests/test-doc-slicer.sh`, read-only, reporting to a scratchpad path. Both files sat outside the
repo, as a probe.

## Outcome

Pass. The delegate had no prior context, ran `doc-slicer --tools` because no tools block was in
its context, used the `--spec` line that block printed to pull both requirements by id without
opening the spec file, ran one `grep -nF` per scenario, and wrote its report with Outcome,
Evidence, and Open. All six fragments resolved. It said the brief alone was enough.

| measure | value |
|---|---|
| received text | the brief above; the handoff by reading it |
| loom script runs | 3: `--tools`, then `--spec context` for each requirement |
| tool uses | 16 |
| duration | 193 s |
| tokens | 72,003 |
| its report | 6,959 bytes |

## Open

- The delegate shared the coordinator's worktree and saw two files change under it mid-run, the
  coordinator's own edits; it proved the drift was not its own and flagged it rather than acting.
  warp.md's rule that a delegate works in its own worktree off a commit holds for a read-only
  probe too, or the coordinator makes no edit until it returns.
- The Codex half of the experiment, and resume and compact on Claude, are unexercised.
- The report ran to five times the handoff; the brief named its sections and set no budget.
