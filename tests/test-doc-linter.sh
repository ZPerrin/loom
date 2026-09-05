#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
LINTER="$DIR/../scripts/doc-linter"

# Clean fixture: unified frontmatter, no links -> exit 0, reports clean.
rm -rf "$DIR/fixtures/repo-clean/.git"
out="$(cd "$DIR/fixtures/repo-clean" && test_git_init && git add -A && bash "$LINTER" 2>&1)"; rc=$?
assert_exit "$rc" "0" "clean fixture exits 0"
assert_contains "$out" "doc-linter: clean" "clean fixture reports clean"
rm -rf "$DIR/fixtures/repo-clean/.git"

# Dirty fixture: link + frontmatter findings, NO stamp tier.
rm -rf "$DIR/fixtures/repo-dirty/.git"
(cd "$DIR/fixtures/repo-dirty" && test_git_init && git add -A)
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

# --- Meta prose is editorial judgment, not a linter check ---
MR="$DIR/fixtures/meta-repo"
rm -rf "$MR"; mkdir -p "$MR/.loom"
( cd "$MR" && test_git_init )
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-07-01\n---\n# Docs\n\nThe doc convention ships with the plugin.\nA fine sentence about the actual project.\n' > "$MR/README.md"
printf '[lint]\nkinds = ["readme", "loom-config"]\nstatuses = ["living"]\n' > "$MR/.loom/loom.toml"
mo="$(cd "$MR" && bash "$LINTER" 2>&1)"; mrc=$?
assert_exit "$mrc" "0" "meta-like prose is not linted"
assert_contains "$mo" "doc-linter: clean" "meta-like prose reports clean"

rm -rf "$MR"

# --- lint vocab and discovery exclusions are config-driven ---
LR="$DIR/fixtures/lint-config-repo"
rm -rf "$LR"; mkdir -p "$LR/.loom" "$LR/docs/archive"
( cd "$LR" && test_git_init )
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-07-01\n---\n# Home\n' > "$LR/README.md"
printf -- '---\nkind: playbook\nstatus: frozen\nupdated: 2026-07-01\n---\n# Runbook\n' > "$LR/docs/playbook.md"
printf -- '---\nkind: nope\nstatus: bogus\nupdated: nope\n---\n# Ignored\n' > "$LR/docs/archive/ignored.md"

printf '[discovery]\nexclude = ["docs/archive"]\n[lint]\nkinds = ["readme", "playbook"]\nstatuses = ["living", "frozen"]\n' > "$LR/.loom/loom.toml"
lo="$(cd "$LR" && bash "$LINTER" 2>&1)"; lrc=$?
assert_exit "$lrc" "0" "configured lint vocab and discovery exclude: clean exit"
assert_contains "$lo" "doc-linter: clean" "configured lint vocab reports clean"

printf '[discovery]\nexclude = ["docs/archive"]\n[lint]\nkinds = ["readme"]\nstatuses = ["living", "frozen"]\n' > "$LR/.loom/loom.toml"
lo="$(cd "$LR" && bash "$LINTER" 2>&1)"; lrc=$?
assert_exit "$lrc" "1" "kind outside configured vocab: exit 1"
assert_contains "$lo" "kind=playbook not allowed" "configured kinds are enforced"
assert_not_contains "$lo" "ignored.md" "discovery exclude removes docs from lint findings"

printf '[discovery]\nexclude = ["docs/archive"]\n[lint]\nkinds = ["readme", "playbook"]\nstatuses = ["living"]\n' > "$LR/.loom/loom.toml"
lo="$(cd "$LR" && bash "$LINTER" 2>&1)"; lrc=$?
assert_exit "$lrc" "1" "status outside configured vocab: exit 1"
assert_contains "$lo" "status=frozen not allowed" "configured statuses are enforced"

rm -f "$LR/docs/playbook.md"
printf '[discovery]\nexclude = ["docs/archive"]\n' > "$LR/.loom/loom.toml"
lo="$(cd "$LR" && bash "$LINTER" 2>&1)"; lrc=$?
assert_exit "$lrc" "1" "loom.toml without lint vocab: exit 1"
assert_contains "$lo" "[lint] missing kinds" "missing lint kinds is explicit"
assert_contains "$lo" "[lint] missing statuses" "missing lint statuses is explicit"
assert_not_contains "$lo" "kind=readme not allowed" "missing lint vocab falls back to shipped kind defaults"
assert_not_contains "$lo" "status=living not allowed" "missing lint vocab falls back to shipped status defaults"

rm -rf "$LR"

# --- [warp] section validation (control-plane config enforcement) ---
# Optional section; when present, the linter requires the core knobs, valid.
WR="$DIR/fixtures/warp-repo"
rm -rf "$WR"; mkdir -p "$WR/.loom"
( cd "$WR" && test_git_init )

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

# --- [weave] section validation (control-plane config enforcement) ---
# Single optional knob; when [weave] is present, the linter requires cleanup, valid.
WV="$DIR/fixtures/weave-repo"
rm -rf "$WV"; mkdir -p "$WV/.loom"
( cd "$WV" && test_git_init )

# Absent -> no WEAVE finding, clean exit.
printf '[lint]\nkinds = ["readme"]\nstatuses = ["living"]\n' > "$WV/.loom/loom.toml"
fo="$(cd "$WV" && bash "$LINTER" 2>&1)"; frc=$?
assert_not_contains "$fo" "WEAVE" "[weave] absent: no weave finding"
assert_exit "$frc" "0" "[weave] absent: clean exit"

# Present + valid -> no WEAVE finding.
printf '[weave]\ncleanup = "always"\n' > "$WV/.loom/loom.toml"
fo="$(cd "$WV" && bash "$LINTER" 2>&1)"
assert_not_contains "$fo" "WEAVE" "valid [weave]: no weave finding"

# Present but empty (cleanup missing) -> finding naming it, exit 1.
printf '[weave]\n' > "$WV/.loom/loom.toml"
fo="$(cd "$WV" && bash "$LINTER" 2>&1)"; frc=$?
assert_exit "$frc" "1" "[weave] missing knob: exit 1"
assert_contains "$fo" "WEAVE"   "[weave] missing cleanup: weave finding"
assert_contains "$fo" "cleanup" "[weave] names the missing cleanup knob"

# Invalid cleanup value -> finding naming the bad value.
printf '[weave]\ncleanup = "sometimes"\n' > "$WV/.loom/loom.toml"
fo="$(cd "$WV" && bash "$LINTER" 2>&1)"
assert_contains "$fo" "sometimes" "[weave] invalid cleanup value flagged"

rm -rf "$WV"

# --- executable-hooks config validation ---
HR="$DIR/fixtures/hook-lint"; rm -rf "$HR"; mkdir -p "$HR/.loom/scripts"
mk_toml() { printf '%s\n' "$1" > "$HR/.loom/loom.toml"; }
lint_hr() { (cd "$HR" && rm -rf .git && test_git_init && git add -A 2>/dev/null; bash "$LINTER" 2>&1); }

# valid: warp with source_repo/branch + worktree=harness + a hook naming an executable script
printf '#!/usr/bin/env bash\necho hi\n' > "$HR/.loom/scripts/warp.sh"; chmod +x "$HR/.loom/scripts/warp.sh"
mk_toml '[skills]
scripts_dir = ".loom/scripts"
[warp]
branch_convention = "feature/<slug>"
source_repo = "."
source_branch = "master"
worktree = "harness"
hook = "warp.sh"'
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
printf 'echo hi\n' > "$HR/.loom/scripts/warp.sh"; chmod -x "$HR/.loom/scripts/warp.sh"
mk_toml '[skills]
scripts_dir = ".loom/scripts"
[warp]
branch_convention = "feature/<slug>"
source_repo = "."
source_branch = "master"
worktree = "always"
hook = "warp.sh"'
if [ -x "$HR/.loom/scripts/warp.sh" ]; then
  o="$(lint_hr)"
  assert_not_contains "$o" "not executable" "non-executable hook skipped when chmod -x is not observable"
else
  o="$(lint_hr)"
  assert_contains "$o" "not executable" "non-executable hook script flagged"
fi

# valid: inline pipeline hook (not a file under scripts_dir) accepted as-is
mk_toml '[skills]
scripts_dir = ".loom/scripts"
[weave]
cleanup = "ask"
hook = "git status --porcelain | grep ."'
o="$(lint_hr)"; assert_not_contains "$o" "HOOK" "inline pipeline hook accepted"

# valid: [specs]/[plans] location overrides as relative in-repo paths (need not exist yet)
mk_toml '[specs]
repo_dir = "documentation/specs"
work_dir = ".loom/work"
[plans]
dir = ".loom/plans"'
o="$(lint_hr)"; assert_not_contains "$o" "LAYOUT" "relative location overrides accepted"

# invalid: absolute or parent-escaping locations
mk_toml '[specs]
repo_dir = "/srv/specs"
work_dir = "../shared/specs"
[plans]
dir = ".loom/../../plans"'
o="$(lint_hr)"; orc=$?
assert_exit "$orc" "1" "bad location overrides fail the lint"
assert_contains "$o" "LAYOUT   .loom/loom.toml: [specs] repo_dir=/srv/specs" "absolute repo_dir flagged"
assert_contains "$o" "[specs] work_dir=../shared/specs"                      "parent-escaping work_dir flagged"
assert_contains "$o" "[plans] dir=.loom/../../plans"                         "embedded .. in plans dir flagged"
rm -rf "$HR"

finish
