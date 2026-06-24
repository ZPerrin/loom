#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
. "$DIR/../scripts/lib/discover.sh"
R="$DIR/fixtures/discover-repo"

# Fresh nested repo: stage the committed fixtures; add a NEW untracked managed doc
# and a gitignored managed doc at runtime to exercise --others / --exclude-standard.
rm -rf "$R/.git" "$R/untracked.md" "$R/ignored.md"
( cd "$R" && git init -q . && git add a.md b.md sub/c.md .gitignore )
printf -- '---\nkind: guide\nstatus: living\nupdated: 2026-06-23\n---\n# u\n\nNew, uncommitted.\n' > "$R/untracked.md"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-06-23\n---\n# i\n\nGitignored.\n' > "$R/ignored.md"

uni="$(doc_universe "$R")"
man="$(managed_docs "$R")"
cand="$(omission_candidates "$R")"
fld="$(frontmatter_field "$R/a.md" kind)"

assert_contains    "$uni"  "a.md"        "universe includes tracked managed doc"
assert_contains    "$uni"  "untracked.md" "universe includes untracked (--others) doc"
assert_not_contains "$uni" "ignored.md"  "universe excludes gitignored doc"

assert_contains    "$man"  "a.md"        "managed includes a.md"
assert_contains    "$man"  "sub/c.md"    "managed includes nested spec"
assert_contains    "$man"  "untracked.md" "managed includes untracked managed doc"
assert_not_contains "$man" "b.md"        "managed excludes frontmatter-less b.md"
assert_not_contains "$man" "ignored.md"  "managed excludes gitignored doc"

assert_contains    "$cand" "b.md"        "candidates include frontmatter-less doc"
assert_not_contains "$cand" "a.md"       "candidates exclude managed doc"

assert_eq          "$fld"  "readme"      "frontmatter_field reads kind"

rm -rf "$R/.git" "$R/untracked.md" "$R/ignored.md"
finish
