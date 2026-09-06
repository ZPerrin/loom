---
kind: readme
status: living
updated: 2026-09-06
---
# loom

loom is my agentic workflow, compressed into a project I can pull into whatever I'm working on
with agents. It is a toolkit and a testbed: currently six skills, the config and state they need, and the
scripts that keep a repo's docs from descending into slop.

It currently touches on these areas:

`workflow optimization`, `context engineering`, `documentation editorializing`, `living specs`, `rsi`

It's also very much a work in progress.

## Abstract

| skill | what it does |
|---|---|
| [dress](skills/dress/SKILL.md) | installs or retunes loom on a repo: the config, the per-skill overrides, and the managed `*.md` set |
| [warp](skills/warp/SKILL.md) | opens a working session: branch and worktree, context, any configured open hook |
| [weave](skills/weave/SKILL.md) | closes a working session: distillation into managed docs, checks, the commit/merge pattern, and the retro |
| [weft](skills/weft/SKILL.md) | editorializes managed documentation as a one-off pass to keep it cohesive and slop free (see [the editorial ethos](references/doc-convention.md)) |
| [spec](skills/spec/SKILL.md) | authors or extends one capability's living spec under the [spec grammar](references/spec-grammar.md), lint-clean before it is presented |
| [refine-spec](skills/refine-spec/SKILL.md) | reconciles one capability's spec against its tests and code and reports drift by requirement id; the writing goes back through spec |

Two files configure them, and five scripts do the deterministic work:

| control surface | what it does |
|---|---|
| `.loom/loom.toml` | settings the scripts enforce the same way on every run |
| `.loom/<skill>.md` | one opinion file per skill, for guidance that hasn't earned determinism yet |
| `doc-scan` | lists the managed docs and the markdown that could join them |
| `doc-linter` | keeps managed docs mechanically clean; specs are graded against the grammar |
| `doc-slicer` | the SessionStart slice, and one section on demand |
| `doc-stamp` | sets frontmatter fields |
| `skill-hook` | runs a skill's configured hook |

The [reference project](references/reference-project.md) shows a minimal dressed repo. This repo
is dressed with itself: `.loom/` is loom's own config, and [docs/specs](docs/specs/) says what
the scripts promise, one spec per capability.

## Install

Codex, from the GitHub marketplace:

```
codex plugin marketplace add ZPerrin/loom --ref master
codex plugin add loom@loom
```

Codex loads plugins when a thread starts, so open a new thread in the repo. To pick up a newer
pushed version:

```
codex plugin marketplace upgrade loom
codex plugin add loom@loom
```

Claude Code, from the same marketplace:

```
/plugin marketplace add ZPerrin/loom
/plugin install loom@loom
```

## License

[MIT](LICENSE) © Zebulon Perrin
