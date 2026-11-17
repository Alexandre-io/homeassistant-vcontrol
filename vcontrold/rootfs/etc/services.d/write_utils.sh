#!/usr/bin/with-contenv bashio
# Helpers for verified setter writes. Sourcing this file has no side effects.

# Map every polled getter to its configured publication type (FLOAT or STRING).
# Usage: load_getter_types "<commands option>" <associative array name>
load_getter_types() {
    local commands_raw=${1-}
    local -n output_map=$2
    local -a entries=()
    local entry name type

    output_map=()
    load_vcontrold_commands_array "${commands_raw}" entries
    for entry in "${entries[@]}"; do
        [[ "${entry}" == *:* ]] || continue
        name=${entry%%:*}
        type=${entry#*:}
        if [[ "${name}" =~ ^get[a-zA-Z0-9_]+$ && "${type}" =~ ^(FLOAT|STRING)$ ]]; then
            output_map["${name}"]=${type}
        fi
    done
}

is_decimal() {
    [[ "${1-}" =~ ^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]]
}

# Trim surrounding whitespace and collapse inner whitespace runs to one space.
normalize_text() {
    local text=${1-}
    local -a words=()

    read -r -a words <<< "${text}"
    printf '%s' "${words[*]}"
}

# Compare the value sent to a setter with the raw read-back of its getter.
# Returns 0 when they match, 1 when they differ and 2 when they cannot be
# compared reliably (multi-line values such as timers, or a numeric value read
# back as text). Numbers match within 0.05 to absorb unit rounding.
setter_readback_matches() {
    local sent=${1-}
    local raw=${2-}
    local first_word

    if [[ -z "${raw}" || "${raw}" == *$'\n'* ]]; then
        return 2
    fi

    if is_decimal "${sent}"; then
        first_word=$(normalize_text "${raw}")
        first_word=${first_word%% *}
        if ! is_decimal "${first_word}"; then
            return 2
        fi
        if awk -v sent="${sent}" -v got="${first_word}" \
            'BEGIN { d = sent - got; if (d < 0) d = -d; exit !(d <= 0.050001) }'; then
            return 0
        fi
        return 1
    fi

    if [[ "$(normalize_text "${raw}")" == "$(normalize_text "${sent}")" ]]; then
        return 0
    fi
    return 1
}

# Flatten a daemon error (often several lines) into one log-friendly line.
single_line() {
    local text=${1-}

    text=${text//$'\r'/}
    text=${text//$'\n'/ | }
    printf '%s' "${text}"
}

# Build the JSON acknowledgement published to <topic>/ack/<setter>.
setter_ack_json() {
    local status=$1 command=$2 value=$3 readback=$4 attempts=$5 error=$6

    jq -cn \
        --arg status "${status}" \
        --arg command "${command}" \
        --arg value "${value}" \
        --arg readback "${readback}" \
        --argjson attempts "${attempts}" \
        --arg error "${error}" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{status: $status, command: $command, value: $value, readback: $readback,
          attempts: $attempts, error: $error, timestamp: $timestamp}'
}
