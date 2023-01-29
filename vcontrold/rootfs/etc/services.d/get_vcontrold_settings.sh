#!/usr/bin/with-contenv bashio

export REFRESH_RATE=$(bashio::config 'refresh')

if bashio::config.has_value 'vcontrol_host'; then
    export VCONTROL_HOST=$(bashio::config 'vcontrol_host')
else
    export VCONTROL_HOST="localhost"
fi

if bashio::config.has_value 'vcontrol_port'; then
    export VCONTROL_PORT=$(bashio::config 'vcontrol_port')
else
    export VCONTROL_PORT="3002"
fi

bashio::log.info "Setting vcontrold host to $VCONTROL_HOST and port to $VCONTROL_PORT ..."
