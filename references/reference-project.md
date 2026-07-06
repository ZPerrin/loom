---
kind: reference
status: living
updated: 2026-07-05
---
# Reference Project

Calibration only. Do not copy this shape wholesale; use it to recognize what a minimal loom surface looks like.

## Tree

```text
example/
  AGENTS.md
  README.md
  frontend/README.md
  backend/README.md
  infra/README.md
  docs/README.md
  docs/roadmap.md
  .loom/loom.toml
  .loom/warp.md
  .loom/weave.md
  .loom/scripts/warp.sh
  .loom/scripts/weave.sh
```

## Example `.loom/loom.toml`

```toml
[discovery]
exclude = ["vendor", "tmp"]

[context]
recent_commits = 15
slice_headers = ["## Now", "## Module Map"]
inject_fields = ["updated", "kind", "location"]

[lint]
kinds = ["readme", "reference", "roadmap", "spec", "plan", "design", "review", "loom-config"]
statuses = ["living", "hardened", "superseded", "ideation"]

[warp]
branch_convention = "feature/<slug>"
worktree = "always"
source_repo = "."
source_branch = "master"
hook = "warp.sh"

[weave]
cleanup = "ask"
rsi = "always"
hook = "weave.sh"
```

## loom.toml Control Surfaces

| Surface | Controls                                                            | Used by |
|---|---------------------------------------------------------------------|---|
| `[discovery].exclude` | path prefixes removed from the markdown files loom manages          | `doc-scan`, `doc-slicer`, `doc-linter` |
| `[context].recent_commits` | commit count in the SessionStart bearings                           | `doc-slicer` |
| `[context].slice_headers` | H2 sections harvested from managed docs                             | `doc-slicer` |
| `[context].inject_fields` | frontmatter fields prefixed onto slices; `location` is path-derived | `doc-slicer` |
| `[lint].kinds` | allowed `kind` frontmatter values                                   | `doc-linter` |
| `[lint].statuses` | allowed `status` frontmatter values                                 | `doc-linter` |
| `[warp].branch_convention` | session-open branch naming pattern, or `ask`                        | `warp` |
| `[warp].worktree` | worktree behavior: `always`, `never`, `ask`, or `harness`           | `warp` |
| `[warp].source_repo` | local path or GitHub ref used to interpret `/warp <arg>`            | `warp` |
| `[warp].source_branch` | base branch new work forks from                                     | `warp` |
| `[warp].hook` | optional session-open command or script                             | `warp`, `skill-hook` |
| `[weave].cleanup` | session-close branch cleanup preference                             | `weave` |
| `[weave].rsi` | end-of-session retro filed to `.loom/warp.md`: `always`, `ask`, `never` (default on) | `weave` |
| `[weave].hook` | optional session-close command or script                            | `weave`, `skill-hook` |
| `.loom/<skill>.md` | repo opinion prose floor for that skill                             | named skill |
| `.loom/scripts/*` | conventional home for hook scripts                                  | configured hooks |

## Example root `README.md`

```md
---
kind: readme
status: living
updated: 2026-07-05
---
# Example

One paragraph of project purpose.

## Module Map

- [frontend](./frontend/):
    - browser client
- [backend](./backend/):
    - API and persistence
- [infra](./infra/):
    - deployment and cloud resources
- [docs](./docs/):
    - durable design notes, roadmap, specs, and plans
```

## Example `AGENTS.md`

```md
---
kind: readme
status: living
updated: 2026-07-05
---
# AGENTS

## Agentic Guidelines

- Gather context progressively: root map -> module README -> deep doc -> code.
- When working in a module, follow its `## Agentic Guidelines` and `## Agentic Validation`.

## Agentic Validation

- Root validation command.
```

## Example module README

```md
---
kind: readme
status: living
updated: 2026-07-05
---
# Backend

Owns the API, domain services, persistence, and tests.

## Overview

One paragraph describing the stable shape of the module.

## Setup

Commands needed to make the module runnable.

## Agentic Guidelines

Durable local rules for how work should happen here.

## Agentic Validation

Commands that prove this module still works.
```

## Example `docs/README.md`

```md
---
kind: readme
status: living
updated: 2026-07-05
---
# Docs

Durable project memory and dated working docs.

## Module Map

- [design](./design/):
    - settled architecture and product decisions
- [specs](./specs/):
    - dated working specs, pruned after distillation
- [plans](./plans/): 
    - dated implementation plans, pruned after close-out
```

## Example `docs/roadmap.md`

```md
---
kind: roadmap
status: living
updated: 2026-07-05
---
# Roadmap

## Now

The current project focus, written as durable direction rather than a session log.

## Next

Near-term choices or milestones.

## Later

Deferred ideas that still matter.
```

## Example `.loom/warp.md`

```md
---
kind: loom-config
status: living
updated: 2026-07-05
---
# warp

Repo opinion for opening work: branch naming, worktree habit, context order, and any kickoff recipe that is not yet deterministic.
```

## Example `.loom/weave.md`

```md
---
kind: loom-config
status: living
updated: 2026-07-05
---
# weave

Repo opinion for closing work: what to distill, what to prune, and how close-out should hand back. Notes on how to approach session retrospectives, etc.
```
