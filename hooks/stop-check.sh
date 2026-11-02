#!/bin/bash
. "$(dirname "$0")/dedupe.sh"
# Stop: with an active plan, send Claude back once per new set of problems (unplanned files, no test, weakened test).
# Each block is logged for learn.sh, so the mistake gets a reflect.
exec python3 -c '
import hashlib, json, os, re, subprocess, sys, time
from fnmatch import fnmatch

try:
    ev = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if ev.get("stop_hook_active"):
    sys.exit(0)

def git(*args):
    r = subprocess.run(["git", "-C", ev.get("cwd") or os.getcwd(), *args], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else ""

top, gitdir = git("rev-parse", "--show-toplevel").strip(), git("rev-parse", "--absolute-git-dir").strip()
if not top or not gitdir:
    sys.exit(0)
pointer = os.path.join(gitdir, "dev-os-scope")
try:
    scope = open(pointer).read().strip()
    allowed = [l.strip() for l in open(scope) if l.strip() and not l.lstrip().startswith("#")]
except OSError:
    sys.exit(0)

entries = git("status", "--porcelain", "-uall", "-z").split("\0")
changed, i = [], 0
while i < len(entries):
    e = entries[i]
    if len(e) > 3:
        changed.append(e[3:])
        if e[0] in "RC":
            i += 1
    i += 1
if not changed:
    sys.exit(0)

TEST = re.compile(r"(^|/)(tests?|__tests__|e2e|spec)/|(Test\.php|\.test\.\w+|\.spec\.\w+)$|(^|/)test_[^/]*\.py$")
SRC = re.compile(r"\.(php|js|mjs|cjs|ts|tsx|jsx|vue|py|rb|go|rs|sh|css|scss)$")
unplanned = sorted(p for p in changed if not any(fnmatch(p, a) for a in allowed))
no_test = any(SRC.search(p) and not TEST.search(p) for p in changed) and not any(TEST.search(p) for p in changed)
ASSERT = re.compile(r"\bassert\w*\s*\(|\bexpect\s*\(|->assert\w*\(|\$this->assert|^[-+]\s*assert(_\w+)?\s")
SKIP = re.compile(r"markTestSkipped|markTestIncomplete|->skip\(|\.(skip|only|fixme)\s*\(|\bx(it|describe|test)\s*\(")
in_head = lambda p: subprocess.run(["git", "-C", top, "cat-file", "-e", "HEAD:" + p], capture_output=True).returncode == 0
weakened = []
for p in changed:
    if not TEST.search(p) or not in_head(p):
        continue
    if not os.path.exists(os.path.join(top, p)):
        if not any(q != p and os.path.basename(q) == os.path.basename(p) for q in changed):
            weakened.append(p + " (deleted)")
        continue
    lines = git("diff", "-U0", "HEAD", "--", p).splitlines()
    rm = [l for l in lines if l.startswith("-") and not l.startswith("---")]
    add = [l for l in lines if l.startswith("+") and not l.startswith("+++")]
    if sum(bool(ASSERT.search(l)) for l in rm) > sum(bool(ASSERT.search(l)) for l in add) or any(SKIP.search(l) for l in add):
        weakened.append(p)
problems = unplanned + (["NO_TEST"] if no_test else []) + ["W:" + w for w in weakened]
if not problems:
    sys.exit(0)

key = hashlib.sha1("\n".join([scope] + problems).encode()).hexdigest()
seen = pointer + ".warned"
if os.path.exists(seen) and open(seen).read().strip() == key:
    sys.exit(0)
open(seen, "w").write(key)

plan = os.path.basename(os.path.dirname(scope))
parts = [f"STOP CHECK (plan \"{plan}\")."]
if unplanned:
    parts.append("UNPLANNED files changed: " + ", ".join(unplanned) + ". Tell the user why each had to change and ask: keep (add to scope.txt) or revert.")
if no_test:
    parts.append("NO TEST CHANGED: source files changed but no test file did. Write the failing test, or say plainly why none is needed.")
if weakened:
    parts.append("TEST WEAKENED: " + ", ".join(weakened) + " (fewer assertions, a new skip/only, or deleted). Restore it, or tell the user exactly why the test was wrong.")
parts.append("This fires once per new set of problems.")
sid = ev.get("session_id")
if sid:
    state = os.environ.get("DEV_OS_STATE") or os.path.expanduser("~/.claude/state")
    os.umask(0o077)
    os.makedirs(state, exist_ok=True)
    with open(os.path.join(state, "learn-" + sid + ".jsonl"), "a") as f:
        f.write(json.dumps({"time": int(time.time() * 1000), "type": "guard", "note": ", ".join(problems)[:200]}) + "\n")
print(json.dumps({"decision": "block", "reason": " ".join(parts)}))
'
