#!/usr/bin/env bash
# Regression test for a soundness bug in "&sprove": an interrupted signal-correspondence
# reduction must not be trusted as a proof.
#
# sprove_scorr_stop.aig (built from sprove_scorr_stop.v) is a sequential miter whose single
# output P is 0 for the first 120 cycles and becomes 1 at cycle 120, so it is NOT equivalent
# (P is SATISFIABLE). bmc3 confirms this by asserting the output in frame 120. Under the
# shallow random simulation used by signal correspondence every flop looks like a constant-0
# candidate, so a "&scorr" sweep that is interrupted before it converges merges them all and
# collapses the miter to 0 ANDs.
#
# Before the fix, when a solver engine found the real counterexample it tripped the stop
# callback, and &sprove reported the collapsed reduction as "UNSATISFIABLE (solved by scnew)"
# -- a false proof, overwriting the correct SATISFIABLE. After the fix, an interrupted
# reduction is discarded, so &sprove never reports UNSAT here.
#
# The trigger is a race between a solver engine and the reduction, so we run &sprove several
# times; a single false UNSAT in any run is a failure.

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
    echo "  run $i: ${verdict:-<no verdict>}"
    echo "$out" | grep -q "is UNSATISFIABLE" && { echo "$out" >&2; fail "&sprove falsely reported UNSATISFIABLE on a non-equivalent miter"; }
done

echo "All regression tests passed."
