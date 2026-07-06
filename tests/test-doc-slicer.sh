#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
SLICER="$DIR/../scripts/doc-slicer"
R="$DIR/fixtures/slice-repo"

rm -rf "$R/.git"
( cd "$R" && test_git_init && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: slice repo" )
out="$(cd "$R" && bash "$SLICER" 2>&1)"; rc=$?
assert_exit "$rc" "0" "slicer exits 0"
assert_contains "$out" "Bearings"              "emits Bearings heading"
assert_contains "$out" "seed: slice repo"      "includes recent commit"
assert_contains "$out" "Shipping the slicer."  "harvests ## Now body"
assert_contains "$out" "the example module"    "harvests ## Module Map body"
assert_contains "$out" "kind: roadmap"         "inject_fields annotates kind"
assert_contains "$out" "docs/roadmap.md" "inject_fields annotates location"
assert_not_contains "$out" "BOGUS" "location annotation is path-derived, not read from frontmatter"
assert_not_contains "$out" "Module overview body." "unconfigured ## Overview NOT harvested"
rm -rf "$R/.git"

# --- query mode: --header pulls one addressable section on demand ---
rm -rf "$R/.git"
( cd "$R" && test_git_init && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: slice repo" )

# Exact header: section body + provenance, none of the session dressing.
qo="$(cd "$R" && bash "$SLICER" --header "## Overview" 2>&1)"; qrc=$?
assert_exit "$qrc" "0" "query: exact header exits 0"
assert_contains "$qo" "Module overview body." "query: emits the section body"
assert_contains "$qo" "mod/README.md"         "query: carries provenance annotation"
assert_not_contains "$qo" "Bearings"          "query: no Bearings block"
assert_not_contains "$qo" "opening context"   "query: no session preamble"

# Bare name is forgiving (Overview -> ## Overview).
qo="$(cd "$R" && bash "$SLICER" --header Overview 2>&1)"
assert_contains "$qo" "Module overview body." "query: bare header name works"

# Path filter narrows the managed set.
qo="$(cd "$R" && bash "$SLICER" --header "## Now" docs 2>&1)"; qrc=$?
assert_exit "$qrc" "0" "query: path filter keeps the matching doc"
assert_contains "$qo" "Shipping the slicer." "query: filtered hit emitted"

# Miss (header exists nowhere under the filter): exit 1 with a note.
qo="$(cd "$R" && bash "$SLICER" --header Overview docs 2>&1)"; qrc=$?
assert_exit "$qrc" "1" "query: no hit under filter exits 1"
assert_contains "$qo" "no managed doc" "query: miss says so"

# Missing header arg: usage error.
qo="$(cd "$R" && bash "$SLICER" --header 2>&1)"; qrc=$?
assert_exit "$qrc" "2" "query: missing header name exits 2"

# Session mode advertises the on-demand query in the preamble.
so="$(cd "$R" && bash "$SLICER" 2>&1)"
assert_contains "$so" "--header" "session preamble advertises the query"
rm -rf "$R/.git"

# No loom.toml: defaults (## Now header, no managed docs) -> Bearings only, no crash.
NC="$DIR/fixtures/slice-noconf"
rm -rf "$NC"; mkdir -p "$NC"
printf 'plain text, no docs\n' > "$NC/notes.txt"
( cd "$NC" && test_git_init && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: no conf" )
nout="$(cd "$NC" && bash "$SLICER" 2>&1)"; nrc=$?
assert_exit "$nrc" "0" "no-config slicer exits 0"
assert_contains "$nout" "Bearings"      "no-config still emits Bearings"
assert_contains "$nout" "seed: no conf" "no-config includes git log"
rm -rf "$NC"

finish
