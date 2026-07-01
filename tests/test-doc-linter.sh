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

# --- META: meta-documentation tripwire ---
# Repo docs whose subject is the doc system (harness references, topology narration) are flagged;
# loom-config docs are exempt; meta_denylist = ["off"] disables; custom lists replace the defaults.
MR="$DIR/fixtures/meta-repo"
rm -rf "$MR"; mkdir -p "$MR/.loom"
( cd "$MR" && git init -q . )
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-07-01\n---\n# Docs\n\nThe doc convention ships with the plugin.\nA fine sentence about the actual project.\n' > "$MR/README.md"
printf -- '---\nkind: loom-config\nstatus: living\nupdated: 2026-07-01\n---\n# weft\n\nWriter policy may say frontmatter and managed set freely.\n' > "$MR/.loom/weft.md"

# Default denylist -> META finding on the readme, none on the loom-config doc.
printf '[lint]\nkinds = ["readme", "loom-config"]\nstatuses = ["living"]\n' > "$MR/.loom/loom.toml"
mo="$(cd "$MR" && bash "$LINTER" 2>&1)"; mrc=$?
assert_exit "$mrc" "1" "meta prose: exit 1"
assert_contains "$mo" "META"          "meta prose: META finding"
assert_contains "$mo" "the plugin"    "META names the tripped term"
assert_contains "$mo" "README.md:8"   "META carries file:line"
assert_not_contains "$mo" "weft.md"   "loom-config docs exempt from META"

# Word boundary: 'plugins' does not trip 'the plugin'... but a real term still does.
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-07-01\n---\n# Docs\n\nWe ship three editor plugins for the app.\n' > "$MR/README.md"
mo="$(cd "$MR" && bash "$LINTER" 2>&1)"; mrc=$?
assert_exit "$mrc" "0" "word boundary: 'plugins' alone stays clean"

# Fenced code blocks are not scanned.
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-07-01\n---\n# Docs\n\n```\nthe plugin, frontmatter, managed set\n```\n' > "$MR/README.md"
mo="$(cd "$MR" && bash "$LINTER" 2>&1)"; mrc=$?
assert_exit "$mrc" "0" "META skips fenced code"

# Opt-out: meta_denylist = ["off"].
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-07-01\n---\n# Docs\n\nThe doc convention ships with the plugin.\n' > "$MR/README.md"
printf '[lint]\nkinds = ["readme", "loom-config"]\nstatuses = ["living"]\nmeta_denylist = ["off"]\n' > "$MR/.loom/loom.toml"
mo="$(cd "$MR" && bash "$LINTER" 2>&1)"; mrc=$?
assert_exit "$mrc" "0" "meta_denylist off: clean exit"

# Custom list replaces the defaults.
printf '[lint]\nkinds = ["readme", "loom-config"]\nstatuses = ["living"]\nmeta_denylist = ["scaffolding lifecycle"]\n' > "$MR/.loom/loom.toml"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-07-01\n---\n# Docs\n\nPer the scaffolding lifecycle, the plugin prunes this.\n' > "$MR/README.md"
mo="$(cd "$MR" && bash "$LINTER" 2>&1)"
assert_contains "$mo" "scaffolding lifecycle" "custom term trips"
assert_not_contains "$mo" '"the plugin"'      "custom list replaces defaults"

rm -rf "$MR"

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

# --- [weft] section validation (control-plane config enforcement) ---
# Single optional knob; when [weft] is present, the linter requires cleanup, valid.
WF="$DIR/fixtures/weft-repo"
rm -rf "$WF"; mkdir -p "$WF/.loom"
( cd "$WF" && git init -q . )

# Absent -> no WEFT finding, clean exit.
printf '[lint]\nkinds = ["readme"]\nstatuses = ["living"]\n' > "$WF/.loom/loom.toml"
fo="$(cd "$WF" && bash "$LINTER" 2>&1)"; frc=$?
assert_not_contains "$fo" "WEFT" "[weft] absent: no weft finding"
assert_exit "$frc" "0" "[weft] absent: clean exit"

# Present + valid -> no WEFT finding.
printf '[weft]\ncleanup = "always"\n' > "$WF/.loom/loom.toml"
fo="$(cd "$WF" && bash "$LINTER" 2>&1)"
assert_not_contains "$fo" "WEFT" "valid [weft]: no weft finding"

# Present but empty (cleanup missing) -> finding naming it, exit 1.
printf '[weft]\n' > "$WF/.loom/loom.toml"
fo="$(cd "$WF" && bash "$LINTER" 2>&1)"; frc=$?
assert_exit "$frc" "1" "[weft] missing knob: exit 1"
assert_contains "$fo" "WEFT"    "[weft] missing cleanup: weft finding"
assert_contains "$fo" "cleanup" "[weft] names the missing cleanup knob"

# Invalid cleanup value -> finding naming the bad value.
printf '[weft]\ncleanup = "sometimes"\n' > "$WF/.loom/loom.toml"
fo="$(cd "$WF" && bash "$LINTER" 2>&1)"
assert_contains "$fo" "sometimes" "[weft] invalid cleanup value flagged"

rm -rf "$WF"

finish
