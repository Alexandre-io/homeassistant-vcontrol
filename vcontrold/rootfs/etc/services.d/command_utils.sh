#!/usr/bin/with-contenv bashio

load_vcontrold_commands_array() {
    local commands_raw=${1-}
    local -n output_array=$2

    output_array=()
    mapfile -t output_array <<< "${commands_raw}"

    if (( ${#output_array[@]} == 1 )) && [[ "${output_array[0]}" == *'|'* ]]; then
        IFS='|' read -r -a output_array <<< "${output_array[0]}"
    fi
}

parse_vcontrold_command_entry() {
    local command_entry=${1-}
    local default_refresh=${2-}
    local -n output_command=$3
    local -n output_type=$4
    local -n output_refresh=$5

    if [[ ! "${command_entry}" =~ ^([a-zA-Z][a-zA-Z0-9_]*):(FLOAT|STRING)(:([1-9][0-9]{0,4}))?$ ]]; then
        return 1
    fi

    output_command=${BASH_REMATCH[1]}
    output_type=${BASH_REMATCH[2]}
    output_refresh=${BASH_REMATCH[4]:-${default_refresh}}

    if [[ ! "${output_refresh}" =~ ^[1-9][0-9]{0,4}$ ]] || (( output_refresh > 86400 )); then
        return 1
    fi
}
