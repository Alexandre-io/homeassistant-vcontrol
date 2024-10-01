#!/usr/bin/with-contenv bashio

# Fetch and export refresh rate from configuration
export REFRESH_RATE=$(bashio::config 'refresh')

# Fetch VCONTROL_HOST and set to localhost by default if not provided
export VCONTROL_HOST=$(bashio::config 'vcontrol_host' || echo "localhost")

# Fetch VCONTROL_PORT and set to 3002 by default if not provided
export VCONTROL_PORT=$(bashio::config 'vcontrol_port' || echo "3002")

# Log the configured VCONTROL host and port
bashio::log.info "vcontrold will be set to host: $VCONTROL_HOST and port: $VCONTROL_PORT"
