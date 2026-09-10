#!/usr/bin/with-contenv bashio

declare -ag MQTT_AUTH_ARGS=()
MQTT_TOPIC=$(bashio::config 'mqtt_topic')
if [[ -z "${MQTT_TOPIC}" || "${MQTT_TOPIC}" == *['+#']* || "${MQTT_TOPIC}" =~ [[:space:][:cntrl:]] || "${MQTT_TOPIC}" == */ ]]; then
    bashio::exit.nok "mqtt_topic must be a non-empty topic prefix without wildcards, whitespace or trailing slash."
fi

if bashio::config.has_value 'mqtt_host'; then
    MQTT_HOST=$(bashio::config 'mqtt_host')
    MQTT_PORT=1883
    if bashio::config.has_value 'mqtt_port'; then
        MQTT_PORT=$(bashio::config 'mqtt_port')
    fi
    MQTT_USER=""
    MQTT_PASSWORD=""
    if bashio::config.has_value 'mqtt_user'; then
        MQTT_USER=$(bashio::config 'mqtt_user')
    fi
    if bashio::config.has_value 'mqtt_password'; then
        MQTT_PASSWORD=$(bashio::config 'mqtt_password')
    fi
    bashio::log.info "Using configured MQTT Host: ${MQTT_HOST}:${MQTT_PORT}"
else
    # Supervisor/Mosquitto may be unavailable temporarily during startup or updates.
    # Re-read all fields after recovery, bypassing Bashio's service cache.
    while true; do
        bashio::cache.flush 'service.info.mqtt'
        if bashio::services.available mqtt \
            && MQTT_HOST=$(bashio::services mqtt host) \
            && MQTT_PORT=$(bashio::services mqtt port) \
            && MQTT_USER=$(bashio::services mqtt username) \
            && MQTT_PASSWORD=$(bashio::services mqtt password) \
            && [[ -n "${MQTT_HOST}" && "${MQTT_HOST}" != null && -n "${MQTT_PORT}" && "${MQTT_PORT}" != null ]]; then
            break
        fi
        bashio::log.warning "Waiting for the Supervisor MQTT service. Configure mqtt_host to use an external broker. Retrying in 5 seconds."
        sleep 5
    done
    [[ "${MQTT_USER}" != null ]] || MQTT_USER=""
    [[ "${MQTT_PASSWORD}" != null ]] || MQTT_PASSWORD=""
    bashio::log.info "Using internal MQTT Host: ${MQTT_HOST}:${MQTT_PORT}"
fi

if [[ ! "${MQTT_PORT}" =~ ^[1-9][0-9]{0,4}$ ]] || (( MQTT_PORT > 65535 )); then
    bashio::exit.nok "mqtt_port must be between 1 and 65535."
fi
export MQTT_TOPIC MQTT_HOST MQTT_PORT MQTT_USER MQTT_PASSWORD
if [[ -n "${MQTT_USER}" ]]; then
    MQTT_AUTH_ARGS+=(-u "${MQTT_USER}")
    if [[ -n "${MQTT_PASSWORD}" ]]; then
        MQTT_AUTH_ARGS+=(-P "${MQTT_PASSWORD}")
    fi
elif [[ -n "${MQTT_PASSWORD}" ]]; then
    bashio::log.warning "MQTT password is set without a username. Ignoring the password."
fi
