#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

source "${repo_root}/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p \
    "${tmp_dir}/addon-config" \
    "${tmp_dir}/bin" \
    "${tmp_dir}/capture" \
    "${tmp_dir}/etc/vcontrold" \
    "${tmp_dir}/legacy-config" \
    "${tmp_dir}/run"

cat > "${tmp_dir}/etc/vcontrold/vcontrold.xml" <<'EOF'
<config debug="#DEBUG#" device="#DEVICEID#">
  <xi:include href="#VITOXML#" />
</config>
EOF

cat > "${tmp_dir}/etc/vcontrold/vito.xml" <<'EOF'
<vito />
EOF

cat > "${tmp_dir}/bin/mock-vcontrold" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "${TEST_CAPTURE_DIR}/vcontrold-args.txt"
EOF
chmod +x "${tmp_dir}/bin/mock-vcontrold"

(
    source "${repo_root}/tests/lib/mock_bashio.sh"

    export SERVICES_DIR="${repo_root}/vcontrold/rootfs/etc/services.d"
    export ADDON_CONFIG_DIR="${tmp_dir}/addon-config"
    export LEGACY_CONFIG_DIR="${tmp_dir}/legacy-config"
    export VCONTROLD_CONFIG_DIR="${tmp_dir}/etc/vcontrold"
    export RUNTIME_DIR="${tmp_dir}/run"
    export VCONTROLD_BIN="${tmp_dir}/bin/mock-vcontrold"
    export TEST_CAPTURE_DIR="${tmp_dir}/capture"

    export BASHIO_CONFIG_tty="${TEST_TTY:-/dev/null}"
    export BASHIO_CONFIG_device_id="2098"
    export BASHIO_CONFIG_refresh="60"
    export BASHIO_CONFIG_commands=$'getTempA:FLOAT:5\ngetError0:STRING\ngetTempWWsoll:FLOAT:5'
    export BASHIO_CONFIG_mqtt_topic="openv"
    export BASHIO_CONFIG_mqtt_host="mqtt.local"
    export BASHIO_CONFIG_debug="false"

    source "${repo_root}/vcontrold/rootfs/etc/services.d/vcontrold/run" > "${tmp_dir}/run.log" 2>&1
)

assert_file_exists "${tmp_dir}/run/polling_groups.tsv"
assert_file_exists "${tmp_dir}/run/poll_5.commands"
assert_file_exists "${tmp_dir}/run/poll_60.commands"
assert_eq \
    $'getTempA\ngetTempWWsoll' \
    "$(cat "${tmp_dir}/run/poll_5.commands")" \
    "generated five-second command group"
assert_eq \
    "getError0" \
    "$(cat "${tmp_dir}/run/poll_60.commands")" \
    "generated default command group"
assert_file_contains "${tmp_dir}/run/poll_5.tmpl" '$C2'
assert_file_contains "${tmp_dir}/run/poll_5.tmpl" '$1'
assert_file_contains "${tmp_dir}/run/poll_5.tmpl" '$2'
assert_file_contains "${tmp_dir}/run/poll_60.tmpl" '$R1'
assert_file_contains "${tmp_dir}/run/polling_groups.tsv" $'5\t'
assert_file_contains "${tmp_dir}/run/polling_groups.tsv" $'60\t'
assert_file_contains "${tmp_dir}/run/vcontrold.xml" 'device="2098"'
assert_file_contains "${tmp_dir}/run/vcontrold.xml" "href=\"${tmp_dir}/etc/vcontrold/vito.xml\""
assert_file_contains "${tmp_dir}/capture/vcontrold-args.txt" "${tmp_dir}/run/vcontrold.xml"
assert_file_contains "${tmp_dir}/capture/vcontrold-args.txt" "${TEST_TTY:-/dev/null}"

printf 'PASS: %s\n' "$(basename "$0")"
