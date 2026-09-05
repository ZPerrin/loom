#!/usr/bin/env bash
# tests/test-lint-spec.sh — spec-doc fixtures and doc-linter integration.
#
# Fixtures: tests/fixtures/spec-repo/docs/specs/*.md (default budgets, ears=strict),
# tests/fixtures/spec-repo-tuned/docs/specs/reset-flow.md ([lint.specs] max_norm_words
# override), and tests/fixtures/spec-repo-ears/docs/specs/*.md ([lint.specs] ears = "warn").
# Every spec fixture is deliberately minimal: one isolated grammar violation per file
# (family prefix in the filename: g/p=structure, r=requirements, s=scenarios,
# w/l=word-list & line-shape), so the expected rule id per file is exact. Grammar is
# references/spec-grammar.md; change-log vocabulary and word lists are
# references/spec-writing-rules.md. Fixtures conform to both, not only to the checker.
#
# scripts/lib/lint-spec.awk (the checker under test) is written by a parallel delegate
# and is NOT expected to exist in every worktree that runs this file; assertions that
# need it are guarded and print a clear `skip` line instead of failing or crashing.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
LINTER="$DIR/../scripts/doc-linter"
AWK_CHECKER="$DIR/../scripts/lib/lint-spec.awk"
SPEC_REPO="$DIR/fixtures/spec-repo"
TUNED_REPO="$DIR/fixtures/spec-repo-tuned"
EARS_REPO="$DIR/fixtures/spec-repo-ears"

# Budget defaults, mirroring lib/lint-spec.awk; spec-repo-tuned overrides max_norm_words
# via [lint.specs] in its own .loom/loom.toml (max_norm_words = 12), and spec-repo-ears
# overrides ears the same way (max_norm_words = 12).
MNW=30; MPS=3; MSC=8; MFL=400
TUNED_MNW=12

# relpath<TAB>expected rule id, "-" meaning clean (no spec finding expected).
# One row per fixture; every violating fixture triggers exactly this one rule.
SPEC_REPO_TABLE="docs/specs/auth-session.md	-
docs/specs/g001-bad-first-line.md	G001
docs/specs/g001-delta-first-line.md	G001
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
docs/specs/l001-bad-invariant-shape.md	L001
docs/specs/l001-bad-changelog-line.md	L001"

# reset-flow.md's normative sentence is 23 words: clean under the default 30-word
# budget (see the doc-linter integration loop below, run at defaults for both repos);
# R008 only once [lint.specs] max_norm_words=12 is in effect (see the tuned-budget block).
TUNED_REPO_TABLE="docs/specs/reset-flow.md	-"

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

  eout="$(run_full_lint "$EARS_REPO")"; erc=$?
  assert_exit "$erc" "0" "spec-repo-ears: ears=warn does not fail the build"
  assert_contains "$eout" "SPECWARN" "spec-repo-ears: R003 is downgraded to a warning"
  assert_contains "$eout" "R003" "spec-repo-ears: SPECWARN names R003"
  rm -rf "$EARS_REPO/.git"
else
  printf '  skip  doc-linter spec integration not present in this worktree (scripts/lib/lint-spec.awk\n'
  printf '        missing, or not yet wired into scripts/doc-linter) — recorded expectations are\n'
  printf '        recorded above for the coordinator to verify once integration lands\n'
fi

# ------------------------------------------------------------------------ tuned budget
# [lint.specs] max_norm_words flows to the checker: same file, clean at the default
# 30-word budget, R008 at the tuned 12-word budget. Checker-only; needs no python3.
echo "-- tuned budget: [lint.specs] max_norm_words --"
if [ ! -f "$AWK_CHECKER" ]; then
  printf '  skip  scripts/lib/lint-spec.awk not present in this worktree\n'
else
  rel="docs/specs/reset-flow.md"
  src="$TUNED_REPO/$rel"
  default_out="$(awk -v rel="$rel" -v max_norm_words="$MNW" \
                     -v max_purpose_sentences="$MPS" -v max_scenarios="$MSC" \
                     -v max_file_lines="$MFL" -f "$AWK_CHECKER" "$src" 2>&1)"
  tuned_out="$(awk -v rel="$rel" -v max_norm_words="$TUNED_MNW" \
                    -v max_purpose_sentences="$MPS" -v max_scenarios="$MSC" \
                    -v max_file_lines="$MFL" -f "$AWK_CHECKER" "$src" 2>&1)"
  assert_not_contains "$default_out" "R008" "reset-flow.md: clean under default max_norm_words=30"
  assert_contains     "$tuned_out"   "R008" "reset-flow.md: R008 under tuned max_norm_words=12"
fi

# --------------------------------------------------------------------------- ears knob
# strict (the default) fails the shape check; off silences it outright. Checker-only,
# same fixture the doc-linter table above lints at the default (strict).
echo "-- checker-direct: ears knob (strict default vs off) --"
if [ ! -f "$AWK_CHECKER" ]; then
  printf '  skip  scripts/lib/lint-spec.awk not present in this worktree\n'
else
  rel="docs/specs/r003-bad-ears-shape.md"
  src="$SPEC_REPO/$rel"
  strict_out="$(awk -v rel="$rel" -v max_norm_words="$MNW" -v max_purpose_sentences="$MPS" \
                    -v max_scenarios="$MSC" -v max_file_lines="$MFL" -f "$AWK_CHECKER" "$src" 2>&1)"
  off_out="$(awk -v rel="$rel" -v max_norm_words="$MNW" -v max_purpose_sentences="$MPS" \
                 -v max_scenarios="$MSC" -v max_file_lines="$MFL" -v ears=off \
                 -f "$AWK_CHECKER" "$src" 2>&1)"
  assert_contains     "$strict_out" "R003" "r003 fixture: R003 fires at the default (strict) ears"
  assert_not_contains "$off_out"    "R003" "r003 fixture: ears=off silences R003 entirely"
fi

# ------------------------------------------------------- [lint.specs] ears config validation
# doc-linter validates the config value itself, independent of any spec content; built and
# torn down here rather than committed, same as the ad hoc config fixtures in
# test-doc-linter.sh (lint-config-repo, warp-repo, …). The spec body is deliberately the
# clean minimal example so the LINT finding below is the only finding in this repo.
echo "-- doc-linter: [lint.specs] ears invalid value --"
if [ "$HAS_INTEGRATION" -eq 1 ]; then
  BADEARS="$DIR/fixtures/spec-repo-badears"
  rm -rf "$BADEARS"; mkdir -p "$BADEARS/.loom" "$BADEARS/docs/specs"
  printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-05\n---\n# Home\n' > "$BADEARS/README.md"
  printf -- '---\nkind: spec\nstatus: living\nupdated: 2026-09-05\n---\n# Capability: demo\n\n## Purpose\nDemonstrates minimal valid spec structure for isolated lint fixtures.\n\n## Requirements\n### R-DEMO-001: Example behavior\nWHEN a user performs the action, the system SHALL record the result within 1 second.\n#### Scenario: basic -> test_example_basic\n- GIVEN a ready system\n- WHEN the user performs the action\n- THEN the result is recorded\n' > "$BADEARS/docs/specs/demo.md"
  printf '[lint]\nkinds = ["readme", "spec"]\nstatuses = ["living"]\n\n[lint.specs]\nears = "loud"\n' > "$BADEARS/.loom/loom.toml"
  ( cd "$BADEARS" && test_git_init >/dev/null 2>&1 && git add -A >/dev/null 2>&1 )
  bout="$(cd "$BADEARS" && bash "$LINTER" 2>&1)"; brc=$?
  assert_exit "$brc" "1" "invalid [lint.specs] ears value fails the lint"
  assert_contains "$bout" "LINT" "invalid ears value reports a LINT finding"
  assert_contains "$bout" "ears=loud not strict|warn|off" "invalid ears value names the bad value and the allowed set"
  rm -rf "$BADEARS"
else
  printf '  skip  doc-linter spec integration not present in this worktree\n'
fi

finish
