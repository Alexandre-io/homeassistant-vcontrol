#!/usr/bin/with-contenv bashio

prepare_polling_groups() {
    local commands_raw=${1-}
    local default_refresh=$2
    local runtime_dir=$3
    local command_entry cmd type interval position value_placeholder
    local -a commands_array=()
    local -A group_counts=()

    POLLING_GROUPS_FILE="${runtime_dir}/polling_groups.tsv"
    POLLING_MAX_REFRESH=0
    POLLING_TOTAL_COMMANDS=0

    rm -f "${runtime_dir}"/poll_*.commands "${runtime_dir}"/poll_*.tmpl "${POLLING_GROUPS_FILE}.tmp"

    load_vcontrold_commands_array "${commands_raw}" commands_array
    for command_entry in "${commands_array[@]}"; do
        [[ -n "${command_entry}" ]] || continue

        if ! parse_vcontrold_command_entry "${command_entry}" "${default_refresh}" cmd type interval; then
            bashio::log.warning "Skipping invalid command entry: ${command_entry}"
            continue
        fi

        group_counts["${interval}"]=$(( ${group_counts["${interval}"]:-0} + 1 ))
        position=${group_counts["${interval}"]}
        ((POLLING_TOTAL_COMMANDS+=1))
        (( interval > POLLING_MAX_REFRESH )) && POLLING_MAX_REFRESH=${interval}

        bashio::log.info "Configuring command ${POLLING_TOTAL_COMMANDS}: ${cmd} with type ${type}, polling every ${interval}s"
        printf '%s\n' "${cmd}" >> "${runtime_dir}/poll_${interval}.commands"

        value_placeholder="\$${position}"
        if [[ "${type}" == "STRING" ]]; then
            value_placeholder="\$R${position}"
        fi

        # US separates fields and RS terminates a record. vclient expands the
        # placeholders; the resulting text is parsed as data, never executed.
        # shellcheck disable=SC2016
        printf '$C%d\037$E%d\037%s\036\n' "${position}" "${position}" "${value_placeholder}" \
            >> "${runtime_dir}/poll_${interval}.tmpl"
    done

    (( POLLING_TOTAL_COMMANDS > 0 )) || return 1

    while IFS= read -r interval; do
        printf '%s\t%s\t%s\n' \
            "${interval}" \
            "${runtime_dir}/poll_${interval}.commands" \
            "${runtime_dir}/poll_${interval}.tmpl" \
            >> "${POLLING_GROUPS_FILE}.tmp"
    done < <(printf '%s\n' "${!group_counts[@]}" | sort -n)

    mv "${POLLING_GROUPS_FILE}.tmp" "${POLLING_GROUPS_FILE}"
}
