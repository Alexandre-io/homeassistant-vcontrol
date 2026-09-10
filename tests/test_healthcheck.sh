#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "${repo_root}/tests/lib/assert.sh"
tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT
export RUNTIME_DIR=${tmp_dir}
echo 300 > "${tmp_dir}/health_max_age"
touch "${tmp_dir}/last_success"
bash "${repo_root}/vcontrold/rootfs/etc/services.d/healthcheck.sh" || fail "fresh MQTT publication should be healthy"
touch -d '10 minutes ago' "${tmp_dir}/last_success"
if bash "${repo_root}/vcontrold/rootfs/etc/services.d/healthcheck.sh"; then
    fail "stale MQTT publication should be unhealthy"
fi
rm "${tmp_dir}/last_success"
if bash "${repo_root}/vcontrold/rootfs/etc/services.d/healthcheck.sh"; then
    fail "no MQTT publication should be unhealthy"
fi
touch "${tmp_dir}/started"
bash "${repo_root}/vcontrold/rootfs/etc/services.d/healthcheck.sh" || fail "first poll should get its startup budget"
touch -d '10 minutes ago' "${tmp_dir}/started"
if bash "${repo_root}/vcontrold/rootfs/etc/services.d/healthcheck.sh"; then
    fail "startup grace must expire without a first publication"
fi
printf 'PASS: %s\n' "$(basename "$0")"
