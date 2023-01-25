#!/usr/bin/with-contenv bashio

export MQTT_HOST=$(bashio::config 'mqtt_host')
export MQTT_PORT=$(bashio::config 'mqtt_port')
export MQTT_USER=$(bashio::config 'mqtt_user')
export MQTT_PASSWORD=$(bashio::config 'mqtt_password')
export MQTT_TOPIC=$(bashio::config 'mqtt_topic')

if [ -n "$MQTT_HOST" ] && [ -n "$MQTT_PORT" ] && [ -n "$MQTT_USER" ] && [ -n "$MQTT_PASSWORD" ]; then
    bashio::log.info "Using configured MQTT Host $MQTT_HOST"
elif ! bashio::services.available "mqtt"; then
    bashio::log.error "No MQTT broker configured and no internal MQTT service found"
    exit
else
    export MQTT_HOST=$(bashio::services mqtt "host")
    export MQTT_PORT=$(bashio::services mqtt "port")
    export MQTT_USER=$(bashio::services mqtt "username")
    export MQTT_PASSWORD=$(bashio::services mqtt "password")
    bashio::log.info "Using internal MQTT Host $MQTT_HOST"
fi
