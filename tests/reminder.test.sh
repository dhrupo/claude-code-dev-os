#!/bin/bash
# Reminder: one short paragraph injected on every prompt.
cd "$(dirname "$0")" || exit 2
. ./lib.sh
HOOK=../hooks/reminder.sh

OUT=$(printf '{"prompt":"fix the export","cwd":"/tmp"}' | "$HOOK" 2>&1)
assert_contains "points at the rulebook" "$OUT" "CLAUDE.md"
assert_contains "asks for the lane"      "$OUT" "lane"
assert_contains "asks before push"       "$OUT" "Ask before push"
assert_contains "stays one paragraph"    "$(printf '%s' "$OUT" | wc -l | tr -d ' ')" "0"
assert_contains "under 400 bytes"        "$([ "$(printf '%s' "$OUT" | wc -c)" -lt 400 ] && echo yes)" "yes"
assert_contains "settings registers it"  "$(jq -r '.hooks.UserPromptSubmit[]?.hooks[]?.command' ../settings.example.json 2>/dev/null)" "reminder.sh"

summary
