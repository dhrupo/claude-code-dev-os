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
assert_contains "plugin has a semver version (got $PV)" "$(printf '%s' "$PV" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$')" "$PV"
assert_contains "plugin.json alone owns the version (marketplace has none)" "[$MV]" "[null]"
assert_contains "plugin version is 2.1.1" "$PV" "2.1.1"
ICON=$(jq -r '.icon // empty' "$P" 2>/dev/null)
assert_contains "plugin.json icon is .claude-plugin/icon.png" "[$ICON]" "[.claude-plugin/icon.png]"
assert_contains "icon file is a PNG" "$(file -b "$ICON" 2>/dev/null)" "PNG image data"
assert_contains "icon is square, 512-2048 px" "$(od -An -tu1 -j16 -N8 "$ICON" 2>/dev/null | awk 'NF==8 {w=$1*16777216+$2*65536+$3*256+$4; h=$5*16777216+$6*65536+$7*256+$8; if (w==h && w>=512 && w<=2048) print "ok"}')" "ok"
assert_contains "icon is under 2 MB" "$([ -f "$ICON" ] && [ "$(wc -c < "$ICON")" -lt 2097152 ] && echo ok)" "ok"

echo "# plugin wiring matches the copy-install wiring"
wiring() { jq -r '.hooks | to_entries[] | .key as $e | .value[] | (.matcher // "*") as $m | .hooks[] | "\($e) \($m) \(.command | sub(".*/hooks/"; "") | sub("\"$"; "")) \(.timeout)"' "$1" 2>/dev/null | sort; }
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
mkdir -p "$W/home/.claude/hooks"; cp hooks/reminder.sh hooks/dedupe.sh "$W/home/.claude/hooks/"
printf '{"hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"%s/home/.claude/hooks/reminder.sh"}]}]}}' "$W" > "$W/wired.json"
printf '{"hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"~/.claude/hooks/other-reminder.sh"}]}]}}' > "$W/other.json"
prompt() { jq -nc '{prompt:"fix the export bug",cwd:"/x",session_id:"s1"}'; }
assert_contains "copy install (no plugin env) still speaks" "$(prompt | env -u CLAUDE_PLUGIN_ROOT DEV_OS_USER_SETTINGS="$W/wired.json" hooks/reminder.sh)" "<rules>"
assert_contains "plugin hook alone speaks" "$(prompt | CLAUDE_PLUGIN_ROOT="$PWD" DEV_OS_USER_SETTINGS="$W/none.json" hooks/reminder.sh)" "<rules>"
assert_contains "plugin hook silent when wired by hand" "[$(prompt | CLAUDE_PLUGIN_ROOT="$PWD" DEV_OS_USER_SETTINGS="$W/wired.json" hooks/reminder.sh)]" "[]"
assert_contains "a different hook name does not silence it" "$(prompt | CLAUDE_PLUGIN_ROOT="$PWD" DEV_OS_USER_SETTINGS="$W/other.json" hooks/reminder.sh)" "<rules>"

echo "# setup-check: push ask missing → said once; added → silent and re-armed"
printf '{"permissions":{"ask":["Bash(git push:*)","Bash(git -C * push *)","Bash(gh pr create:*)"]}}' > "$W/ask.json"
sc() { DEV_OS_USER_SETTINGS="$1" hooks/setup-check.sh </dev/null 2>&1; }
assert_contains "missing ask → one message" "$(sc "$W/none.json")" "README"
assert_contains "second session silent" "[$(sc "$W/none.json")]" "[]"
assert_contains "ask present → silent" "[$(sc "$W/ask.json")]" "[]"
assert_contains "removed again → warns again" "$(sc "$W/none.json")" "README"

echo "# both read the active config folder (CLAUDE_CONFIG_DIR), not always ~/.claude"
mkdir -p "$W/cfg" && printf '{}' > "$W/cfg/settings.json" && rm -f "$DEV_OS_STATE/setup-check.warned"
assert_contains "setup-check reads CLAUDE_CONFIG_DIR's settings" "$(CLAUDE_CONFIG_DIR="$W/cfg" hooks/setup-check.sh </dev/null)" "README"
cp "$W/wired.json" "$W/cfg/settings.json"
assert_contains "dedupe reads CLAUDE_CONFIG_DIR's settings" "[$(prompt | CLAUDE_PLUGIN_ROOT="$PWD" CLAUDE_CONFIG_DIR="$W/cfg" hooks/reminder.sh)]" "[]"

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

echo "# review round 1"
mkdir -p "$W/other/hooks"; printf '#!/bin/bash\necho other\n' > "$W/other/hooks/reminder.sh"
printf '{"hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"python3 %s/other/hooks/reminder.sh"}]}]}}' "$W" > "$W/sameName.json"
printf '{"hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"\\"%s/home/.claude/hooks/reminder.sh\\" 2>/dev/null"}]}]}}' "$W" > "$W/quoted.json"
assert_contains "another tool's hook with the same name does not silence the kit's" "$(prompt | CLAUDE_PLUGIN_ROOT="$PWD" DEV_OS_USER_SETTINGS="$W/sameName.json" hooks/reminder.sh)" "<rules>"
assert_contains "a quoted hand-wired kit copy still counts" "[$(prompt | CLAUDE_PLUGIN_ROOT="$PWD" DEV_OS_USER_SETTINGS="$W/quoted.json" hooks/reminder.sh)]" "[]"
printf '{"permissions":{"ask":["Bash(git push:*)"]}}' > "$W/onlypush.json"; rm -f "$DEV_OS_STATE/setup-check.warned"
assert_contains "setup-check wants all three ask rules" "$(DEV_OS_USER_SETTINGS="$W/onlypush.json" hooks/setup-check.sh </dev/null)" "README"
assert_contains "settings.example.json asks for git -C push too" "$(jq -r '.permissions.ask | join(" ")' settings.example.json)" 'Bash(git -C * push *)'
assert_not_contains "Known gaps no longer says git -C is uncaught" "$(sed -n '/^## Known gaps/,/^## Make/p' README.md)" 'does not catch `git -C . push`'
for f in .claude-plugin/ hooks/hooks.json hooks/setup-check.sh hooks/dedupe.sh; do
  assert_contains "README inventory lists $f" "$(sed -n "/^## What's inside/,/^## Start here/p" README.md)" "$f"
done

echo "# hooks keep Python in .py files (the directory review blocks inline python3 -c)"
SH=$(ls hooks/*.sh 2>/dev/null)
assert_contains "hook scripts found" "$(printf '%s' "$SH" | wc -w | tr -d ' ')" "1"
assert_contains "no hook runs inline python3 -c" "[$(grep -l 'python3 -c' $SH 2>/dev/null)]" "[]"
for h in learn scope-guard stop-check; do
  assert_contains "hooks/$h.sh execs its .py" "$(cat "hooks/$h.sh")" 'exec python3 "$PY"'
  assert_contains "hooks/$h.sh points PY at $h.py" "$(cat "hooks/$h.sh")" "PY=\"\$(dirname \"\$0\")/$h.py\""
  assert_contains "hooks/$h.py exists" "$(test -s "hooks/$h.py" && echo yes)" "yes"
  rm -rf "$W/nopy"; mkdir -p "$W/nopy"; cp hooks/"$h".sh hooks/dedupe.sh "$W/nopy/"
  err=$(printf '{"session_id":"s1","stop_hook_active":false}' | env -u CLAUDE_PLUGIN_ROOT "$W/nopy/$h.sh" 2>&1 >/dev/null); rc=$?
  assert_contains "$h.sh with its .py missing exits 0 (got $rc)" "$rc" "0"
  assert_contains "$h.sh with its .py missing says so" "$err" "dev-os: $h.py missing, copy hooks/*.py"
done
assert_contains "copy install copies the .py hooks" "$(cat README.md)" 'cp -n "$KIT"/hooks/*.py ~/.claude/hooks/'
assert_contains "v1 upgrade copies stop-check.py with stop-check.sh" "$(cat README.md)" '"$KIT/hooks/stop-check.sh" "$KIT/hooks/stop-check.py"'

echo "# README discloses what the plugin runs"
RUNS=$(sed -n '/^## What the plugin runs/,/^## /p' README.md)
HOOKS=$(jq -r '.. | .command? // empty' hooks/hooks.json 2>/dev/null | sed 's#.*/hooks/##' | sort -u)
assert_contains "hooks.json wires 8 scripts" "$(printf '%s\n' "$HOOKS" | grep -c .)" "8"
for s in $HOOKS; do assert_contains "What the plugin runs names $s" "$RUNS" "\`$s\`"; done
assert_contains "What the plugin runs says no network calls" "$RUNS" "No network calls"
assert_contains "What the plugin runs says settings are never edited" "$RUNS" "never edits your settings"
summary
