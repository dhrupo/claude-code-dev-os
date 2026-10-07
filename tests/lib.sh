#!/bin/bash
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
assert_contains()     { if printf '%s' "$2" | grep -qF -- "$3"; then ok "$1"; else bad "$1 (expected: $3)"; fi; }
assert_not_contains() { if printf '%s' "$2" | grep -qF -- "$3"; then bad "$1 (unexpected: $3)"; else ok "$1"; fi; }
summary() { echo "passed $PASS, failed $FAIL"; [ "$FAIL" -eq 0 ]; }
