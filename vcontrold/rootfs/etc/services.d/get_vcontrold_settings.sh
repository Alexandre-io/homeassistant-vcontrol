#!/usr/bin/with-contenv bashio

# Fetch and export refresh rate from configuration
export REFRESH_RATE=$(bashio::config 'refresh')

# Fetch VCONTROL_HOST and set to localhost by default if not provided
if bashio::config.has_value 'vcontrol_host'; then
    export VCONTROL_HOST=$(bashio::config 'vcontrol_host')
else
    bashio::log.warning "vcontrol_host not set in configuration. Defaulting to 'localhost'."
    export VCONTROL_HOST="localhost"
fi

# Fetch VCONTROL_PORT and set to 3002 by default if not provided
if bashio::config.has_value 'vcontrol_port'; then
    export VCONTROL_PORT=$(bashio::config 'vcontrol_port')
else
    bashio::log.warning "vcontrol_port not set in configuration. Defaulting to '3002'."
    export VCONTROL_PORT="3002"
fi

# Log the configured VCONTROL host and port
bashio::log.info "vcontrold will be set to host: $VCONTROL_HOST and port: $VCONTROL_PORT"
