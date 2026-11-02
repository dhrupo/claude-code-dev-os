#!/bin/bash
. "$(dirname "$0")/dedupe.sh"
# Stop: mistakes logged this session (corrections, guard catches) newer than the last reflect block once per set.
PY="$(dirname "$0")/learn.py"
[ -f "$PY" ] || { echo "dev-os: learn.py missing, copy hooks/*.py" >&2; exit 0; }
exec python3 "$PY"
