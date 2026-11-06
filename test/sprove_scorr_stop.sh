#!/usr/bin/env bash
# Regression test for a soundness bug in "&sprove": an interrupted signal-correspondence
# reduction must not be trusted as a proof.
#
# sprove_scorr_stop.aig (built from sprove_scorr_stop.v) is a sequential miter whose single
# output P is 0 for the first 120 cycles and becomes 1 at cycle 120, so it is NOT equivalent
# (P is SATISFIABLE). bmc3 confirms this by asserting the output in frame 120. Under shallow
# random simulation every flop looks like a constant-0 candidate, so a "&scorr" sweep that is
# interrupted before it converges merges them all and collapses the miter to 0 ANDs.
#
# Before the fix, "&sprove -T 1" interrupted the reduction and reported the collapsed miter as
# "UNSATISFIABLE (solved by scnew)" -- a false proof of equivalence. After the fix, an
# interrupted reduction is discarded, so &sprove never reports UNSAT here.

set -eu

ABC=${ABC:-./abc}
HERE=$(dirname "$0")
AIG="$HERE/sprove_scorr_stop.aig"

fail() { echo "FAIL: $1" >&2; exit 1; }

# Ground truth: the miter is non-equivalent (output asserted at frame 120).
bmc=$("$ABC" -q "read_aiger $AIG; bmc3 -F 160" 2>&1) || true
echo "$bmc" | grep -q "asserted in frame 120" || { echo "$bmc" >&2; fail "bmc3 did not find the expected counterexample"; }
echo "PASS: bmc3 shows the miter is non-equivalent (frame 120)"

# &sprove must not prove this non-equivalent miter UNSAT, no matter how short -T is.
for t in 1 2 3; do
    out=$("$ABC" -q "&read $AIG; &sprove -T $t" 2>&1) || true
    echo "$out" | grep -q "is UNSATISFIABLE" && { echo "$out" >&2; fail "&sprove -T $t falsely reported UNSATISFIABLE"; }
    echo "PASS: &sprove -T $t did not falsely prove the miter (`echo "$out" | grep -oE 'is (SATISFIABLE|UNSATISFIABLE) \(solved by [a-z-]+\)|is UNDECIDED' | tail -1`)"
done

echo "All regression tests passed."
