#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

source "${repo_root}/tests/lib/assert.sh"
source "${repo_root}/vcontrold/rootfs/etc/services.d/command_utils.sh"
source "${repo_root}/vcontrold/rootfs/etc/services.d/write_utils.sh"

match() {
    setter_readback_matches "$1" "$2" && printf 0 || printf '%s' "$?"
}

assert_eq 0 "$(match 26 '26.000000 Grad Celsius')" "integer setter matches float read-back"
assert_eq 0 "$(match 1.4 '1.400000')" "decimal setter matches"
assert_eq 0 "$(match 1.45 '1.400000')" "unit rounding within 0.05 matches"
assert_eq 1 "$(match 26 '10.000000 Grad Celsius')" "different number is a mismatch"
assert_eq 1 "$(match 44 '43.000000 Grad Celsius')" "one degree off is a mismatch"
assert_eq 0 "$(match -3 '-3.000000 K')" "negative values match"
assert_eq 0 "$(match 'H+WW' 'H+WW')" "enum text matches"
assert_eq 0 "$(match 'H+WW FS' ' H+WW  FS ')" "enum text ignores surrounding and repeated whitespace"
assert_eq 1 "$(match 'H+WW FS' 'H+WW')" "different enum text is a mismatch"
assert_eq 1 "$(match 'WW' 'ww')" "enum text is case-sensitive"
assert_eq 2 "$(match 1 'H+WW')" "number read back as text is not comparable"
assert_eq 2 "$(match '00:00 24:00' $'1:An:00:00  Aus:24:00\n2:An:--')" "multi-line timers are not comparable"
assert_eq 2 "$(match 26 '')" "empty read-back is not comparable"

assert_eq "a b" "$(normalize_text $'  a \t b  ')" "normalize_text collapses whitespace"
assert_eq "x | y" "$(single_line $'x\ny')" "single_line joins lines"

declare -A types=()
load_getter_types $'getTempWWsoll:FLOAT\ngetBetriebArtM2:STRING\nbad entry\ngetX:INT\nsetFoo:FLOAT' types
assert_eq 2 "${#types[@]}" "only valid polled getters are mapped"
assert_eq FLOAT "${types[getTempWWsoll]}" "FLOAT getter type"
assert_eq STRING "${types[getBetriebArtM2]}" "STRING getter type"

ack=$(setter_ack_json fail setTempWWsoll 44 '43.000000 Grad Celsius' 3 $'quote " and\nnewline')
assert_eq fail "$(jq -r .status <<< "${ack}")" "ack status"
assert_eq 3 "$(jq -r .attempts <<< "${ack}")" "ack attempts is a number"
assert_eq $'quote " and\nnewline' "$(jq -r .error <<< "${ack}")" "ack error survives JSON encoding"

printf 'PASS: %s\n' "$(basename "$0")"
