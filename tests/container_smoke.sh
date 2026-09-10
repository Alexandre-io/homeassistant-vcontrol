#!/usr/bin/env bash
# Exercise the real s6 tree without connecting to Supervisor, a broker or hardware.
set -euo pipefail
image=${1:-vcontrol-audit:local}
name="vcontrol-smoke-$$"
tmp_dir=$(mktemp -d)
cleanup() {
    docker rm -f "${name}" >/dev/null 2>&1 || true
    rm -rf "${tmp_dir}"
}
trap cleanup EXIT
cat > "${tmp_dir}/addons.self.options.config.cache" <<'JSON'
{"tty":"/dev/null","device_id":"2098","debug":false,"refresh":1,"command_timeout":1,"commands":["getTempA:FLOAT"],"vcontrol_host":"192.0.2.1","mqtt_host":"127.0.0.1","mqtt_topic":"openv"}
JSON
cat > "${tmp_dir}/daemon" <<'SH'
#!/usr/bin/env bash
trap 'exit 1' USR1
while true; do sleep 1; done
SH
chmod +x "${tmp_dir}/daemon"

docker run -d --name "${name}" --network none --health-interval=1s \
    -e CACHE_DIR=/test-cache -e TAIL_BIN=/test-cache/daemon \
    -v "${tmp_dir}:/test-cache" "${image}" >/dev/null
for attempt in {1..30}; do
    if docker exec "${name}" test -f /run/vcontrold/ready; then
        break
    fi
    sleep 1
done
docker exec "${name}" test -f /run/vcontrold/ready
# A nonzero service exit used to halt the entire container. Kill the remote-mode
# placeholder and verify s6 replaces it while the other services remain available.
old_pid=$(docker exec "${name}" s6-svstat -o pid /run/service/vcontrold)
docker exec "${name}" s6-svc -1 /run/service/vcontrold
new_pid=${old_pid}
for attempt in {1..20}; do
    new_pid=$(docker exec "${name}" s6-svstat -o pid /run/service/vcontrold)
    if [[ "${new_pid}" != -1 && "${new_pid}" != "${old_pid}" ]]; then
        break
    fi
    sleep 1
done
[[ "${new_pid}" != -1 && "${new_pid}" != "${old_pid}" ]]
for service in vcontrold vclient_pub vclient_sub; do
    [[ $(docker exec "${name}" s6-svstat -o up "/run/service/${service}") == true ]]
done
# Shutdown should let s6 finish normally, without Docker escalating to SIGKILL.
docker stop --time 15 "${name}" >/dev/null
exit_code=$(docker inspect --format '{{.State.ExitCode}}' "${name}")
[[ "${exit_code}" == 0 ]]
printf 'PASS: s6 service recovery and clean container shutdown\n'
