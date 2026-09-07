#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
GATE="$DIR/../scripts/skill-gate"

# A repo with a warp opinion holding a quote, a backslash, and a tab; a warp hook that echoes
# its argument; a weave hook that fails; and no weft or spec opinion or hook.
R="$DIR/fixtures/skill-gate-repo"; rm -rf "$R"; mkdir -p "$R/.loom/scripts" "$R/.loom/skills"
printf -- '---\nkind: loom-config\nstatus: living\nupdated: 2026-09-06\n---\n# Warp\n\n## Opening\n\nSay "hello" with a back\\slash and a\ttab.\n' > "$R/.loom/skills/warp.md"
printf '#!/usr/bin/env bash\necho "hello $1"\n' > "$R/.loom/scripts/hello.sh"; chmod +x "$R/.loom/scripts/hello.sh"
printf '#!/usr/bin/env bash\necho boom >&2\nexit 7\n' > "$R/.loom/scripts/fail.sh"; chmod +x "$R/.loom/scripts/fail.sh"
printf '[warp]\nbranch_convention = "feature/<slug>"\nsource_repo = "."\nworktree = "harness"\nhook = "hello.sh"\n[weave]\ncleanup = "ask"\nhook = "fail.sh"\n' > "$R/.loom/loom.toml"
( cd "$R" && test_git_init && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: skill gate repo" )

run_gate() { # $1=payload
  ( cd "$R" && printf '%s' "$1" | bash "$GATE" 2>&1 )
}
decode() { # stdin=gate output -> the additionalContext text, when python3 is present
  python3 -c 'import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])'
}
warp_payload="$(printf '{"session_id":"s","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Skill","tool_input":{"skill":"loom:warp","args":"issue 12"}}' "$R")"

out="$(run_gate "$warp_payload")"; rc=$?
assert_exit "$rc" "0" "gate-opinion: a loom skill with an opinion file exits 0"
assert_contains "$out" '"hookEventName":"PreToolUse"' "gate-opinion: the output is a PreToolUse hook result"
assert_contains "$out" 'Repo opinion for warp, from .loom/skills/warp.md, layered over the skill' "gate-opinion: the context names the skill and the file"
assert_contains "$out" 'Say \"hello\" with a back\\slash and a\ttab.' "gate-opinion: quote, backslash, and tab are JSON-escaped"
assert_contains "$out" '## Opening' "gate-opinion: the body is carried"
assert_not_contains "$out" 'kind: loom-config' "gate-opinion: the frontmatter is stripped"
assert_contains "$out" 'The warp hook ran at invocation and printed' "hook-ran: the hook's report follows the opinion"
assert_contains "$out" 'hello issue 12' "hook-ran: the hook received the invocation's text"
if command -v python3 >/dev/null 2>&1; then
  decoded="$(printf '%s' "$out" | decode)"
  assert_contains "$decoded" "$(printf 'Say "hello" with a back\\slash and a\ttab.')" "gate-opinion: the context decodes to the file's own line"
fi

# The operator typing the skill: a UserPromptSubmit payload whose prompt opens with /loom:<skill>
# or $loom:<skill>; an ordinary prompt gets nothing, on the fast path.
typed_payload="$(printf '{"session_id":"s","cwd":"%s","hook_event_name":"UserPromptSubmit","prompt":"/loom:warp issue 12\\nsecond line"}' "$R")"
out="$(run_gate "$typed_payload")"; rc=$?
assert_exit "$rc" "0" "gate-typed: a typed loom skill exits 0"
assert_contains "$out" '"hookEventName":"UserPromptSubmit"' "gate-typed: the output is a UserPromptSubmit hook result"
assert_contains "$out" 'Repo opinion for warp, from .loom/skills/warp.md' "gate-typed: the skill is taken from the prompt"
assert_contains "$out" 'hello issue 12 second line' "gate-typed: the prompt's remainder is the hook's argument, newlines as spaces"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"$loom:warp"}')"
assert_contains "$out" 'Repo opinion for warp' "gate-typed: the \$loom: spelling and a bare name are the skill too"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"please warp into issue 12"}')"; rc=$?
assert_exit "$rc" "0" "gate-typed: an ordinary prompt exits 0"
assert_eq "$out" "" "gate-typed: an ordinary prompt gets nothing"

# Codex spells a skill mention $<name>, anywhere in the prompt.
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"please $warp into issue 12"}')"; rc=$?
assert_exit "$rc" "0" "gate-mention: a \$warp mention exits 0"
assert_contains "$out" 'Repo opinion for warp' "gate-mention: the mention is the skill"
assert_contains "$out" 'hello please $warp into issue 12' "gate-mention: the whole prompt is the hook's argument"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"the $specific case"}')"
assert_eq "$out" "" "gate-mention: a longer word starting like a skill name is not a mention"

# Codex desktop's picker sends a Markdown skill link in the prompt. The fixture preserves
# the observed payload shape with session and machine paths replaced by test values.
out="$(run_gate "$(cat "$DIR/fixtures/hooks/codex-skill-mention.json")")"; rc=$?
assert_exit "$rc" "0" "gate-picker: a desktop skill link exits 0"
assert_contains "$out" '"hookEventName":"UserPromptSubmit"' "gate-picker: the result belongs to prompt submission"
assert_contains "$out" 'Repo opinion for warp' "gate-picker: the desktop picker receives the opinion"
assert_contains "$out" 'hello [$loom:warp](/plugin-cache/loom/0.2.0/skills/warp/SKILL.md) Codex desktop hook smoke test. Orient only and keep the current branch and workspace.' "gate-picker: the hook receives the whole invocation"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"please [$loom:warp](/plugin-cache/loom/skills/warp/SKILL.md) orient"}')"
assert_contains "$out" 'hello please [$loom:warp](/plugin-cache/loom/skills/warp/SKILL.md) orient' "gate-picker: a skill link can appear inside a prompt"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"[$warp](/plugin-cache/loom/skills/warp/SKILL.md) orient"}')"
assert_contains "$out" 'Repo opinion for warp' "gate-picker: an unqualified skill link is recognized too"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"[$other:warp](/plugin-cache/other/skills/warp/SKILL.md) orient"}')"
assert_eq "$out" "" "gate-picker-other: another plugin's skill link is ignored"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"[$loom:warped](/plugin-cache/loom/skills/warped/SKILL.md) orient"}')"
assert_eq "$out" "" "gate-picker-other: a longer skill name is not a match"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"[$loom:../warp](/plugin-cache/loom/skills/warp/SKILL.md) orient"}')"
assert_eq "$out" "" "gate-picker-other: an invalid skill name is ignored"

# A harness that passes the payload as the first argument instead of stdin gets the same answer.
out="$( ( cd "$R" && bash "$GATE" "$warp_payload" </dev/null 2>&1 ) )"; rc=$?
assert_exit "$rc" "0" "gate-argv: a payload in the first argument exits 0"
assert_contains "$out" 'Repo opinion for warp' "gate-argv: the payload is read from the argument when stdin is empty"

# A failing hook is reported, never fatal; weave has no opinion file here.
out="$(run_gate '{"tool_name":"Skill","tool_input":{"skill":"loom:weave","args":""}}')"; rc=$?
assert_exit "$rc" "0" "hook-failed: a failing hook still exits 0"
assert_contains "$out" 'The weave hook exited 7 at invocation' "hook-failed: the exit code is reported"
assert_contains "$out" 'boom' "hook-failed: what the hook printed is reported"
assert_not_contains "$out" 'Repo opinion' "hook-failed: no opinion file, no opinion"
if command -v python3 >/dev/null 2>&1; then
  decoded="$(printf '%s' "$out" | decode)"
  assert_contains "$decoded" "exited 7" "hook-failed: the report is valid JSON"
fi

out="$(run_gate '{"tool_name":"Skill","tool_input":{"skill":"loom:weft","args":""}}')"; rc=$?
assert_exit "$rc" "0" "gate-no-opinion: a loom skill without an opinion file or hook exits 0"
assert_eq "$out" "" "hook-unset: nothing is returned when neither exists"

out="$(run_gate '{"tool_name":"Skill","tool_input":{"skill":"anthropic-skills:pdf","args":""}}')"; rc=$?
assert_exit "$rc" "0" "gate-other-skill: another plugin's skill exits 0"
assert_eq "$out" "" "gate-other-skill: nothing is returned"

out="$(run_gate '{"tool_name":"Skill","tool_input":{"skill":"loom:../warp","args":""}}')"; rc=$?
assert_exit "$rc" "0" "gate-bad-name: a skill name that is not letters and hyphens exits 0"
assert_eq "$out" "" "gate-bad-name: nothing is returned"

out="$(run_gate '{"tool_name":"Bash","tool_input":{"command":"ls"}}')"; rc=$?
assert_exit "$rc" "0" "gate-no-payload: a payload naming no skill exits 0"
assert_eq "$out" "" "gate-no-payload: nothing is returned"

out="$(run_gate 'not json')"; rc=$?
assert_exit "$rc" "0" "gate-no-payload: a payload that is not JSON exits 0"
assert_eq "$out" "" "gate-no-payload: nothing is returned for it either"
rm -rf "$R"

finish
