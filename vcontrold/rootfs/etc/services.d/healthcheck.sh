#!/usr/bin/env bash
# Verify actual MQTT progress, without depending on the Supervisor API.
set -euo pipefail
runtime_dir=${RUNTIME_DIR:-/run/vcontrold}
[[ -s "${runtime_dir}/health_max_age" ]] || exit 1
max_age=$(cat "${runtime_dir}/health_max_age")
[[ "${max_age}" =~ ^[1-9][0-9]{0,6}$ ]] || exit 1
heartbeat="${runtime_dir}/last_success"
[[ -f "${heartbeat}" ]] || heartbeat="${runtime_dir}/started"
[[ -f "${heartbeat}" ]] || exit 1
last_success=$(stat -c %Y "${heartbeat}")
age=$(( $(date +%s) - last_success ))
(( age >= 0 && age <= max_age ))

groups_dir="${runtime_dir}/poll_groups"
if [[ -d "${groups_dir}" ]]; then
    for group_dir in "${groups_dir}"/*; do
        [[ -d "${group_dir}" ]] || continue
        group_max_age_file="${group_dir}/health_max_age"
        [[ -s "${group_max_age_file}" ]] || exit 1
        group_max_age=$(cat "${group_max_age_file}")
        [[ "${group_max_age}" =~ ^[1-9][0-9]{0,6}$ ]] || exit 1
        group_heartbeat="${group_dir}/last_success"
        [[ -f "${group_heartbeat}" ]] || group_heartbeat="${runtime_dir}/started"
        [[ -f "${group_heartbeat}" ]] || exit 1
        group_last_success=$(stat -c %Y "${group_heartbeat}")
        group_age=$(( $(date +%s) - group_last_success ))
        (( group_age >= 0 && group_age <= group_max_age )) || exit 1
    done
fi
