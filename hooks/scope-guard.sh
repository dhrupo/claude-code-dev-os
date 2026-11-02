#!/bin/bash
. "$(dirname "$0")/dedupe.sh"
# PostToolUse: warn (never block) when an edit lands on a file the active plan's scope.txt does not list.
# Active plan = the path stored in <git-dir>/dev-os-scope (written by the plan skill).
PY="$(dirname "$0")/scope-guard.py"
[ -f "$PY" ] || { echo '{"systemMessage":"dev-os: scope-guard.py missing, copy hooks/*.py"}'; exit 0; }
exec python3 -I "$PY"
