#!/usr/bin/env bash
# tests/test-doc-scan.sh — doc-scan reports the managed set and the omission candidates apart.
#
# One ad hoc repo, built and torn down under tests/fixtures/scan-repo: two docs with kind
# frontmatter (one nested) and one without. The report is split at its candidates header and
# each side checked, so "listed apart" means apart and not merely both present.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
SCAN="$DIR/../scripts/doc-scan"
R="$DIR/fixtures/scan-repo"; rm -rf "$R"; mkdir -p "$R/sub"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-06\n---\n# a\n' > "$R/a.md"
printf -- '---\nkind: spec\nstatus: living\nupdated: 2026-09-06\n---\n# c\n' > "$R/sub/c.md"
printf '# b\n\nNo frontmatter here.\n' > "$R/b.md"
( cd "$R" && test_git_init && git add -A )

echo "-- doc-scan-report --"
out="$(cd "$R" && bash "$SCAN" 2>&1)"; rc=$?
assert_exit "$rc" "0" "doc-scan-report: doc-scan exits 0"
assert_contains "$out" "# managed"    "doc-scan-report: a managed header opens the first list"
assert_contains "$out" "# candidates" "doc-scan-report: a candidates header opens the second"

managed="$(printf '%s\n' "$out" | awk '/^# candidates/ { exit } { print }')"
cands="$(printf '%s\n' "$out" | awk '/^# candidates/ { on = 1; next } on { print }')"
assert_contains     "$managed" "a.md"     "doc-scan-report: a.md is listed under managed"
assert_contains     "$managed" "sub/c.md" "doc-scan-report: the nested doc is listed under managed"
assert_not_contains "$managed" "b.md"     "doc-scan-report: the candidate is not listed under managed"
assert_contains     "$cands"   "b.md"     "doc-scan-report: b.md is listed under candidates"
assert_not_contains "$cands"   "a.md"     "doc-scan-report: the managed docs are not listed under candidates"

rm -rf "$R"; finish
