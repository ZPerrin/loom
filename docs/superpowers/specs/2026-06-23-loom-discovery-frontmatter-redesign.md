# loom — discovery-driven frontmatter & generic slicing (design)

_Status: draft for review — 2026-06-23_

## 1. Context & motivation

The plugin port ([2026-06-23-loom-plugin-port-design.md](2026-06-23-loom-plugin-port-design.md))
landed a working data-driven harness, but its model for **which docs loom manages**
is *enumeration*: `loom.toml` lists `[modules] dirs` and `[lint] docs_subdirs`, and the
linter/slicer hardcode a few paths (`AGENTS.md`, `docs/README.md`, root `README.md`).
That list is a parallel registry that drifts from the real tree, and it forces a
two-tier document model (frontmatter docs vs. deliberately frontmatter-free "stamped"
READMEs) that complicates every consumer.

This effort **inverts membership from enumeration to discovery**: a doc declares itself
loom-managed by carrying YAML frontmatter, and the harness *finds* the managed set
instead of being told it. `loom.toml` stops enumerating files and shrinks to pure
behavior (slicing) + policy (lint vocabulary). The slicer becomes a generic
section-harvester driven by headers, not paths.

The shaping thesis (operator's framing): keeping a project well-curated and documented —
without slop, at low context cost — is a real chore. Loom is a set of configurable tools
that wrap that chore, shipping a **sensible default ("base suggestion") plus knobs**. So
when an edge case appears, the answer is usually "add a config knob or a frontmatter
attribute," not "hardcode another structural assumption."

## 2. Decisions (locked during brainstorming)

1. **Membership = discovery, not enumeration.** A doc is loom-managed iff it has YAML
   frontmatter with a `kind` key. No dedicated `loom:` marker.
2. **Discovery (key present) is separate from validation (value legal).** A doc with a
   typo'd `kind` is still *found*, then *flagged* — it never silently vanishes.
3. **Unified frontmatter.** Every managed doc — READMEs included — carries top-of-file
   frontmatter. The frontmatter-free README rule and the inline `_updated:` stamp retire.
4. **The discovery universe includes uncommitted work.** Tracked + staged + untracked
   (gitignore-respected), read from the working tree, so brand-new docs are visible to
   weft/weave the moment they're created.
5. **Slicer = generic section-harvester.** Configured by *headers*, not paths. "Module
   Map" is a user convention you may choose to slice — not a loom primitive.
6. **`loom.toml` slims to behavior + policy.** No file/dir enumeration survives.
7. **Omission detection is advisory** and scoped; `scan_exclude` deferred (YAGNI).
8. **A cleanup pass is part of this work** — every doc/skill/comment referencing the old
   two-tier / enumerated model is corrected, so there is one clear forward story.

## 3. The model: discover structure, configure behavior

| Concern | Old (enumerate) | New (discover / configure) |
|---|---|---|
| Which docs are managed | `[modules] dirs`, `docs_subdirs`, hardcoded paths | frontmatter presence, found via git |
| Which sections load at SessionStart | `sections = ["path > ## Header"]` | `slice_headers = ["## Header", …]` (path-free) |
| Module set & order | `[modules] dirs` | a header you slice (e.g. `## Module Map`), if you use one |
| Lint vocabulary | `[lint] kinds/statuses` | unchanged — still policy in `loom.toml` |

Nothing structural is enumerated anymore: it is either **discovered** (frontmatter) or
**routed** (a section you author and choose to slice).

## 4. Component designs

### 4.1 Discovery (the shared primitive)

A single helper resolves the managed-doc set, reused by linter, slicer, and skills.

- **Universe** (all candidate markdown, uncommitted included, junk excluded):
  ```
  git ls-files --cached --others --exclude-standard -- '*.md'
  ```
  `--cached` = tracked + staged; `--others` = untracked; `--exclude-standard` keeps
  `.gitignore` honored (node_modules, build dirs, etc. stay out). No recursive walk; no
  manual prune list. Outside a git repo, fall back to a bounded `find` over
  `${CLAUDE_PROJECT_DIR}` (degraded mode).
- **Membership:** a candidate is managed iff its first line is `---` and its frontmatter
  block contains a `kind:` key. Read from the working tree so uncommitted edits count.
- **Performance:** one `git` call for the universe; frontmatter is the first few lines of
  each file (bounded by markdown count). The slicer's hot path may use
  `git grep -l --untracked -- ...` as a fast pre-filter, but correctness is defined by
  the working-tree read.

### 4.2 Unified frontmatter

Every managed doc opens with:
```
---
kind: <one of [lint] kinds>
status: <one of [lint] statuses>
updated: YYYY-MM-DD
---
```
Root `README.md` and module READMEs now carry this too. Consequences:

- The linter's two tiers (FRONTMATTER + STAMP) collapse into **one frontmatter rule**.
- The inline `## Overview` + `_updated:` stamp is **removed**; freshness comes from the
  `updated` field, which the slicer can inject.
- GitHub renders a small metadata table atop READMEs. Accepted for now; making it
  invisible (e.g. HTML-comment carrier) is a parked future option, not in scope.

### 4.3 Slicer — generic section-harvester

Config (in `[context]`):
```toml
recent_commits = 15
slice_headers  = ["## Now", "## Module Map"]   # sections to lift, by header
inject_fields  = ["updated", "kind", "location"]  # frontmatter prefix per slice
```
Behavior:
1. Emit the git **Bearings** block (recent commits) — unchanged.
2. For each doc in the discovered set, for each section whose header ∈ `slice_headers`,
   emit the section body prefixed with the chosen `inject_fields`.
3. `updated` + `kind` are the freshness/type signal; `location` (source path) is the
   progressive-disclosure pointer — recommended **on** by default, toggleable.

Properties:
- **Location-independent.** Slices are found by discovery + header, so moving a file
  doesn't break the slice — this kills the broken-relative-path failure mode that the
  old `path > header` form (and the stale NOTES.md) suffered.
- **Header choice is the cost control.** A distinctive header (`## Now`) slices one
  section; a common header (`## Overview`) slices many. `dress` surfaces live per-slice
  cost so the always-on tax stays visible. If finer control is ever needed, the escape
  valves are config (a kind-filter, a scope limiter) or a new frontmatter attribute —
  added on demand, not pre-built.

### 4.4 `loom.toml` — slimmed schema

```toml
[context]
recent_commits = 15
slice_headers  = ["## Now", "## Module Map"]
inject_fields  = ["updated", "kind", "location"]

[lint]
kinds    = ["charter", "roadmap", "readme", "guide", "reference", "spec", "plan", "design", "review"]
statuses = ["living", "hardened", "superseded", "scaffolding", "ideation"]
```
**Removed:** `[modules] dirs`, `[lint] docs_subdirs`, and the path-anchored
`context.sections` / `context.include_modules`. `parse-toml.awk` is unchanged (same TOML
subset). Embedded defaults in each script mirror this schema so loom still works config-less.

### 4.5 Linter — single rule + discovery-driven set

- File set = the discovered managed set (no hardcoded paths, no enumerated dirs).
- **Frontmatter check** (one rule, all managed docs): line 1 is `---`; `kind` ∈ `kinds`;
  `status` ∈ `statuses`; `updated` is ISO `YYYY-MM-DD`. Presence of `kind` is what made
  the doc visible; this validates the *values*.
- **Link checks** (BROKEN / CODELINK / MISSING) — retained as-is.
- **Dropped:** the STAMP tier and the "README must be frontmatter-free" rule.

### 4.6 Omission sweep (advisory; weave/weft)

The same `--others`-inclusive universe (§4.1) − discovered managed = **candidates**
(markdown with no frontmatter, uncommitted ones included). weave surfaces them: "these
look like docs but aren't loom-managed — adopt?" Advisory, never auto-mutating. With
module/subdir enumeration gone, the sweep has no structural scope to lean on, so noise is
controlled by **operator triage** (it's advisory — dismiss what isn't a doc) rather than a
built-in filter. `scan_exclude` (a config glob) is **deferred** until a real false-positive
recurs; it is the lever if triage alone proves noisy, not per-file tags.

### 4.7 Uncommitted-doc robustness (weft/weave provenance)

For the everyday consumers (linter, slicer), uncommitted managed docs are included
silently — you want a doc you just wrote linted and sliced before commit. But weft/weave
*act on* the set, so they classify by provenance and **surface, then ask**:

- `git status --porcelain -- '*.md'` → `??` untracked, `A` staged-new, ` M` modified,
  ` D` deleted.
- weft/weave report: "N managed docs are new/uncommitted (…) — distill/adopt in this
  pass?"; "doc X is deleted — drop it?" — ask, don't assume.

This pulls the awareness weft's close-out gate already has (it runs `git status
--porcelain` before merging) *earlier*, into the distill phase, so new docs are caught
when created, not only at merge.

## 5. Skill impacts

- **dress** — scaffolds **unified frontmatter** (READMEs included; no inline stamp),
  writes the **slimmed `loom.toml`** (no module/subdir enumeration). The re-tune loop now
  tunes `slice_headers` / `inject_fields` against live rendered cost.
- **weave** — consumes the **discovery index** (git, not agentic search) for its file
  set; runs the **omission sweep**; surfaces **uncommitted** docs.
- **weft** — same discovery + provenance surfacing in the distill phase; close-out gate
  unchanged in spirit (now redundant-aware of what distill already surfaced).
- **warp** — unaffected (still a stub).

## 6. Cleanup pass (explicit deliverable)

This is required work, not a follow-up: scrub every reference to the old direction,
terminology, and assumptions so the forward path is unambiguous. Known targets:

- **`docs/README.md`** — rewrite the doc-model section: one unified-frontmatter tier (not
  Tier 1 / Tier 2); membership by discovery; the slimmed `loom.toml` keys
  (`slice_headers`/`inject_fields`, not `docs_subdirs`/`sections`/`modules`).
- **`NOTES.md`** — already fully stale (path-reference/manifest/textile-rename questions
  all resolved). Either delete or reduce to genuinely-open items; remove "skeleton only /
  expect broken links."
- **Dogfood docs** — give root `README.md`, `AGENTS.md`, and any module READMEs unified
  frontmatter; delete inline `_updated:` stamps. Rewrite loom's own `loom.toml`.
- **Script headers/comments** — `doc-linter` ("two-tier"), `doc-slicer` ("sections"),
  embedded defaults, and any usage strings.
- **Prior spec** — add a forward-pointing note to
  [2026-06-23-loom-plugin-port-design.md](2026-06-23-loom-plugin-port-design.md) marking
  the enumerated-membership / two-tier parts as superseded by this spec (don't rewrite
  history; mark it).
- **Tests/fixtures** — `repo-clean` / `repo-dirty` / `slice-repo` fixtures encode the old
  two-tier model and `loom.toml` schema; rebuild them for discovery + unified frontmatter.

Exit criterion for the cleanup: a fresh reader of the repo encounters **no** description
of the enumerated/two-tier model as current.

## 7. Blast radius, testing, out of scope

**Touched:** `hooks/doc-slicer` (rewritten as harvester), `scripts/doc-linter`
(single frontmatter rule + discovery set), the `loom.toml` schema, all four SKILL.md
files, loom's dogfood docs, `docs/README.md`, `NOTES.md`, and the entire `tests/`
fixture+assertion set. **Untouched:** `parse-toml.awk`, `run-hook.cmd`, `hooks.json`,
the manifests.

**Testing:** new fixtures for discovery (tracked/staged/untracked/gitignored markdown),
unified-frontmatter lint (valid, bad value, missing key, typo'd kind = found-then-flagged),
header-harvest slicing (path-independence, multi-doc same header, `inject_fields`), and an
omission-sweep fixture (doc without frontmatter → candidate). The bash harness in `tests/`
stays dependency-free.

**Out of scope:** building `warp`; the smoke-test install; an invisible-marker carrier for
READMEs; `scan_exclude`; generating manifests from one core.

## 8. Open questions

- **Specs under `docs/superpowers/`** — currently frontmatter-free and outside the old
  `docs_subdirs`. Under discovery, frontmatter would make them managed. Decision: leave
  them frontmatter-free (unmanaged scaffolding) unless we want them linted/sliced. Default:
  leave unmanaged; revisit if useful.
- **Sequencing vs. smoke-test** — this redesign predates the not-yet-done install
  smoke-test. Likely land this first (it changes the dogfood docs the smoke-test would
  exercise), but confirm before planning.
