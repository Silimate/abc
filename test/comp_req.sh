#!/usr/bin/env bash
# Regression test for &if/&nf -P: an output is relaxed only to the latest output it
# shares logic with. A 16-request priority arbiter sits beside a 64-step and/or
# chain. Without -P, area recovery relaxes the arbiter to the chain's depth; with
# -P it keeps its own, unless the two cones share a gate.

set -eu

ABC=${ABC:-./abc}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }

# $1 = output file, $2 = signal the chain starts from (c0: independent,
# r0: shares an input, s7: shares an arbiter gate)
gen() {
    local i
    {
        echo ".model t"
        printf ".inputs"; for i in $(seq 0 15); do printf " r$i b$i"; done
        for i in $(seq 0 64); do printf " a$i c$i"; done; echo
        printf ".outputs"; for i in $(seq 0 15); do printf " g$i"; done; echo " z"
        for i in $(seq 0 15); do printf ".names r$i b$i e$i\n10 1\n"; done
        printf ".names e0 g0\n1 1\n.names e0 s0\n1 1\n"
        for i in $(seq 1 15); do
            printf ".names e$i s$((i-1)) g$i\n10 1\n.names e$i s$((i-1)) s$i\n1- 1\n-1 1\n"
        done
        printf ".names $2 z0\n1 1\n"
        for i in $(seq 1 64); do printf ".names z$((i-1)) a$i c$i z$i\n11- 1\n--1 1\n"; done
        printf ".names z64 z\n1 1\n.end\n"
    } > "$1"
}

cat > "$TMP/unit.genlib" <<'LIB'
GATE ZERO 1 Y=CONST0;
GATE ONE 1 Y=CONST1;
GATE BUF 1 Y=A; PIN * NONINV 1 999 1 0 1 0
GATE NOT 1 Y=!A; PIN * INV 1 999 1 0 1 0
GATE NAND 2 Y=!(A*B); PIN * INV 1 999 1 0 1 0
GATE NOR 2 Y=!(A+B); PIN * INV 1 999 1 0 1 0
GATE AOI3 3 Y=!((A*B)+C); PIN * INV 1 999 1 0 1 0
GATE OAI3 3 Y=!((A+B)*C); PIN * INV 1 999 1 0 1 0
LIB

# depth of the arbiter outputs after mapping with $2
depth() {
    "$ABC" -q "read_blif $1; read_library $TMP/unit.genlib; strash; &get -n; $2; &put; cone -O 0 -R 16; cleanup; ps" |
        tail -1 | sed 's/.*lev = *//'
}

check() {
    local name=$1 src=$2 map=$3 expect=$4 d0 d1
    gen "$TMP/$name.blif" "$src"
    d0=$(depth "$TMP/$name.blif" "$map")
    d1=$(depth "$TMP/$name.blif" "$(echo "$map" | sed -e 's/&if [^;]*/& -P/g' -e 's/&nf[^;]*/& -P/g')")
    case $expect in
        shallower) [ "$d1" -lt "$d0" ] || fail "$name: -P depth $d1, without $d0" ;;
        same)      [ "$d1" -eq "$d0" ] || fail "$name: -P depth $d1, without $d0" ;;
    esac
    echo "PASS: $name ($map: $d0 -> $d1)"
}

check if_independent    c0 "&if -K 4"                          shallower
check nf_independent    c0 "&nf"                               shallower
check nf_choices        c0 "&st; &if -g -K 6; &synch2; &nf"    shallower
check nf_shared_input   r0 "&nf"                               shallower
check if_shared_gate    s7 "&if -K 4"                          same
check nf_shared_gate    s7 "&nf"                               same

# A boxed network, as Yosys's abc9 hands it over (comp_req_box.v): arbiter g shares no logic
# with a 64-step chain, and arbiter g2 starts the chain through a box. -P relaxes g only to its
# own depth, or with -D to the target; g2 keeps the chain's, since a box joins the logic on
# either side of it.
printf "1 1 1\n2 1 1\n3 1 1\n4 1 1\n5 1 1\n6 1 1\n" > "$TMP/lut6.txt"
printf "bx 4 1 2 1\n#a b\n1 1 # y\n" > "$TMP/bx.box"

# depth of the 16 outputs from CO $1 after &if $2 (g2 starts at CO 5, g at CO 21)
box_depth() {
    "$ABC" -q "read_lut $TMP/lut6.txt; read_box $TMP/bx.box; &read $(dirname "$0")/comp_req_box.xaig; &st; &if -g -K 6; &synch2; &if $2; &put; cone -O $1 -R 16; cleanup; ps" |
        tail -1 | sed 's/.*lev = *//'
}

d0=$(box_depth 21 ""); d1=$(box_depth 21 -P); d2=$(box_depth 21 "-P -D 6")
[ "$d1" -lt "$d0" ] || fail "box_independent: -P depth $d1, without $d0"
echo "PASS: box_independent (&if: $d0 -> $d1)"
[ "$d1" -lt "$d2" ] && [ "$d2" -le 6 ] || fail "box_floor: -P -D 6 depth $d2, -P $d1"
echo "PASS: box_floor (&if -P -D 6: $d2)"
d0=$(box_depth 5 ""); d1=$(box_depth 5 -P)
[ "$d1" -eq "$d0" ] || fail "box_coupled: -P depth $d1, without $d0"
echo "PASS: box_coupled (&if: $d0 -> $d1)"

echo "All regression tests passed."
