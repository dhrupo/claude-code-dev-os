#!/bin/bash
# PostToolUse: warn (never block) when an edit lands on a file the active plan's scope.txt does not list.
# Active plan = the path stored in <git-dir>/dev-os-scope (written by the plan skill).
exec python3 -c '
import json, os, subprocess, sys
from fnmatch import fnmatch

try:
    ev = json.load(sys.stdin)
except Exception:
    sys.exit(0)
inp = ev.get("tool_input") or {}
path = inp.get("file_path") or inp.get("notebook_path")
if not path:
    sys.exit(0)
path = os.path.realpath(os.path.join(ev.get("cwd") or os.getcwd(), path))

base = os.path.dirname(path)
while not os.path.isdir(base):
    base = os.path.dirname(base)

def git(*args):
    r = subprocess.run(["git", "-C", base, *args], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""

top, gitdir = git("rev-parse", "--show-toplevel"), git("rev-parse", "--absolute-git-dir")
if not top or not gitdir:
    sys.exit(0)
pointer = os.path.join(gitdir, "dev-os-scope")
try:
    scope = open(pointer).read().strip()
    allowed = [l.strip() for l in open(scope) if l.strip() and not l.lstrip().startswith("#")]
except OSError:
    sys.exit(0)

rel = os.path.relpath(path, os.path.realpath(top))
if any(fnmatch(rel, pat) for pat in allowed):
    sys.exit(0)

plan = os.path.basename(os.path.dirname(scope))
msg = (f"UNPLANNED FILE: {rel} is not in the scope of plan \"{plan}\" ({scope}). "
       "The edit went through. Tell the user in one line why this file had to change and ask whether "
       "to keep it (then add it to scope.txt) or revert it. If that plan is finished, delete " + pointer + ".")
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}))
'
