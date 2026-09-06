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
assert_contains "$dout" "outside .loom/" "flags loom-config in the wrong directory"
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
assert_exit "$lrc" "0" "loom.toml without lint vocab: exit 0, the shipped vocabulary applies"
assert_not_contains "$lo" "[lint] missing" "an absent [lint] section is not a finding"
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
printf '[warp]\nbranch_convention = "zeb/<slug>"\nworktree = "never"\nsource_repo = "."\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"
assert_not_contains "$wo" "WARP" "valid [warp]: no warp finding"

# Missing worktree knob -> finding naming it, exit 1.
printf '[warp]\nbranch_convention = "x"\nsource_repo = "."\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"; wrc=$?
assert_exit "$wrc" "1" "[warp] missing knob: exit 1"
assert_contains "$wo" "WARP"     "[warp] missing worktree: warp finding"
assert_contains "$wo" "worktree" "[warp] names the missing worktree knob"

# Present but empty -> findings naming every required knob, exit 1 (as [weave] already does).
printf '[warp]\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"; wrc=$?
assert_exit "$wrc" "1" "[warp] empty-warp section: exit 1"
assert_contains "$wo" "branch_convention" "[warp] empty-warp: names branch_convention"
assert_contains "$wo" "source_repo"       "[warp] empty-warp: names source_repo"
assert_contains "$wo" "worktree"          "[warp] empty-warp: names worktree"

# Invalid worktree value -> finding naming the bad value.
printf '[warp]\nbranch_convention = "x"\nworktree = "sometimes"\nsource_repo = "."\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"
assert_contains "$wo" "sometimes" "[warp] invalid worktree value flagged"

# Missing branch_convention -> finding.
printf '[warp]\nworktree = "ask"\nsource_repo = "."\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"
assert_contains "$wo" "branch_convention" "[warp] missing branch_convention: finding"

# Missing source_repo -> finding.
printf '[warp]\nbranch_convention = "x"\nworktree = "ask"\n' > "$WR/.loom/loom.toml"
wo="$(cd "$WR" && bash "$LINTER" 2>&1)"
assert_contains "$wo" "source_repo" "[warp] missing source_repo: finding"

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

# rsi is the section's optional knob: absent is fine, a value outside the set is not.
printf '[weave]\ncleanup = "always"\n' > "$WV/.loom/loom.toml"
fo="$(cd "$WV" && bash "$LINTER" 2>&1)"
assert_not_contains "$fo" "rsi" "[weave] absent rsi: no finding (on by default when unset)"

printf '[weave]\ncleanup = "always"\nrsi = "sometimes"\n' > "$WV/.loom/loom.toml"
fo="$(cd "$WV" && bash "$LINTER" 2>&1)"; frc=$?
assert_exit "$frc" "1" "[weave] invalid rsi: exit 1"
assert_contains "$fo" "WEAVE"         "[weave] invalid rsi: weave finding"
assert_contains "$fo" "rsi=sometimes" "[weave] invalid rsi value flagged"

rm -rf "$WV"

# --- executable-hooks config validation ---
HR="$DIR/fixtures/hook-lint"; rm -rf "$HR"; mkdir -p "$HR/.loom/scripts"
mk_toml() { printf '%s\n' "$1" > "$HR/.loom/loom.toml"; }
lint_hr() { (cd "$HR" && rm -rf .git && test_git_init && git add -A 2>/dev/null; bash "$LINTER" 2>&1); }

# valid: warp with source_repo + worktree=harness + a hook naming an executable script
printf '#!/usr/bin/env bash\necho hi\n' > "$HR/.loom/scripts/warp.sh"; chmod +x "$HR/.loom/scripts/warp.sh"
mk_toml '[skills]
scripts_dir = ".loom/scripts"
[warp]
branch_convention = "feature/<slug>"
source_repo = "."
worktree = "harness"
hook = "warp.sh"'
o="$(lint_hr)"; assert_not_contains "$o" "WARP" "valid warp+hook config: no WARP finding"

# invalid: worktree=bogus
mk_toml '[warp]
branch_convention = "feature/<slug>"
source_repo = "."
worktree = "bogus"'
o="$(lint_hr)"; assert_contains "$o" "worktree=bogus" "invalid worktree value flagged"

# invalid: hook names a script that exists but is NOT executable
printf 'echo hi\n' > "$HR/.loom/scripts/warp.sh"; chmod -x "$HR/.loom/scripts/warp.sh"
mk_toml '[skills]
scripts_dir = ".loom/scripts"
[warp]
branch_convention = "feature/<slug>"
source_repo = "."
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

# --- no config at all: the shipped vocabulary is what documents are checked against ---
# Two shapes of "no config": no .loom directory (noconf-repo), and a .loom directory that
# holds no loom.toml (no-loom-toml). Neither is a LINT finding — loom demands no
# configuration to run — and under both, kind and status are checked against the lists
# doc-linter ships with, so the vocabulary still bites.
NCR="$DIR/fixtures/noconf-repo"; rm -rf "$NCR"; mkdir -p "$NCR/docs"
( cd "$NCR" && test_git_init )
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-06\n---\n# Home\n' > "$NCR/README.md"
nco="$(cd "$NCR" && bash "$LINTER" 2>&1)"; ncrc=$?
assert_exit "$ncrc" "0" "noconf-repo: a repo with no .loom directory exits 0"
assert_contains "$nco" "doc-linter: clean" "noconf-repo: the shipped vocabulary accepts readme/living"
assert_not_contains "$nco" "LINT" "noconf-repo: an absent config is never a LINT finding"

printf -- '---\nkind: bogus\nstatus: living\nupdated: 2026-09-06\n---\n# Odd\n' > "$NCR/docs/odd.md"
nco="$(cd "$NCR" && bash "$LINTER" 2>&1)"; ncrc=$?
assert_exit "$ncrc" "1" "noconf-repo: a kind outside the shipped list still exits 1"
assert_contains "$nco" "kind=bogus not allowed" "noconf-repo: documents are checked against the shipped kinds"
assert_not_contains "$nco" "LINT" "noconf-repo: still no LINT finding without a config"
rm -f "$NCR/docs/odd.md"

# no-loom-toml: the .loom directory exists and the config file does not — same defaults.
mkdir -p "$NCR/.loom"
printf -- '---\nkind: loom-config\nstatus: living\nupdated: 2026-09-06\n---\n# weave notes\n' > "$NCR/.loom/weave.md"
nlo="$(cd "$NCR" && bash "$LINTER" 2>&1)"; nlrc=$?
assert_exit "$nlrc" "0" "no-loom-toml: a .loom directory without loom.toml exits 0"
assert_contains "$nlo" "doc-linter: clean" "no-loom-toml: values check clean against the shipped lists"
assert_not_contains "$nlo" "LINT" "no-loom-toml: a missing loom.toml is not a LINT finding"
rm -rf "$NCR"

# --- gate-refuses: an unparseable loom.toml stops the lint before it starts ---
# A broken config is refused whole, not applied as far as it parsed: the linter names the
# file and exits 2, and the BROKEN link this repo carries is never reported.
GR="$DIR/fixtures/gate-refuses-repo"; rm -rf "$GR"; mkdir -p "$GR/.loom"
( cd "$GR" && test_git_init )
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-06\n---\n# Home\n\n[gone](nope/missing.md)\n' > "$GR/README.md"
printf '[lint]\nkinds = ["readme"]\nstatuses = ["living"]\nbad = { inline = "table" }\n' > "$GR/.loom/loom.toml"
gro="$(cd "$GR" && bash "$LINTER" 2>&1)"; grrc=$?
assert_exit "$grrc" "2" "gate-refuses: an unparseable config exits 2"
assert_contains "$gro" "loom.toml" "gate-refuses: the bad file is named"
assert_not_contains "$gro" "BROKEN" "gate-refuses: nothing is linted"
assert_not_contains "$gro" "clean"  "gate-refuses: no verdict is printed"
rm -rf "$GR"

# --- skipped-links: external, fragment-only, and fenced links are not link findings ---
SL="$DIR/fixtures/skipped-links-repo"; rm -rf "$SL"; mkdir -p "$SL/.loom"
( cd "$SL" && test_git_init )
printf '[lint]\nkinds = ["readme"]\nstatuses = ["living"]\n' > "$SL/.loom/loom.toml"
{ printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-06\n---\n'
  printf '# Home\n\n'
  printf 'An [external link](https://example.invalid/nope.md) and a [fragment link](#home).\n\n'
  printf '```\n[fenced link](nope/missing.md)\n```\n'
} > "$SL/README.md"
slo="$(cd "$SL" && bash "$LINTER" 2>&1)"; slrc=$?
assert_exit "$slrc" "0" "skipped-links: none of the three links is a finding"
assert_contains "$slo" "doc-linter: clean" "skipped-links: the repo reports clean"
assert_not_contains "$slo" "BROKEN" "skipped-links: no BROKEN finding at all"
assert_not_contains "$slo" "nope/missing.md" "skipped-links: the link inside the fence is not resolved"
assert_not_contains "$slo" "example.invalid" "skipped-links: the external link is not resolved"
rm -rf "$SL"

# --- bad-date: an updated value that is not YYYY-MM-DD is named ---
BD="$DIR/fixtures/bad-date-repo"; rm -rf "$BD"; mkdir -p "$BD/.loom"
( cd "$BD" && test_git_init )
printf '[lint]\nkinds = ["readme"]\nstatuses = ["living"]\n' > "$BD/.loom/loom.toml"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-9-6\n---\n# Home\n' > "$BD/README.md"
bdo="$(cd "$BD" && bash "$LINTER" 2>&1)"; bdrc=$?
assert_exit "$bdrc" "1" "bad-date: a non-ISO updated value exits 1"
assert_contains "$bdo" "FRONTMATTER"      "bad-date: reports FRONTMATTER"
assert_contains "$bdo" "updated=2026-9-6" "bad-date: names the offending value"
rm -rf "$BD"

# --- links-mode / links-missing-file: --links runs the link checks alone ---
# No frontmatter is required, so dress can preview a repo's link findings before adoption.
LM="$DIR/fixtures/links-mode-repo"; rm -rf "$LM"; mkdir -p "$LM"
( cd "$LM" && test_git_init )
printf '# Draft\n\n[gone](nope/missing.md)\n' > "$LM/draft.md"
printf '# Fine\n\n[the draft](draft.md)\n' > "$LM/fine.md"
lmo="$(cd "$LM" && bash "$LINTER" --links draft.md 2>&1)"; lmrc=$?
assert_exit "$lmrc" "1" "links-mode: a broken link in an unstamped file exits 1"
assert_contains "$lmo" "BROKEN"          "links-mode: reports BROKEN for the link"
assert_contains "$lmo" "nope/missing.md" "links-mode: names the missing href"
assert_not_contains "$lmo" "FRONTMATTER" "links-mode: frontmatter is neither required nor checked"
lmo="$(cd "$LM" && bash "$LINTER" --links fine.md 2>&1)"; lmrc=$?
assert_exit "$lmrc" "0" "links-mode: a run with no link finding exits 0"
assert_contains "$lmo" "doc-linter --links: clean" "links-mode: a clean run says so in its own words"

lfo="$(cd "$LM" && bash "$LINTER" --links no/such/file.md 2>&1)"; lfrc=$?
assert_exit "$lfrc" "1" "links-missing-file: a path that does not exist exits 1"
assert_contains "$lfo" "INPUT"            "links-missing-file: reports INPUT"
assert_contains "$lfo" "no/such/file.md"  "links-missing-file: names the path"
rm -rf "$LM"

finish
