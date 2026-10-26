#!/usr/bin/env bash
# Regression test for &if on a boxed network with choices. Choices are computed with box
# outputs as free inputs, so &synch2 and &dch make z of box_choices.v, built from the box
# output, a choice for the box input it equals. Ordering the network by its boxes then
# failed ("Boxes are not in a topological order"); the choice is now dropped instead.

set -eu

ABC=${ABC:-./abc}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }

printf "1 1 1\n2 1 1\n3 1 1\n4 1 1\n" > "$TMP/lut4.txt"
printf "bx 4 1 1 1\n#a\n1 # y\n" > "$TMP/bx.box"

for choices in "&synch2" "&dch -f"; do
    out=$("$ABC" -q "read_lut $TMP/lut4.txt; read_box $TMP/bx.box; &read $(dirname "$0")/box_choices.xaig; &st; $choices; &ps; &if -K 4; &verify" 2>&1) || true
    echo "$out" | grep -q "ch = *1 " || { echo "$out" >&2; fail "$choices: no choice to drop"; }
    echo "$out" | grep -q "Networks are equivalent" || { echo "$out" >&2; fail "$choices: &if"; }
    echo "PASS: $choices"
done

echo "All regression tests passed."
