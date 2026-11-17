#!/usr/bin/with-contenv bashio

REFRESH_RATE=$(bashio::config 'refresh')
COMMAND_TIMEOUT=120
WRITE_ATTEMPTS=3
VCONTROL_HOST=localhost
VCONTROL_PORT=3002
if bashio::config.has_value 'command_timeout'; then
    COMMAND_TIMEOUT=$(bashio::config 'command_timeout')
fi
if bashio::config.has_value 'write_attempts'; then
    WRITE_ATTEMPTS=$(bashio::config 'write_attempts')
fi
if bashio::config.has_value 'vcontrol_host'; then
    VCONTROL_HOST=$(bashio::config 'vcontrol_host')
fi
if bashio::config.has_value 'vcontrol_port'; then
    VCONTROL_PORT=$(bashio::config 'vcontrol_port')
fi

if [[ ! "${REFRESH_RATE}" =~ ^[1-9][0-9]{0,4}$ ]] || (( REFRESH_RATE > 86400 )); then
    bashio::exit.nok "refresh must be between 1 and 86400 seconds."
fi
if [[ ! "${COMMAND_TIMEOUT}" =~ ^[1-9][0-9]{0,3}$ ]] || (( COMMAND_TIMEOUT > 3600 )); then
    bashio::exit.nok "command_timeout must be between 1 and 3600 seconds."
fi
if [[ ! "${WRITE_ATTEMPTS}" =~ ^[1-9][0-9]?$ ]] || (( WRITE_ATTEMPTS > 10 )); then
    bashio::exit.nok "write_attempts must be between 1 and 10."
fi
if [[ ! "${VCONTROL_PORT}" =~ ^[1-9][0-9]{0,4}$ ]] || (( VCONTROL_PORT > 65535 )); then
    bashio::exit.nok "vcontrol_port must be between 1 and 65535."
fi
export REFRESH_RATE COMMAND_TIMEOUT WRITE_ATTEMPTS VCONTROL_HOST VCONTROL_PORT
bashio::log.info "vcontrold endpoint: ${VCONTROL_HOST}:${VCONTROL_PORT}; poll timeout: ${COMMAND_TIMEOUT}s."
