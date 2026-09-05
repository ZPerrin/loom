#!/usr/bin/env bash
# tests/test-lint-spec.sh — spec-doc fixtures, oracle parity, and doc-linter integration.
#
# Fixtures: tests/fixtures/spec-repo/docs/specs/*.md (default budgets) and
# tests/fixtures/spec-repo-tuned/docs/specs/reset-flow.md ([lint.specs] override).
# Every spec fixture is deliberately minimal: one isolated grammar violation per file
# (family prefix in the filename: g/p=structure, r=requirements, s=scenarios,
# w/l=word-list & line-shape), so the expected rule id per file is exact. Expectations
# below were derived by running the python oracle (tests/oracle/speclint.py) against a
# frontmatter-blanked copy of each fixture — see blank_frontmatter().
#
# scripts/lib/lint-spec.awk (the checker under test) is written by a parallel delegate
# and is NOT expected to exist in every worktree that runs this file; assertions that
# need it are guarded and print a clear `skip` line instead of failing or crashing.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
LINTER="$DIR/../scripts/doc-linter"
AWK_CHECKER="$DIR/../scripts/lib/lint-spec.awk"
ORACLE="$DIR/oracle/speclint.py"
SPEC_REPO="$DIR/fixtures/spec-repo"
TUNED_REPO="$DIR/fixtures/spec-repo-tuned"

# Budget defaults from contract.md; spec-repo-tuned overrides max_norm_words via
# [lint.specs] in its own .loom/loom.toml (max_norm_words = 12).
MNW=30; MLW=30; MPS=3; MSC=8; MFL=400
TUNED_MNW=12

# relpath<TAB>expected rule id, "-" meaning clean (no spec finding expected).
# One row per fixture; every violating fixture triggers exactly this one rule.
SPEC_REPO_TABLE="docs/specs/auth-session.md	-
docs/specs/g001-bad-first-line.md	G001
docs/specs/g002-unknown-section.md	G002
docs/specs/g003-out-of-order.md	G003
docs/specs/g004-duplicate-section.md	G004
docs/specs/g006-missing-purpose.md	G006
docs/specs/p001-purpose-too-long.md	P001
docs/specs/r001-bad-requirement-header.md	R001
docs/specs/r002-missing-normative.md	R002
docs/specs/r003-bad-ears-shape.md	R003
docs/specs/r004-two-modals.md	R004
docs/specs/r005-should-may.md	R005
docs/specs/r006-extra-body-line.md	R006
docs/specs/r008-normative-too-long.md	R008
docs/specs/r009-mixed-tokens.md	R009
docs/specs/s001-bad-scenario-header.md	S001
docs/specs/s002-no-test-ref.md	S002
docs/specs/s003-missing-when-then.md	S003
docs/specs/s004-too-many-scenarios.md	S004
docs/specs/w001-banned-word.md	W001
docs/specs/w002-flagged-word.md	W002
docs/specs/l001-bad-invariant-shape.md	L001"

# reset-flow.md's normative sentence is 23 words: clean under the default 30-word
# budget (see the parity loop below, run at defaults for both repos); R008 only
# once [lint.specs] max_norm_words=12 is in effect (see the tuned-budget block).
TUNED_REPO_TABLE="docs/specs/reset-flow.md	-"

# --- frontmatter -> blank lines (preserves line numbers) for the oracle, which
# predates frontmatter and would otherwise misparse '---' as the first grammar line.
blank_frontmatter() { # $1=src $2=dst
  awk '
    NR==1 && $0=="---" { infm=1; print ""; next }
    infm && $0=="---"  { infm=0; print ""; next }
    infm               { print ""; next }
    { print }
  ' "$1" > "$2"
}

oracle_tuples() { # $1=blanked file -> sorted "rule<TAB>line<TAB>id" lines
  python3 "$ORACLE" lint "$1" --json 2>/dev/null | python3 -c '
import json, sys
d = json.load(sys.stdin)
rows = sorted(set((f["rule"], f["line"], f.get("id") or "") for f in d["findings"]))
for r in rows:
    print(str(r[0]) + "\t" + str(r[1]) + "\t" + str(r[2]))
'
}

awk_tuples() { # $1=rel $2=file $3=max_norm_words -> sorted "rule<TAB>line<TAB>id" lines
  awk -v rel="$1" -v max_norm_words="$3" -v max_line_words="$MLW" \
      -v max_purpose_sentences="$MPS" -v max_scenarios="$MSC" \
      -v max_file_lines="$MFL" -v json=1 -f "$AWK_CHECKER" "$2" 2>/dev/null | python3 -c '
import json, sys
rows = set()
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    f = json.loads(line)
    rows.add((f["rule"], f["line"], f.get("id") or ""))
for r in sorted(rows):
    print(str(r[0]) + "\t" + str(r[1]) + "\t" + str(r[2]))
'
}

run_full_lint() { # $1=repo dir -> doc-linter output over that repo (git-inits in place)
  ( cd "$1" && rm -rf .git && test_git_init >/dev/null 2>&1 && git add -A >/dev/null 2>&1
    bash "$LINTER" 2>&1 )
}

# ---------------------------------------------------------------- doc-linter integration
# doc-linter itself does not yet call the spec checker in every worktree (the coordinator
# wires that up after both delegates land); detect it instead of assuming either way.
HAS_INTEGRATION=0
if grep -q "lint-spec" "$LINTER" 2>/dev/null && [ -f "$AWK_CHECKER" ]; then
  HAS_INTEGRATION=1
fi

echo "-- doc-linter full lint over spec fixtures --"
if [ "$HAS_INTEGRATION" -eq 1 ]; then
  out="$(run_full_lint "$SPEC_REPO")"; rc=$?
  assert_exit "$rc" "1" "spec-repo: violating specs make doc-linter exit 1"
  while IFS="$(printf '\t')" read -r rel rule; do
    [ -n "$rel" ] || continue
    [ "$rule" = "-" ] && continue
    assert_contains "$out" "$rule" "spec-repo $rel: doc-linter output mentions $rule"
  done <<SPECROWS
$SPEC_REPO_TABLE
SPECROWS
  rm -rf "$SPEC_REPO/.git"

  tout="$(run_full_lint "$TUNED_REPO")"; trc=$?
  assert_exit "$trc" "1" "spec-repo-tuned: tuned normative-length violation makes doc-linter exit 1"
  assert_contains "$tout" "R008" "spec-repo-tuned: doc-linter output mentions R008 under the tuned budget"
  rm -rf "$TUNED_REPO/.git"
else
  printf '  skip  doc-linter spec integration not present in this worktree (scripts/lib/lint-spec.awk\n'
  printf '        missing, or not yet wired into scripts/doc-linter) — oracle-derived expectations are\n'
  printf '        recorded above for the coordinator to verify once integration lands\n'
fi

# ------------------------------------------------------------------------------- parity
# Compare the awk checker directly against the python oracle: same multiset of
# (rule, line, id) per fixture. Run at the ORACLE's own fixed budgets (30/30/3/8/400)
# for every fixture in both repos — this validates grammar-implementation parity, not
# the [lint.specs] override (the oracle has no CLI flag for its budget constants; the
# override is exercised separately below, against the checker only).
echo "-- parity: awk checker vs python oracle --"
if ! command -v python3 >/dev/null 2>&1; then
  printf '  skip  python3 not found\n'
elif [ ! -f "$AWK_CHECKER" ]; then
  printf '  skip  scripts/lib/lint-spec.awk not present in this worktree (checker owned by a parallel delegate)\n'
else
  TMPD="$(mktemp -d)" || { echo "test-lint-spec.sh: mktemp failed" >&2; exit 1; }
  trap 'rm -rf "$TMPD"' EXIT

  check_parity() { # $1=repo dir $2=rel
    local repo="$1" rel="$2" src blanked ot at
    src="$repo/$rel"
    blanked="$TMPD/$(printf '%s' "$rel" | tr '/' '_').blanked.md"
    blank_frontmatter "$src" "$blanked"
    ot="$(oracle_tuples "$blanked")"
    at="$(awk_tuples "$rel" "$src" "$MNW")"
    if [ "$ot" = "$at" ]; then
      printf '  ok   parity %s\n' "$rel"
    else
      printf '  FAIL parity %s\n       oracle: [%s]\n       awk:    [%s]\n' "$rel" "$ot" "$at"
      FAILS=$((FAILS+1))
    fi
  }

  while IFS="$(printf '\t')" read -r rel _; do
    [ -n "$rel" ] || continue
    check_parity "$SPEC_REPO" "$rel"
  done <<SPECROWS
$SPEC_REPO_TABLE
SPECROWS

  while IFS="$(printf '\t')" read -r rel _; do
    [ -n "$rel" ] || continue
    check_parity "$TUNED_REPO" "$rel"
  done <<TUNEDROWS
$TUNED_REPO_TABLE
TUNEDROWS
fi

# ------------------------------------------------------------------------ tuned budget
# [lint.specs] max_norm_words flows to the checker: same file, clean at the default
# 30-word budget, R008 at the tuned 12-word budget. Checker-only; no oracle involved
# (the oracle's MAX_NORM_WORDS is a fixed constant), so this needs no python3.
echo "-- tuned budget: [lint.specs] max_norm_words --"
if [ ! -f "$AWK_CHECKER" ]; then
  printf '  skip  scripts/lib/lint-spec.awk not present in this worktree\n'
else
  rel="docs/specs/reset-flow.md"
  src="$TUNED_REPO/$rel"
  default_out="$(awk -v rel="$rel" -v max_norm_words="$MNW" -v max_line_words="$MLW" \
                     -v max_purpose_sentences="$MPS" -v max_scenarios="$MSC" \
                     -v max_file_lines="$MFL" -f "$AWK_CHECKER" "$src" 2>&1)"
  tuned_out="$(awk -v rel="$rel" -v max_norm_words="$TUNED_MNW" -v max_line_words="$MLW" \
                    -v max_purpose_sentences="$MPS" -v max_scenarios="$MSC" \
                    -v max_file_lines="$MFL" -f "$AWK_CHECKER" "$src" 2>&1)"
  assert_not_contains "$default_out" "R008" "reset-flow.md: clean under default max_norm_words=30"
  assert_contains     "$tuned_out"   "R008" "reset-flow.md: R008 under tuned max_norm_words=12"
fi

finish
