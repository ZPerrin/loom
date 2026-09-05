---
name: warp
description: Use when opening a unit of work in a loom managed repo, especially when orientation, branch/worktree setup, ticket context, or kickoff guidance may be needed.
---

## Warp

Open a unit of work. warp orients the session, establishes the branch/worktree when configured, runs an optional open hook, and hands back ready to work. It never commits and never writes session docs; close-out and durable distillation belong to weave.

`warp` handles two repo states:

- **Unconfigured:** no `[warp]` section exists in `.loom/loom.toml`; configure the flow or orient only.
- **Configured:** `[warp]` section exists in `.loom/loom.toml`; run the confirmed flow and stop only for real session unknowns or git safety.

## Warp Control Surfaces

These are the surfaces `warp` reads or writes directly. The full `.loom/loom.toml` key map lives in the reference project.

| Surface | Warp uses it for |
|---|---|
| `[warp].branch_convention` | session-open branch naming pattern, or `ask` |
| `[warp].worktree` | worktree behavior: `always`, `never`, `ask`, or `harness` |
| `[warp].source_repo` | local path or GitHub ref used to interpret `/warp <arg>` |
| `[warp].hook` | optional session-open command, run via `skill-hook` |
| `.loom/warp.md` | repo opinion for orientation, workspace setup, and kickoff |
| `.loom/scripts/*` | conventional home for hook scripts |

## Workflow Graph

```mermaid
flowchart TD
    invoke["/warp [arg]"] --> cfg{"[warp] configured?"}
    cfg -->|no or configure| configure["Configure - survey, propose, confirm"]
    configure --> confirm{"Operator confirms?"}
    confirm -->|revise| configure
    confirm -->|declines| orient["Orient - load needed context"]
    confirm -->|approved| write["Write - [warp] + optional warp.md"]
    cfg -->|yes| orient
    write --> orient
    orient --> open["Open - branch/worktree/hook"]
    open --> kickoff["Kick off - compose named tools or hand back"]
```

## Workflow

### 1. Configure - approval boundary

Use only on first run, missing `[warp]`, or `/warp configure`.

- Survey how the repo opens work: branch names, source branch, worktree habit, ticket refs, existing `.loom/warp.md`, and open scripts.
- Propose the `[warp]` knobs and any `.loom/warp.md` repo opinion.
- Write nothing until the operator approves the exact diff.
- If the operator declines, write nothing and continue to Orient only.

### 2. Orient - load enough context

- Read `.loom/warp.md` if present, including any `## Experiments` a prior weave retro filed for this session to weigh.
- Treat the SessionStart slice as already loaded; pull extra sections with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-slicer" --header "<name>" [path-filter]`.
- Resolve `/warp <arg>` through `source_repo`: GitHub ref means fetch the issue/PR; local path means free-text work description; no arg means ask only if needed.
- Do not mutate the workspace before orientation.

### 3. Open - establish the workspace

- If `[warp] hook` is set, run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/skill-hook" warp "<slug>"`.
- Hook exit `0`: verify the working directory and continue.
- Hook exit `3`: no hook; open by hand.
- Other hook exit: surface the failure, then fall back to the prose floor unless git safety blocks.
- Manual open: name the branch from `branch_convention`, fork from the checkout warp was invoked on unless the invocation names a base, and apply `worktree`.
- `worktree = always|ask` means the session works inside the worktree; verify `pwd` before the first edit.
- `worktree = harness` delegates worktree creation to the host harness; a hook there handles only residual setup.
- Never discard, stash, switch away from, or move uncommitted work without confirmation.

### 4. Kick off - compose or hand back

Compose only what `.loom/warp.md` names: a brainstorm, plan, code pass, or no tool at all. If a named tool is absent, say so and continue with an oriented workspace.

## Output

Report the oriented work, loaded context, branch/worktree and verified working directory, hook result, kickoff action or handback, and any named tool that was unavailable. In configure mode, report the `[warp]` knobs and `.loom/warp.md` changes. warp never commits.
