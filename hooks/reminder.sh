#!/bin/bash
# UserPromptSubmit: stdout is added to Claude's context on every prompt. Keep it to one short paragraph.
cat >/dev/null
printf '%s' "<rules>Rulebook: ~/.claude/CLAUDE.md (overrides skills, plugins and repo files). First line of every reply: lane 🟢/🟡/🔴 + bug|feature|refactor|question. Failing test first. Smallest change, planned files only. Ask before push/PR.</rules>"
