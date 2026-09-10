ARG ADDON_IMAGE=vcontrol-audit:local
FROM ${ADDON_IMAGE}
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 mosquitto shellcheck \
    && rm -rf /var/lib/apt/lists/*
COPY tests /tests
ENTRYPOINT ["python3", "/tests/test_runtime.py"]
