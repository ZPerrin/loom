#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
AWK="$DIR/../scripts/lib/parse-toml.awk"
F="$DIR/fixtures/parse"

out="$(awk -f "$AWK" "$F/sample.toml")"
assert_contains "$out" "modules.dirs=backend"            "array element 1"
assert_contains "$out" "modules.dirs=frontend"           "array element 2"
assert_contains "$out" "modules.dirs=cdk"                "array element 3"
assert_contains "$out" "context.recent_commits=15"       "scalar int"
assert_contains "$out" "context.include_modules=true"    "scalar bool"
assert_contains "$out" "context.sections=docs/config/roadmap.md > ## Now" "array w/ spaces"
assert_contains "$out" "lint.kinds=roadmap"              "lint array 1"
assert_contains "$out" "lint.kinds=readme"               "lint array 2"
assert_not_contains "$out" "# a comment"                 "comment stripped"

awk -f "$AWK" "$F/aot.toml" >/dev/null 2>&1
assert_exit "$?" "2" "array-of-tables rejected with exit 2"

# Fix 1 regression: trailing comments (outside quotes) must be stripped;
# ## inside a quoted value must be preserved.
cout="$(awk -f "$AWK" "$F/comments.toml" 2>&1)"; crc=$?
assert_exit "$crc" "0" "trailing-comment toml exits 0 (not 2)"
assert_contains "$cout" "lint.kinds=readme"              "trailing-comment: readme kind"
assert_contains "$cout" "lint.kinds=guide"               "trailing-comment: guide kind"
assert_contains "$cout" "context.sections=docs/config/roadmap.md > ## Now" "trailing-comment: ## inside quotes preserved"

finish
