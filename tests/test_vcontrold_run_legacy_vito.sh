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

cat > "${tmp_dir}/legacy-config/vito.xml" <<'EOF'
<legacy-vito />
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

    export BASHIO_CONFIG_tty="/dev/null"
    export BASHIO_CONFIG_device_id="2098"
    export BASHIO_CONFIG_refresh="60"
    export BASHIO_CONFIG_commands=$'getTempA:FLOAT'
    export BASHIO_CONFIG_mqtt_topic="openv"
    export BASHIO_CONFIG_mqtt_host="mqtt.local"
    export BASHIO_CONFIG_debug="false"

    source "${repo_root}/vcontrold/rootfs/etc/services.d/vcontrold/run" > "${tmp_dir}/run.log" 2>&1
)

assert_file_contains "${tmp_dir}/run.log" "Using legacy custom vito.xml file from /homeassistant/vcontrold."
assert_file_contains "${tmp_dir}/run/vcontrold.xml" "href=\"${tmp_dir}/legacy-config/vito.xml\""
assert_file_contains "${tmp_dir}/capture/vcontrold-args.txt" "${tmp_dir}/run/vcontrold.xml"

printf 'PASS: %s\n' "$(basename "$0")"
