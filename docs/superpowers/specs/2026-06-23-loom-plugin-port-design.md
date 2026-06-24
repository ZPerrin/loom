# loom — plugin port & data-driven restructure (design)

_Status: draft for review — 2026-06-23_

> **Superseded in part (2026-06-23):** the enumerated managed-doc model (`[modules] dirs`,
> `docs_subdirs`) and the two-tier frontmatter/stamp document model described here are
> replaced by discovery-driven frontmatter and generic slicing — see
> [2026-06-23-loom-discovery-frontmatter-redesign.md](2026-06-23-loom-discovery-frontmatter-redesign.md).
> The bash+awk / data-driven / dual-tool decisions still hold.

## 1. Context & motivation

`loom` is a self-maintaining docs & context harness, forklifted out of the `jack`
repo as a skeleton (five skills copied verbatim, the SessionStart hook, the linter,
and parallel Claude/Codex plugin manifests). The forklifted artifacts assume `jack`'s
in-tree `.claude/` layout: they reference `../../../docs/README.md`, run
`python3 .claude/skills/.../doc-lint.py`, and hardcode `jack`'s module set
(`backend/frontend/cdk`). As an *installed plugin* these break.

This effort turns the skeleton into a coherent, best-practices plugin that installs
and runs in **both Claude Code and Codex**, and that users/agents can **tune per
project** without editing plugin internals.

The core realization that shapes everything: an installed plugin lives in a
**read-only, auto-updated cache** (`${CLAUDE_PLUGIN_ROOT}`). Anything tunable
per-project must therefore live in the **user's repo** (`${CLAUDE_PROJECT_DIR}`),
not in the plugin. So the harness splits into generic enforcement code (shipped,
read-only) + a small declarative config the harness manages in each target repo.

## 2. Decisions (locked during brainstorming)

1. **Data-driven.** The plugin ships generic code; each repo owns a small config
   (`loom.toml`) that drives the slicer and linter. Tuning edits config, not code.
2. **bash (not Python).** The slicer and linter are **bash 3.2+ + `awk`**. No Python
   runtime assumed. bash is the ecosystem norm (cf. superpowers), and the
   cross-platform wrapper `exec bash`es the scripts anyway, so POSIX-`sh` purism buys
   nothing. Stay bash-3.2-safe (macOS ships 3.2): no associative arrays, no `${x^^}`.
   `awk` does the markdown line-processing (section slicing, link regex).
3. **Cross-platform via a polyglot wrapper** (adopted from superpowers, MIT). A
   `hooks/run-hook.cmd` file valid as *both* a Windows `.cmd` and a Unix shell script
   routes hook invocation to bash on both platforms; hook scripts are **extensionless**
   (`doc-slicer`, not `doc-slicer.sh`) to dodge Claude Code Windows' auto-`bash`-prepend
   on `.sh`; no bash on Windows → `exit 0` silently (plugin still works, sans context).
4. **`loom.toml` — a constrained TOML subset.** Chosen for human readability + editor
   support. To keep the bash/awk reader small (~40 lines) and robust, the config commits
   to an easy-to-parse subset: `[table]` headers, `key = scalar` (string/int/bool),
   and single-line `key = ["arrays"]`. **No** arrays-of-tables, inline tables, multiline
   values, or trailing comments. Contained risk: the "subset trap" (see §11).
5. **Single `${CLAUDE_PLUGIN_ROOT}`.** It is substituted inline in skill content and
   hook commands, and Codex sets it as a compat alias — so one value works in both
   tools. The separate `hooks.codex.json` collapses into one `hooks.json`.
6. **Full textile nomenclature now** (avoid renaming twice), with plain names for the
   two scripts.

### Naming

| Term | Role | Kind | Was |
|---|---|---|---|
| **loom** | the system | — | — |
| **dress** | stand up the harness: scaffold docs + initial `loom.toml`, and re-tune it | skill | `init-docs` (+ `refine-context` + `refine-linter`) |
| **weave** | whole-cloth doc reconciliation | skill | `refine-docs` |
| **weft** | session-close: distill work into docs (will grow: cleanup, MR/merge after a doc pass) | skill | `wrap` |
| **warp** | session-open bookend: branch kickoff, naming, GH/Jira, worktree (nebulous, user-malleable) | skill | — (new **stub**) |
| **doc-slicer** | SessionStart context materializer (the "Bearings" output) | shell script | `source-doc-context.py` |
| **doc-linter** | doc hygiene checks (links, frontmatter, stamps) | shell script | `doc-lint.py` |

`warp` and the expanded `weft` are **future** and intentionally nebulous; this pass
only **stubs `warp`** and **renames `wrap → weft`** (keeping current behavior).

## 3. Architecture: the plugin / repo split

| In the plugin (`${CLAUDE_PLUGIN_ROOT}`, read-only, auto-updates) | In the user's repo (`${CLAUDE_PROJECT_DIR}`, editable, version-controlled) |
|---|---|
| Skills: `dress`, `weave`, `weft`, `warp` (stub) | `docs/README.md` (prose source of truth) |
| `hooks/doc-slicer` (generic, config-driven) | module READMEs, `docs/config/roadmap.md` |
| `scripts/doc-linter` (generic, config-driven) | **`docs/config/loom.toml`** — the tunable config |
| `hooks/hooks.json` | — |

The scripts resolve the target repo via `git rev-parse --show-toplevel` (fallback
`$CLAUDE_PROJECT_DIR`, then cwd), so they operate on the user's repo wherever the
plugin physically lives.

## 4. Repository layout (target)

```
loom/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json            # Claude dev marketplace
├── .codex-plugin/
│   └── plugin.json                 # hooks → ./hooks/hooks.json
├── .agents/plugins/
│   └── marketplace.json            # Codex dev marketplace
├── hooks/
│   ├── hooks.json                  # single file, ${CLAUDE_PLUGIN_ROOT}, routes via run-hook.cmd
│   ├── run-hook.cmd                # polyglot Windows/Unix wrapper (from superpowers, MIT)
│   └── doc-slicer                  # SessionStart hook (extensionless, #!/usr/bin/env bash)
├── scripts/
│   └── doc-linter                  # linter (extensionless bash; skill-invoked as `bash …`)
├── skills/
│   ├── dress/
│   │   ├── SKILL.md
│   │   └── templates/              # doc seeds + minimal loom.toml
│   ├── weave/SKILL.md
│   ├── weft/SKILL.md
│   └── warp/SKILL.md               # stub
├── docs/                           # loom's own docs (incl. this spec)
├── tests/                          # synthetic fixture tree + expected linter findings
├── README.md
└── NOTES.md
```

**Deleted vs current skeleton:** `hooks/hooks.codex.json`,
`hooks/source-doc-context.py`, `scripts/doc-lint.py` (old Python),
`skills/refine-docs/doc-lint.py` (byte-dup), `skills/init-docs/templates/*.py`
(ejects no longer shipped), and the old skill dirs `init-docs/`, `refine-docs/`,
`refine-context/`, `refine-linter/`, `wrap/` (renamed/folded).

## 5. Config: `loom.toml`

Lives at `${CLAUDE_PROJECT_DIR}/docs/config/loom.toml`. `dress` scaffolds a minimal one
and keeps it in sync.

```toml
# loom.toml — per-repo harness config. Managed by /loom:dress.

[modules]
# Dirs treated as modules: each gets a stamped `## Overview` (linter) and an
# Overview slice in the SessionStart context (slicer).
dirs = ["backend", "frontend", "cdk"]

[context]
# What the SessionStart hook injects, in fixed order: commits, sections, modules.
recent_commits = 15
sections = ["docs/config/roadmap.md > ## Now"]   # each entry: "file > ## Header"
include_modules = true

[lint]
# Frontmatter enums + the docs/ subdirs whose *.md carry frontmatter.
kinds = ["charter", "roadmap", "readme", "guide", "reference", "spec", "plan", "design", "review"]
statuses = ["living", "hardened", "superseded", "scaffolding", "ideation"]
docs_subdirs = ["config", "specs", "plans", "design"]
```

**Supported subset (the awk reader handles exactly this):**
- `[table]` header lines set the current section.
- `key = "string"`, `key = 42`, `key = true|false` — scalars (quotes stripped).
- `key = ["a", "b", "c"]` — single-line arrays (split on `,`, quotes/space stripped).
- Whole-line and trailing `#` comments (the parser strips the first `#` outside
  double-quotes, so `## Now` inside a quoted value survives) and blank lines ignored.

**Not supported** (fail loudly, don't half-parse): arrays-of-tables (`[[x]]`), inline
tables (`{…}`), multiline arrays/strings.

Encoding notes: section slices are compound strings `"file > ## Header"` (split on the
first ` > `) since we avoid arrays-of-tables; slice order is fixed
(commits → sections → modules), which matches current behavior.

## 6. Scripts (bash 3.2+ + awk)

Both scripts are **extensionless** and `#!/usr/bin/env bash`. The hook is invoked via
the polyglot wrapper (`run-hook.cmd doc-slicer`); the linter is invoked from skills as
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"` (explicit `bash`, no `.sh`).

### `doc-slicer` (SessionStart hook)
- Reads `loom.toml` (or defaults — see §8) and emits, to stdout, the SessionStart
  context: a preamble, a **Bearings** git-recency block, then each configured slice.
- Section slicing = print lines from a `## Header` to the next `## ` sibling (awk).
- Module slice = the module's Module-Map line as a heading + its README `## Overview`
  body, looped over configured modules.
- No-config behavior: git bearings + roadmap `## Now` only (generic, safe).
- **Output form:** raw text to stdout (added to context by Claude Code) for v1.
  superpowers instead emits structured JSON (`hookSpecificOutput.additionalContext`)
  with a bash JSON-escaper; adopt that only if raw stdout proves insufficient on either
  tool.

### `doc-linter`
- Reimplements the current checks in awk, with `kinds`/`statuses`/`docs_subdirs` and
  the module list from `loom.toml` (defaults from §8):
  - **BROKEN** — relative links that don't resolve.
  - **CODELINK** — `` [`text`](url) `` code-styled links.
  - **MISSING** — `` - `path` — desc `` nav items that resolve but aren't linked.
  - **FRONTMATTER** — `docs/` tree + `AGENTS.md`: valid `kind`/`status`/ISO `updated`.
  - **STAMP** — root + module READMEs: frontmatter-free, stamped `## Overview`.
- Skips fenced code blocks; uses `git check-ignore` for the MISSING rule.
- Exit 1 on findings, 0 clean.

Behavioral parity with the existing Python linter is the bar; the awk rewrite is the
main implementation risk (§12). Validate by dogfooding loom's own docs tree (which has
its own `docs/config/loom.toml`) plus a small synthetic fixture exercising each finding
type (a known broken link, a code-styled link, a missing frontmatter field, an unstamped
README), asserting expected output.

## 7. Skills

All SKILL.md files: update frontmatter `name`/`description`, fix path references (§8),
and reframe bodies to the data-driven model.

- **dress** (was `init-docs` + `refine-context` + `refine-linter`): conversationally
  stand up the harness — scaffold `docs/README.md` (source of truth), module READMEs,
  roadmap seed, and a minimal `loom.toml` — then prove it clean via `doc-linter`.
  Also handles **ongoing tuning** of `loom.toml` (slice list + lint rules), since
  data-driven config collapses both old `refine-*` skills into "edit `loom.toml`".
  `templates/` holds the doc seeds + the seed `loom.toml`.
- **weave** (was `refine-docs`): whole-tree reconciliation against code + `docs/README.md`.
- **weft** (was `wrap`): session-close distill into docs. Current behavior, renamed.
- **warp** (new, **stub**): placeholder SKILL.md describing intended session-open
  scope (branch/naming/ticket/worktree); explicitly marked unimplemented.

## 8. Path-reference rules

- **Harness's own files** → `${CLAUDE_PLUGIN_ROOT}/...`. Skills invoke the linter as
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"` (was `python3 .claude/.../doc-lint.py`).
  Inline-substituted in skill content; works in both tools. The hook is wired in
  `hooks.json` as `"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd" doc-slicer` (matcher
  `startup|clear|compact`, `async:false`).
- **Target-repo docs** → project-relative prose (`docs/README.md`, `AGENTS.md`,
  `README.md`) — the agent runs in the project cwd; these point at the *user's* docs,
  not the plugin's. Not markdown links (they'd resolve against the plugin tree).
- **Intra-plugin links** (skill → script) → correct relative path within the plugin
  tree, e.g. `../../scripts/doc-linter`.
- **Defaults when `loom.toml` is absent:** both scripts ship hardcoded sensible
  defaults (the `kinds`/`statuses`/`docs_subdirs` above; slicer = git + roadmap
  `## Now`) so the plugin is useful immediately, before `dress` runs.

## 9. Manifests & marketplaces

- `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`: keep; Codex `hooks` →
  `./hooks/hooks.json`. Keep `version` (`0.0.1`).
- `.claude-plugin/marketplace.json` (Claude) + `.agents/plugins/marketplace.json`
  (Codex) both retained — **not duplicates**: Claude keeps manifest+marketplace in
  `.claude-plugin/`; Codex splits manifest (`.codex-plugin/`) from marketplace
  (`.agents/plugins/`).
- Hand-maintain both manifests for now (generate-from-one-core deferred). superpowers
  confirms this is the norm: it hand-maintains a committed `.codex-plugin/plugin.json`
  and uses `scripts/sync-to-codex-plugin.sh` only to *publish* into OpenAI's separate
  marketplace monorepo (rsync + PR) — a model for loom *later*, when it targets the
  official Codex marketplace. Note superpowers' Codex build excludes `hooks/` (ships
  skills-only); loom deliberately keeps the hook for Codex (verified supported).
- The Codex `interface` block (displayName/capabilities/icons/brandColor) can be
  enriched for marketplace presentation later; minimal is fine for the dev marketplace.

## 10. Out of scope / deferred

- Building `warp` (stub only); expanding `weft` beyond today's behavior.
- The actual smoke-test install (`/plugin marketplace add …` + Codex equivalent) —
  the next effort after this build.
- Generating the two manifests from a single shared core.

## 11. Risks & open questions

- **awk linter parity.** Rewriting the careful Python linter in awk is the main risk;
  mitigate with a synthetic fixture tree (one case per finding type) plus dogfooding
  loom's own docs, asserting expected findings.
- **TOML subset trap.** Users/agents may write valid TOML the awk reader doesn't handle
  (arrays-of-tables, inline/multiline, trailing comments). Mitigate: `dress` writes and
  maintains the canonical shape; the reader rejects unrecognized constructs with a clear
  error rather than silently mis-parsing; the supported subset is documented in `dress`
  and beside `loom.toml`.
- **Codex local-marketplace root path.** Known issue
  [openai/codex#17066](https://github.com/openai/codex/issues/17066): a local
  marketplace plugin `source.path` may not be `"./"` (repo root); Codex may require the
  plugin nested under `plugins/`. If it bites at smoke-test, fix with a layout tweak,
  not a redesign. Claude is fine with root.
- **Codex inline substitution.** Confirm Codex substitutes `${CLAUDE_PLUGIN_ROOT}` in
  skill content (Claude does); if it only exports it as an env var, the double-quoted
  `"${CLAUDE_PLUGIN_ROOT}/…"` form still works at shell-expansion time.
- **Hook output form.** Raw-stdout vs JSON `additionalContext` (§6) — verify raw text
  injects cleanly on both tools; fall back to the superpowers JSON-escaper if not.
- **bash 3.2 ceiling.** Keep scripts 3.2-safe; test on macOS `/bin/bash`. The polyglot
  `run-hook.cmd` and extensionless scripts are lifted from superpowers (MIT) — preserve
  the attribution, and document the pattern in loom's own docs (cf. their
  `docs/windows/polyglot-hooks.md`).

## 12. Done criteria

- Plugin tree matches §4; deletions done.
- `doc-slicer` and `doc-linter` run clean (bash 3.2 + awk) on loom's own docs tree with
  a `loom.toml`, and behave sensibly with no `loom.toml`; the synthetic fixture produces
  exactly the expected findings. `run-hook.cmd doc-slicer` works on Unix (and degrades to
  `exit 0` without bash).
- All skill path references resolve under an installed-plugin layout.
- Skills renamed/folded per §7; `warp` stub present.
- Single `hooks/hooks.json`; manifests updated.
- (Smoke-test install is the *next* effort, not a gate here.)
```
