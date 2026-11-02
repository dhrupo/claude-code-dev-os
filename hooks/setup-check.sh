#!/bin/bash
. "$(dirname "$0")/dedupe.sh"
# SessionStart: a plugin can't ship the push/PR ask rules; say so once until they are added.
STATE=${DEV_OS_STATE:-$HOME/.claude/state}; mkdir -p "$STATE"
S=${DEV_OS_USER_SETTINGS:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json}; MARK="$STATE/setup-check.warned"
if jq -e '[.permissions.ask[]? | select(startswith("Bash(git push"))] | length > 0' "$S" >/dev/null 2>&1; then
  rm -f "$MARK"; exit 0
fi
[ -f "$MARK" ] && exit 0
touch "$MARK"
echo "dev-os: your Claude settings.json has no ask rule for git push or gh pr create, so pushes won't stop for a yes. Tell the user once: see the kit README, section \"After install\" (https://github.com/dhrupo/claude-code-dev-os#after-install)."
