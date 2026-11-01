#!/bin/bash
# PreToolUse(Skill) + UserPromptExpansion (typed /skill): one line per skill use, read by learn.sh and meditate.
STATE="${DEV_OS_STATE:-$HOME/.claude/state}"
mkdir -p "$STATE" 2>/dev/null
umask 077
jq -c '(if .tool_name == "Skill" then .tool_input.skill elif .hook_event_name == "UserPromptExpansion" then (.command_name // "" | ltrimstr("/")) else empty end) as $s
  | select($s != "") | {time:(now*1000|floor), skill:$s, cwd:.cwd, sid:.session_id}' 2>/dev/null >> "$STATE/skill-usage.jsonl"
exit 0
