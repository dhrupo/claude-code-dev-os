#!/bin/bash
# The dev-os Claude Code plugin: manifests agree, plugin wiring matches the copy-install wiring, no double hooks.
cd "$(dirname "$0")/.." || exit 2
. tests/lib.sh
P=.claude-plugin/plugin.json; M=.claude-plugin/marketplace.json

echo "# manifests"
assert_contains "plugin is named dev-os" "$(jq -r .name "$P" 2>&1)" "dev-os"
assert_contains "marketplace lists dev-os from this repo" "$(jq -r '.plugins[] | select(.name=="dev-os") | .source' "$M" 2>&1)" "./"
assert_contains "marketplace has an owner" "$(jq -r '.owner.name // empty' "$M" 2>/dev/null)" "Dhrupo"
PV=$(jq -r .version "$P" 2>/dev/null); MV=$(jq -r '.plugins[] | select(.name=="dev-os") | .version' "$M" 2>/dev/null)
assert_contains "plugin has a version (got $PV)" "[$PV]" "[2.1.0]"
assert_contains "marketplace version agrees (got $MV)" "[$MV]" "[$PV]"

echo "# plugin wiring matches the copy-install wiring"
wiring() { jq -r '.hooks | to_entries[] | .key as $e | .value[] | (.matcher // "*") as $m | .hooks[] | "\($e) \($m) \(.command | sub(".*/hooks/"; "") | sub("\"$"; ""))"' "$1" 2>/dev/null | sort; }
A=$(wiring settings.example.json); B=$(wiring hooks/hooks.json)
assert_contains "copy wiring covers 6 events (got $(printf '%s\n' "$A" | awk '{print $1}' | sort -u | wc -l | tr -d ' '))" "$(printf '%s\n' "$A" | awk '{print $1}' | sort -u | wc -l | tr -d ' ')" "6"
assert_contains "plugin wiring covers 6 events" "$(printf '%s\n' "$B" | awk '{print $1}' | sort -u | wc -l | tr -d ' ')" "6"
assert_contains "same (event, matcher, script) set" "$(diff <(printf '%s\n' "$A" | grep -v setup-check) <(printf '%s\n' "$B" | grep -v setup-check) && echo same)" "same"
BAD=$(jq -r '.. | .command? // empty' hooks/hooks.json 2>/dev/null | grep -v '^"${CLAUDE_PLUGIN_ROOT}"/hooks/')
assert_contains "every plugin hook path is quoted \${CLAUDE_PLUGIN_ROOT} (bad: $BAD)" "[$BAD]" "[]"
for s in $(jq -r '.. | .command? // empty' hooks/hooks.json 2>/dev/null | sed 's#.*/hooks/##'); do
  assert_contains "hooks/$s is executable" "$(test -x "hooks/$s" && echo yes)" "yes"
done

echo "# every wired hook loads the duplicate guard"
for s in $(jq -r '.. | .command? // empty' hooks/hooks.json 2>/dev/null | sed 's#.*/hooks/##' | sort -u); do
  assert_contains "hooks/$s sources dedupe.sh" "$(sed -n '2,4p' "hooks/$s" 2>/dev/null)" '. "$(dirname "$0")/dedupe.sh"'
done

echo "# duplicate guard: plugin hook steps aside only when the same hook is wired by hand"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
export DEV_OS_STATE="$W/state"
printf '{"hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"~/.claude/hooks/reminder.sh"}]}]}}' > "$W/wired.json"
printf '{"hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"~/.claude/hooks/other-reminder.sh"}]}]}}' > "$W/other.json"
prompt() { jq -nc '{prompt:"fix the export bug",cwd:"/x",session_id:"s1"}'; }
assert_contains "copy install (no plugin env) still speaks" "$(prompt | env -u CLAUDE_PLUGIN_ROOT DEV_OS_USER_SETTINGS="$W/wired.json" hooks/reminder.sh)" "<rules>"
assert_contains "plugin hook alone speaks" "$(prompt | CLAUDE_PLUGIN_ROOT="$PWD" DEV_OS_USER_SETTINGS="$W/none.json" hooks/reminder.sh)" "<rules>"
assert_contains "plugin hook silent when wired by hand" "[$(prompt | CLAUDE_PLUGIN_ROOT="$PWD" DEV_OS_USER_SETTINGS="$W/wired.json" hooks/reminder.sh)]" "[]"
assert_contains "a different hook name does not silence it" "$(prompt | CLAUDE_PLUGIN_ROOT="$PWD" DEV_OS_USER_SETTINGS="$W/other.json" hooks/reminder.sh)" "<rules>"

echo "# setup-check: push ask missing → said once; added → silent and re-armed"
printf '{"permissions":{"ask":["Bash(git push:*)"]}}' > "$W/ask.json"
sc() { DEV_OS_USER_SETTINGS="$1" hooks/setup-check.sh </dev/null 2>&1; }
assert_contains "missing ask → one message" "$(sc "$W/none.json")" "README"
assert_contains "second session silent" "[$(sc "$W/none.json")]" "[]"
assert_contains "ask present → silent" "[$(sc "$W/ask.json")]" "[]"
assert_contains "removed again → warns again" "$(sc "$W/none.json")" "README"

echo "# plugin skill names and paths"
mkdir -p "$DEV_OS_STATE"
printf '{"time":%s,"skill":"dev-os:reflect","sid":"s9"}\n' "$(($(date +%s)*1000+5000))" > "$DEV_OS_STATE/skill-usage.jsonl"
printf '{"time":%s,"type":"correction","note":"x"}\n' "$(($(date +%s)*1000))" > "$DEV_OS_STATE/learn-s9.jsonl"
assert_contains "learn.sh counts dev-os:reflect as reflect" "[$(printf '{"session_id":"s9","stop_hook_active":false}' | hooks/learn.sh)]" "[]"
assert_contains "plan skill finds its template in either install" "$(cat skills/plan/SKILL.md)" '${CLAUDE_SKILL_DIR}/template/'
assert_contains "rulebook names the plugin prefix" "$(cat CLAUDE.md)" "dev-os:<name>"
R=$(cat README.md)
assert_contains "README: plugin install command" "$R" "/plugin marketplace add dhrupo/claude-code-dev-os"
assert_contains "README: install line" "$R" "/plugin install dev-os@dhrupo"
assert_contains "README: after-install push ask covers git -C" "$R" 'Bash(git -C * push *)'
assert_contains "README: pick one install" "$R" "Pick one install"
summary
