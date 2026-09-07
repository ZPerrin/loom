#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
HOOK="$DIR/../scripts/lint-hook"

# A repo with one managed doc that fails the linter, one that passes, a second failing doc,
# a markdown file without frontmatter, and a file that is not markdown.
R="$DIR/fixtures/lint-hook-repo"; rm -rf "$R"; mkdir -p "$R/docs"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-06\n---\n# Broken\n\nSee [gone](./gone.md).\n' > "$R/docs/broken.md"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-06\n---\n# Clean\n\nNothing links.\n' > "$R/docs/clean.md"
printf -- '---\nkind: readme\nstatus: living\nupdated: 2026-09-06\n---\n# Other\n\nSee [also gone](./also-gone.md).\n' > "$R/docs/other.md"
printf '# Plain\n\nNo frontmatter, [gone](./gone.md).\n' > "$R/docs/plain.md"
printf 'not markdown\n' > "$R/docs/notes.txt"
( cd "$R" && test_git_init && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: lint hook repo" )

# The harness payload for a Write, with the file under test; stdout and stderr captured together.
run_hook() { # $1=file_path value
  ( cd "$R" && printf '{"session_id":"s","hook_event_name":"PostToolUse","tool_name":"Write","cwd":"%s","tool_input":{"file_path":"%s","content":"x"},"tool_response":{"filePath":"%s"}}' "$R" "$1" "$1" | bash "$HOOK" 2>&1 )
}

out="$(run_hook "$R/docs/broken.md")"; rc=$?
assert_exit "$rc" "2" "hook-finding: a managed doc with a finding exits 2"
assert_contains "$out" "BROKEN" "hook-finding: the finding is returned"
assert_contains "$out" "docs/broken.md" "hook-finding: the finding names the doc"
assert_not_contains "$out" "docs/other.md" "hook-only-its-findings: another doc's finding is not returned"

out="$(run_hook "$R/docs/clean.md")"; rc=$?
assert_exit "$rc" "0" "hook-clean: a clean managed doc exits 0"
assert_eq "$out" "" "hook-clean: nothing is returned"

out="$(run_hook "$R/docs/plain.md")"; rc=$?
assert_exit "$rc" "0" "hook-unmanaged: markdown without kind frontmatter exits 0"
assert_eq "$out" "" "hook-unmanaged: nothing is returned"

out="$(run_hook "$R/docs/notes.txt")"; rc=$?
assert_exit "$rc" "0" "hook-unmanaged: a file that is not markdown exits 0"
assert_eq "$out" "" "hook-unmanaged: nothing is returned for it either"

out="$(run_hook "$R/docs/missing.md")"; rc=$?
assert_exit "$rc" "0" "hook-no-path: a path that does not exist exits 0"

out="$( ( cd "$R" && printf '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"ls"}}' | bash "$HOOK" 2>&1 ) )"; rc=$?
assert_exit "$rc" "0" "hook-no-path: a payload without a file path exits 0"
assert_eq "$out" "" "hook-no-path: nothing is returned"

out="$( ( cd "$R" && printf 'not json' | bash "$HOOK" 2>&1 ) )"; rc=$?
assert_exit "$rc" "0" "hook-no-path: a payload that is not JSON exits 0"

# A relative path is taken from the working directory.
out="$(run_hook "docs/broken.md")"; rc=$?
assert_exit "$rc" "2" "hook-relative: a relative path resolves from the working directory"

# A harness that passes the payload as the first argument instead of stdin gets the same answer.
out="$( ( cd "$R" && bash "$HOOK" "$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$R/docs/broken.md")" </dev/null 2>&1 ) )"; rc=$?
assert_exit "$rc" "2" "lint-argv: a payload in the first argument is read when stdin is empty"
assert_contains "$out" "docs/broken.md" "lint-argv: the finding names the doc"

# Codex's apply_patch names its files as patch headers; every managed doc it touches is linted.
out="$( ( cd "$R" && printf '{"tool_name":"apply_patch","tool_input":{"patch":"*** Begin Patch\\n*** Update File: docs/broken.md\\n@@\\n-a\\n+b\\n*** Add File: docs/notes.txt\\n+x\\n*** End Patch"}}' | bash "$HOOK" 2>&1 ) )"; rc=$?
assert_exit "$rc" "2" "lint-apply-patch: an apply_patch touching a managed doc with a finding exits 2"
assert_contains "$out" "docs/broken.md" "lint-apply-patch: the finding names the doc from the patch header"

# The file path is the first one in the payload; a path inside the content is not it.
out="$( ( cd "$R" && printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"{\\"file_path\\":\\"/nowhere.md\\"}"}}' "$R/docs/broken.md" | bash "$HOOK" 2>&1 ) )"; rc=$?
assert_exit "$rc" "2" "hook-first-path: the payload's first file path is the one linted"
assert_contains "$out" "docs/broken.md" "hook-first-path: the finding names that doc"

# An escaped slash in the path is undone.
esc="$(printf '%s' "$R/docs/broken.md" | sed 's#/#\\\\/#g')"
out="$( ( cd "$R" && printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$esc" | bash "$HOOK" 2>&1 ) )"; rc=$?
assert_exit "$rc" "2" "hook-relative: a JSON-escaped path resolves too"
rm -rf "$R"

finish
