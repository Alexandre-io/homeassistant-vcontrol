# Vcontrol Home Assistant add-on repository

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FAlexandre-io%2Fhomeassistant-vcontrol)

## Add-ons

This repository contains the following add-ons

### [Vcontrol add-on](./vcontrold)

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]

## Development

The extension is a Bashio/s6 bridge around upstream vcontrold 0.98.12. Runtime data
is stored in `/run/vcontrold`; custom XML files remain in the mapped config folders.

Run the fast shell regression tests:

```sh
bash tests/run.sh
```

Build and exercise the real Bashio, vclient and Mosquitto clients against a local
boiler simulator and a disposable MQTT broker (no heating hardware needed):

```sh
docker build --build-arg BUILD_ARCH=amd64 --build-arg BUILD_VERSION=1.14.0 -t vcontrol-audit:local vcontrold
docker build -f tests/Dockerfile -t vcontrol-audit:tests .
docker run --rm vcontrol-audit:tests
bash tests/container_smoke.sh
```

Use `BUILD_ARCH=aarch64` on an ARM64 machine. CI builds and tests on native amd64
and ARM64 runners, then publishes the tested images to the existing Docker Hub
repositories only after both architectures pass and the extension version changes
on `main`. Pull requests and documentation-only updates never publish.
`build.yaml` is no longer used; base image and labels live in the Dockerfile.
Bump `vcontrold/config.yaml` and update `vcontrold/CHANGELOG.md` for each release.

See [configuration and recovery instructions](vcontrold/DOCS.md).


[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
