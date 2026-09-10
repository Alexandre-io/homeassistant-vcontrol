# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
ARG BUILD_FROM=ghcr.io/home-assistant/base-debian:trixie-2026.08.0
FROM ${BUILD_FROM}

ARG BUILD_VERSION=dev
ARG BUILD_ARCH
LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.name="Vcontrol add-on" \
    io.hass.description="MQTT bridge for Viessmann vcontrold" \
    io.hass.url="https://github.com/Alexandre-io/homeassistant-vcontrol" \
    org.opencontainers.image.title="Home Assistant Add-on: Vcontrol add-on" \
    org.opencontainers.image.description="MQTT bridge for Viessmann vcontrold." \
    org.opencontainers.image.source="https://github.com/Alexandre-io/homeassistant-vcontrol" \
    org.opencontainers.image.licenses="Apache-2.0"

ENV VCONTROLD_VERSION="v0.98.12"

RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        libxml2 \
        libxml2-dev \
        mosquitto-clients && \
    git clone --depth 1 --branch "${VCONTROLD_VERSION}" https://github.com/openv/vcontrold.git /tmp/vcontrold && \
    cmake -S /tmp/vcontrold -B /tmp/vcontrold/build -DMANPAGES=OFF && \
    cmake --build /tmp/vcontrold/build --parallel "$(nproc)" && \
    cmake --install /tmp/vcontrold/build && \
    apt-get purge -y --auto-remove \
        build-essential \
        cmake \
        git \
        libxml2-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy root filesystem
COPY rootfs /

HEALTHCHECK --interval=30s --timeout=5s --start-period=5m --retries=3 \
    CMD ["/bin/bash", "/etc/services.d/healthcheck.sh"]
