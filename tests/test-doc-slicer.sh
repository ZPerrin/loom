#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
SLICER="$DIR/../scripts/doc-slicer"
SCRIPTS="$(cd "$DIR/../scripts" && pwd)"
R="$DIR/fixtures/slice-repo"

rm -rf "$R/.git"
( cd "$R" && test_git_init && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: slice repo" )
out="$(cd "$R" && bash "$SLICER" 2>&1)"; rc=$?
assert_exit "$rc" "0" "slicer exits 0"
assert_contains "$out" "Bearings"              "emits Bearings heading"
assert_contains "$out" "## Tools"              "tools-listed: the slice opens with the tools block"
assert_contains "$out" "\`$SCRIPTS\`"          "tools-listed: names the scripts directory"
assert_contains "$out" "\`doc-scan\`"          "tools-listed: doc-scan"
assert_contains "$out" "\`doc-linter\`"        "tools-listed: doc-linter"
assert_contains "$out" "\`doc-stamp "          "tools-listed: doc-stamp"
assert_contains "$out" "Repo specs: \`docs/specs/\`"      "tools-listed: the shipped repo specs location"
assert_contains "$out" "handoffs \`.loom/handoffs/\`"     "tools-listed: the shipped handoffs location"
assert_contains "$out" "reports \`.loom/reports/\`"       "tools-listed: the shipped reports location"
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
assert_not_contains "$qo" "## Tools"          "query: no tools block"

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

# --- tools mode: the block alone, for a delegate's brief ---
to="$(cd "$R" && bash "$SLICER" --tools 2>&1)"; trc=$?
assert_exit "$trc" "0" "tools-alone: --tools exits 0"
assert_contains "$to" "## Tools" "tools-alone: the block is emitted"
assert_contains "$to" "\`$SCRIPTS\`" "tools-alone: names the scripts directory"
assert_not_contains "$to" "Bearings" "tools-alone: no bearings"
assert_not_contains "$to" "Shipping the slicer." "tools-alone: no harvested section"
assert_not_contains "$to" "opening context" "tools-alone: no slices line"
to2="$(cd "$R" && bash "$SLICER" --tools 2>&1)"
assert_eq "$to2" "$to" "tools-bytes: the same query yields identical bytes"
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
nto="$(cd "$NC" && bash "$SLICER" --tools 2>&1)"; ntrc=$?
assert_exit "$ntrc" "0" "tools-noconf: --tools with no config exits 0"
assert_contains "$nto" "handoffs \`.loom/handoffs/\`" "tools-noconf: the shipped handoffs location is named"
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
assert_contains "$dgo" "## Tools"                     "session-start-degrades: the tools block is still emitted"
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

# locations-resolved: the tools block names each location from its key, or its shipped default,
# as a directory with one trailing slash whatever the key held.
LR="$DIR/fixtures/locations-repo"; rm -rf "$LR"; mkdir -p "$LR/.loom"
printf '[specs]\nrepo_dir = "documentation/specs/"\n[handoffs]\ndir = ".loom/briefs"\n' > "$LR/.loom/loom.toml"
( cd "$LR" && test_git_init && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: locations" )
lro="$(cd "$LR" && bash "$SLICER" --tools 2>&1)"; lrrc=$?
assert_exit "$lrrc" "0" "locations-resolved: exits 0"
assert_contains "$lro" "Repo specs: \`documentation/specs/\`" "locations-resolved: a configured repo_dir, one trailing slash"
assert_contains "$lro" "handoffs \`.loom/briefs/\`" "locations-resolved: a configured handoffs dir"
assert_contains "$lro" "reports \`.loom/reports/\`" "locations-resolved: an unset reports dir takes the shipped default"
assert_contains "$lro" "plans \`.loom/plans/\`" "locations-resolved: an unset plans dir takes the shipped default"
assert_not_contains "$lro" "docs/specs/" "locations-resolved: the default is not named when the key is set"
rm -rf "$LR"

# --- spec mode: one capability's spec, or one block of it, found by its Capability line ---
SR="$DIR/fixtures/spec-slice-repo"; rm -rf "$SR"; mkdir -p "$SR/notes" "$SR/docs/specs"
cat > "$SR/notes/spec-b.md" <<'EOS'
---
kind: spec
status: living
updated: 2026-09-06
---
# Capability: billing

## Purpose
billing is what the customer pays.

## Invariants
- INV-1: A charge is never made twice.
- INV-2: An invoice is immutable once sent.

## Requirements
### R-BILL-001: An invoice is sent once
WHEN an invoice is finalized, the system SHALL send it once.
#### Scenario: send-once -> tests/bill.sh#once
- WHEN an invoice is finalized
- THEN it is sent once
#### Scenario: resend-refused -> tests/bill.sh#resend
- WHEN a sent invoice is finalized again
- THEN the second send is refused

### R-BILL-002: A refund reverses a charge
WHEN a refund is issued, the system SHALL reverse the charge.
#### Scenario: refund -> tests/bill.sh#refund
- WHEN a refund is issued
- THEN the charge is reversed

## Non-goals
- N-1: Tax is the ledger capability.
- N-10: Currency conversion is the ledger capability.

## Change log
- 2026-09-06 R-BILL-001: the resend refusal was untested -> asserted
EOS
printf -- '---\nkind: spec\nstatus: living\nupdated: 2026-09-06\n---\n# Billing decoy\n\nNo Capability line, so no capability.\n' > "$SR/docs/specs/decoy.md"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-06\n---\n# Capability: billing\n\nA readme decoy that borrows the first line.\n' > "$SR/README.md"
( cd "$SR" && test_git_init && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: spec slice repo" )

so="$(cd "$SR" && bash "$SLICER" --spec billing 2>&1)"; src=$?
assert_exit "$src" "0" "spec-by-capability: exits 0"
assert_contains "$so" "R-BILL-001" "spec-by-capability: the spec body is emitted"
assert_contains "$so" "notes/spec-b.md" "spec-by-capability: provenance names the path the Capability line was found at"
assert_not_contains "$so" "status: living" "spec-by-capability: frontmatter is stripped"
assert_not_contains "$so" "Bearings" "spec-by-capability: no bearings"
assert_not_contains "$so" "opening context" "spec-by-capability: no preamble"
assert_not_contains "$so" "decoy" "spec-decoys: a spec without a Capability line and a readme with one are both skipped"

so2="$(cd "$SR" && bash "$SLICER" --spec billing 2>&1)"
assert_eq "$so2" "$so" "spec-bytes: the same query yields identical bytes"

so="$(cd "$SR" && bash "$SLICER" --spec billing ids 2>&1)"
assert_contains "$so" "R-BILL-001: An invoice is sent once" "spec-ids: each requirement id with its title"
assert_contains "$so" "R-BILL-002: A refund reverses a charge" "spec-ids: every requirement is listed"
assert_not_contains "$so" "WHEN" "spec-ids: no sentence or scenario text"

so="$(cd "$SR" && bash "$SLICER" --spec billing R-BILL-001 2>&1)"; src=$?
assert_exit "$src" "0" "spec-block: a requirement id exits 0"
assert_contains "$so" "### R-BILL-001: An invoice is sent once" "spec-block: the header is emitted"
assert_contains "$so" "WHEN an invoice is finalized, the system SHALL send it once." "spec-block: the normative sentence is emitted"
assert_contains "$so" "resend-refused" "spec-block: the requirement's scenarios come with it"
assert_not_contains "$so" "R-BILL-002" "spec-block: the next requirement is not"
assert_not_contains "$so" "Non-goals" "spec-block: the section after it is not"

so="$(cd "$SR" && bash "$SLICER" --spec billing N-1 2>&1)"
assert_contains "$so" "N-1: Tax" "spec-line: the one non-goal line"
assert_not_contains "$so" "N-10" "spec-line: N-1 does not match N-10"
so="$(cd "$SR" && bash "$SLICER" --spec billing INV-2 2>&1)"
assert_contains "$so" "INV-2: An invoice is immutable" "spec-line: an invariant by id"
assert_not_contains "$so" "INV-1" "spec-line: only the named invariant"

so="$(cd "$SR" && bash "$SLICER" --spec billing Non-goals 2>&1)"
assert_contains "$so" "N-10: Currency" "spec-section: a section by bare name"
assert_not_contains "$so" "INV-1" "spec-section: only that section"

so="$(cd "$SR" && bash "$SLICER" --spec billing R-BILL-009 2>&1)"; src=$?
assert_exit "$src" "1" "spec-no-block: an id the spec lacks exits 1"
assert_contains "$so" "no block" "spec-no-block: the miss says so"
so="$(cd "$SR" && bash "$SLICER" --spec ledger 2>&1)"; src=$?
assert_exit "$src" "1" "spec-no-capability: a capability no spec names exits 1"
assert_contains "$so" "no managed spec" "spec-no-capability: the miss says so"
so="$(cd "$SR" && bash "$SLICER" --spec 2>&1)"; src=$?
assert_exit "$src" "2" "spec-usage: --spec with no capability exits 2"
so="$(cd "$SR" && bash "$SLICER" 2>&1)"
assert_contains "$so" "--spec" "advertises: the session preamble names the spec query too"
rm -rf "$SR"

finish
