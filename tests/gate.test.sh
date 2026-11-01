#!/bin/bash
# Test gate: a per-repo pre-commit hook that refuses a commit while the project's own test command fails.
cd "$(dirname "$0")" || exit 2
. ./lib.sh
GATE=$(cd .. && pwd)/bin/gate-install

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
REPO="$WORK/repo"; mkdir -p "$REPO"; git -C "$REPO" init -q
cm() { git -C "$REPO" -c user.email=t@t -c user.name=t commit -qm "$1" 2>&1; echo "[rc=$?]"; }
echo x > "$REPO/a.txt"; git -C "$REPO" add a.txt

echo "# no .dev-os-test: refuse to install, say how to add one"
OUT=$(cd "$REPO" && "$GATE" 2>&1); RC=$?
assert_contains "install refused without a test command" "[rc=$RC]" "[rc=1]"
assert_contains "says how to add one" "$OUT" ".dev-os-test"
assert_contains "no hook written" "hook=$(test -e "$REPO/.git/hooks/pre-commit" && echo yes || echo no)" "hook=no"

echo "# install, then a failing test command blocks the commit"
printf 'test -f ok.flag\n' > "$REPO/.dev-os-test"
OUT=$(cd "$REPO" && "$GATE" 2>&1); RC=$?
assert_contains "installs with a test command" "[rc=$RC]" "[rc=0]"
OUT=$(cm red)
assert_contains "red tests refuse the commit" "$OUT" "[rc=1]"
assert_contains "names the gate" "$OUT" "test gate"

echo "# green tests let it through"
touch "$REPO/ok.flag"
assert_contains "green tests commit" "$(cm green)" "[rc=0]"

echo "# exit code is the test command's own, not a pipe's"
printf 'false | cat\n' > "$REPO/.dev-os-test"; echo y >> "$REPO/a.txt"; git -C "$REPO" add a.txt
assert_contains "a failing stage inside a pipe still blocks" "$(cm pipe)" "[rc=1]"

echo "# empty or missing test command at commit time fails loud"
: > "$REPO/.dev-os-test"
OUT=$(cm empty); assert_contains "empty test command blocks" "$OUT" "[rc=1]"; assert_contains "says it is empty" "$OUT" "empty"
rm "$REPO/.dev-os-test"
assert_contains "missing test command blocks" "$(cm missing)" "[rc=1]"

echo "# installing from a subfolder still writes the repo's own hook"
REPO3="$WORK/repo3"; mkdir -p "$REPO3/src"; git -C "$REPO3" init -q; echo 'false' > "$REPO3/.dev-os-test"
(cd "$REPO3/src" && "$GATE" >/dev/null 2>&1)
assert_contains "hook lands in the repo's .git/hooks" "hook=$(test -x "$REPO3/.git/hooks/pre-commit" && echo yes || echo no)" "hook=yes"
assert_contains "nothing written beside the repo" "stray=$(test -e "$WORK/.git" && echo yes || echo no)" "stray=no"

echo "# the project's own git calls don't touch the commit's index"
REPO4="$WORK/repo4"; mkdir -p "$REPO4"; git -C "$REPO4" init -q; echo a > "$REPO4/a.txt"; git -C "$REPO4" add a.txt
git -C "$REPO4" -c user.email=t@t -c user.name=t commit -qm base
cat > "$REPO4/inner-git-test.sh" <<'T'
D=$(mktemp -d) && git -C "$D" init -q && echo x > "$D/inner.txt" && git -C "$D" add inner.txt && rm -rf "$D"
T
echo 'bash inner-git-test.sh' > "$REPO4/.dev-os-test"; (cd "$REPO4" && "$GATE" >/dev/null 2>&1)
echo b >> "$REPO4/a.txt"
assert_contains "commit -a with a git-using test suite goes through" "$(git -C "$REPO4" -c user.email=t@t -c user.name=t commit -qam inner 2>&1; echo "[rc=$?]")" "[rc=0]"

echo "# a global core.hooksPath is not ours to change"
HP="$WORK/globalhooks"; mkdir -p "$HP"; printf '[core]\n\thooksPath = %s\n' "$HP" > "$WORK/gcfg"
REPO5="$WORK/repo5"; mkdir -p "$REPO5"; git -C "$REPO5" init -q; echo true > "$REPO5/.dev-os-test"
OUT=$(cd "$REPO5" && GIT_CONFIG_GLOBAL="$WORK/gcfg" "$GATE" 2>&1); RC=$?
assert_contains "refuses a hooks folder outside this repo" "[rc=$RC]" "[rc=1]"
assert_contains "nothing written to the global hooks folder" "files=$(ls "$HP" | wc -l | tr -d ' ')" "files=0"
assert_contains "says why" "$OUT" "core.hooksPath"

echo "# a global core.hooksPath that does not exist yet is refused too"
HP2="$WORK/not-yet-hooks"; printf '[core]\n\thooksPath = %s\n' "$HP2" > "$WORK/gcfg2"
REPO6="$WORK/repo6"; mkdir -p "$REPO6"; git -C "$REPO6" init -q; echo true > "$REPO6/.dev-os-test"
(cd "$REPO6" && GIT_CONFIG_GLOBAL="$WORK/gcfg2" "$GATE" >/dev/null 2>&1); RC=$?
assert_contains "missing global hooks folder: install refused" "[rc=$RC]" "[rc=1]"
assert_contains "missing global hooks folder: not created" "made=$(test -e "$HP2" && echo yes || echo no)" "made=no"

echo "# never overwrites a hook it did not write"
REPO2="$WORK/repo2"; mkdir -p "$REPO2/.git/hooks"; git -C "$REPO2" init -q
printf '#!/bin/sh\necho husky\n' > "$REPO2/.git/hooks/pre-commit"; echo 'true' > "$REPO2/.dev-os-test"
OUT=$(cd "$REPO2" && "$GATE" 2>&1); RC=$?
assert_contains "foreign hook: install refused" "[rc=$RC]" "[rc=1]"
assert_contains "foreign hook kept" "$(cat "$REPO2/.git/hooks/pre-commit")" "husky"
summary
