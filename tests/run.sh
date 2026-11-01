#!/bin/bash
# Run every test file; exit non-zero if any fails or README's check count is stale.
cd "$(dirname "$0")" || exit 2
rc=0; total=0
for t in ./*.test.sh; do
  echo "== $t"
  out=$(bash "$t"); r=$?; printf '%s\n' "$out"; [ $r -eq 0 ] || rc=1
  n=$(printf '%s\n' "$out" | sed -n 's/^passed \([0-9]*\), failed \([0-9]*\)$/\1 \2/p' | tail -1)
  [ -n "$n" ] || { echo "$t printed no 'passed N, failed M' line" >&2; rc=1; n="0 0"; }
  total=$((total + ${n% *} + ${n#* }))
done
[ -s .private-patterns ] && total=$((total - 1))   # the private-names check runs only with this git-ignored file
want=$(sed -n 's/^| `tests\/` | \([0-9]*\) checks.*/\1/p' ../README.md)
echo "== total: $total checks (README says ${want:-?})"
[ "$want" = "$total" ] || { echo "README check count is stale: README says ${want:-nothing}, the suite ran $total" >&2; rc=1; }
exit $rc
