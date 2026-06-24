# loom Skills Rename/Reframe + Cleanup Implementation Plan (Plan 2 of 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename and reframe loom's skills to the textile vocabulary and the data-driven model, repoint every path reference to the installed-plugin layout, delete the old jack-shaped skeleton, and make loom lint-clean against its own linter.

**Architecture:** loom ships skills (`dress`, `weave`, `weft`, `warp`-stub) that operate on a target repo's docs and its `docs/config/loom.toml`, plus the Plan-1 scripts (`doc-linter`, `doc-slicer`) run from `${CLAUDE_PLUGIN_ROOT}`. Skills reference harness files via `${CLAUDE_PLUGIN_ROOT}` and target-repo docs via plain repo-relative prose. The old Python tooling and per-tool duplicates are deleted.

**Tech Stack:** Markdown (SKILL.md), JSON manifests, TOML config, bash (verification only).

This plan implements the rename/reframe/cleanup parts of `docs/superpowers/specs/2026-06-23-loom-plugin-port-design.md` (§2 naming, §4 deletions, §7 skills, §8 path rules, §9 manifests). Plan 1 (the scripts + tests) is already merged on this branch and must stay green.

---

## Shared conventions (apply in every skill edit)

When editing any `SKILL.md`, apply these substitutions consistently:

| Old (jack / in-tree) | New (installed plugin) |
|---|---|
| `python3 .claude/skills/refine-docs/doc-lint.py` | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"` |
| `python3 .claude/hooks/source-doc-context.py` | `bash "${CLAUDE_PLUGIN_ROOT}/hooks/doc-slicer"` |
| `[docs/README.md](../../../docs/README.md)` | `docs/README.md` (plain prose — points at the *target* repo) |
| `[README.md](../../../README.md)` | `README.md` |
| `[AGENTS.md](../../../AGENTS.md)` | `AGENTS.md` |
| `[roadmap.md](../../../docs/config/roadmap.md)` | `docs/config/roadmap.md` |
| `[settings.json](../../settings.json)` | (drop — the hook ships in the plugin, not target settings) |
| `/wrap` | `/weft` · `/refine-docs` | `/weave` · `/init-docs`,`/refine-linter`,`/refine-context` | `/dress` |

Rule of thumb: **harness's own files** → `${CLAUDE_PLUGIN_ROOT}/…`; **target-repo docs** → plain repo-relative text, not markdown links (a link would resolve against the plugin tree). After each task, no `SKILL.md` may contain `.claude/`, `../../../`, `python3 …doc-lint`, `source-doc-context`, or `settings.json`.

---

## Task 1: Rename `wrap` → `weft` and reframe

**Files:**
- Rename: `skills/wrap/` → `skills/weft/` (via `git mv`)
- Modify: `skills/weft/SKILL.md`

- [ ] **Step 1: Rename the directory**

```bash
git mv skills/wrap skills/weft
```

- [ ] **Step 2: Edit `skills/weft/SKILL.md`** — apply exactly these changes:

1. Frontmatter `name: wrap` → `name: weft`.
2. In the description, replace the leading verb phrasing and the `/wrap into <branch>` mentions: change `Invoke as \`/wrap into <branch>\`` → `Invoke as \`/weft into <branch>\``.
3. Body line 6: replace `Follow [docs/README.md](../../../docs/README.md):` → `Follow \`docs/README.md\`:`.
4. Body line 10–11: replace both `**\`/wrap\`**` → `**\`/weft\`**` and `**\`/wrap into <branch>\`**` → `**\`/weft into <branch>\`**`.
5. Body line 19: replace `check off \`## Milestones\` in [roadmap.md](../../../docs/config/roadmap.md)` → `check off \`## Milestones\` in \`docs/config/roadmap.md\``.
6. Body line 22: replace `Run the bundled linter \`python3 .claude/skills/refine-docs/doc-lint.py\`` → `Run the bundled linter \`bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"\``.
7. Body line 29 (the gate): replace `\`python3 .claude/skills/refine-docs/doc-lint.py\` exits 0` → `\`bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"\` exits 0`.

Leave the distill + close-out methodology otherwise intact (its future expansion is out of scope).

- [ ] **Step 3: Verify no stale references remain in the file**

Run:
```bash
grep -nE '\.claude/|\.\./\.\./\.\./|python3 .*doc-lint|source-doc-context|/wrap|settings\.json' skills/weft/SKILL.md || echo "CLEAN"
```
Expected: `CLEAN`.

- [ ] **Step 4: Commit**

```bash
git add -A skills/weft
git commit -m "refactor: rename wrap -> weft; repoint paths to plugin root"
```

---

## Task 2: Rename `refine-docs` → `weave` and reframe

**Files:**
- Rename: `skills/refine-docs/SKILL.md` → `skills/weave/SKILL.md` (the directory; note `skills/refine-docs/doc-lint.py` is deleted in Task 5, NOT moved)
- Modify: `skills/weave/SKILL.md`

- [ ] **Step 1: Rename, dropping the dup linter**

```bash
git mv skills/refine-docs skills/weave
git rm skills/weave/doc-lint.py        # byte-dup of scripts/doc-linter's predecessor; gone
```

- [ ] **Step 2: Edit `skills/weave/SKILL.md`** — apply exactly:

1. Frontmatter `name: refine-docs` → `name: weave`.
2. Body line 6: `aligned to [docs/README.md](../../../docs/README.md)` → `aligned to \`docs/README.md\``; and `Same ethos as \`/wrap\`` → `Same ethos as \`/weft\``.
3. Body line 10: `follow the root [README.md](../../../README.md) \`## Module Map\`` → `follow the root \`README.md\` \`## Module Map\``; and replace `Cover backend / frontend / cdk in turn.` → `Cover each module in the Module Map in turn.`
4. Body line 15: `Run the bundled linter \`python3 .claude/skills/refine-docs/doc-lint.py\` (in this skill's directory)` → `Run the bundled linter \`bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"\``.

- [ ] **Step 3: Verify**

```bash
grep -nE '\.claude/|\.\./\.\./\.\./|python3 .*doc-lint|backend / frontend / cdk|/refine-docs|/wrap' skills/weave/SKILL.md || echo "CLEAN"
```
Expected: `CLEAN`.

- [ ] **Step 4: Commit**

```bash
git add -A skills/weave
git commit -m "refactor: rename refine-docs -> weave; generic modules; plugin-root linter"
```

---

## Task 3: Create `dress` (fold `init-docs` + `refine-context` + `refine-linter`)

**Files:**
- Rename: `skills/init-docs/` → `skills/dress/` (via `git mv`)
- Replace: `skills/dress/SKILL.md` (full rewrite below)
- Delete: `skills/dress/templates/doc-lint.py`, `skills/dress/templates/source-doc-context.py`
- Create: `skills/dress/templates/loom.toml`
- (Note: `skills/refine-context/` and `skills/refine-linter/` are removed in Task 5 — their substance moves here.)

- [ ] **Step 1: Rename and drop the Python seeds**

```bash
git mv skills/init-docs skills/dress
git rm skills/dress/templates/doc-lint.py skills/dress/templates/source-doc-context.py
```

- [ ] **Step 2: Write the seed config** — Create `skills/dress/templates/loom.toml`:

```toml
# loom.toml — per-repo harness config. Managed by /loom:dress.
# A minimal starting point: tune it with /loom:dress as the repo grows.

[modules]
# Dirs treated as modules. Each gets a stamped `## Overview` (linter) and an
# Overview slice in the SessionStart context (slicer). Empty = no modules yet.
dirs = []

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

- [ ] **Step 3: Replace `skills/dress/SKILL.md`** with exactly:

```markdown
---
name: dress
description: Stand up (or re-tune) the loom doc harness on a repo — negotiate the root README identity and doc location, scaffold the coherent doc structure (module READMEs, docs/README.md, roadmap) plus a minimal docs/config/loom.toml, and prove it lint-clean. Also the place to re-tune loom.toml's context slices and lint rules as the repo drifts. Use when adopting loom on a repo or adjusting what it tracks.
---

Dress the loom: stand up the doc harness conversationally — explaining each artifact as it lands and letting the operator pivot — so the result is a *coherent* harness, not just files. The endstate definition of what docs mean lives in `docs/README.md`; everything else implements it. The harness's runtime (the SessionStart slicer and the linter) ships with the plugin and runs from `${CLAUDE_PLUGIN_ROOT}`; what this skill writes into the repo is the **docs** and a small **`docs/config/loom.toml`** that drives them. Stage; never commit.

## Foundation first (invest the conversation here)

Everything derives from a few decisions — settle them before generating:

1. **Project identity** — the root `README.md` `## Overview` (what it is) and `## Module Map` (what exists), derived from the actual top-level code dirs.
2. **Doc location & organization** — where `docs/` lives and how it is structured, captured as `docs/README.md`. This *is* the source of truth; lock it, then generate downstream.
3. **The config** — `docs/config/loom.toml`: the module set, the SessionStart context slices, and the lint rules. Seed it from [templates/loom.toml](templates/loom.toml) and fill it from the chosen structure.

## Detect-and-adapt

- **Blank repo:** write the canonical templates with guiding placeholder prose under each canonical header; prompt for the identity one-liner, module list, charter-or-not.
- **Existing repo:** inventory what exists and **map content into canonical homes** rather than overwrite — fold an existing README intro into `## Overview`, derive `## Module Map` from real top-level dirs, fill module `## Overview`s cheaply from code where obvious, and **flag gaps** ("backend has no Setup section — fill via /weft") instead of inventing detail. Never clobber existing prose silently.

## Canonical layout to produce

- `README.md` — `## Overview` (stamped) · `## Module Map` · `## Getting Started`; frontmatter-free.
- `AGENTS.md` (with `CLAUDE.md` symlink) — router + GLOBAL `## Agentic Guidelines` / `## Agentic Validation` only.
- `<module>/README.md` — `## Overview` (stamped) · `## Setup` · `## Structure` · `## Agentic Guidelines` · `## Agentic Validation`.
- `docs/README.md` — how docs work (taxonomy / lifecycle / nomenclature / ethos): the source of truth.
- `docs/config/` — `roadmap.md` (required) · `loom.toml` (required) · `charter.md` (optional).
- `docs/{specs,plans,design,diagrams}/` — scaffolding + assets.

## The config: `docs/config/loom.toml`

`loom.toml` is what the plugin's runtime reads — there is no per-repo Python to edit. It is a small TOML subset: `[table]` headers, `key = scalar`, and single-line `key = ["arrays"]` (trailing `#` comments fine). Three tables:

- `[modules] dirs = [...]` — the module set. Drives both the linter's stamped-README list and the slicer's per-module Overview slices.
- `[context]` — what the SessionStart hook injects: `recent_commits` (git bearings), `sections` (each `"file > ## Header"`, e.g. the roadmap `## Now`), and `include_modules`. Start maximal, then trim *down* — the slice is paid every session, so cut to what changes the next action.
- `[lint]` — `kinds` / `statuses` (frontmatter enums) and `docs_subdirs` (which `docs/` dirs carry frontmatter), mirroring the "Nomenclature" + "Module Map" in `docs/README.md`. The linter is a literal encoding of `docs/README.md`; keep them in agreement.

**Re-tune (the facilitator loop)** — to adjust what loads or what the linter enforces:
1. Render the live context: `bash "${CLAUDE_PLUGIN_ROOT}/hooks/doc-slicer"` from the repo root, and show the operator the actual output with a rough per-slice line/token cost so the always-on tax is visible.
2. Tune `[context]` / `[modules]` / `[lint]` in `loom.toml` with the operator — add/drop/reorder slices, add/remove modules, adjust enums to match `docs/README.md`. Re-render, re-show. Loop until it lands.
3. If a sliced header is missing, the slicer emits nothing for it — fix the doc with `/weft`, not by working around it here.

## Cohesion (the binding invariant)

Generate every dependent artifact *from* `docs/README.md` so a pivot propagates: module READMEs, `loom.toml`'s module set / enums, the slice list. Offer pivots (charter in/out, which dirs are modules, keep/drop `docs/design` + `docs/diagrams`, the `docs/` location) and recommend a core — but never leave a reference pointing at the old shape.

## Self-check

End by running `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"` — the scaffold is born lint-clean, which also proves the cross-reference web is coherent.

## Output

Report what was scaffolded vs. mapped from existing content, the pivots chosen, the `loom.toml` written, gaps flagged for `/weft`, and the clean lint run.
```

- [ ] **Step 4: Verify**

```bash
grep -nE '\.claude/|\.\./\.\./\.\./|python3 .*doc-lint|source-doc-context|/init-docs|/refine-(linter|context|docs)|settings\.json' skills/dress/SKILL.md || echo "CLEAN"
ls skills/dress/templates    # expect: only loom.toml
```
Expected: `CLEAN`, and `templates/` contains only `loom.toml`.

- [ ] **Step 5: Commit**

```bash
git add -A skills/dress
git commit -m "refactor: init-docs -> dress; fold refine-context/-linter; data-driven loom.toml"
```

---

## Task 4: Add the `warp` stub

**Files:**
- Create: `skills/warp/SKILL.md`

- [ ] **Step 1: Write the stub** — Create `skills/warp/SKILL.md`:

```markdown
---
name: warp
description: (Planned, not yet implemented) Session-open bookend — kick off a unit of work: name and create the branch, set up a worktree, and wire in any ticket/PR context, so a session starts oriented. The open complement to /weft (the close-out). Invoking it today reports that it is a stub.
---

**Status: stub — not yet implemented.** `warp` is the session-*open* bookend, the complement to `/weft` (session close). Where `weft` distills landed work into docs and closes out the branch, `warp` will *open* a unit of work.

Intended scope (deliberately nebulous; meant to be shaped per-repo by the operator):

- Name the work and create/checkout the branch under a consistent convention.
- Optionally set up an isolated worktree.
- Pull in ticket / issue / PR context (e.g. GitHub or Jira) so the session boots oriented.

If invoked now, explain that `warp` is a placeholder and point at `/weft` for closing out work and `/dress` for standing up or tuning the harness.
```

- [ ] **Step 2: Verify it has no stale references**

```bash
grep -nE '\.claude/|\.\./\.\./\.\./|python3|settings\.json' skills/warp/SKILL.md || echo "CLEAN"
```
Expected: `CLEAN`.

- [ ] **Step 3: Commit**

```bash
git add -A skills/warp
git commit -m "feat: add warp skill stub (planned session-open bookend)"
```

---

## Task 5: Delete the old skeleton + repoint the Codex manifest

**Files:**
- Delete: `hooks/hooks.codex.json`, `hooks/source-doc-context.py`, `scripts/doc-lint.py`
- Delete: `skills/refine-context/`, `skills/refine-linter/` (their substance moved into `dress`)
- Modify: `.codex-plugin/plugin.json` (`hooks` → `./hooks/hooks.json`)

- [ ] **Step 1: Remove the dead files and folded skill dirs**

```bash
git rm hooks/hooks.codex.json hooks/source-doc-context.py scripts/doc-lint.py
git rm -r skills/refine-context skills/refine-linter
```

- [ ] **Step 2: Repoint the Codex hooks path** — in `.codex-plugin/plugin.json`, change:

```json
  "hooks": "./hooks/hooks.codex.json",
```
to:
```json
  "hooks": "./hooks/hooks.json",
```

- [ ] **Step 3: Verify the deletions and that nothing references the removed files**

```bash
ls hooks/                       # expect: hooks.json, run-hook.cmd, doc-slicer  (no .codex.json, no .py)
ls skills/                      # expect: dress weave weft warp  (no refine-*, init-docs, wrap, refine-docs)
grep -rnE 'hooks\.codex\.json|source-doc-context|scripts/doc-lint\.py|refine-context|refine-linter|init-docs' \
  skills .codex-plugin .claude-plugin hooks/hooks.json || echo "NO STALE REFS"
```
Expected: the listed dirs are clean, and `NO STALE REFS`.

- [ ] **Step 4: Validate both manifests still name only existing files**

```bash
# Codex manifest points at ./hooks/hooks.json and ./skills/ — both must exist.
test -f hooks/hooks.json && test -d skills && echo "codex paths ok"
# JSON well-formedness without jq (awk slurp + brace balance is enough here):
for m in .codex-plugin/plugin.json .claude-plugin/plugin.json .claude-plugin/marketplace.json .agents/plugins/marketplace.json; do
  awk 'BEGIN{o=0} {n=gsub(/{/,"{"); c=gsub(/}/,"}"); o+=n-c} END{print FILENAME": "(o==0?"balanced":"UNBALANCED")}' "$m"
done
```
Expected: `codex paths ok` and every manifest `balanced`.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: delete jack-shaped skeleton; point Codex manifest at unified hooks.json"
```

---

## Task 6: Make loom lint-clean against its own linter (dogfood) + gitignore

**Files:**
- Create: `docs/config/loom.toml`
- Create: `docs/README.md`
- Create: `AGENTS.md`
- Modify: `README.md` (add a stamped `## Overview`)
- Modify: `.gitignore` (add `.idea/`)

loom isn't an app with `backend/frontend` modules, so it configures **no modules** — only the root README needs a stamped `## Overview`, and the `docs/` tree + `AGENTS.md` need frontmatter. Keep all of this minimal; loom is a plugin, not a worked example.

- [ ] **Step 1: Add loom's own config** — Create `docs/config/loom.toml`:

```toml
# loom.toml — loom's own harness config (loom dogfoods its linter/slicer).
[modules]
dirs = []

[context]
recent_commits = 15
sections = ["docs/config/roadmap.md > ## Now"]
include_modules = false

[lint]
kinds = ["charter", "roadmap", "readme", "guide", "reference", "spec", "plan", "design", "review"]
statuses = ["living", "hardened", "superseded", "scaffolding", "ideation"]
docs_subdirs = ["config", "specs", "plans", "design"]
```

Note: `docs/superpowers/` is intentionally NOT in `docs_subdirs`, so the spec/plan files there are not frontmatter-linted. Only `docs/config/*.md` is (the roadmap).

- [ ] **Step 2: Create `docs/config/roadmap.md`** (referenced by the slicer's default section):

```markdown
---
kind: roadmap
status: living
updated: 2026-06-23
---
# Roadmap

## Now

Porting loom from the jack-shaped skeleton into a coherent Claude+Codex plugin: data-driven `loom.toml`, bash+awk `doc-linter`/`doc-slicer`, textile skill nomenclature.

## Next

Smoke-test the install on both tools; design and build `warp`.

## Milestones

- [x] Core scripts (parser, linter, slicer, hook wiring) — Plan 1
- [ ] Skills rename/reframe + cleanup — Plan 2
- [ ] Smoke-test install (Claude + Codex)
```

- [ ] **Step 3: Create `docs/README.md`** (the source-of-truth doc; must carry frontmatter):

```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# How loom's docs work

loom is a docs & context harness. Its own docs follow the convention it ships:

- **Tier 1 (frontmatter docs):** everything under `docs/config/` plus `AGENTS.md` open with `kind` / `status` / `updated` frontmatter.
- **Tier 2 (stamped READMEs):** the root `README.md` (and any module READMEs) stay frontmatter-free and instead carry a `## Overview` with an `_updated: YYYY-MM-DD_` stamp.
- **Config:** `docs/config/loom.toml` drives the linter (`kinds`/`statuses`/`docs_subdirs`) and the SessionStart slicer (`recent_commits`/`sections`/`modules`).
- **Links are routing:** one home per fact, surfaced by progressive disclosure (root map → deeper doc → code).

The design specs and plans for loom live under `docs/superpowers/` and are intentionally outside the linted `docs_subdirs`.
```

- [ ] **Step 4: Create `AGENTS.md`** (router; carries frontmatter):

```markdown
---
kind: reference
status: living
updated: 2026-06-23
---
# AGENTS

loom — a self-maintaining docs & context harness, packaged as a Claude Code + Codex plugin.

## Agentic Guidelines

- The harness runtime is bash 3.2 + awk, no Python/jq/node. Keep it dependency-free.
- Per-repo tuning lives in `docs/config/loom.toml`, not in plugin code.

## Agentic Validation

- Tests: `bash tests/run`.
- Docs: `bash scripts/doc-linter`.
```

- [ ] **Step 5: Add a stamped `## Overview` to the root `README.md`** — insert directly after the top `# <title>` line (read the file first; keep existing content below). The block:

```markdown
## Overview
_updated: 2026-06-23_

A self-maintaining docs & context harness, packaged as a plugin for Claude Code and Codex. Skills (`dress`, `weave`, `weft`, `warp`) keep a repo's documentation — and thus agent context — high-quality almost autonomously; a SessionStart hook stitches doc slices into each session's opening bearings.
```

If `README.md` already has an `## Overview`, update its stamp/body instead of adding a second one.

- [ ] **Step 6: Gitignore the IDE dir** — append to `.gitignore`:

```
.idea/
```

- [ ] **Step 7: Run loom's linter on loom — must be clean**

```bash
bash scripts/doc-linter
```
Expected: `doc-linter: clean ✓`, exit 0. If it flags anything, fix the flagged file (a missing stamp, a bad enum, a broken link) until clean — do not weaken the linter.

- [ ] **Step 8: Confirm the slicer renders loom's bearings**

```bash
bash hooks/doc-slicer | head -12
```
Expected: the preamble + `## Bearings` git block + the roadmap `## Now` body. No errors.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "docs: loom dogfoods its own harness (lint-clean); gitignore .idea"
```

---

## Task 7: Final verification sweep

**Files:** none (verification only)

- [ ] **Step 1: No stale path references anywhere in skills**

```bash
grep -rnE '\.claude/|\.\./\.\./\.\./|python3 .*doc-lint|source-doc-context|settings\.json|/wrap|/refine-(docs|linter|context)|/init-docs' skills/ || echo "SKILLS CLEAN"
```
Expected: `SKILLS CLEAN`.

- [ ] **Step 2: Skill set is exactly the four textile skills**

```bash
ls -d skills/*/    # expect exactly: skills/dress/ skills/warp/ skills/weave/ skills/weft/
for s in dress weave weft warp; do grep -q "^name: $s$" "skills/$s/SKILL.md" && echo "$s name ok" || echo "$s NAME MISMATCH"; done
```
Expected: only the four dirs; all four `name ok`.

- [ ] **Step 3: Plan-1 test suite still green**

```bash
bash tests/run
```
Expected: `ALL TESTS PASSED`.

- [ ] **Step 4: loom lints clean and the slicer runs**

```bash
bash scripts/doc-linter && echo "LINT OK"; bash hooks/doc-slicer >/dev/null && echo "SLICE OK"
```
Expected: `doc-linter: clean ✓`, `LINT OK`, `SLICE OK`.

- [ ] **Step 5: Old skeleton is fully gone**

```bash
ls hooks/source-doc-context.py scripts/doc-lint.py hooks/hooks.codex.json skills/refine-context skills/refine-linter skills/init-docs skills/wrap skills/refine-docs 2>&1 | grep -c 'No such file' 
```
Expected: `8` (all eight paths gone).

- [ ] **Step 6: Commit (allow-empty milestone marker, if no changes)**

```bash
git commit --allow-empty -m "chore: Plan 2 complete — loom ported to data-driven plugin"
```

---

## Self-review notes (already applied)

- **Spec coverage:** §2 naming → Tasks 1–4; §7 skill reframes → Tasks 1–3; `warp` stub → Task 4; §4 deletions → Task 5; §9 Codex manifest → Task 5; §8 path rules → shared conventions + per-task greps; dogfood validation (§12) → Task 6.
- **Path-rule consistency:** every skill edit ends with a grep gate proving no `.claude/`, `../../../`, `python3 …doc-lint`, `source-doc-context`, or `settings.json` remain.
- **Order:** skills are reframed (removing refs to old files) before the old files are deleted (Task 5), so no task leaves a dangling reference mid-flight.
- **Dogfood scope:** loom configures zero modules (it's a plugin, not an app) — only root-README stamp + `docs/` frontmatter are needed for clean lint; `docs/superpowers/` is deliberately excluded from `docs_subdirs`.

## Execution handoff

After all tasks land green, the branch holds the full port (Plan 1 + Plan 2). Next real-world step (separate, not in this plan): **smoke-test the install** — `/plugin marketplace add /Users/zebulonperrin/IdeaProjects/loom` then `/plugin install loom@loom-dev`, and the Codex equivalent (watch for issue openai/codex#17066 on the root `source.path`). Then use superpowers:finishing-a-development-branch.
