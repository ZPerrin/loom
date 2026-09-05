---
kind: readme
status: living
updated: 2026-09-05
---
# loom

loom is a foray into baking my own workflows into a harness.

It currently touches on these areas:

`workflow optimization`, `context engineering`, `documentation editorializing`, `rsi`

It's also very much a work in progress.

## Abstract

You get 5 skills, two ways to configure them, and a small docs harness around both.

| skills | what it does |
|---|---|
| [dress](skills/dress/SKILL.md) | onboards loom into a project so loom can help maintain managed `*.md` documentation |
| [warp](skills/warp/SKILL.md) | starts a working session: worktree and branch creation, context gathering, and any configured preamble |
| [weave](skills/weave/SKILL.md) | closes a working session: preferred commit/merge pattern, checks, and distillation into managed documentation |
| [weft](skills/weft/SKILL.md) | editorializes managed documentation as a one-off pass to keep it cohesive and slop free (see [the editorial ethos](references/doc-convention.md)) |
| [spec](skills/spec/SKILL.md) | authors or extends one capability's living spec under the [spec grammar](references/spec-grammar.md), lint-clean before it is presented |

| control surface | what it does |
|---|---|
| `.loom/loom.toml` | gives you a minimal control surface for more deterministic settings |
| `.loom/<skill>.md` | gives each skill a non-deterministic local override to nudge it to your liking |
| `doc-linter` | keeps managed documentation mechanically clean |
| `doc-slicer` | slices documentation context efficiently, including the SessionStart "Bearings" context from `.loom/loom.toml.[context]` |
| `doc-slicer --header <name>` | answers on-demand context queries mid-session so an agent pulls one addressable section instead of a whole file |

See the [reference project](references/reference-project.md) for a better idea of how this all works.

## Install

Install loom in Codex from the GitHub repository:

```
codex plugin marketplace add ZPerrin/loom --ref master
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

## License

[MIT](LICENSE) © Zebulon Perrin
