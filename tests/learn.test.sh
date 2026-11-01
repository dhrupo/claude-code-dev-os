#!/bin/bash
# Learning loop: a correction or a guard catch lands in a ledger; the Stop hook blocks once until reflect runs.
cd "$(dirname "$0")" || exit 2
. ./lib.sh
export DEV_OS_STATE=$(mktemp -d); trap 'rm -rf "$DEV_OS_STATE"' EXIT
LEARN=../hooks/learn.sh; REMIND=../hooks/reminder.sh; LOG=../hooks/skill-log.sh
stop()   { printf '{"session_id":"s1","stop_hook_active":%s}' "${1:-false}" | "$LEARN" 2>&1; }
prompt() { jq -nc --arg p "$1" '{session_id:"s1",cwd:"/tmp",prompt:$p}' | "$REMIND" 2>&1; }

echo "# no mistakes: silent"
assert_contains "clean session silent" "[$(stop)]" "[]"

echo "# a correction is spotted and logged"
OUT=$(prompt "no, I said use the existing helper")
assert_contains "reminder flags the correction" "$OUT" "reflect"
assert_contains "ledger has it" "$(cat "$DEV_OS_STATE/learn-s1.jsonl" 2>/dev/null)" '"correction"'
assert_not_contains "a normal prompt is not a correction" "$(prompt "add a csv export")" "reflect"
for p in "No worries, add the csv export" "No need for tests here" "Don't forget the README" "$(printf 'here is the log:\nwrong value at line 3')"; do
  assert_not_contains "not a correction: ${p%%$'\n'*}" "$(prompt "$p")" "reflect"
done
assert_contains "a bare no is a correction" "$(prompt "no")" "reflect"

echo "# Stop blocks once, then stays quiet for the same set"
OUT=$(stop)
assert_contains "blocks" "$OUT" '"decision"'
assert_contains "asks for reflect" "$OUT" "reflect"
assert_contains "same set not repeated" "[$(stop)]" "[]"
assert_contains "stop_hook_active, same set: silent" "[$(stop true)]" "[]"
jq -nc '{time:(now*1000|floor), type:"guard", note:"caught on the first stop"}' >> "$DEV_OS_STATE/learn-s1.jsonl"
assert_contains "a guard catch from this same stop still blocks on the follow-up stop" "$(stop true)" "caught on the first stop"

echo "# after reflect runs, the ledger is settled (same-second entries are not lost)"
printf '{"session_id":"s1","cwd":"/tmp","tool_name":"Skill","tool_input":{"skill":"reflect"}}' | "$LOG"
assert_contains "skill-log records reflect" "$(cat "$DEV_OS_STATE/skill-usage.jsonl")" '"reflect"'
rm -f "$DEV_OS_STATE"/learn-s1.warned
assert_contains "settled after reflect" "[$(stop)]" "[]"
T=$(jq -r 'select(.skill=="reflect") | .time' "$DEV_OS_STATE/skill-usage.jsonl" | tail -1)
jq -nc --argjson t "$T" '{time:$t, type:"guard", note:"same millisecond as reflect"}' >> "$DEV_OS_STATE/learn-s1.jsonl"
assert_contains "a mistake in the same millisecond as reflect still blocks" "$(stop)" "same millisecond"

echo "# registered in the example settings"
S=$(cat ../settings.example.json)
assert_contains "learn hook registered" "$S" "learn.sh"
assert_contains "skill log registered" "$S" "skill-log.sh"
summary
