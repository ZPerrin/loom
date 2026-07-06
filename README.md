---
kind: readme
status: living
updated: 2026-07-06
---
# loom

loom is a foray into baking my own workflows into a harness.

It currently touches on these areas:

`workflow optimization`, `context engineering`, `documentation editorializing`, `rsi`

It's also very much a work in progress.

## Abstract

You get 4 skills and two ways to configure them.

`.loom/loom.toml` gives you a minimal control surface for more deterministic settings.  
`.loom/<skill>.md` overrides give a non-deterministic way to further nudge them to your liking.

`dress` onboards loom into your project, loom will help maintain ***.md** documentation.

`warp` starts a working session, handling worktree and branch creation, context gathering, and any other session preamble you configure

`weave` closes it out, sweeping work into a preferred commit/merge pattern and distilling changes into your managed documentation.

`weft` editorializes the managed documentation as a one-off to help keep things cohesive and slop free (see [the editorial ethos](references/doc-convention.md)).

A linter/slicer pair that ship with the plugin allow for us to both keep the documentation clean, and slice documentation context efficiently.

A SessionStart hook does this by default, injecting the configured settings from `.loom/loom.toml.[context]` directly into the system context. The same slicer answers on-demand queries mid-session (`doc-slicer --header <name>`), so an agent pulls one addressable section instead of reading a whole file.

Pseudo-hooks can also be configured and placed under `.loom/scripts` to drive more deterministic behavior.

See the [reference project](references/reference-project.md) for a better idea of how this all works.

## Naming (textile ethos)

The harness is a loom; sessions are woven on it.

| term | what it names                                                   | where |
|---|-----------------------------------------------------------------|---|
| **loom** | the system / this repo                                          | here |
| **dress** | stand up or re-tune the harness                                 | `skills/dress` |
| **warp** | session-*open* bookend — orient before work                     | `skills/warp` |
| **weave** | session-*close* bookend — distill, check, and hand off work     | `skills/weave` |
| **weft** | project-docs editorial pass — prune, route, compress            | `skills/weft` |
| **doc-slicer** | the per-session context the hook threads in ("Bearings")        | `scripts/doc-slicer` |
| **doc-linter** | doc hygiene checks (links + frontmatter)                        | `scripts/doc-linter` |

## Install

Install loom in Codex from the GitHub repository:

```
codex plugin marketplace add ZPerrin/loom --ref main
codex plugin add loom@loom
```

Then start a new Codex thread in the repository where you want to use loom.
Codex loads installed plugins when a thread starts.

To pick up a newer pushed version:

```
codex plugin marketplace upgrade loom
codex plugin add loom@loom
```

Claude Code can use the same GitHub-backed marketplace from its plugin flow:

```
/plugin marketplace add ZPerrin/loom
/plugin install loom@loom
```
