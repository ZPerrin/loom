---
kind: reference
status: living
updated: 2026-09-07
---
# Reference Project

Calibration only. Do not copy this shape wholesale; use it to recognize what a minimal loom surface looks like.

## Tree

```text
example/
  .gitignore
  AGENTS.md
  CLAUDE.md
  README.md
  frontend/README.md
  backend/README.md
  infra/README.md
  docs/README.md
  docs/roadmap.md
  docs/specs/<capability>.md
  .loom/loom.toml
  .loom/skills/warp.md
  .loom/skills/weave.md
  .loom/scripts/warp.sh
  .loom/scripts/weave.sh
  .loom/specs/yyyy-mm-dd-<slug-or-issue>.md
  .loom/plans/yyyy-mm-dd-<slug-or-issue>.md
  .loom/handoffs/yyyy-mm-dd-<slug>.md
  .loom/reports/yyyy-mm-dd-<slug>.md
```

`.loom/` is two planes. The config plane is `loom.toml`, `skills/` holding one opinion file per skill, and
`scripts/` holding the hooks, one named after each skill that has one.
The data plane is `specs/`, `plans/`, `handoffs/`, and `reports/`: dated work state, listed by
age. A handoff is the brief one delegated task works from; a report is what that run found.
Whether that state is committed is the operator's one adoption decision; a dressed repo has
answered it, in `.gitignore` or by committing the directories. The example ignores specs and plans
and commits handoffs and reports, since a delegate's worktree sees only what is committed. Repo
specs are not work state; they are capability-keyed, committed, and live under `docs/specs/`.
Every location has a `loom.toml` override; discovery is kind-based, so moving a doc never breaks
hygiene.

## Example `.gitignore`

```text
.loom/specs/
.loom/plans/
```

## Example `CLAUDE.md`

Claude Code reads `CLAUDE.md` and never `AGENTS.md`, so a dressed repo carries the one-line import
and excludes it from discovery, since it has no frontmatter of its own:

```text
@AGENTS.md
```

## Example `.loom/loom.toml`

```toml
[discovery]
exclude = ["vendor", "tmp", "CLAUDE.md"]

[context]
recent_commits = 15
slice_headers = ["## Now", "## Module Map"]
inject_fields = ["updated", "kind", "location"]

[lint]
kinds = ["readme", "reference", "roadmap", "spec", "plan", "handoff", "report", "design", "review", "loom-config"]
statuses = ["living", "hardened", "superseded"]

[lint.specs]            # spec-check budgets and word lists; omit a key to take its shipped default
max_norm_words = 24
flagged = ["robust"]

[specs]                 # defaults shown; set only to move a location
repo_dir = "docs/specs"
work_dir = ".loom/specs"

[plans]
dir = ".loom/plans"

[handoffs]
dir = ".loom/handoffs"

[reports]
dir = ".loom/reports"

[warp]                  # every key optional; the defaults are ask, harness, and "."
branch_convention = "feature/<slug>"
worktree = "harness"
source_repo = "."

[weave]
cleanup = "ask"
rsi = "always"
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
| `[lint.specs].max_norm_words`, `.max_purpose_sentences`, `.max_scenarios`, `.max_file_lines` | spec-check budgets; shipped defaults 30, 3, 8, 400 | `doc-linter` |
| `[lint.specs].banned`, `.flagged` | words appended to the checker's built-in lists; banned fails, flagged warns | `doc-linter` |
| `[lint.specs].ears` | EARS shape check: `strict` (default) fails, `warn` warns, `off` skips; the one-modal rule holds regardless | `doc-linter` |
| `[specs].repo_dir` | home of capability-keyed repo specs (default `docs/specs`)          | `doc-linter`, `doc-slicer`, spec skills |
| `[specs].work_dir` | home of dated work specs (default `.loom/specs`)                    | `doc-linter`, `doc-slicer`, spec skills |
| `[plans].dir` | home of dated plans (default `.loom/plans`)                          | `doc-linter`, `doc-slicer` |
| `[handoffs].dir` | home of dated handoffs, one brief per delegated task (default `.loom/handoffs`) | `doc-linter`, `doc-slicer` |
| `[reports].dir` | home of dated reports, what a run found (default `.loom/reports`)    | `doc-linter`, `doc-slicer` |
| `[skills].scripts_dir` | home of hook scripts (default `.loom/scripts`)                      | `doc-linter`, `skill-hook` |
| `[warp].branch_convention` | session-open branch naming pattern, or `ask` (the default)          | `warp` |
| `[warp].worktree` | worktree behavior: `always`, `never`, `ask`, or `harness` (the default) | `warp` |
| `[warp].source_repo` | local path or GitHub ref used to interpret `/warp <arg>` (default `.`) | `warp` |
| `[weave].cleanup` | session-close branch cleanup preference                             | `weave` |
| `[weave].rsi` | end-of-session retro filed to `.loom/skills/warp.md`: `always`, `ask`, `never` (default on) | `weave` |
| `[<skill>].hook` | names the hook when it is a command or a script not named after the skill; run with no input the moment the skill is invoked, by the harness where its hooks fire and by the skill's prose as the floor, its receipt and report reaching the skill as context | `skill-gate`, `skill-hook`, the skill |
| `.loom/skills/<skill>.md` | repo opinion for that skill, handed to it at invocation           | named skill, `skill-gate` |
| `.loom/scripts/<skill>` | that skill's hook, found by name with or without `.sh` | `skill-hook`, `skill-gate` |

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
    - durable design notes, roadmap, and capability specs
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

Durable project memory.

## Module Map

- [specs](./specs/):
    - what the code does, one living spec per capability
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

## Example `.loom/skills/warp.md`

```md
---
kind: loom-config
status: living
updated: 2026-07-05
---
# warp

Repo opinion for opening work: branch naming, worktree habit, context order, and any kickoff recipe that is not yet deterministic.
```

## Example `.loom/skills/weave.md`

```md
---
kind: loom-config
status: living
updated: 2026-07-05
---
# weave

Repo opinion for closing work: what to distill, what to prune, and how close-out should hand back. Notes on how to approach session retrospectives, etc.
```

## Example `.loom/handoffs/2026-07-05-rate-limit.md`

One brief per delegated task, in warp's delegation shape. It cites behavior by reference and
never restates it; a delegate trusts the reference over the brief.

```md
---
kind: handoff
status: living
updated: 2026-07-05
---
# Handoff: rate-limit the login route

## Objective
What is true when this is done, in one sentence.

## Scope
In: the login route and its tests. Out: the session store, the docs.

## Constraints
The base commit, verified before the first edit. The runtime's scripts directory; if the tools
block is absent, run `doc-slicer --tools` there first. The git verbs never used. The files that
win over this brief.

## Acceptance
Your own actions, each checkable: you ran `bash tests/run` and it printed ALL TESTS PASSED; you
listed every file you added with its job going forward.

## Return
The report at `.loom/reports/2026-07-05-rate-limit.md`, and what it carries.
```

## Example `.loom/reports/2026-07-05-rate-limit.md`

What a run found, against its handoff: the outcome, the evidence, and what stays open. A
validation or research report keeps the frontmatter and picks its own sections.

```md
---
kind: report
status: living
updated: 2026-07-05
---
# Report: rate-limit the login route

## Outcome
What is now true, against the handoff's Objective; what was left out, and why.

## Evidence
The commands run and what they printed; the files and commits, each with its job going forward.

## Open
What the operator must rule on.
```
