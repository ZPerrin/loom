#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
TRACE="$DIR/../scripts/hook-trace"
LOG="$DIR/fixtures/hook-trace.jsonl"; rm -f "$LOG"

printf '{"hook_event_name":"PreToolUse","tool_name":"shell"}' | LOOM_HOOK_TRACE="$LOG" bash "$TRACE" a b; rc=$?
assert_exit "$rc" "0" "trace-appends: the tracer exits 0"
assert_contains "$(cat "$LOG")" '"argv":"a b"' "trace-appends: the arguments are logged"
assert_contains "$(cat "$LOG")" 'PreToolUse' "trace-appends: the payload is logged"
LOOM_HOOK_TRACE="$LOG" bash "$TRACE" '{"as":"argv"}' </dev/null
assert_eq "$(grep -c . "$LOG")" "2" "trace-appends: each event is one more line"
if command -v python3 >/dev/null 2>&1; then
  ok="$(python3 -c 'import json,sys; [json.loads(l) for l in open(sys.argv[1])]; print("ok")' "$LOG")"
  assert_eq "$ok" "ok" "trace-appends: every line is valid JSON"
fi
rm -f "$LOG"
finish
