---
kind: reference
status: living
updated: 2026-07-03
---
# Tooling — loom's executable surface

The plugin ships five scripts (bash + awk, no deps). Each answers a question an agent would
otherwise burn tokens inferring with grep, glob, or whole-file reads. Reach for the script
first: the answer arrives smaller, with provenance, and from the same discovery the linter
enforces — so the query and the validation pass can never disagree about what a doc is. Paths are under
`${CLAUDE_PLUGIN_ROOT}` (skills receive it expanded; elsewhere it is the plugin install root).

| the question | the invocation |
|---|---|
| What docs are managed here, and what's still a candidate? | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-scan"` |
| What does one section say — without reading the file? | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-slicer" --header "<name>" [path-filter…]` |
| Is the doc web sound? (the close-out check) | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"` |
| What link findings would adopting these files create? | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter" --links [FILE…]` |
| Set or replace frontmatter keys | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-stamp" <file> key=value …` |
| How does a skill run its configured hook? | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/skill-hook" <skill> [args…]` |

- **doc-scan** — membership is discovery; never enumerate the managed set by glob, it drifts.
- **doc-slicer --header** — one addressable section, carrying the same provenance annotation
  the session slice uses. Bare names are forgiving (`Overview` → `## Overview`); trailing
  arguments narrow by path substring (`--header Overview harness`); a miss exits 1 with a
  note. Prefer it whenever the question is doc-shaped — "what's the validation command?",
  "what does `## Now` say?" — and read a whole file only when you are about to rewrite it.
- **doc-linter** — the doc check. `--links` is the frontmatter-agnostic preview for docs not yet
  adopted; use it when the plain linter's silence would just mean "not managed yet".
- **doc-stamp** — idempotent frontmatter writes. Never hand-roll a shell loop for this:
  shell-reserved names like zsh's `status` silently fail the write.
- **skill-hook** — runs a skill's `[<skill>] hook` from `loom.toml` with `[skills] scripts_dir`
  prepended to PATH. Exit **0** the hook ran clean · **3** no hook configured (the skill uses its
  prose floor) · any other = the hook's own failing code, which the calling skill interprets (warp
  falls to the floor; weave stops close-out). loom validates the hook's form, never its content.
