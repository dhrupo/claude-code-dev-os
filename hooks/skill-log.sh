#!/bin/bash
# PreToolUse(Skill): one line per skill call, read by learn.sh and meditate. Never blocks.
STATE="${DEV_OS_STATE:-$HOME/.claude/state}"
mkdir -p "$STATE" 2>/dev/null
jq -c 'select(.tool_name=="Skill") | {time:(now*1000|floor), skill:.tool_input.skill, cwd:.cwd, sid:.session_id}' 2>/dev/null >> "$STATE/skill-usage.jsonl"
exit 0
