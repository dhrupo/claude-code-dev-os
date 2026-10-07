#!/bin/bash
# Run every test file; exit non-zero if any fails.
cd "$(dirname "$0")" || exit 2
rc=0
for t in ./*.test.sh; do echo "== $t"; bash "$t" || rc=1; done
exit $rc
