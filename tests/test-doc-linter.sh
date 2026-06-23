#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
LINTER="$DIR/../scripts/doc-linter"

# Clean fixture: must exit 0 and report clean.
rm -rf "$DIR/fixtures/repo-clean/.git"
out="$(cd "$DIR/fixtures/repo-clean" && git init -q . && git add -A && bash "$LINTER" 2>&1)"; rc=$?
assert_exit "$rc" "0" "clean fixture exits 0"
assert_contains "$out" "doc-linter: clean" "clean fixture reports clean"
rm -rf "$DIR/fixtures/repo-clean/.git"

# Dirty fixture: link findings.
rm -rf "$DIR/fixtures/repo-dirty/.git"
(cd "$DIR/fixtures/repo-dirty" && git init -q . && git add -A)
dout="$(cd "$DIR/fixtures/repo-dirty" && bash "$LINTER" 2>&1)"; drc=$?
assert_exit "$drc" "1" "dirty fixture exits 1"
assert_contains "$dout" "BROKEN"   "reports BROKEN link"
assert_contains "$dout" "nope/missing.md" "names the broken href"
assert_contains "$dout" "CODELINK" "reports CODELINK"
assert_contains "$dout" "MISSING"  "reports MISSING list-path link"
assert_contains "$dout" "FRONTMATTER" "reports bad frontmatter kind"
assert_contains "$dout" "STAMP"       "reports missing Overview stamp"
# Fix 2 regression: module dir with a space must not be silently skipped.
assert_contains "$dout" "STAMP my mod/README.md" "spaced-dir module stamp checked"
rm -rf "$DIR/fixtures/repo-dirty/.git"

finish
