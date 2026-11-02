# Sourced by every hook. Under the plugin, step aside when the same hook is already wired by hand.
if [ -n "$CLAUDE_PLUGIN_ROOT" ] && jq -e --arg n "/hooks/$(basename "$0")" \
  '[.hooks[]?[]?.hooks[]?.command // empty | select(endswith($n))] | length > 0' \
  "${DEV_OS_USER_SETTINGS:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json}" >/dev/null 2>&1; then exit 0; fi
