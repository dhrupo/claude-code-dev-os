#!/bin/bash
. "$(dirname "$0")/dedupe.sh"
# Stop: with an active plan, send Claude back once per new set of problems (unplanned files, no test, weakened test).
# Each block is logged for learn.sh, so the mistake gets a reflect.
PY="$(dirname "$0")/stop-check.py"
[ -f "$PY" ] || { echo '{"systemMessage":"dev-os: stop-check.py missing, copy hooks/*.py"}'; exit 0; }
exec python3 -I "$PY"
