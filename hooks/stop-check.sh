#!/bin/bash
# Stop: with an active plan, send Claude back once per new set of problems
# (files outside scope.txt, including Bash edits, or source changed with no test changed).
exec python3 -c '
import hashlib, json, os, re, subprocess, sys
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
problems = unplanned + (["NO_TEST"] if no_test else [])
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
parts.append("This fires once per new set of problems.")
print(json.dumps({"decision": "block", "reason": " ".join(parts)}))
'
