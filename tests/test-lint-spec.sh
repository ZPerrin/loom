#!/usr/bin/env bash
# tests/test-lint-spec.sh — spec-doc fixtures and doc-linter integration.
#
# Fixtures: tests/fixtures/spec-repo/docs/specs/*.md (default budgets, ears=strict),
# tests/fixtures/spec-repo-tuned/docs/specs/reset-flow.md ([lint.specs] max_norm_words
# override), and tests/fixtures/spec-repo-ears/docs/specs/*.md ([lint.specs] ears = "warn").
# Every spec fixture is deliberately minimal: one isolated grammar violation per file
# (family prefix in the filename: g/p=structure, r=requirements, s=scenarios,
# w/l=word-list & line-shape), so the expected rule id per file is exact — the table loop
# below asserts the rule on the lint lines that name that file, not merely somewhere in the
# run, so two fixtures sharing a rule id each still carry their own assertion. Grammar is
# references/spec-grammar.md; change-log vocabulary and word lists are
# references/spec-writing-rules.md. Fixtures conform to both, not only to the checker.
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
# overrides ears the same way (ears = "warn").
MNW=30; MPS=3; MSC=8; MFL=400
TUNED_MNW=12

# relpath<TAB>expected rule id, "-" meaning clean (asserted: no lint line names the file).
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
docs/specs/s001-bad-bullet-keyword.md	S001
docs/specs/s001-bad-bullet-opens-with-and.md	S001
docs/specs/s002-no-test-ref.md	S002
docs/specs/s003-missing-when-then.md	S003
docs/specs/s004-too-many-scenarios.md	S004
docs/specs/w001-banned-word.md	W001
docs/specs/w002-flagged-word.md	W002
docs/specs/l001-bad-invariant-shape.md	L001
docs/specs/l001-bad-changelog-line.md	L001
docs/specs/r010-duplicate-inv-id.md	R010
docs/specs/r010-duplicate-requirement-id.md	R010"

# reset-flow.md's normative sentence is 23 words: clean under the default 30-word
# budget (see the doc-linter integration loop below, run at defaults for both repos);
# R008 only once [lint.specs] max_norm_words=12 is in effect (see the tuned-budget block).
TUNED_REPO_TABLE="docs/specs/reset-flow.md	-"

run_full_lint() { # $1=repo dir -> doc-linter output over that repo (git-inits in place)
  ( cd "$1" && rm -rf .git && test_git_init >/dev/null 2>&1 && git add -A >/dev/null 2>&1
    bash "$LINTER" 2>&1 )
}

# ---------------------------------------------------------------- doc-linter integration

echo "-- doc-linter full lint over spec fixtures --"
out="$(run_full_lint "$SPEC_REPO")"; rc=$?
assert_exit "$rc" "1" "spec-repo: violating specs make doc-linter exit 1"
while IFS="$(printf '\t')" read -r rel rule; do
  [ -n "$rel" ] || continue
  if [ "$rule" = "-" ]; then
    assert_not_contains "$out" "$rel" "spec-repo $rel: conforming fixture yields no finding"
  else
    assert_contains "$(printf '%s\n' "$out" | grep -F "$rel")" "$rule" \
      "spec-repo $rel: the lint line naming this fixture reports $rule"
  fi
done <<SPECROWS
$SPEC_REPO_TABLE
SPECROWS

# R010's message carries positions, so assert them: the finding lands on the second header
# and names the first's line. Both numbers are read out of the fixture, never hardcoded.
echo "-- duplicate requirement id: R010 at the second header, naming the first --"
DUP_REL="docs/specs/r010-duplicate-requirement-id.md"
dup_first="$(grep -n '^### R-DEMO-001' "$SPEC_REPO/$DUP_REL" | sed -n 1p | cut -d: -f1)"
dup_second="$(grep -n '^### R-DEMO-001' "$SPEC_REPO/$DUP_REL" | sed -n 2p | cut -d: -f1)"
dup_out="$(printf '%s\n' "$out" | grep -F "$DUP_REL")"
assert_contains "$dup_out" "$DUP_REL:$dup_second:" \
  "duplicate id: R010 is reported at the second R-DEMO-001 header"
assert_contains "$dup_out" "duplicate id R-DEMO-001 (first at line $dup_first)" \
  "duplicate id: the message names the first header's line"

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

# ------------------------------------------------------------------------ tuned budget
# [lint.specs] max_norm_words flows to the checker: same file, clean at the default
# 30-word budget, R008 at the tuned 12-word budget. Checker-only.
echo "-- tuned budget: [lint.specs] max_norm_words --"
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

# --------------------------------------------------------------------------- ears knob
# strict (the default) fails the shape check; off silences it outright. Checker-only,
# same fixture the doc-linter table above lints at the default (strict).
echo "-- checker-direct: ears knob (strict default vs off) --"
rel="docs/specs/r003-bad-ears-shape.md"
src="$SPEC_REPO/$rel"
strict_out="$(awk -v rel="$rel" -v max_norm_words="$MNW" -v max_purpose_sentences="$MPS" \
                  -v max_scenarios="$MSC" -v max_file_lines="$MFL" -f "$AWK_CHECKER" "$src" 2>&1)"
off_out="$(awk -v rel="$rel" -v max_norm_words="$MNW" -v max_purpose_sentences="$MPS" \
               -v max_scenarios="$MSC" -v max_file_lines="$MFL" -v ears=off \
               -f "$AWK_CHECKER" "$src" 2>&1)"
assert_contains     "$strict_out" "R003" "r003 fixture: R003 fires at the default (strict) ears"
assert_not_contains "$off_out"    "R003" "r003 fixture: ears=off silences R003 entirely"

# ------------------------------------------------------- [lint.specs] ears config validation
# doc-linter validates the config value itself, independent of any spec content; built and
# torn down here rather than committed, same as the ad hoc config fixtures in
# test-doc-linter.sh (lint-config-repo, warp-repo, …). The spec body is deliberately the
# clean minimal example so the LINT finding below is the only finding in this repo.
echo "-- doc-linter: [lint.specs] ears invalid value --"
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

# --------------------------------------------------------- [lint.specs] budget fallback
# An invalid budget reports LINT and the checker runs at the shipped default: the 26-word
# sentence is clean at 30 and would trip R008 under a budget of 0.
echo "-- doc-linter: [lint.specs] invalid budget falls back to the default --"
BADBUDGET="$DIR/fixtures/spec-repo-badbudget"
rm -rf "$BADBUDGET"; mkdir -p "$BADBUDGET/.loom" "$BADBUDGET/docs/specs"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-05\n---\n# Home\n' > "$BADBUDGET/README.md"
printf -- '---\nkind: spec\nstatus: living\nupdated: 2026-09-05\n---\n# Capability: demo\n\n## Purpose\nDemonstrates minimal valid spec structure for isolated lint fixtures.\n\n## Requirements\n### R-DEMO-001: Example behavior\nWHEN a user performs the action, the system SHALL record the result within 1 second and keep the record for 30 days after the action completes.\n#### Scenario: basic -> test_example_basic\n- GIVEN a ready system\n- WHEN the user performs the action\n- THEN the result is recorded\n' > "$BADBUDGET/docs/specs/demo.md"
printf '[lint]\nkinds = ["readme", "spec"]\nstatuses = ["living"]\n\n[lint.specs]\nmax_norm_words = 0\n' > "$BADBUDGET/.loom/loom.toml"
( cd "$BADBUDGET" && test_git_init >/dev/null 2>&1 && git add -A >/dev/null 2>&1 )
bbout="$(cd "$BADBUDGET" && bash "$LINTER" 2>&1)"; bbrc=$?
assert_exit "$bbrc" "1" "invalid [lint.specs] budget fails the lint"
assert_contains "$bbout" "max_norm_words=0 not a positive integer" "invalid budget names the key and the value"
assert_not_contains "$bbout" "R008" "invalid budget falls back to the shipped default: no R008 at 26 words"
rm -rf "$BADBUDGET"

# ------------------------------------------------------ [lint.specs] max_file_lines (G005)
# A doc longer than the budget warns at its own last line, and a warning never fails the
# run. Built ad hoc so the budget can be tiny instead of the fixture being huge; the last
# line is counted from the file rather than hardcoded.
echo "-- doc-linter: [lint.specs] max_file_lines over-length warning --"
OVERLEN="$DIR/fixtures/spec-repo-overlength"
rm -rf "$OVERLEN"; mkdir -p "$OVERLEN/.loom" "$OVERLEN/docs/specs"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-05\n---\n# Home\n' > "$OVERLEN/README.md"
printf -- '---\nkind: spec\nstatus: living\nupdated: 2026-09-05\n---\n# Capability: demo\n\n## Purpose\nDemonstrates minimal valid spec structure for isolated lint fixtures.\n\n## Requirements\n### R-DEMO-001: Example behavior\nWHEN a user performs the action, the system SHALL record the result within 1 second.\n#### Scenario: basic -> test_example_basic\n- GIVEN a ready system\n- WHEN the user performs the action\n- THEN the result is recorded\n' > "$OVERLEN/docs/specs/demo.md"
printf '[lint]\nkinds = ["readme", "spec"]\nstatuses = ["living"]\n\n[lint.specs]\nmax_file_lines = 10\n' > "$OVERLEN/.loom/loom.toml"
( cd "$OVERLEN" && test_git_init >/dev/null 2>&1 && git add -A >/dev/null 2>&1 )
olast="$(awk 'END{print NR}' "$OVERLEN/docs/specs/demo.md")"
oout="$(cd "$OVERLEN" && bash "$LINTER" 2>&1)"; orc=$?
assert_exit "$orc" "0" "over-length: G005 is a warning and does not fail the run"
assert_contains "$oout" "SPECWARN docs/specs/demo.md:$olast:" "over-length: the warning lands on the file's last line"
assert_contains "$oout" "file exceeds 10 lines" "over-length: the message names the configured budget"
assert_contains "$oout" "(G005)" "over-length: the rule reported is G005"
rm -rf "$OVERLEN"

# ------------------------------------------ [lint.specs] banned / flagged custom word lists
# The configured arrays append to the checker's built-in lists: a configured banned phrase
# is an error naming the phrase, a configured flagged verb a warning naming the verb.
echo "-- doc-linter: [lint.specs] custom banned and flagged word lists --"
WORDLISTS="$DIR/fixtures/spec-repo-wordlists"
rm -rf "$WORDLISTS"; mkdir -p "$WORDLISTS/.loom" "$WORDLISTS/docs/specs"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-05\n---\n# Home\n' > "$WORDLISTS/README.md"
printf -- '---\nkind: spec\nstatus: living\nupdated: 2026-09-05\n---\n# Capability: demo\n\n## Purpose\nDemonstrates the widget-flow for isolated lint fixtures.\n\n## Invariants\n- INV-1: The parser does not juggle two configs.\n\n## Requirements\n### R-DEMO-001: Example behavior\nWHEN a user performs the action, the system SHALL record the result within 1 second.\n#### Scenario: basic -> test_example_basic\n- GIVEN a ready system\n- WHEN the user performs the action\n- THEN the result is recorded\n' > "$WORDLISTS/docs/specs/demo.md"
printf '[lint]\nkinds = ["readme", "spec"]\nstatuses = ["living"]\n\n[lint.specs]\nbanned = ["widget-flow"]\nflagged = ["juggle"]\n' > "$WORDLISTS/.loom/loom.toml"
( cd "$WORDLISTS" && test_git_init >/dev/null 2>&1 && git add -A >/dev/null 2>&1 )
cwout="$(cd "$WORDLISTS" && bash "$LINTER" 2>&1)"; cwrc=$?
assert_exit "$cwrc" "1" "custom-lists: a configured banned word fails the lint"
assert_contains "$cwout" "SPEC     docs/specs/demo.md" "custom-lists: the banned word is reported as an error"
assert_contains "$cwout" "banned word: 'widget-flow'" "custom-lists: W001 names widget-flow"
assert_contains "$cwout" "(W001)" "custom-lists: the banned word's rule is W001"
assert_contains "$cwout" "SPECWARN docs/specs/demo.md" "custom-lists: the flagged verb is reported as a warning"
assert_contains "$cwout" "weak verb: 'juggle'" "custom-lists: W002 names juggle"
assert_contains "$cwout" "(W002)" "custom-lists: the flagged verb's rule is W002"
rm -rf "$WORDLISTS"

finish
