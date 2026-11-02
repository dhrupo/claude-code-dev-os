#!/bin/bash
. "$(dirname "$0")/dedupe.sh"
# SessionStart: a plugin can't ship the push/PR ask rules; say so once until they are added.
umask 077
STATE=${DEV_OS_STATE:-$HOME/.claude/state}; mkdir -p "$STATE"
S=${DEV_OS_USER_SETTINGS:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json}; MARK="$STATE/setup-check.warned"
if jq -e '(.permissions.ask // []) as $a | ["Bash(git push:*)","Bash(git -C * push *)","Bash(gh pr create:*)"] | all(. as $r | $a | index($r))' "$S" >/dev/null 2>&1; then
  rm -f "$MARK"; exit 0
fi
[ -f "$MARK" ] && exit 0
touch "$MARK"
echo "dev-os: your Claude settings.json is missing an ask rule for git push, git -C push or gh pr create, so some pushes won't stop for a yes. Tell the user once: see the kit README, section \"After install\" (https://github.com/dhrupo/claude-code-dev-os#after-install)."
