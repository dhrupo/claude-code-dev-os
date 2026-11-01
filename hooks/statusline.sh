#!/bin/bash
# Status line: model + context %; saves the percent so ctx-handoff.sh can offer a fresh session.
umask 077
INPUT=$(cat)
STATE="${DEV_OS_STATE:-$HOME/.claude/state}"
MODEL=$(printf '%s' "$INPUT" | jq -r '.model.display_name // "?"')
USED=$(printf '%s' "$INPUT" | jq -r '.context_window.used_percentage // empty')
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')
[ -n "$USED" ] && [ -n "$SID" ] && mkdir -p "$STATE" && echo "${USED%.*}" > "$STATE/ctx-$SID.txt"
printf '%s' "$MODEL${USED:+ · ${USED%.*}% context}"
