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
printf '[warp]\nbranch_convention = "zeb/<slug>"\nworktree = "never"\nsource_repo = "."\nsource_branch = "main"\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"
assert_not_contains "$wo" "WARP" "valid [warp]: no warp finding"

# Missing worktree knob -> finding naming it, exit 1.
printf '[warp]\nbranch_convention = "x"\nsource_repo = "."\nsource_branch = "main"\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"; wrc=$?
assert_exit "$wrc" "1" "[warp] missing knob: exit 1"
assert_contains "$wo" "WARP"     "[warp] missing worktree: warp finding"
assert_contains "$wo" "worktree" "[warp] names the missing worktree knob"

# Invalid worktree value -> finding naming the bad value.
printf '[warp]\nbranch_convention = "x"\nworktree = "sometimes"\nsource_repo = "."\nsource_branch = "main"\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"
assert_contains "$wo" "sometimes" "[warp] invalid worktree value flagged"

# Missing branch_convention -> finding.
printf '[warp]\nworktree = "ask"\nsource_repo = "."\nsource_branch = "main"\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"
assert_contains "$wo" "branch_convention" "[warp] missing branch_convention: finding"

# Missing source_repo -> finding.
printf '[warp]\nbranch_convention = "x"\nworktree = "ask"\nsource_branch = "main"\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"
assert_contains "$wo" "source_repo" "[warp] missing source_repo: finding"

# Missing source_branch -> finding.
printf '[warp]\nbranch_convention = "x"\nworktree = "ask"\nsource_repo = "."\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"
assert_contains "$wo" "source_branch" "[warp] missing source_branch: finding"

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

# --- executable-hooks config validation ---
HR="$DIR/fixtures/hook-lint"; rm -rf "$HR"; mkdir -p "$HR/.loom/scripts"
mk_toml() { printf '%s\n' "$1" > "$HR/.loom/loom.toml"; }
lint_hr() { (cd "$HR" && rm -rf .git && git init -q . && git add -A 2>/dev/null; bash "$LINTER" 2>&1); }

# valid: warp with source_repo/branch + worktree=harness + a hook naming an executable script
printf '#!/usr/bin/env bash\necho hi\n' > "$HR/.loom/scripts/warp-open.sh"; chmod +x "$HR/.loom/scripts/warp-open.sh"
mk_toml '[skills]
scripts_dir = ".loom/scripts"
[warp]
branch_convention = "feature/<slug>"
source_repo = "."
source_branch = "master"
worktree = "harness"
hook = "warp-open.sh"'
o="$(lint_hr)"; assert_not_contains "$o" "WARP" "valid warp+hook config: no WARP finding"

# invalid: worktree=bogus
mk_toml '[warp]
branch_convention = "feature/<slug>"
source_repo = "."
source_branch = "master"
worktree = "bogus"'
o="$(lint_hr)"; assert_contains "$o" "worktree=bogus" "invalid worktree value flagged"

# invalid: [warp] present but missing source_branch
mk_toml '[warp]
branch_convention = "feature/<slug>"
source_repo = "."
worktree = "always"'
o="$(lint_hr)"; assert_contains "$o" "missing source_branch" "missing source_branch flagged"

# invalid: hook names a script that exists but is NOT executable
printf 'echo hi\n' > "$HR/.loom/scripts/dead.sh"; chmod -x "$HR/.loom/scripts/dead.sh"
mk_toml '[skills]
scripts_dir = ".loom/scripts"
[warp]
branch_convention = "feature/<slug>"
source_repo = "."
source_branch = "master"
worktree = "always"
hook = "dead.sh"'
o="$(lint_hr)"; assert_contains "$o" "not executable" "non-executable hook script flagged"

# valid: inline pipeline hook (not a file under scripts_dir) accepted as-is
mk_toml '[skills]
scripts_dir = ".loom/scripts"
[weft]
cleanup = "ask"
hook = "git status --porcelain | grep ."'
o="$(lint_hr)"; assert_not_contains "$o" "HOOK" "inline pipeline hook accepted"
rm -rf "$HR"

finish
