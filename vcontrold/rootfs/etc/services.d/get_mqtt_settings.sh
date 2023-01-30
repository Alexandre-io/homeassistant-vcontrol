#!/usr/bin/with-contenv bashio

export MQTT_TOPIC=$(bashio::config 'mqtt_topic')

if bashio::config.has_value 'mqtt_host' \
    && bashio::config.has_value 'mqtt_port' \
    && bashio::config.has_value 'mqtt_user' \
    && bashio::config.has_value 'mqtt_password';
then
    export MQTT_HOST=$(bashio::config 'mqtt_host')
    export MQTT_PORT=$(bashio::config 'mqtt_port')
    export MQTT_USER=$(bashio::config 'mqtt_user')
    export MQTT_PASSWORD=$(bashio::config 'mqtt_password')
    bashio::log.info "Using configured MQTT Host $MQTT_HOST:$MQTT_PORT"
elif ! bashio::services.available "mqtt"; then
    bashio::exit.nok "No MQTT broker configured and no internal MQTT service found"
else
    export MQTT_HOST=$(bashio::services mqtt "host")
    export MQTT_PORT=$(bashio::services mqtt "port")
    export MQTT_USER=$(bashio::services mqtt "username")
    export MQTT_PASSWORD=$(bashio::services mqtt "password")
    bashio::log.info "Using internal MQTT Host $MQTT_HOST:$MQTT_PORT"
fi
