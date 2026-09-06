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
assert_contains "$out" "Fenced example inside the section." "fenced: a code block inside the section stays in the body"
assert_not_contains "$out" "Fenced Now body." "fenced: a header inside a code block is not a section"
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

# A fenced header is not a section, in query mode too.
qo="$(cd "$R" && bash "$SLICER" --header "## Now" 2>&1)"
assert_not_contains "$qo" "mod/README.md" "fenced: query skips the doc whose only match is fenced"

# Several path filters OR-match: a doc matching any one of them is kept.
qo="$(cd "$R" && bash "$SLICER" --header "## Now" nope docs 2>&1)"; qrc=$?
assert_exit "$qrc" "0" "OR-match: several filters exit 0 when one matches"
assert_contains "$qo" "Shipping the slicer." "OR-match: the doc matching the second filter is emitted"

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
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-06\n---\n# Notes\n\n## Now\n\nShipped header body.\n' > "$NC/notes.md"
( cd "$NC" && test_git_init && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: no conf" )
nout="$(cd "$NC" && bash "$SLICER" 2>&1)"; nrc=$?
assert_exit "$nrc" "0" "no-config slicer exits 0"
assert_contains "$nout" "Bearings"      "no-config still emits Bearings"
assert_contains "$nout" "seed: no conf" "no-config includes git log"
assert_contains "$nout" "Shipped header body." "no-config harvests the shipped ## Now header from a managed doc"
rm -rf "$NC"

# session-start-degrades: an unparseable loom.toml is refused whole and the slice runs on
# the shipped defaults. The [context] override above the bad line names "## Later"; the
# shipped default names "## Now", so which body is harvested says which config won.
DG="$DIR/fixtures/degrade-repo"; rm -rf "$DG"; mkdir -p "$DG/.loom"
printf -- '---\nkind: roadmap\nstatus: living\nupdated: 2026-09-06\n---\n# Plan\n\n## Now\n\nShipping the default header.\n\n## Later\n\nThe overridden header.\n' > "$DG/plan.md"
printf '[context]\nslice_headers = ["## Later"]\n\n[lint]\nbad = { inline = "table" }\n' > "$DG/.loom/loom.toml"
( cd "$DG" && test_git_init && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: degrade repo" )
dgo="$(cd "$DG" && bash "$SLICER" 2>&1)"; dgrc=$?
assert_exit "$dgrc" "0" "session-start-degrades: an unparseable config still exits 0"
assert_contains "$dgo" "Bearings"                     "session-start-degrades: bearings are still emitted"
assert_contains "$dgo" "Shipping the default header." "session-start-degrades: the shipped ## Now header is harvested"
assert_not_contains "$dgo" "The overridden header."   "session-start-degrades: no key from the refused file takes effect"
rm -rf "$DG"

# bearings-count: the commit count comes from [context].recent_commits, not a constant.
BC="$DIR/fixtures/bearings-repo"; rm -rf "$BC"; mkdir -p "$BC/.loom"
printf '[context]\nrecent_commits = 2\n' > "$BC/.loom/loom.toml"
( cd "$BC" && test_git_init && for m in first second third; do echo "$m" > note.txt; git add -A; git -c user.email=t@t -c user.name=t commit -q -m "commit: $m"; done )
bco="$(cd "$BC" && bash "$SLICER" 2>&1)"; bcrc=$?
assert_exit "$bcrc" "0" "bearings-count: exits 0"
assert_contains "$bco" "commit: third"      "bearings-count: newest commit shown"
assert_contains "$bco" "commit: second"     "bearings-count: second commit shown"
assert_not_contains "$bco" "commit: first"  "bearings-count: the third-newest commit is cut by recent_commits = 2"
rm -rf "$BC"

finish
