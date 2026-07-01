---
kind: reference
status: living
updated: 2026-07-01
---
# Tooling — loom's executable surface

The plugin ships four scripts (bash + awk, no deps). Each answers a question an agent would
otherwise burn tokens inferring with grep, glob, or whole-file reads. Reach for the script
first: the answer arrives smaller, with provenance, and from the same discovery the linter
enforces — so the query and the gate can never disagree about what a doc is. Paths are under
`${CLAUDE_PLUGIN_ROOT}` (skills receive it expanded; elsewhere it is the plugin install root).

| the question | the invocation |
|---|---|
| What docs are managed here, and what's still a candidate? | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-scan"` |
| What does one section say — without reading the file? | `bash "${CLAUDE_PLUGIN_ROOT}/hooks/doc-slicer" --header "<name>" [path-filter…]` |
| Is the doc web sound? (the close-out gate) | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"` |
| What link findings would adopting these files create? | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter" --links [FILE…]` |
| Set or replace frontmatter keys | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-stamp" <file> key=value …` |

- **doc-scan** — membership is discovery; never enumerate the managed set by glob, it drifts.
- **doc-slicer --header** — one addressable section, carrying the same provenance annotation
  the session slice uses. Bare names are forgiving (`Overview` → `## Overview`); trailing
  arguments narrow by path substring (`--header Overview harness`); a miss exits 1 with a
  note. Prefer it whenever the question is doc-shaped — "what's the validation command?",
  "what does `## Now` say?" — and read a whole file only when you are about to rewrite it.
- **doc-linter** — the gate. `--links` is the frontmatter-agnostic preview for docs not yet
  adopted; use it when the plain linter's silence would just mean "not managed yet".
- **doc-stamp** — idempotent frontmatter writes. Never hand-roll a shell loop for this:
  shell-reserved names like zsh's `status` silently fail the write.
