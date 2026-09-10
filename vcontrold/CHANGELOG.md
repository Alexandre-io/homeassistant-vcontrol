<!-- https://developers.home-assistant.io/docs/add-ons/presentation#keeping-a-changelog -->
## 1.13.5

- Add FLOCK again

## 1.13.4

- Fix startup failure when using a legacy custom `vito.xml` from `/homeassistant/vcontrold`

## 1.13.3

- Fix MQTT publishing for `STRING` commands so text payloads stay strings in MQTT clients such as MQTT Explorer
- Clarify the `commands` configuration format in the add-on documentation and translated option descriptions

## 1.13.2

- Fix parsing of the Home Assistant `commands` list so all configured commands are loaded again

## 1.13.1

- Fix compatibility with custom `vcontrold.xml` files that still use legacy or relative `vito.xml` XInclude paths

## 1.13.0

- Align the add-on with current Home Assistant 2026 / Supervisor conventions
- Switch custom XML handling to `addon_config` with legacy `config/vcontrold` fallback
- Fix MQTT setter topic parsing, string publishing, and runtime script robustness
- Move runtime-generated files to `/run/vcontrold` and simplify the Docker build

## 1.12.5

- Code Optimization

## 1.11.0

- Allow custom vcontrold.xml

## 1.10.1

- Improve logging (@ppuetsch)

## 1.10.0

- Fix build

## 1.9.0

- Allow custom vito.xml
- Upgrade debian to bookworm

## 1.8.4

- Added polish translation (@Qbunjo)

## 1.8.3

- Deactivated exposed port by default for security reasons (@Schm1tz1)

## 1.8.2

- Fix error code check (@ppuetsch)
- Make scripts executable (@ppuetsch)

## 1.8.1

- Added vclient error handling

## 1.8.0

- Set vcontrol host&port as optional configuration
- Fix Vcontrold boot sequence

## 1.7.0

- Added feature to make mqtt broker configurable (@ppuetsch)
- Added command setBetriebArtM1 for V200KW1 (@Razzer90)

## 1.6.0

- Added feature to switch to remote vcontrold (@Schm1tz1)

## 1.5.1

- Add DE translation (@Schm1tz1)
- Update docs (@Schm1tz1 & @Bjoern3003)

## 1.5.0

- Add debug config

## 1.4.0

- Add new devices

## 1.3.5

- Add configs

## 1.2.3

- First beta release

## 1.0.0

- Initial release
