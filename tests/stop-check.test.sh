#!/bin/bash
# Stop check: with an active plan, send Claude back once for unplanned or untested changes.
cd "$(dirname "$0")" || exit 2
. ./lib.sh
HOOK=../hooks/stop-check.sh

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
export DEV_OS_STATE="$WORK/state"
REPO="$WORK/repo"; PLAN="$WORK/plans/fix-export"
mkdir -p "$REPO/src" "$REPO/tests" "$PLAN"
git -C "$REPO" init -q
echo a > "$REPO/src/Export.php"; echo a > "$REPO/README.md"
git -C "$REPO" add -A; git -C "$REPO" -c user.email=t@t -c user.name=t commit -qm init
printf 'src/*.php\ntests/*\n' > "$PLAN/scope.txt"
GITDIR=$(git -C "$REPO" rev-parse --absolute-git-dir)
echo "$PLAN/scope.txt" > "$GITDIR/dev-os-scope"

stop() { printf '{"session_id":"s1","cwd":"%s","stop_hook_active":%s}' "${2:-$REPO}" "${1:-false}" | "$HOOK" 2>&1; }

echo "# clean tree is silent"
assert_contains "no changes silent" "[$(stop)]" "[]"

echo "# source changed without a test"
echo b > "$REPO/src/Export.php"
OUT=$(stop)
assert_contains "blocks once"           "$OUT" '"decision": "block"'
assert_contains "names missing test"    "$OUT" "NO TEST CHANGED"
assert_contains "names the plan"        "$OUT" "fix-export"
assert_contains "same set not repeated" "[$(stop)]" "[]"

echo "# unplanned file (e.g. a Bash edit) is a new problem -> fires again"
echo b > "$REPO/README.md"
OUT=$(stop)
assert_contains "flags unplanned file" "$OUT" "README.md"
assert_contains "labels it unplanned"  "$OUT" "UNPLANNED"

echo "# planned source + test -> silent"
git -C "$REPO" checkout -q README.md
echo t > "$REPO/tests/ExportTest.php"
assert_contains "source+test in scope silent" "[$(stop)]" "[]"

echo "# a weakened test fires (removed assert, new skip)"
printf 'assert(1);\nassert(2);\n' > "$REPO/tests/ExportTest.php"; git -C "$REPO" add -A; git -C "$REPO" -c user.email=t@t -c user.name=t commit -qm t
printf 'assert(1);\n' > "$REPO/tests/ExportTest.php"; echo d > "$REPO/src/Export.php"
OUT=$(stop); assert_contains "removed assert flagged" "$OUT" "TEST WEAKENED"
rm -f "$GITDIR/dev-os-scope.warned"
printf 'assert(1);\nassert(2);\ntest.skip("x");\n' > "$REPO/tests/ExportTest.php"
OUT=$(stop); assert_contains "new skip flagged" "$OUT" "TEST WEAKENED"
assert_contains "guard catch logged for reflect" "$(cat "$DEV_OS_STATE"/learn-*.jsonl 2>/dev/null)" '"guard"'
rm -f "$GITDIR/dev-os-scope.warned"
printf 'assert(1);\nassert(2);\nassert result == 3\n' > "$REPO/tests/ExportTest.php"; git -C "$REPO" add -A; git -C "$REPO" -c user.email=t@t -c user.name=t commit -qm t2
printf 'assert(1);\nassert(2);\n' > "$REPO/tests/ExportTest.php"
OUT=$(stop); assert_contains "removed bare assert flagged" "$OUT" "TEST WEAKENED"
git -C "$REPO" checkout -q tests/ExportTest.php src/Export.php
rm -f "$GITDIR/dev-os-scope.warned"; echo e > "$REPO/src/Export.php"; mkdir -p "$REPO/tests/unit"
mv "$REPO/tests/ExportTest.php" "$REPO/tests/unit/ExportTest.php"
assert_not_contains "a moved test is not a deleted test" "$(stop)" "TEST WEAKENED"
mv "$REPO/tests/unit/ExportTest.php" "$REPO/tests/ExportTest.php"; rmdir "$REPO/tests/unit"
git -C "$REPO" checkout -q tests/ExportTest.php src/Export.php

echo "# loop + context guards"
echo c > "$REPO/notes.txt"
assert_contains "stop_hook_active silent" "[$(stop true)]" "[]"
rm "$GITDIR/dev-os-scope"
assert_contains "no active plan silent" "[$(stop)]" "[]"
assert_contains "outside a repo silent" "[$(stop false "$WORK")]" "[]"

echo "# registered in the example settings"
assert_contains "settings registers it" "$(jq -r '.hooks.Stop[]?.hooks[]?.command' ../settings.example.json 2>/dev/null)" "stop-check.sh"

summary
