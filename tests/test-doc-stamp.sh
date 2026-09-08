#!/usr/bin/env bash
# tests/test-doc-stamp.sh — doc-stamp writes lifecycle frontmatter and touches nothing else.
#
# Three shapes, one block each: a file with no frontmatter (stamp-bare), one whose block
# already holds some of the keys (stamp-existing), and the same command run twice
# (stamp-twice). Files are built and torn down under tests/fixtures/stamp-repo; doc-stamp
# takes a path and never consults discovery, so the directory needs no git.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
STAMP="$DIR/../scripts/doc-stamp"
R="$DIR/fixtures/stamp-repo"; rm -rf "$R"; mkdir -p "$R"

# --- stamp-bare: a bare file gains a block holding exactly the given keys ---
echo "-- stamp-bare --"
F="$R/bare.md"
printf '# Title\n\nBody line one.\n\n- a list item\n' > "$F"
before="$(cat "$F")"
bash "$STAMP" "$F" kind=readme status=living updated=2026-09-06; rc=$?
assert_exit "$rc" "0" "stamp-bare: doc-stamp exits 0"
assert_eq "$(sed -n '1,5p' "$F")" \
  "$(printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-06\n---')" \
  "stamp-bare: the file gains a frontmatter block holding kind, status and updated"
assert_eq "$(sed -n '6,$p' "$F")" "$before" "stamp-bare: its content is unchanged"

# --- stamp-existing: named keys are set in place, new ones appended, the rest untouched ---
echo "-- stamp-existing --"
F="$R/existing.md"
printf -- '---\nkind: guide\nstatus: living\n---\n# Guide\n\nUnchanged body.\n' > "$F"
before="$(cat "$F")"
bash "$STAMP" "$F" status=hardened updated=2026-09-06; rc=$?
assert_exit "$rc" "0" "stamp-existing: doc-stamp exits 0"
after="$(cat "$F")"
assert_contains "$after" "status: hardened"      "stamp-existing: status carries the new value"
assert_not_contains "$after" "status: living"    "stamp-existing: the old status value is gone"
assert_contains "$after" "updated: 2026-09-06"   "stamp-existing: updated is added"
# every other line unchanged: drop the two keys doc-stamp was told to write, compare the rest
assert_eq "$(printf '%s\n' "$after"  | grep -v '^status:' | grep -v '^updated:')" \
          "$(printf '%s\n' "$before" | grep -v '^status:' | grep -v '^updated:')" \
          "stamp-existing: every other line is unchanged"

# --- stamp-twice: the same command a second time is a no-op ---
echo "-- stamp-twice --"
F="$R/twice.md"
printf '# Notes\n\nA line.\n' > "$F"
bash "$STAMP" "$F" kind=readme status=living updated=2026-09-06
once="$(cat "$F")"
bash "$STAMP" "$F" kind=readme status=living updated=2026-09-06; rc=$?
assert_exit "$rc" "0" "stamp-twice: the second run exits 0"
assert_eq "$(cat "$F")" "$once" "stamp-twice: the file is unchanged"

rm -rf "$R"; finish
