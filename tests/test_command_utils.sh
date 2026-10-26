#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

source "${repo_root}/tests/lib/assert.sh"
source "${repo_root}/vcontrold/rootfs/etc/services.d/command_utils.sh"

declare -a commands_array=()

load_vcontrold_commands_array $'getTempA:FLOAT\ngetTempWWist:FLOAT\ngetTempWWsoll:FLOAT' commands_array
assert_eq "3" "${#commands_array[@]}" "multiline command count"
assert_eq "getTempA:FLOAT" "${commands_array[0]}" "multiline first command"
assert_eq "getTempWWist:FLOAT" "${commands_array[1]}" "multiline second command"
assert_eq "getTempWWsoll:FLOAT" "${commands_array[2]}" "multiline third command"

load_vcontrold_commands_array 'getTempA:FLOAT|getTempWWist:FLOAT|getTempWWsoll:FLOAT' commands_array
assert_eq "3" "${#commands_array[@]}" "pipe-delimited command count"
assert_eq "getTempA:FLOAT" "${commands_array[0]}" "pipe-delimited first command"
assert_eq "getTempWWist:FLOAT" "${commands_array[1]}" "pipe-delimited second command"
assert_eq "getTempWWsoll:FLOAT" "${commands_array[2]}" "pipe-delimited third command"

declare parsed_command parsed_type parsed_refresh

parse_vcontrold_command_entry "getTempA:FLOAT" 60 parsed_command parsed_type parsed_refresh
assert_eq "getTempA" "${parsed_command}" "default interval command"
assert_eq "FLOAT" "${parsed_type}" "default interval type"
assert_eq "60" "${parsed_refresh}" "default interval refresh"

parse_vcontrold_command_entry "getTimerWWMo:STRING:3600" 60 parsed_command parsed_type parsed_refresh
assert_eq "getTimerWWMo" "${parsed_command}" "explicit interval command"
assert_eq "STRING" "${parsed_type}" "explicit interval type"
assert_eq "3600" "${parsed_refresh}" "explicit interval refresh"

for invalid in "getTempA:FLOAT:0" "getTempA:FLOAT:86401" "getTempA:BAD:5" "bad command:FLOAT:5" "getTempA:FLOAT:5:extra"; do
    if parse_vcontrold_command_entry "${invalid}" 60 parsed_command parsed_type parsed_refresh; then
        fail "invalid command entry accepted: ${invalid}"
    fi
done

printf 'PASS: %s\n' "$(basename "$0")"
