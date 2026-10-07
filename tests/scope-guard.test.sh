#!/bin/bash
# Scope guard: warn (never block) when an edit lands on a file the active plan didn't list.
cd "$(dirname "$0")" || exit 2
. ./lib.sh
HOOK=../hooks/scope-guard.sh

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
REPO="$WORK/repo"; PLAN="$WORK/plans/add-thing"
mkdir -p "$REPO/src" "$PLAN" "$WORK/loose"
git -C "$REPO" init -q
printf 'src/*.php\nREADME.md\n\n# comment\n' > "$PLAN/scope.txt"
GITDIR=$(git -C "$REPO" rev-parse --absolute-git-dir)
echo "$PLAN/scope.txt" > "$GITDIR/dev-os-scope"

edit() { printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"},"cwd":"%s"}' "$1" "$REPO" | "$HOOK" 2>&1; }

echo "# listed files stay silent"
assert_contains "glob match silent"  "[$(edit "$REPO/src/Export.php")]" "[]"
assert_contains "exact match silent" "[$(edit "$REPO/README.md")]" "[]"

echo "# unplanned file warns, never blocks"
OUT=$(edit "$REPO/src/lib/Other.js")
assert_contains     "warns on unplanned file" "$OUT" "UNPLANNED FILE"
assert_contains     "names the file"          "$OUT" "src/lib/Other.js"
assert_contains     "names the plan"          "$OUT" "add-thing"
assert_contains     "is PostToolUse context"  "$OUT" "PostToolUse"
assert_not_contains "never blocks"            "$OUT" '"block"'

echo "# silent when there is nothing to check against"
assert_contains "file outside any repo silent" "[$(edit "$WORK/loose/x.txt")]" "[]"
rm "$GITDIR/dev-os-scope"
assert_contains "no active plan silent" "[$(edit "$REPO/src/lib/Other.js")]" "[]"

echo "# registered in the example settings"
assert_contains "settings registers it" "$(jq -r '.hooks.PostToolUse[]?.hooks[]?.command' ../settings.example.json 2>/dev/null)" "scope-guard.sh"

summary
