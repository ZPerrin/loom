#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
. "$DIR/../scripts/lib/discover.sh"
R="$DIR/fixtures/discover-repo"

# Fresh nested repo: stage the committed fixtures; add a NEW untracked managed doc
# and a gitignored managed doc at runtime to exercise --others / --exclude-standard,
# plus a CLAUDE.md-style symlink whose target is already in the universe.
rm -rf "$R/.git" "$R/untracked.md" "$R/ignored.md" "$R/link.md"
( cd "$R" && test_git_init && git add a.md b.md sub/c.md .gitignore )
printf -- '---\nkind: guide\nstatus: living\nupdated: 2026-06-23\n---\n# u\n\nNew, uncommitted.\n' > "$R/untracked.md"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-06-23\n---\n# i\n\nGitignored.\n' > "$R/ignored.md"
ln -s a.md "$R/link.md"

uni="$(doc_universe "$R")"
man="$(managed_docs "$R")"
cand="$(omission_candidates "$R")"
fld="$(frontmatter_field "$R/a.md" kind)"

assert_contains    "$uni"  "a.md"        "universe includes tracked managed doc"
assert_contains    "$uni"  "untracked.md" "universe includes untracked (--others) doc"
assert_not_contains "$uni" "ignored.md"  "universe excludes gitignored doc"
assert_not_contains "$uni" "link.md"     "universe skips symlinked doc (target is the doc)"

assert_contains    "$man"  "a.md"        "managed includes a.md"
assert_contains    "$man"  "sub/c.md"    "managed includes nested spec"
assert_contains    "$man"  "untracked.md" "managed includes untracked managed doc"
assert_not_contains "$man" "b.md"        "managed excludes frontmatter-less b.md"
assert_not_contains "$man" "ignored.md"  "managed excludes gitignored doc"

assert_contains    "$cand" "b.md"        "candidates include frontmatter-less doc"
assert_not_contains "$cand" "a.md"       "candidates exclude managed doc"

assert_eq          "$fld"  "readme"      "frontmatter_field reads kind"

rm -rf "$R/.git" "$R/untracked.md" "$R/ignored.md" "$R/link.md"

# Exclusion: a [discovery] exclude prefix removes matching paths from the universe.
rm -rf "$R/.git" "$R/.loom"
mkdir -p "$R/.loom"
printf '[discovery]\nexclude = ["sub"]\n' > "$R/.loom/loom.toml"
( cd "$R" && test_git_init && git add a.md b.md sub/c.md .gitignore .loom/loom.toml )
xman="$(managed_docs "$R")"
assert_not_contains "$xman" "sub/c.md" "excluded prefix drops sub/c.md from managed set"
assert_contains    "$xman" "a.md"     "non-excluded managed doc still present"
rm -rf "$R/.git" "$R/.loom"

# no-partial-effect: a config the parser refuses yields no excludes at all. The exclude sits
# above the unparseable line, so a read that stopped at the error and kept what it had would
# drop sub/c.md; refusing the file whole keeps the whole universe.
rm -rf "$R/.git" "$R/.loom"
mkdir -p "$R/.loom"
printf '[discovery]\nexclude = ["sub"]\n\n[lint]\nbad = { inline = "table" }\n' > "$R/.loom/loom.toml"
( cd "$R" && test_git_init && git add a.md b.md sub/c.md .gitignore .loom/loom.toml )
assert_eq "$(doc_excludes "$R")" "" "no-partial-effect: a refused config yields no exclude prefixes"
bman="$(managed_docs "$R")"
assert_contains "$bman" "sub/c.md" "no-partial-effect: the exclude above the bad line does not take effect"
assert_contains "$bman" "a.md"     "no-partial-effect: the rest of the repo is still discovered"
rm -rf "$R/.git" "$R/.loom"

# no-git-fallback: outside a git checkout the universe comes from a bounded find. The probe
# directory sits inside loom's own worktree, so GIT_CEILING_DIRECTORIES stops git's upward
# search at tests/fixtures and makes it genuinely not-a-checkout.
NG="$DIR/fixtures/nogit-dir"; rm -rf "$NG"; mkdir -p "$NG/sub"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-06\n---\n# n\n' > "$NG/n.md"
printf -- '---\nkind: spec\nstatus: living\nupdated: 2026-09-06\n---\n# d\n' > "$NG/sub/d.md"
export GIT_CEILING_DIRECTORIES="$DIR/fixtures"
if git -C "$NG" rev-parse --git-dir >/dev/null 2>&1; then is_repo=yes; else is_repo=no; fi
nguni="$(doc_universe "$NG")"
ngman="$(managed_docs "$NG")"
unset GIT_CEILING_DIRECTORIES
assert_eq "$is_repo" "no" "no-git-fallback: the probe directory is not a git checkout"
assert_contains "$nguni" "n.md"     "no-git-fallback: top-level markdown is still found"
assert_contains "$nguni" "sub/d.md" "no-git-fallback: nested markdown is still found"
assert_contains "$ngman" "sub/d.md" "no-git-fallback: the found files still classify as managed"
rm -rf "$NG"

finish
