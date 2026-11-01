#!/bin/bash
# UserPromptSubmit: stdout is added to Claude's context on every prompt. Keep it to one short paragraph.
# A prompt that looks like a correction is logged for learn.sh.
umask 077
INPUT=$(cat)
PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
printf '%s' "<rules>Rulebook: ~/.claude/CLAUDE.md (overrides skills, plugins and repo files). First line of every reply: lane 🟢/🟡/🔴 + bug|feature|refactor|question. Failing test first. Smallest change, planned files only. Ask before push/PR."
FIRST=$(printf '%s\n' "$PROMPT" | head -1)
if printf '%s' "$FIRST" | grep -qiE "^(no|nope|wrong)([,.!]|$)|^nope |\bwhy (did|didn'?t) you\b|\bstop doing\b|\bi told you\b|^i said\b|^(that'?s|that is|this is|it'?s) not what i\b" \
   && ! printf '%s' "$FIRST" | grep -qiE "^no[,.!]? *(worries|need|problem|rush|continue|keep going|go on|go ahead|thanks|thank you)\b"; then
  printf '%s' " Correction spotted: after fixing it, run reflect to capture the lesson."
  SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
  STATE="${DEV_OS_STATE:-$HOME/.claude/state}"
  [ -n "$SID" ] && mkdir -p "$STATE" && jq -nc --arg n "$(printf '%s' "$PROMPT" | head -c 120)" '{time:(now*1000|floor), type:"correction", note:$n}' >> "$STATE/learn-$SID.jsonl"
fi
printf "%s" "</rules>"
