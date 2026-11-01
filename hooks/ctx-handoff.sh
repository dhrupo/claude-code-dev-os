#!/bin/bash
# Stop: offer a fresh session once at 80%+ context, and once when a second plan starts in the same session.
umask 077
INPUT=$(cat)
[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')
[ -n "$SID" ] || exit 0
STATE="${DEV_OS_STATE:-$HOME/.claude/state}"; mkdir -p "$STATE"
find "$STATE" -maxdepth 1 \( -name 'ctx-*' -o -name 'learn-*' -o -name 'plans-*' \) -mtime +7 -delete 2>/dev/null
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
GITDIR=$(git -C "${CWD:-/}" rev-parse --absolute-git-dir 2>/dev/null)
PLAN=$([ -n "$GITDIR" ] && cat "$GITDIR/dev-os-scope" 2>/dev/null)
if [ -n "$PLAN" ]; then
  SEEN="$STATE/plans-$SID.txt"; FIRST=$(head -1 "$SEEN" 2>/dev/null)
  if ! grep -qxF "$PLAN" "$SEEN" 2>/dev/null; then
    echo "$PLAN" >> "$SEEN"
    if [ -n "$FIRST" ]; then
      jq -n --arg a "$(basename "$(dirname "$FIRST")")" --arg b "$(basename "$(dirname "$PLAN")")" \
        '{decision:"block", reason:("NEW TASK: this session already worked on plan \"\($a)\"; plan \"\($b)\" is a new task. Finish the current step, then offer the user a fresh session with a short handoff note saved in the \"\($b)\" plan folder. Asks once per plan.")}'
      exit 0
    fi
  fi
fi
[ -f "$STATE/ctx-$SID.txt" ] && [ ! -f "$STATE/ctx-$SID.asked" ] || exit 0
PCT=$(tr -dc '0-9' < "$STATE/ctx-$SID.txt")
[ -n "$PCT" ] && [ "$PCT" -ge 80 ] || exit 0
touch "$STATE/ctx-$SID.asked"
jq -n --arg p "$PCT" '{decision:"block", reason:("CONTEXT: about \($p)% used. Finish the current step, then ask the user: hand off to a fresh session? On yes, write a handoff note (goal, decisions, next step, what was verified) in the active plan folder and give the command to resume. Asks once per session.")}'
