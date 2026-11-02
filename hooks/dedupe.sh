# Sourced by every hook. Under the plugin, step aside when the kit's own copy of this hook is wired by hand
# (a hand-wired file that also sources dedupe.sh), so nothing runs twice and other tools' same-named hooks don't count.
if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
  _n=$(basename "$0")
  for _p in $(jq -r --arg n "/hooks/$_n" '.hooks[]?[]?.hooks[]?.command // empty | select(contains($n))' \
      "${DEV_OS_USER_SETTINGS:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json}" 2>/dev/null | grep -oE "[^ \"']*/hooks/$_n"); do
    _p=${_p/#\~/$HOME}; _p=${_p//\$HOME/$HOME}
    grep -q 'dedupe\.sh' "$_p" 2>/dev/null && exit 0
  done
fi
