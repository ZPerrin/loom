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
