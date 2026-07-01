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
( cd "$R" && git init -q . && git add a.md b.md sub/c.md .gitignore )
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
( cd "$R" && git init -q . && git add a.md b.md sub/c.md .gitignore .loom/loom.toml )
xman="$(managed_docs "$R")"
assert_not_contains "$xman" "sub/c.md" "excluded prefix drops sub/c.md from managed set"
assert_contains    "$xman" "a.md"     "non-excluded managed doc still present"
rm -rf "$R/.git" "$R/.loom"

finish
