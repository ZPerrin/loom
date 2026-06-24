# loom Core Scripts Implementation Plan (Plan 1 of 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build loom's data-driven, dependency-free core — a TOML-subset config reader, the `doc-linter` and `doc-slicer` scripts, and the cross-platform SessionStart hook wiring — all bash 3.2 + awk, with a fixture-based test suite.

**Architecture:** A standalone awk program (`parse-toml.awk`) normalizes a constrained `loom.toml` subset into flat `table.key=value` lines. Two bash scripts consume that: `scripts/doc-linter` (doc hygiene checks) and `hooks/doc-slicer` (SessionStart context). Both resolve the target repo via `git rev-parse --show-toplevel` and fall back to embedded defaults when no `loom.toml` is present. A polyglot `hooks/run-hook.cmd` (from superpowers, MIT) routes the hook to bash on Windows and Unix. Tests are plain bash scripts asserting against synthetic fixtures — no test framework dependency.

**Tech Stack:** bash 3.2+, awk (POSIX), git. No Python, no jq, no node, no bats.

This plan implements the spec at `docs/superpowers/specs/2026-06-23-loom-plugin-port-design.md` (§5 config, §6 scripts, §8 defaults/paths, parts of §4 layout and §12 done-criteria). It does **not** touch skills, manifests, or deletions — those are Plan 2.

---

## File structure

| File | Responsibility |
|---|---|
| `tests/lib.sh` | Tiny assert helpers (`assert_eq`, `assert_contains`, `assert_exit`, `finish`). Sourced by every test. |
| `tests/run` | Runs every `tests/test-*.sh`, aggregates pass/fail. |
| `scripts/lib/parse-toml.awk` | Standalone awk: `loom.toml` subset → normalized `table.key=value` lines; exit 2 on unsupported constructs. |
| `tests/test-parse-toml.sh` | Unit tests for the parser (scalars, arrays, tables, comments, rejection). |
| `tests/fixtures/parse/*.toml` | Parser input fixtures. |
| `scripts/doc-linter` | Bash linter: BROKEN / CODELINK / MISSING / FRONTMATTER / STAMP checks. Config-driven with defaults. |
| `tests/test-doc-linter.sh` | Linter tests against `tests/fixtures/repo-dirty` and `tests/fixtures/repo-clean`. |
| `tests/fixtures/repo-dirty/` | Synthetic repo with exactly one of each finding type. |
| `tests/fixtures/repo-clean/` | Synthetic repo that lints clean. |
| `hooks/doc-slicer` | Bash SessionStart hook: bearings (git) + configured section/module slices. |
| `tests/test-doc-slicer.sh` | Slicer tests against a fixture repo. |
| `hooks/run-hook.cmd` | Polyglot Windows/Unix wrapper (adapted from superpowers, MIT). |
| `hooks/hooks.json` | SessionStart hook registration routing through `run-hook.cmd`. |

Shared config-reading is the awk program (`parse-toml.awk`), invoked via `awk -f` by both scripts — no bash sourcing of shared libs, so each script stays self-contained.

---

## Task 1: Test harness

**Files:**
- Create: `tests/lib.sh`
- Create: `tests/run`

- [ ] **Step 1: Write the assert library**

Create `tests/lib.sh`:

```bash
# tests/lib.sh — minimal assertion helpers (bash 3.2 safe, no deps).
# Usage: source this, call asserts, end with `finish`.
FAILS=0

assert_eq() { # $1=actual $2=expected $3=label
  if [ "$1" = "$2" ]; then printf '  ok   %s\n' "$3"
  else printf '  FAIL %s\n       expected: [%s]\n       actual:   [%s]\n' "$3" "$2" "$1"; FAILS=$((FAILS+1)); fi
}

assert_contains() { # $1=haystack $2=needle $3=label
  case "$1" in
    *"$2"*) printf '  ok   %s\n' "$3" ;;
    *) printf '  FAIL %s\n       missing: [%s]\n       in:      [%s]\n' "$3" "$2" "$1"; FAILS=$((FAILS+1)) ;;
  esac
}

assert_not_contains() { # $1=haystack $2=needle $3=label
  case "$1" in
    *"$2"*) printf '  FAIL %s\n       unexpected: [%s]\n' "$3" "$2"; FAILS=$((FAILS+1)) ;;
    *) printf '  ok   %s\n' "$3" ;;
  esac
}

assert_exit() { # $1=actual_code $2=expected_code $3=label
  if [ "$1" = "$2" ]; then printf '  ok   %s\n' "$3"
  else printf '  FAIL %s (exit %s, expected %s)\n' "$3" "$1" "$2"; FAILS=$((FAILS+1)); fi
}

finish() { # call at end of a test file
  if [ "$FAILS" -ne 0 ]; then printf '%s FAILED\n' "${0##*/}"; exit 1; fi
  printf '%s passed\n' "${0##*/}"
}
```

- [ ] **Step 2: Write the test runner**

Create `tests/run` (extensionless, executable):

```bash
#!/usr/bin/env bash
# tests/run — run every tests/test-*.sh, report aggregate result.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
rc=0
for t in "$DIR"/test-*.sh; do
  [ -e "$t" ] || continue
  printf '== %s ==\n' "${t##*/}"
  bash "$t" || rc=1
done
[ "$rc" -eq 0 ] && printf '\nALL TESTS PASSED\n' || printf '\nSOME TESTS FAILED\n'
exit "$rc"
```

- [ ] **Step 3: Make the runner executable and verify it runs with no tests yet**

Run:
```bash
chmod +x tests/run && bash tests/run
```
Expected: prints `ALL TESTS PASSED` (no `test-*.sh` files yet), exit 0.

- [ ] **Step 4: Commit**

```bash
git add tests/lib.sh tests/run
git commit -m "test: add dependency-free bash assert harness"
```

---

## Task 2: TOML-subset parser

**Files:**
- Create: `scripts/lib/parse-toml.awk`
- Create: `tests/fixtures/parse/sample.toml`
- Create: `tests/fixtures/parse/aot.toml`
- Test: `tests/test-parse-toml.sh`

- [ ] **Step 1: Write fixtures**

Create `tests/fixtures/parse/sample.toml`:

```toml
# a comment
[modules]
dirs = ["backend", "frontend", "cdk"]

[context]
recent_commits = 15
sections = ["docs/config/roadmap.md > ## Now"]
include_modules = true

[lint]
kinds = ["charter", "readme"]
```

Create `tests/fixtures/parse/aot.toml` (unsupported construct):

```toml
[[slice]]
type = "git"
```

- [ ] **Step 2: Write the failing test**

Create `tests/test-parse-toml.sh`:

```bash
#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
AWK="$DIR/../scripts/lib/parse-toml.awk"
F="$DIR/fixtures/parse"

out="$(awk -f "$AWK" "$F/sample.toml")"
assert_contains "$out" "modules.dirs=backend"            "array element 1"
assert_contains "$out" "modules.dirs=frontend"           "array element 2"
assert_contains "$out" "modules.dirs=cdk"                "array element 3"
assert_contains "$out" "context.recent_commits=15"       "scalar int"
assert_contains "$out" "context.include_modules=true"    "scalar bool"
assert_contains "$out" "context.sections=docs/config/roadmap.md > ## Now" "array w/ spaces"
assert_contains "$out" "lint.kinds=charter"              "lint array 1"
assert_contains "$out" "lint.kinds=readme"               "lint array 2"
assert_not_contains "$out" "#"                           "comment stripped"

awk -f "$AWK" "$F/aot.toml" >/dev/null 2>&1
assert_exit "$?" "2" "array-of-tables rejected with exit 2"

finish
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bash tests/test-parse-toml.sh`
Expected: FAIL (awk file does not exist yet → asserts fail).

- [ ] **Step 4: Write the parser**

Create `scripts/lib/parse-toml.awk`:

```awk
# parse-toml.awk — emit normalized "table.key=value" lines for loom's TOML subset.
# One line per scalar; one line per array element (repeated key). Exit 2 on any
# unsupported construct (array-of-tables, inline table, multiline, unparseable).
# Subset limits: single-line arrays only; array elements must not contain commas.
function strip(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function dequote(s) {
  s = strip(s)
  if (s ~ /^".*"$/) s = substr(s, 2, length(s) - 2)
  return s
}
/^[ \t]*#/   { next }   # full-line comment
/^[ \t]*$/   { next }   # blank
/^[ \t]*\[\[/ { print "parse-toml: unsupported array-of-tables: " $0 > "/dev/stderr"; exit 2 }
/^[ \t]*\[/  {          # [table]
  t = $0; sub(/^[ \t]*\[/, "", t); sub(/\][ \t]*$/, "", t); table = strip(t); next
}
index($0, "=") {
  eq  = index($0, "=")
  key = strip(substr($0, 1, eq - 1))
  val = strip(substr($0, eq + 1))
  if (val ~ /\{/) { print "parse-toml: unsupported inline table: " $0 > "/dev/stderr"; exit 2 }
  if (val ~ /^\[/) {
    if (val !~ /\]$/) { print "parse-toml: unsupported multiline array: " $0 > "/dev/stderr"; exit 2 }
    inner = val; sub(/^\[/, "", inner); sub(/\]$/, "", inner)
    n = split(inner, arr, ",")
    for (i = 1; i <= n; i++) { e = dequote(arr[i]); if (e != "") print table "." key "=" e }
  } else {
    print table "." key "=" dequote(val)
  }
  next
}
{ print "parse-toml: unparseable line: " $0 > "/dev/stderr"; exit 2 }
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bash tests/test-parse-toml.sh`
Expected: all `ok`, prints `test-parse-toml.sh passed`, exit 0.

- [ ] **Step 6: Commit**

```bash
git add scripts/lib/parse-toml.awk tests/test-parse-toml.sh tests/fixtures/parse
git commit -m "feat: TOML-subset config parser (parse-toml.awk)"
```

---

## Task 3: Linter skeleton — config, file lists, clean exit

**Files:**
- Create: `scripts/doc-linter`
- Create: `tests/fixtures/repo-clean/` (see below)
- Test: `tests/test-doc-linter.sh` (clean case only this task)

- [ ] **Step 1: Build the clean fixture repo**

Create these files:

`tests/fixtures/repo-clean/docs/config/loom.toml`:
```toml
[modules]
dirs = ["mod"]
[lint]
kinds = ["readme", "reference"]
statuses = ["living"]
docs_subdirs = ["config"]
```

`tests/fixtures/repo-clean/AGENTS.md`:
```markdown
---
kind: reference
status: living
updated: 2026-06-23
---
# Agents
See [the readme](README.md).
```

`tests/fixtures/repo-clean/docs/README.md`:
```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# Docs
```

`tests/fixtures/repo-clean/README.md`:
```markdown
# Project

## Overview
_updated: 2026-06-23_

A project.
```

`tests/fixtures/repo-clean/mod/README.md`:
```markdown
# Mod

## Overview
_updated: 2026-06-23_

A module.
```

- [ ] **Step 2: Write the failing test (clean fixture lints clean)**

Create `tests/test-doc-linter.sh`:

```bash
#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
LINTER="$DIR/../scripts/doc-linter"

# Clean fixture: must exit 0 and report clean.
out="$(cd "$DIR/fixtures/repo-clean" && git init -q . && git add -A && bash "$LINTER" 2>&1)"; rc=$?
assert_exit "$rc" "0" "clean fixture exits 0"
assert_contains "$out" "doc-linter: clean" "clean fixture reports clean"
rm -rf "$DIR/fixtures/repo-clean/.git"

finish
```

Note: the linter uses `git check-ignore`, so the fixture needs a git repo; the test inits a throwaway one and removes it.

- [ ] **Step 3: Run test to verify it fails**

Run: `bash tests/test-doc-linter.sh`
Expected: FAIL (`doc-linter` does not exist).

- [ ] **Step 4: Write the linter skeleton**

Create `scripts/doc-linter` (extensionless):

```bash
#!/usr/bin/env bash
# doc-linter — doc hygiene for loom-managed Markdown (bash 3.2 + awk, no deps).
# Checks: BROKEN, CODELINK, MISSING (links); FRONTMATTER, STAMP (two-tier).
# Config: <repo>/docs/config/loom.toml (TOML subset) or embedded defaults.
set -u

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
PARSE_AWK="$SELF_DIR/lib/parse-toml.awk"

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null && return
  printf '%s\n' "${CLAUDE_PROJECT_DIR:-$PWD}"
}
ROOT="$(repo_root)"

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
lint.statuses=ideation
lint.docs_subdirs=config
lint.docs_subdirs=specs
lint.docs_subdirs=plans
lint.docs_subdirs=design'
CONF="$ROOT/docs/config/loom.toml"
if [ -f "$CONF" ]; then
  CFG="$(awk -f "$PARSE_AWK" "$CONF")" || { echo "doc-linter: bad loom.toml" >&2; exit 2; }
else
  CFG="$DEFAULT_CFG"
fi
cfg_get() { printf '%s\n' "$CFG" | awk -F= -v k="$1" '$1==k{sub(/^[^=]*=/,""); print}'; }

KINDS="$(cfg_get lint.kinds)"
STATUSES="$(cfg_get lint.statuses)"
SUBDIRS="$(cfg_get lint.docs_subdirs)"
MODULES="$(cfg_get modules.dirs)"

# --- file lists ---
exists() { [ -e "$1" ]; }

frontmatter_docs() {  # tier 1: docs/ tree + AGENTS.md
  exists "$ROOT/AGENTS.md" && printf '%s\n' "$ROOT/AGENTS.md"
  exists "$ROOT/docs/README.md" && printf '%s\n' "$ROOT/docs/README.md"
  for sub in $SUBDIRS; do
    for f in "$ROOT/docs/$sub"/*.md; do exists "$f" && printf '%s\n' "$f"; done
  done
}
stamped_readmes() {   # tier 2: root + module READMEs
  exists "$ROOT/README.md" && printf '%s\n' "$ROOT/README.md"
  for m in $MODULES; do exists "$ROOT/$m/README.md" && printf '%s\n' "$ROOT/$m/README.md"; done
}
skill_docs() {        # any in-repo skills (none under a plugin install)
  for f in "$ROOT"/.claude/skills/*/SKILL.md; do exists "$f" && printf '%s\n' "$f"; done
}

FINDINGS=""
add() { FINDINGS="${FINDINGS}$1
"; }

# (checks added in later tasks)

# --- run ---
# placeholder run wiring; checks appended in Tasks 4-7.

if [ -z "$FINDINGS" ]; then
  echo "doc-linter: clean ✓"
  exit 0
fi
printf '%s' "$FINDINGS"
exit 1
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bash tests/test-doc-linter.sh`
Expected: `ok` for both asserts, `test-doc-linter.sh passed`, exit 0.

- [ ] **Step 6: Commit**

```bash
git add scripts/doc-linter tests/test-doc-linter.sh tests/fixtures/repo-clean
git commit -m "feat: doc-linter skeleton (config + file lists + clean exit)"
```

---

## Task 4: Linter — link checks (BROKEN, CODELINK, MISSING)

**Files:**
- Modify: `scripts/doc-linter` (add link-check logic + wire into run)
- Modify: `tests/fixtures/repo-dirty/` (create with link issues)
- Modify: `tests/test-doc-linter.sh` (add dirty-link assertions)

- [ ] **Step 1: Build the dirty fixture (link cases)**

Create `tests/fixtures/repo-dirty/docs/config/loom.toml`:
```toml
[modules]
dirs = ["mod"]
[lint]
kinds = ["readme", "reference"]
statuses = ["living"]
docs_subdirs = ["config"]
```

Create `tests/fixtures/repo-dirty/docs/README.md`:
```markdown
---
kind: readme
status: living
updated: 2026-06-23
---
# Docs

A [broken link](nope/missing.md) here.
A [`code-styled`](README.md) link here.

## Files
- `config/loom.toml` — the config
```

(The first line gives a BROKEN finding, the second a CODELINK finding, the list item a MISSING finding since `config/loom.toml` resolves but isn't a link.)

- [ ] **Step 2: Write failing assertions**

Add to `tests/test-doc-linter.sh` before `finish`:

```bash
# Dirty fixture: link findings.
(cd "$DIR/fixtures/repo-dirty" && git init -q . && git add -A)
dout="$(cd "$DIR/fixtures/repo-dirty" && bash "$LINTER" 2>&1)"; drc=$?
assert_exit "$drc" "1" "dirty fixture exits 1"
assert_contains "$dout" "BROKEN"   "reports BROKEN link"
assert_contains "$dout" "nope/missing.md" "names the broken href"
assert_contains "$dout" "CODELINK" "reports CODELINK"
assert_contains "$dout" "MISSING"  "reports MISSING list-path link"
rm -rf "$DIR/fixtures/repo-dirty/.git"
```

- [ ] **Step 3: Run to verify it fails**

Run: `bash tests/test-doc-linter.sh`
Expected: FAIL (no link checks yet; dirty fixture currently reports clean).

- [ ] **Step 4: Add the link-check logic**

In `scripts/doc-linter`, replace the `# (checks added in later tasks)` comment with:

```bash
# Emit, per line of a markdown file, candidate findings. awk extracts; bash
# resolves filesystem existence (awk can't stat). Fenced code blocks skipped.
# Output lines: "BROKEN<TAB>href", "CODELINK<TAB>text", "MISSING<TAB>span".
scan_lines() { # $1=file
  awk '
    /^[ \t]*```/ { fence = !fence; next }
    fence { next }
    {
      line = $0
      # links: [text](href)
      s = line
      while (match(s, /\[[^]]*\]\([^)]+\)/)) {
        chunk = substr(s, RSTART, RLENGTH)
        href = chunk; sub(/^[^(]*\(/, "", href); sub(/\)$/, "", href)
        sub(/#.*$/, "", href)
        if (href !~ /^(https?:|mailto:)/ && href != "") print "BROKEN\t" href
        # code-styled link text: [`...`](
        if (chunk ~ /^\[`[^`]*`\]\(/) {
          t = chunk; sub(/^\[`/, "", t); sub(/`\].*$/, "", t); print "CODELINK\t" t
        }
        s = substr(s, RSTART + RLENGTH)
      }
      # MISSING: list lead "- `path` — desc" that is not itself a link
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
```

Then add the run wiring just before the final `if [ -z "$FINDINGS" ]` block:

```bash
for f in $(frontmatter_docs; stamped_readmes; skill_docs); do
  check_links "$f"
done
```

Note on subshells: `add` mutates `FINDINGS`, so the `for` loop must run in the current shell. `$(...)` only builds the file list (a subshell is fine there); the loop body runs in-process. Do **not** pipe the file list into a `while read` loop — that would run `check_links` (and `add`) in a subshell and lose the findings.

- [ ] **Step 5: Run to verify it passes**

Run: `bash tests/test-doc-linter.sh`
Expected: clean fixture still exits 0; dirty fixture exits 1 with BROKEN/CODELINK/MISSING. All `ok`.

- [ ] **Step 6: Commit**

```bash
git add scripts/doc-linter tests/test-doc-linter.sh tests/fixtures/repo-dirty
git commit -m "feat: doc-linter link checks (BROKEN/CODELINK/MISSING)"
```

---

## Task 5: Linter — FRONTMATTER and STAMP checks

**Files:**
- Modify: `scripts/doc-linter` (add the two checks + wire in)
- Modify: `tests/fixtures/repo-dirty/` (add frontmatter + stamp offenders)
- Modify: `tests/test-doc-linter.sh`

- [ ] **Step 1: Add fixture offenders**

Append to `tests/fixtures/repo-dirty/docs/README.md` frontmatter so its `kind` is invalid — change the frontmatter block at the top to:
```markdown
---
kind: bogus
status: living
updated: 2026-06-23
---
```
(`kind: bogus` is not in the fixture's `kinds`, giving a FRONTMATTER finding.)

Create `tests/fixtures/repo-dirty/README.md` (root readme, no stamp → STAMP finding):
```markdown
# Project

## Overview

No stamp line here.
```

- [ ] **Step 2: Write failing assertions**

Add to `tests/test-doc-linter.sh` before the `rm -rf` of the dirty `.git`:
```bash
assert_contains "$dout" "FRONTMATTER" "reports bad frontmatter kind"
assert_contains "$dout" "STAMP"       "reports missing Overview stamp"
```

- [ ] **Step 3: Run to verify it fails**

Run: `bash tests/test-doc-linter.sh`
Expected: FAIL (FRONTMATTER/STAMP not implemented).

- [ ] **Step 4: Add the checks**

In `scripts/doc-linter`, after `check_links()`, add:

```bash
in_list() { case " $2 " in *" $1 "*) return 0;; *) return 1;; esac; }

check_frontmatter() { # $1=file
  local f="$1" rel; rel="${f#"$ROOT"/}"
  local first; IFS= read -r first < "$f"
  if [ "$first" != "---" ]; then
    add "FRONTMATTER $rel: missing frontmatter (expected \`---\` on line 1)"; return
  fi
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

check_stamp() { # $1=file
  local f="$1" rel; rel="${f#"$ROOT"/}"
  local first; IFS= read -r first < "$f"
  if [ "$first" = "---" ]; then
    add "STAMP $rel: README should stay frontmatter-free (use a stamped \`## Overview\`)"
  fi
  # find "## Overview", then the next non-blank line must be the stamp.
  awk '
    /^##[ \t]+Overview[ \t]*$/ { seen=1; next }
    seen {
      if ($0 ~ /^[ \t]*$/) next
      if ($0 ~ /^_updated:[ \t]*[0-9]{4}-[0-9]{2}-[0-9]{2}_?[ \t]*$/) { print "OK"; exit }
      print "NOSTAMP"; exit
    }
    END { if (!seen) print "NOOVERVIEW" }
  ' "$f" | {
    read -r r
    case "$r" in
      NOSTAMP)     add "STAMP $rel: \`## Overview\` missing \`_updated: YYYY-MM-DD_\` stamp" ;;
      NOOVERVIEW)  add "STAMP $rel: missing \`## Overview\` section" ;;
    esac
  }
}
```

Note: `check_stamp`'s awk output is consumed in the **same** pipeline's `{ }` block; but `add` there runs in a subshell and won't mutate `FINDINGS`. To avoid that, capture instead:

```bash
check_stamp() { # $1=file  (subshell-safe version)
  local f="$1" rel r; rel="${f#"$ROOT"/}"
  local first; IFS= read -r first < "$f"
  [ "$first" = "---" ] && add "STAMP $rel: README should stay frontmatter-free (use a stamped \`## Overview\`)"
  r="$(awk '
    /^##[ \t]+Overview[ \t]*$/ { seen=1; next }
    seen { if ($0 ~ /^[ \t]*$/) next
           if ($0 ~ /^_updated:[ \t]*[0-9]{4}-[0-9]{2}-[0-9]{2}_?[ \t]*$/) {print "OK"; exit}
           print "NOSTAMP"; exit }
    END { if (!seen) print "NOOVERVIEW" }' "$f")"
  case "$r" in
    NOSTAMP)    add "STAMP $rel: \`## Overview\` missing \`_updated: YYYY-MM-DD_\` stamp" ;;
    NOOVERVIEW) add "STAMP $rel: missing \`## Overview\` section" ;;
  esac
}
```

Use the subshell-safe version. Then wire the runs after the link loop:

```bash
for f in $(frontmatter_docs); do check_frontmatter "$f"; done
for f in $(stamped_readmes); do check_stamp "$f"; done
```

- [ ] **Step 5: Run to verify it passes**

Run: `bash tests/test-doc-linter.sh`
Expected: all `ok`; clean fixture exits 0, dirty exits 1 with all five finding types.

- [ ] **Step 6: Commit**

```bash
git add scripts/doc-linter tests/test-doc-linter.sh tests/fixtures/repo-dirty
git commit -m "feat: doc-linter frontmatter + stamp checks"
```

---

## Task 6: Slicer — bearings + repo resolution

**Files:**
- Create: `hooks/doc-slicer`
- Create: `tests/fixtures/slice-repo/` (a tiny git repo with docs)
- Test: `tests/test-doc-slicer.sh`

- [ ] **Step 1: Build the slicer fixture**

Create `tests/fixtures/slice-repo/docs/config/loom.toml`:
```toml
[modules]
dirs = ["mod"]
[context]
recent_commits = 5
sections = ["docs/config/roadmap.md > ## Now"]
include_modules = true
```

Create `tests/fixtures/slice-repo/docs/config/roadmap.md`:
```markdown
## Now

Shipping the slicer.

## Next

Later stuff.
```

Create `tests/fixtures/slice-repo/README.md`:
```markdown
# Slice Repo

## Module Map
- [mod](mod) — the example module
```

Create `tests/fixtures/slice-repo/mod/README.md`:
```markdown
# Mod

## Overview
_updated: 2026-06-23_

Module overview body.
```

- [ ] **Step 2: Write the failing test**

Create `tests/test-doc-slicer.sh`:

```bash
#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
SLICER="$DIR/../hooks/doc-slicer"
R="$DIR/fixtures/slice-repo"

( cd "$R" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: slice repo" )
out="$(cd "$R" && bash "$SLICER" 2>&1)"; rc=$?
assert_exit "$rc" "0" "slicer exits 0"
assert_contains "$out" "Bearings"               "emits Bearings heading"
assert_contains "$out" "seed: slice repo"       "includes recent commit"
assert_contains "$out" "Shipping the slicer."   "includes roadmap Now section"
assert_contains "$out" "Module overview body."  "includes module Overview"
assert_contains "$out" "the example module"     "includes module map line"
rm -rf "$R/.git"

finish
```

- [ ] **Step 3: Run to verify it fails**

Run: `bash tests/test-doc-slicer.sh`
Expected: FAIL (`hooks/doc-slicer` does not exist).

- [ ] **Step 4: Write the slicer**

Create `hooks/doc-slicer` (extensionless):

```bash
#!/usr/bin/env bash
# doc-slicer — SessionStart context for loom (bash 3.2 + awk, no deps).
# Emits, to stdout: a preamble, a git "Bearings" block, then configured slices
# (roadmap/section slices, then per-module Overview slices). Config from
# <repo>/docs/config/loom.toml (TOML subset) or embedded defaults.
set -u

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
PARSE_AWK="$SELF_DIR/../scripts/lib/parse-toml.awk"

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null && return
  printf '%s\n' "${CLAUDE_PROJECT_DIR:-$PWD}"
}
ROOT="$(repo_root)"

DEFAULT_CFG='context.recent_commits=15
context.sections=docs/config/roadmap.md > ## Now
context.include_modules=true'
CONF="$ROOT/docs/config/loom.toml"
if [ -f "$CONF" ]; then
  CFG="$(awk -f "$PARSE_AWK" "$CONF")" || CFG="$DEFAULT_CFG"
else
  CFG="$DEFAULT_CFG"
fi
cfg_get() { printf '%s\n' "$CFG" | awk -F= -v k="$1" '$1==k{sub(/^[^=]*=/,""); print}'; }

COMMITS="$(cfg_get context.recent_commits)"; COMMITS="${COMMITS:-15}"
INCLUDE_MODULES="$(cfg_get context.include_modules)"
MODULES="$(cfg_get modules.dirs)"

# print the markdown under "<header>" in <file>, header line excluded.
emit_section() { # $1=file $2=header
  [ -f "$1" ] || return 0
  awk -v hdr="$2" '
    $0 == hdr { cap = 1; next }
    cap && /^## / { exit }
    cap { print }
  ' "$1"
}
# the root README Module-Map bullet for <dir>, minus leading "- ".
map_line() { # $1=dir
  [ -f "$ROOT/README.md" ] || return 0
  awk -v d="$1" 'index($0, "[" d "]") { sub(/^- /, ""); print; exit }' "$ROOT/README.md"
}

printf '_The slices below are your opening context — the next ring of progressive disclosure past AGENTS.md. Read the deeper docs when a task goes past a slice._\n\n'

printf '## Bearings — recent activity (from git)\n\n_Where the work just was, newest first:_\n\n'
git -C "$ROOT" log --oneline -"$COMMITS" 2>/dev/null || echo "(no git history)"
printf '\n'

# configured section slices (e.g. roadmap "## Now")
cfg_get context.sections | while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  file="${entry%% > *}"; header="${entry#* > }"
  body="$(emit_section "$ROOT/$file" "$header")"
  [ -n "$body" ] && printf '%s\n\n' "$body"
done

# module slices
if [ "${INCLUDE_MODULES:-}" = "true" ] && [ -n "$MODULES" ]; then
  printf '## Module Map\n\n_Slices from each module, pointing at the deeper module docs:_\n\n'
  for m in $MODULES; do
    line="$(map_line "$m")"
    [ -n "$line" ] && printf '### %s\n' "$line"
    emit_section "$ROOT/$m/README.md" "## Overview"
    printf '\n'
  done
fi
```

- [ ] **Step 5: Run to verify it passes**

Run: `bash tests/test-doc-slicer.sh`
Expected: all `ok`, exit 0.

- [ ] **Step 6: Commit**

```bash
git add hooks/doc-slicer tests/test-doc-slicer.sh tests/fixtures/slice-repo
git commit -m "feat: doc-slicer SessionStart context (bearings + config slices)"
```

---

## Task 7: Slicer — no-config defaults behavior

**Files:**
- Modify: `tests/test-doc-slicer.sh` (add a no-config case)

- [ ] **Step 1: Write the failing assertion**

Add to `tests/test-doc-slicer.sh` before `finish`:

```bash
# No loom.toml: must still emit Bearings (defaults), not crash.
NC="$DIR/fixtures/slice-noconf"
mkdir -p "$NC"
printf '## Now\n\nDefault path works.\n' > "$NC/.keep-roadmap-absent" # noise file, no docs/
( cd "$NC" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: no conf" )
nout="$(cd "$NC" && bash "$SLICER" 2>&1)"; nrc=$?
assert_exit "$nrc" "0" "no-config slicer exits 0"
assert_contains "$nout" "Bearings"      "no-config still emits Bearings"
assert_contains "$nout" "seed: no conf" "no-config includes git log"
rm -rf "$NC"
```

- [ ] **Step 2: Run to verify behavior**

Run: `bash tests/test-doc-slicer.sh`
Expected: PASS — the slicer already handles missing config via `DEFAULT_CFG` and the missing-file guards in `emit_section`/`map_line`. If it fails, fix the guards (do not assume any file exists).

- [ ] **Step 3: Commit**

```bash
git add tests/test-doc-slicer.sh
git commit -m "test: doc-slicer no-config defaults path"
```

---

## Task 8: Cross-platform hook wiring

**Files:**
- Create: `hooks/run-hook.cmd`
- Create: `hooks/hooks.json`
- Test: manual verification (documented below)

- [ ] **Step 1: Add the polyglot wrapper**

Create `hooks/run-hook.cmd` (adapted from superpowers, MIT — preserve attribution):

```bat
: << 'CMDBLOCK'
@echo off
REM Cross-platform polyglot wrapper for loom hook scripts.
REM Windows: cmd.exe runs this batch portion, finds bash, calls the named script.
REM Unix: the shell treats ": <<" as a no-op heredoc and runs the bottom portion.
REM Hook scripts are extensionless so Windows auto-detection (which prepends bash
REM to anything containing .sh) doesn't interfere.
REM Adapted from obra/superpowers (MIT).
REM Usage: run-hook.cmd <script-name> [args...]

if "%~1"=="" ( echo run-hook.cmd: missing script name >&2 & exit /b 1 )
set "HOOK_DIR=%~dp0"
if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    "C:\Program Files (x86)\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
where bash >nul 2>nul
if %ERRORLEVEL% equ 0 (
    bash "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
REM No bash found — degrade silently (plugin still works, no context injection).
exit /b 0
CMDBLOCK

# Unix: run the named script directly through bash.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
exec bash "${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
```

- [ ] **Step 2: Add the hook registration**

Create `hooks/hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" doc-slicer",
            "async": false
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 3: Verify the wrapper runs the slicer on Unix**

Run (from inside a git repo with docs, e.g. the slice fixture re-inited, or loom itself):
```bash
chmod +x hooks/run-hook.cmd hooks/doc-slicer scripts/doc-linter
bash hooks/run-hook.cmd doc-slicer | head -5
```
Expected: prints the preamble + `## Bearings` block (same as calling `doc-slicer` directly).

- [ ] **Step 4: Validate hooks.json is well-formed**

Run: `awk 'BEGIN{while((getline l < "hooks/hooks.json")>0) s=s l} END{print (index(s,"run-hook.cmd")>0)?"ok":"missing"}'`
Expected: `ok`. (No `jq` dependency; a full JSON validate happens at install/smoke-test in Plan 2.)

- [ ] **Step 5: Commit**

```bash
git add hooks/run-hook.cmd hooks/hooks.json
git commit -m "feat: cross-platform SessionStart hook wiring (polyglot run-hook.cmd)"
```

---

## Task 9: Full suite green + executable bits

**Files:**
- Modify: repo (ensure executable bits, run full suite)

- [ ] **Step 1: Ensure scripts are executable**

Run:
```bash
chmod +x scripts/doc-linter hooks/doc-slicer hooks/run-hook.cmd tests/run
git update-index --chmod=+x scripts/doc-linter hooks/doc-slicer hooks/run-hook.cmd tests/run 2>/dev/null || true
```

- [ ] **Step 2: Run the whole suite**

Run: `bash tests/run`
Expected: each `test-*.sh` prints `passed`; final line `ALL TESTS PASSED`, exit 0.

- [ ] **Step 3: Dogfood the linter on loom itself**

Run: `bash scripts/doc-linter`
Expected: findings against loom's *current* docs (loom isn't conformant yet — that's Plan 2). Confirm it runs without a bash/awk error and prints findings or clean. This is a smoke check of the script, not a clean-pass gate.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: mark loom scripts executable; full test suite green"
```

---

## Self-review notes (already applied)

- **Spec coverage:** §5 config subset → Tasks 2; §6 `doc-linter` → Tasks 3–5; §6 `doc-slicer` → Tasks 6–7; §8 defaults → Tasks 3/6/7; cross-platform wiring (Decision 3) → Task 8; fixture-based validation (§6/§11/§12) → throughout. Skills/manifests/deletions are explicitly Plan 2.
- **Subshell pitfall:** `add()` mutates a global; every check loop runs in the current shell (file lists via `$(...)` then a `for`, never a pipe into `while`). Called out in Tasks 4 and 5.
- **bash 3.2 safety:** no associative arrays, no `${x^^}`; config carried as text + `awk` filtering.
- **Known subset limits (documented in `parse-toml.awk`):** single-line arrays; array elements must not contain commas. loom's config never needs either.

---

## Execution handoff

Plan 1 complete. After it lands green, Plan 2 will cover: rename/reframe skills (`init-docs`→`dress` folding the two `refine-*`; `refine-docs`→`weave`; `wrap`→`weft`; `warp` stub), fix all skill path references to `${CLAUDE_PLUGIN_ROOT}`, update the Codex `plugin.json` hooks path, delete the old skeleton (`hooks.codex.json`, old Python, dup linter, py templates, old skill dirs), make loom's own docs lint-clean, and add `dress/templates/` seeds.
