#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "${repo_root}/tests/lib/assert.sh"

for invalid in 0 -1 abc 99999999999999999999999999999999; do
    if (
        source "${repo_root}/tests/lib/mock_bashio.sh"
        BASHIO_CONFIG_refresh=${invalid}
        source "${repo_root}/vcontrold/rootfs/etc/services.d/get_vcontrold_settings.sh"
    ) >/dev/null 2>&1; then
        fail "invalid refresh accepted: ${invalid}"
    fi
done
printf 'PASS: %s\n' "$(basename "$0")"
