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

qc="$(awk -f "$AWK" "$F/quoted-comma.toml" 2>&1)"; qrc=$?
assert_exit "$qrc" "0" "quoted-comma.toml exits 0"
assert_contains "$qc" "context.sections=a, b" "quoted-comma: a comma inside a quoted element stays in it"
assert_contains "$qc" "context.sections=c"    "quoted-comma: the next element still arrives on its own"
assert_not_contains "$qc" "sections=\"a"       "quoted-comma: no half-quoted fragment is emitted"

ml="$(awk -f "$AWK" "$F/multiline.toml" 2>&1)"; mrc=$?
assert_exit "$mrc" "2" "multiline.toml: multiline array rejected with exit 2"
assert_contains "$ml" "multiline array" "multiline.toml: the refusal names the construct"
il="$(awk -f "$AWK" "$F/inline.toml" 2>&1)"; irc=$?
assert_exit "$irc" "2" "inline.toml: inline table rejected with exit 2"
assert_contains "$il" "inline table" "inline.toml: the refusal names the construct"

awk -f "$AWK" "$F/aot.toml" >/dev/null 2>&1
assert_exit "$?" "2" "array-of-tables rejected with exit 2"

# Fix 1 regression: trailing comments (outside quotes) must be stripped;
# ## inside a quoted value must be preserved.
cout="$(awk -f "$AWK" "$F/comments.toml" 2>&1)"; crc=$?
assert_exit "$crc" "0" "trailing-comment toml exits 0 (not 2)"
assert_contains "$cout" "lint.kinds=readme"              "trailing-comment: readme kind"
assert_contains "$cout" "lint.kinds=guide"               "trailing-comment: guide kind"
assert_contains "$cout" "context.sections=docs/config/roadmap.md > ## Now" "trailing-comment: ## inside quotes preserved"

CRLF="$F/crlf.toml"
printf '[discovery]\r\nexclude = ["tests/fixtures", "skills"]\r\n' > "$CRLF"
crlf_out="$(awk -f "$AWK" "$CRLF" 2>&1)"; crlf_rc=$?
assert_exit "$crlf_rc" "0" "crlf toml exits 0"
assert_contains "$crlf_out" "discovery.exclude=tests/fixtures" "crlf toml array element 1"
assert_contains "$crlf_out" "discovery.exclude=skills" "crlf toml array element 2"
rm -f "$CRLF"

finish
