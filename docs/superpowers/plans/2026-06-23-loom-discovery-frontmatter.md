# loom — discovery-driven frontmatter & generic slicing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace loom's enumerated managed-doc model (loom.toml module/subdir lists + two document tiers) with discovery — a doc is managed iff it carries `kind:` frontmatter — and make the slicer a path-free header-harvester.

**Architecture:** A new sourced bash library `scripts/lib/discover.sh` resolves the managed-doc set from `git ls-files --cached --others --exclude-standard` (uncommitted docs included, gitignored excluded) by frontmatter presence. The linter and slicer both source it; the linter drops its two-tier/STAMP logic for a single frontmatter rule over the discovered set, and the slicer harvests configured `slice_headers` across that set, prefixing each slice with `inject_fields` read from frontmatter. `loom.toml` slims to `[context]` (recent_commits / slice_headers / inject_fields) + `[lint]` (kinds / statuses). All of loom's own dogfood docs migrate to unified frontmatter, and a cleanup pass removes every stale reference to the old model.

**Tech Stack:** bash 3.2 + awk (no Python/jq/node); the dependency-free test harness in `tests/`; git plumbing (`ls-files`, `status`, `check-ignore`).

**Sequencing note:** Tasks are ordered so the repo stays green at every commit. loom dogfoods its own linter, so the linter rewrite and the dogfood-doc frontmatter migration land together in Task 3. `scripts/lib/parse-toml.awk` and its tests are NOT modified (the parser is generic; only loom's *use* of the schema changes).

---

## File structure

| File | Responsibility | Task |
|---|---|---|
| `scripts/lib/discover.sh` (new) | shared discovery primitives: universe, managed set, candidates, frontmatter read, repo root | 1 |
| `scripts/doc-scan` (new) | CLI wrapper: print managed vs. unmanaged-candidate markdown; consumed by weave/weft | 1 |
| `tests/test-discover.sh` (new) + `tests/fixtures/discover-repo/` | discovery unit tests across tracked/staged/untracked/gitignored | 1 |
| `hooks/doc-slicer` (rewrite) | generic header-harvester over the managed set | 2 |
| `tests/test-doc-slicer.sh` (rewrite) + `tests/fixtures/slice-repo/` (rebuild) | slicer tests for path-free harvesting + inject_fields | 2 |
| `scripts/doc-linter` (rewrite) | one frontmatter rule + link checks over the discovered set | 3 |
| `README.md`, `docs/README.md`, `docs/config/loom.toml` (loom's own) | dogfood migration to unified frontmatter + slimmed schema | 3 |
| `tests/test-doc-linter.sh` (rewrite) + `tests/fixtures/repo-clean,repo-dirty/` (rebuild) | linter tests for unified frontmatter, no STAMP tier | 3 |
| `skills/{dress,weave,weft}/SKILL.md` | reframe to discovery / unified frontmatter / new keys / omission sweep / provenance | 4 |
| `NOTES.md`, prior spec, README naming table | cleanup pass over stale direction | 5 |

---

## Task 1: Discovery foundation

Build the shared library every consumer will use, plus a thin CLI for the skills. Pure addition — nothing existing changes, so the repo stays green.

**Files:**
- Create: `scripts/lib/discover.sh`
- Create: `scripts/doc-scan`
- Create: `tests/fixtures/discover-repo/a.md`, `b.md`, `sub/c.md`, `.gitignore`
- Test: `tests/test-discover.sh`

- [ ] **Step 1: Create the discovery fixture files**

Create `tests/fixtures/discover-repo/a.md`:
```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# a

Managed doc.
```

Create `tests/fixtures/discover-repo/b.md`:
```markdown
# b

No frontmatter — a candidate, not managed.
```

Create `tests/fixtures/discover-repo/sub/c.md`:
```markdown
---
kind: spec
status: ideation
updated: 2026-06-23
---
# c

Managed doc in a subdir.
```

Create `tests/fixtures/discover-repo/.gitignore`:
```
ignored.md
```

- [ ] **Step 2: Write the failing test**

Create `tests/test-discover.sh`:
```bash
#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
. "$DIR/../scripts/lib/discover.sh"
R="$DIR/fixtures/discover-repo"

# Fresh nested repo: stage the committed fixtures; add a NEW untracked managed doc
# and a gitignored managed doc at runtime to exercise --others / --exclude-standard.
rm -rf "$R/.git" "$R/untracked.md" "$R/ignored.md"
( cd "$R" && git init -q . && git add a.md b.md sub/c.md .gitignore )
printf -- '---\nkind: guide\nstatus: living\nupdated: 2026-06-23\n---\n# u\n\nNew, uncommitted.\n' > "$R/untracked.md"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-06-23\n---\n# i\n\nGitignored.\n' > "$R/ignored.md"

uni="$(doc_universe "$R")"
man="$(managed_docs "$R")"
cand="$(omission_candidates "$R")"
fld="$(frontmatter_field "$R/a.md" kind)"

assert_contains    "$uni"  "a.md"        "universe includes tracked managed doc"
assert_contains    "$uni"  "untracked.md" "universe includes untracked (--others) doc"
assert_not_contains "$uni" "ignored.md"  "universe excludes gitignored doc"

assert_contains    "$man"  "a.md"        "managed includes a.md"
assert_contains    "$man"  "sub/c.md"    "managed includes nested spec"
assert_contains    "$man"  "untracked.md" "managed includes untracked managed doc"
assert_not_contains "$man" "b.md"        "managed excludes frontmatter-less b.md"
assert_not_contains "$man" "ignored.md"  "managed excludes gitignored doc"

assert_contains    "$cand" "b.md"        "candidates include frontmatter-less doc"
assert_not_contains "$cand" "a.md"       "candidates exclude managed doc"

assert_eq          "$fld"  "readme"      "frontmatter_field reads kind"

rm -rf "$R/.git" "$R/untracked.md" "$R/ignored.md"
finish
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `bash tests/test-discover.sh`
Expected: FAIL — `discover.sh` does not exist, so sourcing errors / functions undefined.

- [ ] **Step 4: Implement the discovery library**

Create `scripts/lib/discover.sh`:
```bash
# scripts/lib/discover.sh — managed-doc discovery for loom (bash 3.2 + awk, no deps).
# Source this, then call the functions below. A doc is "managed" iff it has YAML
# frontmatter containing a `kind:` key (presence, not value-validity). The universe is
# git tracked + staged + untracked (gitignore-respected), read from the working tree, so
# uncommitted docs are visible. Degrades to a bounded find outside a git repo.
# All paths are emitted repo-root-relative.

loom_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null && return
  printf '%s\n' "${CLAUDE_PROJECT_DIR:-$PWD}"
}

doc_universe() { # $1=ROOT  -> repo-relative *.md paths
  local root="$1"
  if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$root" ls-files --cached --others --exclude-standard -- '*.md'
  else
    ( cd "$root" 2>/dev/null && find . -type f -name '*.md' \
        -not -path '*/.git/*' -not -path '*/node_modules/*' | sed 's|^\./||' )
  fi
}

has_kind_frontmatter() { # $1=abs file  -> exit 0 iff frontmatter has a kind: key
  local first
  IFS= read -r first < "$1" 2>/dev/null || return 1
  [ "$first" = "---" ] || return 1
  awk '
    NR==1        { next }            # skip opening ---
    /^---[ \t]*$/ { exit 1 }         # closing --- reached, no kind found
    /^kind:/     { exit 0 }          # kind key present
    END          { exit 1 }
  ' "$1"
}

managed_docs() { # $1=ROOT  -> repo-relative paths of managed docs
  local root="$1" rel
  doc_universe "$root" | while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    has_kind_frontmatter "$root/$rel" && printf '%s\n' "$rel"
  done
}

omission_candidates() { # $1=ROOT  -> repo-relative *.md lacking kind frontmatter
  local root="$1" rel
  doc_universe "$root" | while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    has_kind_frontmatter "$root/$rel" || printf '%s\n' "$rel"
  done
}

frontmatter_field() { # $1=abs file  $2=key  -> value (frontmatter block only)
  awk -v k="$2" '
    NR==1        { if ($0 != "---") exit; next }
    /^---[ \t]*$/ { exit }
    index($0, k ":") == 1 { v=$0; sub(/^[^:]*:[ \t]*/, "", v); print v; exit }
  ' "$1"
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `bash tests/test-discover.sh`
Expected: PASS — `test-discover.sh passed`.

- [ ] **Step 6: Implement the doc-scan CLI wrapper**

Create `scripts/doc-scan`:
```bash
#!/usr/bin/env bash
# doc-scan — classify a repo's markdown as loom-managed vs. unmanaged candidates.
# Consumed by weave/weft to surface docs that look like docs but carry no frontmatter.
# Output: a "# managed" header + paths, then a "# candidates" header + paths.
set -u
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SELF_DIR/lib/discover.sh"
ROOT="$(loom_repo_root)"

printf '# managed (%s)\n' "$ROOT"
managed_docs "$ROOT"
printf '# candidates — markdown without kind frontmatter\n'
omission_candidates "$ROOT"
```

- [ ] **Step 7: Smoke-test doc-scan against loom itself**

Run: `bash scripts/doc-scan`
Expected: lists loom's managed docs (`README.md`, `AGENTS.md`, `docs/README.md`, `docs/config/charter.md`, `docs/config/roadmap.md`) under `# managed`, and the `docs/superpowers/**` specs/plans under `# candidates` (they are intentionally unmanaged — see Task 4 weave prose).
Note: at this point `README.md` is still frontmatter-free (migrated in Task 3), so it will appear under candidates until then — that is expected.

- [ ] **Step 8: Run the full suite**

Run: `bash tests/run`
Expected: `ALL TESTS PASSED` (existing linter/slicer/parse tests untouched and still green).

- [ ] **Step 9: Commit**

```bash
git add scripts/lib/discover.sh scripts/doc-scan tests/test-discover.sh tests/fixtures/discover-repo
git commit -m "feat: discovery library — managed-doc set via frontmatter + git

scripts/lib/discover.sh resolves the managed-doc set from git ls-files
(tracked+staged+untracked, gitignore-respected) by kind: frontmatter presence.
scripts/doc-scan exposes managed vs. candidate classification for weave/weft.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 1b: Discovery exclusion knob

Discovery sees loom's own `tests/fixtures/**` (tracked markdown with `kind:` frontmatter), which would break dogfooding (the dirty fixtures fail the linter; a fixture `## Now` leaks into the slicer). Add a universe-level `[discovery] exclude` prefix filter so all consumers honor it, and exclude loom's fixtures.

**Files:**
- Modify: `scripts/lib/discover.sh` (filter `doc_universe`; add `doc_excludes`/`_excluded`/`_list_md`)
- Modify: `tests/test-discover.sh` (add an exclusion assertion)
- Modify: `docs/config/loom.toml` (add `[discovery] exclude = ["tests/fixtures"]`)

- [ ] **Step 1: Add the failing exclusion assertion**

In `tests/test-discover.sh`, immediately before the final `finish`, insert:
```bash
# Exclusion: a [discovery] exclude prefix removes matching paths from the universe.
rm -rf "$R/.git" "$R/docs"
mkdir -p "$R/docs/config"
printf '[discovery]\nexclude = ["sub"]\n' > "$R/docs/config/loom.toml"
( cd "$R" && git init -q . && git add a.md b.md sub/c.md .gitignore docs/config/loom.toml )
xman="$(managed_docs "$R")"
assert_not_contains "$xman" "sub/c.md" "excluded prefix drops sub/c.md from managed set"
assert_contains    "$xman" "a.md"     "non-excluded managed doc still present"
rm -rf "$R/.git" "$R/docs"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test-discover.sh`
Expected: FAIL — `doc_universe` does not yet read `[discovery] exclude`, so `sub/c.md` is still listed.

- [ ] **Step 3: Implement the exclusion filter**

In `scripts/lib/discover.sh`, add a self-locating dir just below the header comment:
```bash
_DISCOVER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
```
Then replace the existing `doc_universe` function with these four functions:
```bash
# raw markdown listing (git-aware, gitignore-respected; bounded find fallback)
_list_md() { # $1=ROOT
  local root="$1"
  if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$root" ls-files --cached --others --exclude-standard -- '*.md'
  else
    ( cd "$root" 2>/dev/null && find . -type f -name '*.md' \
        -not -path '*/.git/*' -not -path '*/node_modules/*' | sed 's|^\./||' )
  fi
}

# exclude path-prefixes from [discovery] exclude in <ROOT>/docs/config/loom.toml
doc_excludes() { # $1=ROOT
  local conf="$1/docs/config/loom.toml"
  [ -f "$conf" ] || return 0
  awk -f "$_DISCOVER_DIR/parse-toml.awk" "$conf" 2>/dev/null \
    | awk -F= '$1=="discovery.exclude"{sub(/^[^=]*=/,""); print}'
}

_excluded() { # $1=relpath $2=newline-separated exclude prefixes -> 0 if excluded
  local p="$1" e
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    case "$p" in "$e"|"$e"/*) return 0 ;; esac
  done <<EOF
$2
EOF
  return 1
}

doc_universe() { # $1=ROOT -> repo-relative *.md, minus [discovery] exclude prefixes
  local root="$1" excl rel
  excl="$(doc_excludes "$root")"
  _list_md "$root" | while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    _excluded "$rel" "$excl" || printf '%s\n' "$rel"
  done
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tests/test-discover.sh`
Expected: PASS — `test-discover.sh passed`.

- [ ] **Step 5: Exclude loom's own fixtures**

In `docs/config/loom.toml`, add a `[discovery]` table at the top (above `[modules]`):
```toml
[discovery]
exclude = ["tests/fixtures"]
```
(This is harmless to the still-current old linter/slicer — they read `[lint]`/`[context]`, and `parse-toml.awk` parses the new table fine.)

- [ ] **Step 6: Verify loom's own discovery now skips fixtures**

Run: `bash scripts/doc-scan`
Expected: under `# managed`, loom's real docs only — NO `tests/fixtures/**` paths. Under `# candidates`, the `docs/superpowers/**` specs/plans (still no `tests/fixtures/**`).

- [ ] **Step 7: Run the full suite**

Run: `bash tests/run`
Expected: `ALL TESTS PASSED`.

- [ ] **Step 8: Commit**

```bash
git add scripts/lib/discover.sh tests/test-discover.sh docs/config/loom.toml
git commit -m "feat: [discovery] exclude — keep test fixtures out of the managed set

doc_universe now filters repo-relative paths against [discovery] exclude prefixes
from loom.toml, so the linter/slicer/doc-scan uniformly skip excluded trees. loom
excludes tests/fixtures so it can dogfood its own harness without linting its
intentionally-malformed fixtures or slicing their headers.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Slicer → header harvester

Rewrite the SessionStart slicer to harvest configured headers across the discovered set, path-free, with `inject_fields` annotations. Update loom's own `[context]` config and rebuild the slicer fixtures/tests. The linter is untouched, so the repo stays green.

**Files:**
- Modify: `hooks/doc-slicer` (full rewrite)
- Modify: `docs/config/loom.toml` (`[context]` table only)
- Rebuild: `tests/fixtures/slice-repo/` (README.md, mod/README.md, docs/config/roadmap.md, docs/config/loom.toml)
- Test: `tests/test-doc-slicer.sh` (rewrite)

- [ ] **Step 1: Rebuild the slice-repo fixture**

Replace `tests/fixtures/slice-repo/README.md` with:
```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# example

## Module Map

- the example module — see [mod](mod/README.md)
```

Replace `tests/fixtures/slice-repo/mod/README.md` with:
```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# mod

## Overview

Module overview body.
```

Replace `tests/fixtures/slice-repo/docs/config/roadmap.md` with:
```markdown
---
kind: roadmap
status: living
updated: 2026-06-23
---
# Roadmap

## Now

Shipping the slicer.

## Next

Later stuff.
```

Replace `tests/fixtures/slice-repo/docs/config/loom.toml` with:
```toml
[context]
recent_commits = 15
slice_headers = ["## Now", "## Module Map"]
inject_fields = ["kind", "location"]
```

- [ ] **Step 2: Write the failing test**

Replace `tests/test-doc-slicer.sh` with:
```bash
#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
SLICER="$DIR/../hooks/doc-slicer"
R="$DIR/fixtures/slice-repo"

rm -rf "$R/.git"
( cd "$R" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: slice repo" )
out="$(cd "$R" && bash "$SLICER" 2>&1)"; rc=$?
assert_exit "$rc" "0" "slicer exits 0"
assert_contains "$out" "Bearings"              "emits Bearings heading"
assert_contains "$out" "seed: slice repo"      "includes recent commit"
assert_contains "$out" "Shipping the slicer."  "harvests ## Now body"
assert_contains "$out" "the example module"    "harvests ## Module Map body"
assert_contains "$out" "kind: roadmap"         "inject_fields annotates kind"
assert_contains "$out" "docs/config/roadmap.md" "inject_fields annotates location"
assert_not_contains "$out" "Module overview body." "unconfigured ## Overview NOT harvested"
rm -rf "$R/.git"

# No loom.toml: defaults (## Now header, no managed docs) -> Bearings only, no crash.
NC="$DIR/fixtures/slice-noconf"
rm -rf "$NC"; mkdir -p "$NC"
printf 'plain text, no docs\n' > "$NC/notes.txt"
( cd "$NC" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: no conf" )
nout="$(cd "$NC" && bash "$SLICER" 2>&1)"; nrc=$?
assert_exit "$nrc" "0" "no-config slicer exits 0"
assert_contains "$nout" "Bearings"      "no-config still emits Bearings"
assert_contains "$nout" "seed: no conf" "no-config includes git log"
rm -rf "$NC"

finish
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `bash tests/test-doc-slicer.sh`
Expected: FAIL — the current slicer reads `context.sections`/`include_modules`, so it won't harvest `## Module Map` via `slice_headers` and won't emit `kind:`/location annotations.

- [ ] **Step 4: Rewrite the slicer**

Replace `hooks/doc-slicer` with:
```bash
#!/usr/bin/env bash
# doc-slicer — SessionStart context for loom (bash 3.2 + awk, no deps).
# Emits a preamble, a git "Bearings" block, then harvests every section whose header is
# in context.slice_headers across the discovered managed-doc set, each prefixed with a
# context.inject_fields annotation (frontmatter values; `location` = the source path).
# Path-free: slices are found by discovery + header, so moving a file never breaks them.
set -u

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
PARSE_AWK="$SELF_DIR/../scripts/lib/parse-toml.awk"
. "$SELF_DIR/../scripts/lib/discover.sh"
ROOT="$(loom_repo_root)"

DEFAULT_CFG='context.recent_commits=15
context.slice_headers=## Now
context.inject_fields=updated
context.inject_fields=kind
context.inject_fields=location'
CONF="$ROOT/docs/config/loom.toml"
if [ -f "$CONF" ]; then
  CFG="$(awk -f "$PARSE_AWK" "$CONF")" || CFG="$DEFAULT_CFG"
else
  CFG="$DEFAULT_CFG"
fi
cfg_get() { printf '%s\n' "$CFG" | awk -F= -v k="$1" '$1==k{sub(/^[^=]*=/,""); print}'; }

COMMITS="$(cfg_get context.recent_commits)"; COMMITS="${COMMITS:-15}"
case "$COMMITS" in ''|*[!0-9]*) COMMITS=15 ;; esac
SLICE_HEADERS="$(cfg_get context.slice_headers)"
INJECT_FIELDS="$(cfg_get context.inject_fields)"

# print the markdown under "<header>" in <file>, header line excluded, stop at next "## ".
emit_section() { # $1=file $2=header
  [ -f "$1" ] || return 0
  awk -v hdr="$2" '
    $0 == hdr { cap = 1; next }
    cap && /^## / { exit }
    cap { print }
  ' "$1"
}

# one-line annotation for a managed doc, built from INJECT_FIELDS in order.
annotate() { # $1=rel
  local rel="$1" abs="$ROOT/$1" out="" field val
  while IFS= read -r field; do
    [ -n "$field" ] || continue
    case "$field" in
      location) val="$rel" ;;
      *) v="$(frontmatter_field "$abs" "$field")"; [ -n "$v" ] && val="$field: $v" || val="" ;;
    esac
    [ -n "$val" ] && { [ -n "$out" ] && out="$out · $val" || out="$val"; }
  done <<EOF
$INJECT_FIELDS
EOF
  printf '%s' "$out"
}

printf '_The slices below are your opening context — the next ring of progressive disclosure past AGENTS.md. Read the deeper docs when a task goes past a slice._\n\n'

printf '## Bearings — recent activity (from git)\n\n_Where the work just was, newest first:_\n\n'
git -C "$ROOT" log --oneline -"$COMMITS" 2>/dev/null || echo "(no git history)"
printf '\n'

# Harvest configured headers across the managed set (cache the set once).
MANAGED="$(managed_docs "$ROOT")"
while IFS= read -r hdr; do
  [ -n "$hdr" ] || continue
  shown=""
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    body="$(emit_section "$ROOT/$rel" "$hdr")"
    [ -n "$body" ] || continue
    if [ -z "$shown" ]; then printf '## %s\n\n' "${hdr#"## "}"; shown=1; fi
    ann="$(annotate "$rel")"
    [ -n "$ann" ] && printf '_%s_\n\n' "$ann"
    printf '%s\n\n' "$body"
  done <<EOF
$MANAGED
EOF
done <<EOF
$SLICE_HEADERS
EOF
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `bash tests/test-doc-slicer.sh`
Expected: PASS — `test-doc-slicer.sh passed`.

- [ ] **Step 6: Migrate loom's own `[context]` config**

In `docs/config/loom.toml`, replace the `[context]` table. Change:
```toml
[context]
recent_commits = 15
sections = ["docs/config/roadmap.md > ## Now"]
include_modules = false
```
to:
```toml
[context]
recent_commits = 15
slice_headers = ["## Now"]
inject_fields = ["updated", "kind", "location"]
```
Leave the `[modules]` and `[lint]` tables unchanged for now — Task 3 removes `[modules]`.

- [ ] **Step 7: Verify the slicer renders loom's own bearings**

Run: `bash hooks/doc-slicer`
Expected: a Bearings block of recent commits, then a `## Now` slice harvested from `docs/config/roadmap.md` with an annotation line containing `kind: roadmap · location` path. No crash, exit 0.

- [ ] **Step 8: Run the full suite**

Run: `bash tests/run`
Expected: `ALL TESTS PASSED`.

- [ ] **Step 9: Commit**

```bash
git add hooks/doc-slicer docs/config/loom.toml tests/test-doc-slicer.sh tests/fixtures/slice-repo
git commit -m "feat: slicer harvests headers across discovered docs (path-free)

doc-slicer now reads context.slice_headers + context.inject_fields and harvests
matching sections across the managed set, annotating each with frontmatter
fields (location = source path). Drops the path-anchored sections/modules model.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Linter → discovery + unified frontmatter

The coupled task: rewrite the linter to lint the discovered set with one frontmatter rule (no STAMP tier), migrate loom's own README/docs to unified frontmatter, slim `[lint]` config, and rebuild the linter fixtures/tests. Everything green under the new linter by the end.

**Files:**
- Modify: `scripts/doc-linter` (full rewrite)
- Modify: `README.md` (add frontmatter, drop inline stamp + fix naming table)
- Modify: `docs/README.md` (rewrite doc-model section for unified frontmatter)
- Modify: `docs/config/loom.toml` (drop `[modules]`; keep `[lint]`)
- Rebuild: `tests/fixtures/repo-clean/`, `tests/fixtures/repo-dirty/`
- Test: `tests/test-doc-linter.sh` (rewrite)

- [ ] **Step 1: Rebuild the repo-clean fixture**

Replace `tests/fixtures/repo-clean/README.md`:
```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# clean

A tidy repo with no findings.
```

Replace `tests/fixtures/repo-clean/AGENTS.md`:
```markdown
---
kind: reference
status: living
updated: 2026-06-23
---
# AGENTS

Guidelines live here.
```

Replace `tests/fixtures/repo-clean/docs/README.md`:
```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# docs

How docs work here.
```

Replace `tests/fixtures/repo-clean/mod/README.md`:
```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# mod

A module.
```

Replace `tests/fixtures/repo-clean/docs/config/loom.toml`:
```toml
[lint]
kinds = ["charter", "roadmap", "readme", "guide", "reference", "spec", "plan", "design", "review"]
statuses = ["living", "hardened", "superseded", "scaffolding", "ideation"]
```

- [ ] **Step 2: Rebuild the repo-dirty fixture**

Replace `tests/fixtures/repo-dirty/README.md` (note the em-dash `—` is U+2014):
```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# dirty

See [docs](nope/missing.md).

Run [`run`](run.md) to start.

- `mod/README.md` — the module doc
```

Create `tests/fixtures/repo-dirty/run.md` (frontmatter-less link target — unmanaged, just resolves the code-styled link):
```markdown
# run

Just a link target.
```

Replace `tests/fixtures/repo-dirty/docs/README.md`:
```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# docs

Clean docs index.
```

Replace `tests/fixtures/repo-dirty/mod/README.md`:
```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# mod

Valid module (a real MISSING-link target).
```

Replace `tests/fixtures/repo-dirty/my mod/README.md` (spaced dir; invalid kind drives a FRONTMATTER finding that must name the spaced path):
```markdown
---
kind: bogus
status: living
updated: 2026-06-23
---
# spaced

Bad kind in a directory whose name has a space.
```

Create `tests/fixtures/repo-dirty/docs/config/loom.toml`:
```toml
[lint]
kinds = ["charter", "roadmap", "readme", "guide", "reference", "spec", "plan", "design", "review"]
statuses = ["living", "hardened", "superseded", "scaffolding", "ideation"]
```

- [ ] **Step 3: Write the failing test**

Replace `tests/test-doc-linter.sh`:
```bash
#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
LINTER="$DIR/../scripts/doc-linter"

# Clean fixture: unified frontmatter, no links -> exit 0, reports clean.
rm -rf "$DIR/fixtures/repo-clean/.git"
out="$(cd "$DIR/fixtures/repo-clean" && git init -q . && git add -A && bash "$LINTER" 2>&1)"; rc=$?
assert_exit "$rc" "0" "clean fixture exits 0"
assert_contains "$out" "doc-linter: clean" "clean fixture reports clean"
rm -rf "$DIR/fixtures/repo-clean/.git"

# Dirty fixture: link + frontmatter findings, NO stamp tier.
rm -rf "$DIR/fixtures/repo-dirty/.git"
(cd "$DIR/fixtures/repo-dirty" && git init -q . && git add -A)
dout="$(cd "$DIR/fixtures/repo-dirty" && bash "$LINTER" 2>&1)"; drc=$?
assert_exit "$drc" "1" "dirty fixture exits 1"
assert_contains "$dout" "BROKEN"            "reports BROKEN link"
assert_contains "$dout" "nope/missing.md"   "names the broken href"
assert_contains "$dout" "CODELINK"          "reports CODELINK"
assert_contains "$dout" "MISSING"           "reports MISSING list-path link"
assert_contains "$dout" "FRONTMATTER"       "reports bad frontmatter kind"
assert_contains "$dout" "my mod/README.md"  "spaced-dir managed doc is checked (no word-split)"
assert_not_contains "$dout" "STAMP"         "STAMP tier removed"
rm -rf "$DIR/fixtures/repo-dirty/.git"

finish
```

- [ ] **Step 4: Run the test to verify it fails**

Run: `bash tests/test-doc-linter.sh`
Expected: FAIL — the current linter emits STAMP findings (and the clean fixture's READMEs now carry frontmatter, which the old STAMP rule rejects), so both the clean and `not_contains STAMP` assertions fail.

- [ ] **Step 5: Rewrite the linter**

Replace `scripts/doc-linter` with:
```bash
#!/usr/bin/env bash
# doc-linter — doc hygiene for loom-managed Markdown (bash 3.2 + awk, no deps).
# Managed set = discovery (frontmatter with a kind: key), via scripts/lib/discover.sh.
# Checks: BROKEN, CODELINK, MISSING (links); FRONTMATTER (kind/status/updated values).
# Config: <repo>/docs/config/loom.toml ([lint] kinds/statuses) or embedded defaults.
set -u

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
PARSE_AWK="$SELF_DIR/lib/parse-toml.awk"
. "$SELF_DIR/lib/discover.sh"
ROOT="$(loom_repo_root)"

# --- config: normalized "table.key=value" text, from loom.toml or defaults ---
DEFAULT_CFG='lint.kinds=charter
lint.kinds=roadmap
lint.kinds=readme
lint.kinds=guide
lint.kinds=reference
lint.kinds=spec
lint.kinds=plan
lint.kinds=design
lint.kinds=review
lint.statuses=living
lint.statuses=hardened
lint.statuses=superseded
lint.statuses=scaffolding
lint.statuses=ideation'
CONF="$ROOT/docs/config/loom.toml"
if [ -f "$CONF" ]; then
  CFG="$(awk -f "$PARSE_AWK" "$CONF")" || { echo "doc-linter: bad loom.toml" >&2; exit 2; }
else
  CFG="$DEFAULT_CFG"
fi
cfg_get() { printf '%s\n' "$CFG" | awk -F= -v k="$1" '$1==k{sub(/^[^=]*=/,""); print}'; }

KINDS="$(cfg_get lint.kinds)"
STATUSES="$(cfg_get lint.statuses)"

FINDINGS=""
add() { FINDINGS="${FINDINGS}$1
"; }

# Emit, per line of a markdown file, candidate findings. awk extracts; bash resolves
# filesystem existence. Fenced code blocks skipped.
# Output lines: "BROKEN<TAB>href", "CODELINK<TAB>text", "MISSING<TAB>span".
scan_lines() { # $1=file
  awk '
    /^[ \t]*```/ { fence = !fence; next }
    fence { next }
    {
      line = $0
      s = line
      while (match(s, /\[[^]]*\]\([^)]+\)/)) {
        chunk = substr(s, RSTART, RLENGTH)
        href = chunk; sub(/^[^(]*\(/, "", href); sub(/\)$/, "", href)
        sub(/#.*$/, "", href)
        if (href !~ /^(https?:|mailto:)/ && href != "") print "BROKEN\t" href
        if (chunk ~ /^\[`[^`]*`\]\(/) {
          t = chunk; sub(/^\[`/, "", t); sub(/`\].*$/, "", t); print "CODELINK\t" t
        }
        s = substr(s, RSTART + RLENGTH)
      }
      if (line ~ /^[ \t]*[-*][ \t]+`[^`]+`[ \t]*—/ && line !~ /\]\(/) {
        span = line; sub(/^[ \t]*[-*][ \t]+`/, "", span); sub(/`.*$/, "", span)
        if (span ~ /[\/.]/) print "MISSING\t" span
      }
    }
  ' "$1"
}

check_links() { # $1=file
  local f="$1" dir rel kind rest
  dir="$(dirname "$f")"; rel="${f#"$ROOT"/}"
  while IFS=$'\t' read -r kind rest; do
    case "$kind" in
      BROKEN)
        [ -e "$dir/$rest" ] || add "BROKEN   $rel: $rest" ;;
      CODELINK)
        add "CODELINK $rel: \`$rest\` — use plain link text [$rest](…)" ;;
      MISSING)
        local tgt="$dir/$rest"
        if [ -e "$tgt" ] && ! git -C "$ROOT" check-ignore -q "$tgt" 2>/dev/null; then
          add "MISSING $rel: list path \`$rest\` should be a link"
        fi ;;
    esac
  done < <(scan_lines "$f")
}

in_list() { printf '%s\n' "$2" | grep -qxF "$1"; }

check_frontmatter() { # $1=file  (every managed doc has frontmatter; validate values)
  local f="$1" rel; rel="${f#"$ROOT"/}"
  local kind status updated line k v
  while IFS= read -r line; do
    [ "$line" = "---" ] && break
    case "$line" in
      *:*) k="${line%%:*}"; v="${line#*:}"; v="${v# }"
           case "$k" in kind) kind="$v";; status) status="$v";; updated) updated="$v";; esac ;;
    esac
  done < <(tail -n +2 "$f")
  in_list "${kind:-}" "$KINDS" || add "FRONTMATTER $rel: kind=${kind:-} not allowed"
  in_list "${status:-}" "$STATUSES" || add "FRONTMATTER $rel: status=${status:-} not allowed"
  case "${updated:-}" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) add "FRONTMATTER $rel: updated=${updated:-} not an ISO date (YYYY-MM-DD)" ;;
  esac
}

# --- run: lint the discovered managed set (current shell, so add() persists) ---
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  f="$ROOT/$rel"
  check_links "$f"
  check_frontmatter "$f"
done < <(managed_docs "$ROOT")

if [ -z "$FINDINGS" ]; then
  echo "doc-linter: clean ✓"
  exit 0
fi
printf '%s' "$FINDINGS"
exit 1
```

- [ ] **Step 6: Run the linter test to verify it passes**

Run: `bash tests/test-doc-linter.sh`
Expected: PASS — `test-doc-linter.sh passed`.

- [ ] **Step 7: Migrate loom's root README to unified frontmatter**

In `README.md`, replace the top:
```markdown
# loom

## Overview
_updated: 2026-06-23_
```
with:
```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# loom

## Overview
```
(Add the frontmatter block; delete the `_updated: 2026-06-23_` stamp line. Keep the `## Overview` heading and its paragraph.)

Also in `README.md`, fix the naming-table row for the linter — change:
```markdown
| **doc-linter** | doc hygiene checks (links, frontmatter, stamps) | `scripts/doc-linter` |
```
to:
```markdown
| **doc-linter** | doc hygiene checks (links + frontmatter) | `scripts/doc-linter` |
```

- [ ] **Step 8: Rewrite loom's `docs/README.md` doc-model section**

Replace the body of `docs/README.md` (keep its existing frontmatter block) with:
```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# How loom's docs work

loom is a docs & context harness. Its own docs follow the convention it ships:

- **Membership is discovery, not enumeration.** A doc is loom-managed iff it opens with
  YAML frontmatter carrying a `kind:` key (`status` and `updated` too). loom finds the
  managed set with git (`scripts/doc-scan`) — tracked, staged, and uncommitted markdown,
  with gitignored paths excluded. No registry of paths to maintain.
- **One frontmatter rule for every doc.** READMEs included — there is no separate
  "stamped, frontmatter-free" tier. Freshness lives in the `updated` field.
- **Config drives behavior, not membership.** `docs/config/loom.toml` carries `[context]`
  (`recent_commits` / `slice_headers` / `inject_fields` for the SessionStart slicer) and
  `[lint]` (`kinds` / `statuses` — the validation vocabulary, and `kinds` is the discovery
  key). It enumerates no files or modules.
- **Links are routing:** one home per fact, surfaced by progressive disclosure (root map →
  deeper doc → code).

The design specs and plans under `docs/superpowers/` are intentionally frontmatter-free, so
discovery treats them as unmanaged scaffolding rather than durable docs.
```

- [ ] **Step 9: Slim loom's `loom.toml` — drop `[modules]`**

In `docs/config/loom.toml`, delete the `[modules]` table entirely:
```toml
[modules]
dirs = []
```
Leave `[context]` (set in Task 2) and `[lint]` as-is. Then change the `[lint]` table to drop `docs_subdirs` — remove this line:
```toml
docs_subdirs = ["config"]
```
The final `loom.toml` is exactly:
```toml
# loom.toml — loom's own harness config (loom dogfoods its linter/slicer).
[context]
recent_commits = 15
slice_headers = ["## Now"]
inject_fields = ["updated", "kind", "location"]

[lint]
kinds = ["charter", "roadmap", "readme", "guide", "reference", "spec", "plan", "design", "review"]
statuses = ["living", "hardened", "superseded", "scaffolding", "ideation"]
```

- [ ] **Step 10: Verify loom dogfoods clean under the new linter**

Run: `bash scripts/doc-linter`
Expected: `doc-linter: clean ✓` (exit 0). loom's managed docs are now `README.md`, `AGENTS.md`, `docs/README.md`, `docs/config/charter.md`, `docs/config/roadmap.md` — all with valid frontmatter and no broken links.

- [ ] **Step 11: Run the full suite**

Run: `bash tests/run`
Expected: `ALL TESTS PASSED`.

- [ ] **Step 12: Commit**

```bash
git add scripts/doc-linter README.md docs/README.md docs/config/loom.toml tests/test-doc-linter.sh tests/fixtures/repo-clean tests/fixtures/repo-dirty
git commit -m "feat: linter over discovered set, one frontmatter rule; unify dogfood docs

doc-linter now lints the discovered managed set (no hardcoded paths, no module
enumeration) with a single frontmatter rule — the two-tier STAMP logic is gone.
loom's own README/docs migrate to unified frontmatter and loom.toml drops
[modules]/docs_subdirs, slimming to [context] + [lint].

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Skills — reframe to discovery model

Update the three active skills' prose to the discovery / unified-frontmatter / new-config-key model, and wire in the omission sweep (via `doc-scan`) and uncommitted-doc provenance surfacing. These are prose files (no code tests); verification is the linter + a targeted grep.

**Files:**
- Modify: `skills/dress/SKILL.md`, `skills/dress/templates/loom.toml`
- Modify: `skills/weave/SKILL.md`
- Modify: `skills/weft/SKILL.md`

- [ ] **Step 1: Update the dress template config**

Replace `skills/dress/templates/loom.toml` with:
```toml
# loom.toml — per-repo harness config. The plugin ships generic code; this drives it.
# [context] tunes the SessionStart slice; [lint] is the validation vocabulary.

[context]
recent_commits = 15
slice_headers = ["## Now", "## Module Map"]   # sections to harvest, by header (path-free)
inject_fields = ["updated", "kind", "location"]  # frontmatter to prefix each slice with

[lint]
kinds = ["charter", "roadmap", "readme", "guide", "reference", "spec", "plan", "design", "review"]
statuses = ["living", "hardened", "superseded", "scaffolding", "ideation"]
```

- [ ] **Step 2: Reframe `skills/dress/SKILL.md`**

Make these edits to `skills/dress/SKILL.md`:

Replace the canonical-layout bullets describing the two-tier model:
```markdown
- `README.md` — `## Overview` (stamped) · `## Module Map` · `## Getting Started`; frontmatter-free.
```
with:
```markdown
- `README.md` — frontmatter (`kind: readme`) + `## Overview` · `## Module Map` · `## Getting Started`. Like every managed doc, it opens with frontmatter; freshness is the `updated` field, not an inline stamp.
```

Replace the module-README bullet:
```markdown
- `<module>/README.md` — `## Overview` (stamped) · `## Setup` · `## Structure` · `## Agentic Guidelines` · `## Agentic Validation`.
```
with:
```markdown
- `<module>/README.md` — frontmatter (`kind: readme`) + `## Overview` · `## Setup` · `## Structure` · `## Agentic Guidelines` · `## Agentic Validation`.
```

Replace the `## The config` section's table of three tables with this two-table description:
```markdown
- `[context]` — what the SessionStart hook injects: `recent_commits` (git bearings),
  `slice_headers` (which sections to harvest, *by header* — path-free, so moving a file
  never breaks a slice), and `inject_fields` (frontmatter to prefix each slice with, e.g.
  `updated`/`kind`/`location`). Start maximal, then trim *down* — the slice is paid every
  session, so cut to what changes the next action.
- `[lint]` — `kinds` / `statuses` (frontmatter enums), mirroring the "Nomenclature" in
  `docs/README.md`. `kinds` is also the discovery key: a doc is loom-managed iff it carries
  a `kind`. The config enumerates no files or modules — membership is discovered.
```

In the re-tune facilitator loop, replace the module/section language so it reads:
```markdown
2. Tune `[context]` / `[lint]` in `loom.toml` with the operator — add/drop/reorder
   `slice_headers`, adjust `inject_fields`, adjust enums to match `docs/README.md`.
   Re-render, re-show. Loop until it lands.
```

- [ ] **Step 3: Reframe `skills/weave/SKILL.md`**

In `skills/weave/SKILL.md`, change the workflow's step 1 to drive inspection from discovery, and add an omission step. Replace step 1:
```markdown
1. Inspect by progressive disclosure: start at `AGENTS.md`, follow the root `README.md` `## Module Map` to the module READMEs; scan headings before bodies; read only the docs and code the reconciliation touches. Cover each module in the Module Map in turn.
```
with:
```markdown
1. Enumerate the managed set deterministically with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-scan"` (frontmatter discovery over tracked + uncommitted markdown) rather than agentic globbing. Inspect by progressive disclosure: start at `AGENTS.md`, follow the root `README.md` `## Module Map`, scan headings before bodies; read only the docs and code the reconciliation touches.
2. **Surface omissions and uncommitted work.** `doc-scan`'s candidate list is markdown lacking frontmatter — surface it and ask whether any should be adopted as managed docs (the `docs/superpowers/` specs/plans are intentionally unmanaged scaffolding; don't pester about those). Then run `git status --porcelain -- '*.md'`: surface new/uncommitted (`??`/`A`) and deleted (` D`) managed docs and ask whether to distill/adopt or drop them — don't assume.
```
Renumber the remaining steps (the old 2–6 become 3–7).

- [ ] **Step 4: Reframe `skills/weft/SKILL.md`**

In `skills/weft/SKILL.md`, add provenance awareness to the distill phase. After the existing step 1 (scope the delta), insert a new step:
```markdown
2. **Surface uncommitted docs early.** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-scan"` and `git status --porcelain -- '*.md'`. New/uncommitted (`??`/`A`) managed docs and frontmatter-less candidates created this session are easy to miss — name them and confirm whether each should be distilled, adopted, or left, before refreshing the durable layer.
```
Renumber the remaining distill steps accordingly. Update the references to the stamped `## Overview` so they no longer imply a frontmatter-free README — change "refresh the touched module README's `## Overview` (its `_updated:` stamp + paragraph)" to "refresh the touched module README's frontmatter `updated` field and `## Overview` paragraph".

- [ ] **Step 5: Verify skills reference no stale model**

Run: `grep -rn "stamp\|_updated:\|docs_subdirs\|include_modules\|context.sections\|\[modules\]\|frontmatter-free" skills/`
Expected: no matches (every reference to the old stamp/enumeration model is gone). If any remain, fix them.

- [ ] **Step 6: Confirm loom still lints clean**

Run: `bash scripts/doc-linter && bash tests/run`
Expected: `doc-linter: clean ✓` then `ALL TESTS PASSED` (skills aren't linted, but this confirms nothing regressed).

- [ ] **Step 7: Commit**

```bash
git add skills
git commit -m "refactor: skills speak the discovery model

dress scaffolds unified frontmatter + the slimmed two-table loom.toml; weave/weft
enumerate via doc-scan instead of agentic globbing, surface omission candidates,
and ask about uncommitted/deleted docs before acting.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Cleanup pass over stale direction

Remove every remaining reference to the old model so a fresh reader meets no description of it as current (the spec's exit criterion). Prose-only; verification is grep + the linter.

**Files:**
- Modify: `NOTES.md`
- Modify: `docs/superpowers/specs/2026-06-23-loom-plugin-port-design.md` (forward-pointer only)
- Modify: `hooks/*`, `scripts/*` comments if any stale terms remain

- [ ] **Step 1: Rewrite NOTES.md to current reality**

Replace the entire contents of `NOTES.md` with:
```markdown
# loom — scratch notes

Loose pile of thoughts. Not authoritative. Prune as things settle.

## Open questions

- **warp** — the session-*open* bookend — is still a stub. It's the next real skill.
- **Manifests** — Claude (`.claude-plugin/`) and Codex (`.codex-plugin/` + `.agents/`)
  are hand-maintained. Generate from one core only once it hurts. Watch the Codex
  local-marketplace `source.path: "./"` (may be rejected — confirm at smoke-test).
- **Invisible README frontmatter** — GitHub renders a metadata table atop READMEs.
  Accepted for now; an HTML-comment carrier is a possible future option.
- **Omission-sweep noise** — `docs/superpowers/` specs/plans show up as unmanaged
  candidates. Triaged manually for now; a `scan_exclude` glob is the lever if it gets noisy.

## Status

- Core scripts (parser, discovery, linter, slicer, hook wiring) built and green.
- Membership is discovery (frontmatter), not enumeration; one unified frontmatter tier.
- Not yet smoke-tested as an installed plugin (Claude + Codex).
```

- [ ] **Step 2: Add a forward-pointer to the superseded port spec**

In `docs/superpowers/specs/2026-06-23-loom-plugin-port-design.md`, immediately under the `_Status: ...` line near the top, insert:
```markdown
> **Superseded in part (2026-06-23):** the enumerated managed-doc model (`[modules] dirs`,
> `docs_subdirs`) and the two-tier frontmatter/stamp document model described here are
> replaced by discovery-driven frontmatter and generic slicing — see
> [2026-06-23-loom-discovery-frontmatter-redesign.md](2026-06-23-loom-discovery-frontmatter-redesign.md).
> The bash+awk / data-driven / dual-tool decisions still hold.
```

- [ ] **Step 3: Grep the whole repo for stale terms**

Run: `grep -rn "docs_subdirs\|include_modules\|context.sections\|stamped README\|frontmatter-free\|two-tier\|_updated:" --include='*.md' --include='doc-*' . | grep -v docs/superpowers/specs/2026-06-23-loom-plugin-port-design.md | grep -v docs/superpowers/plans/`
Expected: no matches outside the historical port spec/plans. Investigate and fix any hit (e.g. a lingering script comment or README line). The discovery-frontmatter spec/plan legitimately mention these terms while describing the change — exclude `docs/superpowers/` design docs from the failure criterion.

- [ ] **Step 4: Final full verification**

Run: `bash tests/run && bash scripts/doc-linter && bash hooks/doc-slicer >/dev/null && echo OK`
Expected: `ALL TESTS PASSED`, then `doc-linter: clean ✓`, then `OK` (slicer renders without error).

- [ ] **Step 5: Commit**

```bash
git add NOTES.md docs/superpowers/specs/2026-06-23-loom-plugin-port-design.md
git commit -m "docs: cleanup pass — retire stale two-tier/enumeration references

Rewrite the stale NOTES.md to current reality; mark the enumerated/two-tier parts
of the port spec superseded by the discovery-frontmatter redesign. Fresh readers
no longer meet the old model described as current.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Done criteria

- `bash tests/run` → `ALL TESTS PASSED` (discover, slicer, linter, parse-toml suites).
- `bash scripts/doc-linter` → `doc-linter: clean ✓` (loom dogfoods the new linter).
- `bash hooks/doc-slicer` renders Bearings + a path-free `## Now` slice with `kind`/location annotation.
- `bash scripts/doc-scan` lists loom's managed docs and the unmanaged specs/plans as candidates.
- No file or module is enumerated in `loom.toml`; membership is discovered everywhere.
- No doc/skill/comment describes the two-tier/stamp/enumeration model as current.
- Out of scope (unchanged): `parse-toml.awk`, `run-hook.cmd`, `hooks.json`, manifests, `warp`, the smoke-test install, `scan_exclude`.
