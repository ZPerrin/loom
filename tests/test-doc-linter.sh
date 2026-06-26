#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
LINTER="$DIR/../scripts/doc-linter"

# Clean fixture: unified frontmatter, no links -> exit 0, reports clean.
rm -rf "$DIR/fixtures/repo-clean/.git"
out="$(cd "$DIR/fixtures/repo-clean" && git init -q . && git add -A && bash "$LINTER" 2>&1)"; rc=$?
assert_exit "$rc" "0" "clean fixture exits 0"
assert_contains "$out" "doc-linter: clean" "clean fixture reports clean"
rm -rf "$DIR/fixtures/repo-clean/.git"

# Dirty fixture: link + frontmatter findings, NO stamp tier.
rm -rf "$DIR/fixtures/repo-dirty/.git"
(cd "$DIR/fixtures/repo-dirty" && git init -q . && git add -A)
dout="$(cd "$DIR/fixtures/repo-dirty" && bash "$LINTER" 2>&1)"; drc=$?
assert_exit "$drc" "1" "dirty fixture exits 1"
assert_contains "$dout" "BROKEN"            "reports BROKEN link"
assert_contains "$dout" "nope/missing.md"   "names the broken href"
assert_contains "$dout" "CODELINK"          "reports CODELINK"
assert_contains "$dout" "MISSING"           "reports MISSING list-path link"
assert_contains "$dout" "FRONTMATTER"       "reports bad frontmatter kind"
assert_contains "$dout" "my mod/README.md"  "spaced-dir managed doc is checked (no word-split)"
assert_not_contains "$dout" "STAMP"         "STAMP tier removed"
assert_contains "$dout" "PLACEMENT"          "reports misplaced loom-config doc"
assert_contains "$dout" "outside config_dir" "flags loom-config in the wrong directory"
assert_contains "$dout" "no skill named"     "flags loom-config with a non-skill basename"
rm -rf "$DIR/fixtures/repo-dirty/.git"

# --- [warp] section validation (control-plane config enforcement) ---
# Optional section; when present, the linter requires the core knobs, valid.
WR="$DIR/fixtures/warp-repo"
rm -rf "$WR"; mkdir -p "$WR/.loom"
( cd "$WR" && git init -q . )

# Absent -> no WARP finding, clean exit.
printf '[lint]\nkinds = ["readme"]\nstatuses = ["living"]\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"; wrc=$?
assert_not_contains "$wo" "WARP" "[warp] absent: no warp finding"
assert_exit "$wrc" "0" "[warp] absent: clean exit"

# Present + valid -> no WARP finding.
printf '[warp]\nbranch_convention = "zeb/<slug>"\nworktree = "never"\nwork_source = "github"\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"
assert_not_contains "$wo" "WARP" "valid [warp]: no warp finding"

# Missing worktree knob -> finding naming it, exit 1.
printf '[warp]\nbranch_convention = "x"\nwork_source = "none"\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"; wrc=$?
assert_exit "$wrc" "1" "[warp] missing knob: exit 1"
assert_contains "$wo" "WARP"     "[warp] missing worktree: warp finding"
assert_contains "$wo" "worktree" "[warp] names the missing worktree knob"

# Invalid worktree value -> finding naming the bad value.
printf '[warp]\nbranch_convention = "x"\nworktree = "sometimes"\nwork_source = "none"\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"
assert_contains "$wo" "sometimes" "[warp] invalid worktree value flagged"

# Missing branch_convention -> finding.
printf '[warp]\nworktree = "ask"\nwork_source = "none"\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"
assert_contains "$wo" "branch_convention" "[warp] missing branch_convention: finding"

# Missing work_source -> finding.
printf '[warp]\nbranch_convention = "x"\nworktree = "ask"\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"
assert_contains "$wo" "work_source" "[warp] missing work_source: finding"

rm -rf "$WR"

finish
