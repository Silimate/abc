#!/usr/bin/env bash
# Regression test for &sprove treating a reduction with no AND nodes as a proof.
# sprove_const_po.aig (from sprove_const_po.v) is a non-equivalent miter whose output P is
# asserted in frame 1. &scorr reduces it to no AND nodes with P driven by a flop; before the
# fix &sprove reported that as "UNSATISFIABLE (solved by scnew)".

set -eu

ABC=${ABC:-./abc}
HERE=$(dirname "$0")
AIG="$HERE/sprove_const_po.aig"

fail() { echo "FAIL: $1" >&2; exit 1; }

# Ground truth: the miter is non-equivalent (output asserted at frame 1).
bmc=$("$ABC" -q "read_aiger $AIG; bmc3 -F 10" 2>&1) || true
echo "$bmc" | grep -q "asserted in frame 1" || { echo "$bmc" >&2; fail "bmc3 did not find the expected counterexample"; }
echo "PASS: bmc3 shows the miter is non-equivalent (frame 1)"

# &sprove must report it SATISFIABLE, never UNSATISFIABLE.
for i in 1 2 3; do
    out=$("$ABC" -q "&read $AIG; &sprove" 2>&1) || true
    verdict=$(echo "$out" | grep -oE "is (SATISFIABLE|UNSATISFIABLE) \(solved by [a-z-]+\)|is UNDECIDED" | tail -1)
    [ -n "$verdict" ] || { echo "$out" >&2; fail "&sprove produced no verdict (run $i)"; }
    echo "  run $i: $verdict"
    echo "$out" | grep -q "is SATISFIABLE" || { echo "$out" >&2; fail "&sprove did not report the non-equivalent miter SATISFIABLE"; }
done

echo "All regression tests passed."
