#!/bin/bash
# Fresh-session nudges: once at ~80% context, once when a second plan starts in the same session;
# after compaction the active plan and next task are restated.
cd "$(dirname "$0")" || exit 2
. ./lib.sh
export DEV_OS_STATE=$(mktemp -d); WORK=$(mktemp -d); trap 'rm -rf "$DEV_OS_STATE" "$WORK"' EXIT
H=../hooks/ctx-handoff.sh; C=../hooks/compact.sh; SL=../hooks/statusline.sh
REPO="$WORK/repo"; mkdir -p "$REPO" "$WORK/plans/a" "$WORK/plans/b"; git -C "$REPO" init -q
GITDIR=$(git -C "$REPO" rev-parse --absolute-git-dir)
printf -- '- [x] 1. done\n- [ ] 2. write the export test\n' > "$WORK/plans/a/tasks.md"
touch "$WORK/plans/a/scope.txt" "$WORK/plans/b/scope.txt"
stop() { printf '{"session_id":"s1","cwd":"%s","stop_hook_active":false}' "$REPO" | "$H" 2>&1; }

echo "# context % comes from the status line"
OUT=$(printf '{"session_id":"s1","model":{"display_name":"M"},"context_window":{"used_percentage":83.4}}' | "$SL")
assert_contains "status line shows the percent" "$OUT" "83%"
assert_contains "status line saves it" "$(cat "$DEV_OS_STATE/ctx-s1.txt")" "83"

echo "# 80%+: ask once"
OUT=$(stop); assert_contains "asks to hand off" "$OUT" "fresh session"
assert_contains "only once" "[$(stop)]" "[]"

echo "# a second plan in the same session: ask once"
echo "$WORK/plans/a/scope.txt" > "$GITDIR/dev-os-scope"; stop >/dev/null
echo "$WORK/plans/b/scope.txt" > "$GITDIR/dev-os-scope"
OUT=$(stop); assert_contains "new plan flagged" "$OUT" "new task"
assert_contains "names both plans" "$(printf '%s' "$OUT" | jq -r .reason)" '"a"'
assert_contains "only once per plan" "[$(stop)]" "[]"

echo "# after compaction: restate the plan and next task"
echo "$WORK/plans/a/scope.txt" > "$GITDIR/dev-os-scope"
OUT=$(printf '{"cwd":"%s"}' "$REPO" | "$C")
assert_contains "restates next task" "$OUT" "write the export test"
assert_contains "no plan, no output" "[$(printf '{"cwd":"%s"}' "$WORK" | "$C")]" "[]"

echo "# registered"
S=$(cat ../settings.example.json)
assert_contains "handoff registered" "$S" "ctx-handoff.sh"
assert_contains "compact registered" "$S" "compact.sh"
assert_contains "status line registered" "$S" "statusline.sh"
summary
