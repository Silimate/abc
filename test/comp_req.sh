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


# A hub: nine 9-input cones b share only one AND gate (rdy = ar & br, 10 fanouts) with a
# 258-input cone a. -P joins them in one group, so area recovery relaxes b toward a's depth;
# -H 8 keeps the hub out of the groups and b at its own depth, -H 16 does not, and -Q 20 caps b
# near its own delay-optimal arrival unless -D floors it higher.
# $1 = output name, then the signals: a balanced XOR tree
xtree() {
    local out=$1 lvl=0 i next; shift
    local sigs=("$@")
    while [ ${#sigs[@]} -gt 1 ]; do
        next=()
        for ((i = 0; i + 1 < ${#sigs[@]}; i += 2)); do
            printf ".names %s %s %s_%d_%d\n10 1\n01 1\n" "${sigs[i]}" "${sigs[i+1]}" "$out" $lvl $i
            next+=("${out}_${lvl}_$i")
        done
        [ $((${#sigs[@]} % 2)) -eq 0 ] || next+=("${sigs[${#sigs[@]}-1]}")
        sigs=("${next[@]}"); lvl=$((lvl + 1))
    done
    printf ".names %s %s\n1 1\n" "${sigs[0]}" "$out"
}
{
    echo ".model hub"
    printf ".inputs ar br"; for i in $(seq 0 15); do printf " x$i"; done
    for i in $(seq 0 255); do printf " y$i"; done; echo
    printf ".outputs"; for i in $(seq 0 8); do printf " b$i"; done; echo " a"
    printf ".names ar br rdy\n11 1\n"
    for i in $(seq 0 8); do
        xtree xb$i $(for k in $(seq $i $((i + 7))); do printf " x$k"; done)
        printf ".names rdy xb$i b$i\n11 1\n"
    done
    xtree xa $(for k in $(seq 0 255); do printf " y$k"; done)
    printf ".names rdy xa a\n11 1\n.end\n"
} > "$TMP/hub.blif"

# depth of the b outputs (or with $2 = a, of a) after the abc9 flow's mapping with &if $1
hub_depth() {
    local cone="-O 0 -R 9"; [ "${2:-}" = a ] && cone="-O 9 -R 1"
    "$ABC" -q "read_blif $TMP/hub.blif; strash; &get -n; &st; &if -g -K 6; &synch2; &if -K 6 $1; &put; cone $cone; cleanup; ps" |
        tail -1 | sed 's/.*lev = *//'
}

dp=$(hub_depth -P); d8=$(hub_depth "-P -H 8"); d16=$(hub_depth "-P -H 16"); dq=$(hub_depth "-P -Q 20")
[ "$d8" -lt "$dp" ] || fail "hub_cap: -P -H 8 depth $d8, -P $dp"
echo "PASS: hub_cap (&if -P: $dp -> -P -H 8: $d8)"
[ "$d16" -eq "$dp" ] || fail "hub_below_cap: -P -H 16 depth $d16, -P $dp"
echo "PASS: hub_below_cap (&if -P -H 16: $d16)"
[ "$dq" -lt "$dp" ] || fail "hub_slack: -P -Q 20 depth $dq, -P $dp"
echo "PASS: hub_slack (&if -P -Q 20: $dq)"
da=$(hub_depth -P a); d=$(hub_depth "-P -Q 20 -D $da")
[ "$d" -eq "$(hub_depth "-P -D $da")" ] || fail "hub_slack_floor: -P -Q 20 -D $da depth $d"
echo "PASS: hub_slack_floor (&if -P -Q 20 -D $da: $d)"
for f in "-H 8" "-Q 20"; do
    [ "$(hub_depth "-P $f" a)" -eq "$da" ] || fail "hub_deep: -P $f changes a's depth $da"
done
echo "PASS: hub_deep (a: $da)"
"$ABC" -q "read_blif $TMP/hub.blif; strash; &get -n; &if -K 6 -Q 20" 2>&1 | grep -q 'only with "-P"' ||
    fail "hub_needs_P: &if -Q without -P"
echo "PASS: hub_needs_P"
# A hub counted by all its fanouts: rdy drives nine outputs directly and one AND into a deep
# cone, so only one of its ten fanouts is an AND. -H 8 still keeps it out of the groups (h at its
# own depth); -H 16 does not.
{
    echo ".model cohub"
    printf ".inputs"; for i in $(seq 0 15); do printf " x$i"; done
    for i in $(seq 0 255); do printf " y$i"; done; echo
    printf ".outputs"; for i in $(seq 0 8); do printf " h$i"; done; echo " a"
    xtree rdy $(for k in $(seq 0 15); do printf " x$k"; done)
    for i in $(seq 0 8); do printf ".names rdy h$i\n1 1\n"; done
    xtree xa $(for k in $(seq 0 255); do printf " y$k"; done)
    printf ".names rdy xa a\n11 1\n.end\n"
} > "$TMP/cohub.blif"
cohub_depth() {
    "$ABC" -q "read_blif $TMP/cohub.blif; strash; &get -n; &st; &if -g -K 6; &synch2; &if -K 6 $1; &put; cone -O 0 -R 9; cleanup; ps" |
        tail -1 | sed 's/.*lev = *//'
}
dp=$(cohub_depth -P); d8=$(cohub_depth "-P -H 8"); d16=$(cohub_depth "-P -H 16")
[ "$d8" -lt "$dp" ] && [ "$d16" -eq "$dp" ] || fail "hub_co_fanouts: -P $dp, -P -H 8 $d8, -P -H 16 $d16"
echo "PASS: hub_co_fanouts (&if -P: $dp -> -P -H 8: $d8)"
for f in -Q -H; do
    "$ABC" -q "read_blif $TMP/hub.blif; strash; &get -n; &if -K 6 $f -P" 2>&1 | grep -q 'nonnegative integer' ||
        fail "hub_missing_value: &if $f -P took -P as its value"
done
echo "PASS: hub_missing_value"

echo "All regression tests passed."
