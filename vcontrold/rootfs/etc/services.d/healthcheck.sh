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
