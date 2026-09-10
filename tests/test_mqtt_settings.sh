#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "${repo_root}/tests/lib/assert.sh"
source "${repo_root}/tests/lib/mock_bashio.sh"

BASHIO_CONFIG_mqtt_topic=openv
BASHIO_SERVICE_mqtt_host=mqtt.internal
BASHIO_SERVICE_mqtt_port=1883
BASHIO_SERVICE_mqtt_username=bridge
BASHIO_SERVICE_mqtt_password='a password with $ and " quotes'
attempts=0
bashio::services.available() {
    ((attempts+=1))
    (( attempts >= 3 ))
}
bashio::cache.flush() { :; }
sleep() { :; }
source "${repo_root}/vcontrold/rootfs/etc/services.d/get_mqtt_settings.sh"
assert_eq mqtt.internal "${MQTT_HOST}" "broker discovered after temporary absence"
assert_eq "${BASHIO_SERVICE_mqtt_password}" "${MQTT_AUTH_ARGS[3]}" "password preserved"
printf 'PASS: %s\n' "$(basename "$0")"
