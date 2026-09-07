#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
GATE="$DIR/../scripts/skill-gate"
HOOK="$DIR/../scripts/skill-hook"

# A repo with a warp opinion holding a quote, a backslash, and a tab; a warp hook that prints;
# a weave hook that fails; a dress hook that exits 0 saying nothing; a spec hook
# found by name with no key; and no weft opinion or hook.
R="$DIR/fixtures/skill-gate-repo"; rm -rf "$R"; mkdir -p "$R/.loom/scripts" "$R/.loom/skills"
printf -- '---\nkind: loom-config\nstatus: living\nupdated: 2026-09-06\n---\n# Warp\n\n## Opening\n\nSay "hello" with a back\\slash and a\ttab.\n' > "$R/.loom/skills/warp.md"
printf '#!/usr/bin/env bash\necho hello\n' > "$R/.loom/scripts/hello.sh"; chmod +x "$R/.loom/scripts/hello.sh"
printf '#!/usr/bin/env bash\necho boom >&2\nexit 7\n' > "$R/.loom/scripts/fail.sh"; chmod +x "$R/.loom/scripts/fail.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$R/.loom/scripts/quiet.sh"; chmod +x "$R/.loom/scripts/quiet.sh"
printf '#!/usr/bin/env bash\necho spec by name\n' > "$R/.loom/scripts/spec"; chmod +x "$R/.loom/scripts/spec"
printf '[warp]\nbranch_convention = "feature/<slug>"\nsource_repo = "."\nworktree = "harness"\nhook = "hello.sh"\n[weave]\ncleanup = "ask"\nhook = "fail.sh"\n[dress]\nhook = "quiet.sh"\n' > "$R/.loom/loom.toml"
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
assert_contains "$out" 'and printed:\n\nhello' "hook-ran: what it printed follows"
assert_contains "$out" '"additionalContext":"loom gate: warp\nopinion: read .loom/skills/warp.md\nhook: ran hello.sh, exit 0\n\nRepo opinion' "receipt-found: the receipt is the skill, the opinion read, and the hook run with its exit, and none of the invocation's text"
assert_eq "$( (cd "$R" && bash "$HOOK" --name warp) )" "hello.sh" "receipt-found: skill-hook --name resolves the key"
if command -v python3 >/dev/null 2>&1; then
  decoded="$(printf '%s' "$out" | decode)"
  assert_contains "$decoded" "$(printf 'Say "hello" with a back\\slash and a\ttab.')" "gate-opinion: the context decodes to the file's own line"
  assert_eq "$(printf '%s\n' "$decoded" | head -n 1)" "loom gate: warp" "receipt-found: the receipt is the first line of the context"
fi

# The operator typing the skill: a UserPromptSubmit payload whose prompt opens with /loom:<skill>
# or $loom:<skill>; an ordinary prompt gets nothing, on the fast path.
typed_payload="$(printf '{"session_id":"s","cwd":"%s","hook_event_name":"UserPromptSubmit","prompt":"/loom:warp issue 12\\nsecond line"}' "$R")"
out="$(run_gate "$typed_payload")"; rc=$?
assert_exit "$rc" "0" "gate-typed: a typed loom skill exits 0"
assert_contains "$out" '"hookEventName":"UserPromptSubmit"' "gate-typed: the output is a UserPromptSubmit hook result"
assert_contains "$out" 'Repo opinion for warp, from .loom/skills/warp.md' "gate-typed: the skill is taken from the prompt"
assert_contains "$out" 'hook: ran hello.sh, exit 0' "gate-typed: the hook runs for a typed skill"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"/loom:warp fix the \"auth\" bug"}')"
assert_contains "$out" 'Repo opinion for warp' "gate-typed: a quote later in the prompt changes nothing"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"$loom:warp"}')"
assert_contains "$out" 'Repo opinion for warp' "gate-typed: the \$loom: spelling and a bare name are the skill too"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"/warp orient only"}')"
assert_contains "$out" 'loom gate: warp\nopinion: read .loom/skills/warp.md\nhook: ran hello.sh, exit 0' "receipt-bare-name: a typed /warp the host resolved gets the receipt too"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"/simplify the diff"}')"
assert_eq "$out" "" "receipt-bare-name: a typed command that is not a loom skill gets nothing"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"/other:warp orient"}')"
assert_eq "$out" "" "receipt-bare-name: another plugin's typed warp gets nothing"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"please warp into issue 12"}')"; rc=$?
assert_exit "$rc" "0" "gate-typed: an ordinary prompt exits 0"
assert_eq "$out" "" "gate-typed: an ordinary prompt gets nothing"

# Codex spells a skill mention $<name>, anywhere in the prompt.
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"please $warp into issue 12"}')"; rc=$?
assert_exit "$rc" "0" "gate-mention: a \$warp mention exits 0"
assert_contains "$out" 'Repo opinion for warp' "gate-mention: the mention is the skill"
assert_contains "$out" 'hook: ran hello.sh, exit 0' "gate-mention: the hook runs for a mention"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"please $warp"}')"
assert_contains "$out" 'Repo opinion for warp' "gate-mention: a mention that ends the prompt is the skill"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"the $specific case"}')"
assert_eq "$out" "" "gate-mention: a longer word starting like a skill name is not a mention"

# R-HOOKS-012: native Codex inline namespaced mention, anonymized from route R17.
out="$(run_gate "$(cat "$DIR/fixtures/hooks/codex-inline-namespaced-mention.json")")"
assert_contains "$out" 'loom gate: warp\nopinion: read .loom/skills/warp.md\nhook: ran hello.sh, exit 0' "receipt-inline-namespaced: the native inline namespaced mention gets the full receipt"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"please $loom:warp"}')"
assert_contains "$out" 'loom gate: warp' "receipt-inline-namespaced: the mention may end the prompt"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"please $loom:warp\norient"}')"
assert_contains "$out" 'loom gate: warp' "receipt-inline-namespaced: an escaped newline ends the name"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"please $loom:warped orient"}')"
assert_eq "$out" "" "receipt-inline-namespaced: a longer name is ignored"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"please $other:warp orient"}')"
assert_eq "$out" "" "receipt-inline-namespaced: another namespace is ignored"

# Codex desktop's picker sends a Markdown skill link in the prompt. The fixture preserves
# the observed payload shape with session and machine paths replaced by test values.
out="$(run_gate "$(cat "$DIR/fixtures/hooks/codex-skill-mention.json")")"; rc=$?
assert_exit "$rc" "0" "gate-picker: a desktop skill link exits 0"
assert_contains "$out" '"hookEventName":"UserPromptSubmit"' "gate-picker: the result belongs to prompt submission"
assert_contains "$out" 'Repo opinion for warp' "gate-picker: the desktop picker receives the opinion"
assert_contains "$out" 'hook: ran hello.sh, exit 0' "gate-picker: the hook runs and its report reaches the skill"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"please [$loom:warp](/plugin-cache/loom/skills/warp/SKILL.md) orient"}')"
assert_contains "$out" 'Repo opinion for warp' "gate-picker: a skill link can appear inside a prompt"
out="$(run_gate '{"hook_event_name":"UserPromptSubmit","prompt":"the \"auth\" flow: [$loom:warp](/plugin-cache/loom/skills/warp/SKILL.md) orient"}')"
assert_contains "$out" 'Repo opinion for warp' "gate-picker: a quote in the prompt before the mention hides nothing"
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
assert_contains "$out" 'loom gate: weave\nopinion: none\nhook: failed fail.sh, exit 7\n\nThe weave hook exited 7' "receipt-failed: the receipt names the hook as failed with its exit code, and the opinion as none"
if command -v python3 >/dev/null 2>&1; then
  decoded="$(printf '%s' "$out" | decode)"
  assert_contains "$decoded" "exited 7" "hook-failed: the report is valid JSON"
fi

# Neither an opinion nor a hook: the receipt alone. A quiet hook and one found by name are named.
out="$(run_gate '{"tool_name":"Skill","tool_input":{"skill":"loom:weft","args":""}}')"; rc=$?
assert_exit "$rc" "0" "gate-no-opinion: a loom skill without an opinion file or hook exits 0"
assert_contains "$out" '"additionalContext":"loom gate: weft\nopinion: none\nhook: none"}}' "receipt-none: a skill with neither gets the receipt and nothing beneath it"
assert_not_contains "$out" 'at invocation' "hook-unset: no hook report follows the receipt"
( cd "$R" && bash "$HOOK" --name weft >/dev/null 2>&1 ); assert_exit "$?" "3" "receipt-none: skill-hook --name exits 3 when there is none"

out="$(run_gate '{"tool_name":"Skill","tool_input":{"skill":"loom:dress","args":"retune"}}')"; rc=$?
assert_exit "$rc" "0" "receipt-quiet: a hook that exits 0 saying nothing exits 0"
assert_contains "$out" 'hook: ran quiet.sh, exit 0"}}' "receipt-quiet: the hook is named with exit 0 and nothing follows"

out="$(run_gate '{"tool_name":"Skill","tool_input":{"skill":"loom:spec","args":""}}')"; rc=$?
assert_exit "$rc" "0" "receipt-by-convention: a hook found by name exits 0"
assert_contains "$out" 'hook: ran spec, exit 0' "receipt-by-convention: the hook found by name is named on the receipt"
assert_contains "$out" 'spec by name' "receipt-by-convention: its output follows"
assert_eq "$( (cd "$R" && bash "$HOOK" --name spec) )" "spec" "receipt-by-convention: skill-hook --name resolves the file"

# A config the parser refuses: the receipt says so and carries the runner's one line.
RB="$DIR/fixtures/skill-gate-refused"; rm -rf "$RB"; mkdir -p "$RB/.loom/scripts"
printf '[warp]\nhook = "hello.sh"\n[lint]\nbad = { inline = "table" }\n' > "$RB/.loom/loom.toml"
( cd "$RB" && test_git_init && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed: refused config" )
out="$( ( cd "$RB" && printf '%s' "$warp_payload" | bash "$GATE" 2>&1 ) )"; rc=$?
assert_exit "$rc" "0" "receipt-refused: a refused config still exits 0"
assert_contains "$out" 'hook: refused, exit 2, .loom/loom.toml unparseable' "receipt-refused: the receipt says refused and names the config"
assert_contains "$out" 'The warp hook exited 2 at invocation' "receipt-refused: the refusal is reported as the hook's outcome"
assert_contains "$out" 'refusing to run the warp hook' "receipt-refused: the runner's one line follows"
rm -rf "$RB"

out="$(run_gate '{"tool_name":"Skill","tool_input":{"skill":"anthropic-skills:pdf","args":""}}')"; rc=$?
assert_exit "$rc" "0" "gate-other-skill: another plugin's skill exits 0"
assert_eq "$out" "" "gate-other-skill: nothing is returned"

# A host that resolves a bare skill name reports it bare; another plugin's skill of that name is not loom's.
out="$(run_gate '{"tool_name":"Skill","tool_input":{"skill":"warp","args":""}}')"; rc=$?
assert_exit "$rc" "0" "receipt-bare-name: a bare skill name the host resolved exits 0"
assert_contains "$out" 'loom gate: warp\nopinion: read .loom/skills/warp.md\nhook: ran hello.sh, exit 0' "receipt-bare-name: the bare name gets the receipt, the opinion, and the hook"
out="$(run_gate '{"tool_name":"Skill","tool_input":{"skill":"other:warp","args":""}}')"
assert_eq "$out" "" "receipt-bare-name: another plugin's warp is not loom's"

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
