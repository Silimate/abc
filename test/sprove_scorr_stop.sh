#!/usr/bin/env bash
# Regression test for &sprove trusting an interrupted &scorr reduction as a proof.
# sprove_scorr_stop.aig (from sprove_scorr_stop.v) is a non-equivalent miter: output P is 0
# until cycle 120 (bmc3 asserts it in frame 120). When a solver engine finds the CEX it
# trips &scorr's stop callback mid-sweep; before the fix &sprove reported the collapsed
# reduction as "UNSATISFIABLE (solved by scnew)". The trigger is a race, so we retry below.

set -eu

ABC=${ABC:-./abc}
HERE=$(dirname "$0")
AIG="$HERE/sprove_scorr_stop.aig"

fail() { echo "FAIL: $1" >&2; exit 1; }

# Ground truth: the miter is non-equivalent (output asserted at frame 120).
bmc=$("$ABC" -q "read_aiger $AIG; bmc3 -F 160" 2>&1) || true
echo "$bmc" | grep -q "asserted in frame 120" || { echo "$bmc" >&2; fail "bmc3 did not find the expected counterexample"; }
echo "PASS: bmc3 shows the miter is non-equivalent (frame 120)"

# &sprove must never prove this non-equivalent miter UNSAT.
for i in 1 2 3 4 5 6 7 8; do
    out=$("$ABC" -q "&read $AIG; &sprove -T 1" 2>&1) || true
    verdict=$(echo "$out" | grep -oE "is (SATISFIABLE|UNSATISFIABLE) \(solved by [a-z-]+\)|is UNDECIDED" | tail -1)
    [ -n "$verdict" ] || { echo "$out" >&2; fail "&sprove produced no verdict (run $i)"; }
    echo "  run $i: $verdict"
    echo "$out" | grep -q "is UNSATISFIABLE" && { echo "$out" >&2; fail "&sprove falsely reported UNSATISFIABLE on a non-equivalent miter"; }
done

echo "All regression tests passed."
