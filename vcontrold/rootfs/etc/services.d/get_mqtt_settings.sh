#!/usr/bin/with-contenv bashio

# Fetch MQTT topic from the configuration
export MQTT_TOPIC=$(bashio::config 'mqtt_topic')

# Check if user has provided MQTT configuration
if bashio::config.has_value 'mqtt_host' \
    && bashio::config.has_value 'mqtt_port' \
    && bashio::config.has_value 'mqtt_user' \
    && bashio::config.has_value 'mqtt_password'; then

    # Use configured MQTT settings
    export MQTT_HOST=$(bashio::config 'mqtt_host')
    export MQTT_PORT=$(bashio::config 'mqtt_port')
    export MQTT_USER=$(bashio::config 'mqtt_user')
    export MQTT_PASSWORD=$(bashio::config 'mqtt_password')
    bashio::log.info "Using configured MQTT Host: $MQTT_HOST:$MQTT_PORT"

# If no user configuration is found, check if internal MQTT service is available
elif bashio::services.available "mqtt"; then

    # Use internal MQTT service settings
    export MQTT_HOST=$(bashio::services mqtt "host")
    export MQTT_PORT=$(bashio::services mqtt "port")
    export MQTT_USER=$(bashio::services mqtt "username")
    export MQTT_PASSWORD=$(bashio::services mqtt "password")
    bashio::log.info "Using internal MQTT Host: $MQTT_HOST:$MQTT_PORT"

# Exit if neither user-provided nor internal MQTT configuration is available
else
    bashio::exit.nok "No MQTT broker configured and no internal MQTT service available"
fi
