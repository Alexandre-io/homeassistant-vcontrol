# Home Assistant Add-on: Vcontrol add-on

This add-on targets current 64-bit Home Assistant systems (`aarch64`, `amd64`).

## How to use
Once installed, the add-on fetches data from `vcontrold` and pushes it to the MQTT topic `openv` by executing the commands provided in the configuration and publishing the returned values into a corresponding topic for that specific command. A list of all possible commands and formats can be found in **/etc/vcontrold/vito.xml**.

Example: Command `getTempA` is executed and its return value is pushed into topic `openv/getTempA`.

If you want to set values / write to Vitodens, simply write to a topic that has the name of the setter command as specified in **/etc/vcontrold/vito.xml**.

Example: Writing a value to the topic `openv/setTempWWsoll` will set the target temperature for hot water to a new value. You will be able to see it in `openv/getTempWWsoll` in the next readout cycle.

## Configuration

### Add-On Configuration
In the configuration section, you have 2 choices to connect to your **Vitodens** device using an **Optolink** interface:
1. For a locally connected **Optolink** cable, set the USB/TTY device. The add-on will pass through that USB port and run **vcontrold** locally inside Docker.
2. For a remotely running **vcontrold** (e.g. RPi connected to your **Vitodens** device), select its hostname and port (_Vcontrold host/port_). These settings are by default set to localhost:3002.

Select a _refresh rate_ that defines the interval used for polling your device and the _device id_ (typically also seen in the device identifier string) which is used to select the correct mapping for the commands that are executed.
 

The commands section can be edited and extended in YAML mode, e.g.
```yaml
commands:
  - getTempA:FLOAT
  - getTempWWist:FLOAT
  - getTempWWsoll:FLOAT
  - getTempKist:FLOAT
  - getTempKsoll:FLOAT
  - getTempVListM1:FLOAT
  - getTempVListM2:FLOAT
  - getTempRL17A:FLOAT
  - getTempAbgas:FLOAT
  - getTempKol:FLOAT
  - getTempSpu:FLOAT
  - getTempRaumNorSollM1:FLOAT
  - getTempRaumNorSollM2:FLOAT
  - getTempRaumRedSollM1:FLOAT
  - getTempRaumRedSollM2:FLOAT
  - getBrennerStatus:FLOAT
  - getBrennerStarts:FLOAT
  - getBrennerStunden1:FLOAT
  - getBrennerStunden2:FLOAT
  - getPumpeStatusM1:FLOAT
  - getPumpeStatusSp:FLOAT
  - getPumpeStatusZirku:FLOAT
  - getPumpeStatusM2:FLOAT
  - getError0:STRING
  - getError1:STRING
  - getError2:STRING
  - getError3:STRING
  - getError4:STRING
  - getError5:STRING
  - getError6:STRING
  - getError7:STRING
  - getError8:STRING
  - getError9:STRING
  - getNeigungM1:FLOAT
  - getNeigungM2:FLOAT
  - getNiveauM1:FLOAT
  - getNiveauM2:FLOAT
  - getBetriebPartyM1:STRING
  - getBetriebPartyM2:STRING
  - getTempPartyM1:FLOAT
  - getTempPartyM2:FLOAT
  - getBetriebSparM1:STRING
  - getBetriebSparM2:STRING
  - getTimerM1Mo:STRING
  - getTimerM2Mo:STRING
  - getTimerWWMo:STRING
```

Each list entry uses the format `command:TYPE`.
Use `FLOAT` for numeric values and `STRING` for text payloads such as error codes, timer definitions, or string-like status values that should stay strings in MQTT clients.

### Integration into Home Assistant
To create entities in Home Assistant, you need to configure MQTT sensors - short example with getters and setters (taken from https://github.com/Alexandre-io/homeassistant-vcontrol/issues/7):
```yaml
mqtt:
  binary_sensor:
    - name: "Status Zirklulationspumpe"
      unique_id: "vcontroldgetPumpeStatusZirku"
      state_topic: "openv/getPumpeStatusZirku"
      device_class: running
      value_template: "{% if(value | int == 0) %}OFF{% else %}ON{% endif %}"
      device:
        identifiers: vcontrold
        manufacturer: Viessmann
  sensor:
    - name: "Aussentemperatur"
      unique_id: "vcontroldgetTempA"
      device_class: temperature
      state_topic: "openv/getTempA"
      unit_of_measurement: "°C"
      value_template: |-
        {{ value | float | round(2) }}
      device:
        identifiers: vcontrold
        manufacturer: Viessmann

  switch:
    - name: "Betriebsart Party"
      unique_id: "vcontroldgetBetriebPartyM1"
      state_topic: "openv/getBetriebPartyM1"
      command_topic: "openv/setBetriebPartyM1"
      device:
        identifiers: vcontrold
        manufacturer: Viessmann
      value_template: | 
        {{ value | float | round(0) }}
      payload_on: "1"
      payload_off: "0"
      state_on: "1"
      state_off: "0"
```
### Custom vito.xml / vcontrold.xml configuration file

The add-on uses the public add-on config folder for custom XML files. It verifies the existence of `vito.xml` and `vcontrold.xml` during startup.

Place the files in the Home Assistant path:
```
addon_configs/<repository_id>_vcontrold/vito.xml
addon_configs/<repository_id>_vcontrold/vcontrold.xml
```

For backward compatibility, existing files in `config/vcontrold/` are still detected in read-only mode.

The repository ID is part of the directory name shown by Home Assistant; it is not
literally `vcontrold`. For a local installation the prefix is `local`. Inside the
container this directory is mounted at `/config`. Custom files take precedence over
the legacy files in `/homeassistant/vcontrold`, then the bundled defaults. Your
original XML files are never rewritten.

### Reliability and recovery (1.14.0)

- For USB Optolink adapters, prefer the stable `/dev/serial/by-id/...` path shown in
  **Settings → System → Hardware**. `/dev/ttyUSB0` can identify a different adapter
  after a host reboot. The extension waits for a missing local serial device and
  retries daemon failures. Network serial endpoints (`host:port`) remain supported.
- `refresh` is the delay between completed read cycles (1–86400 seconds).
  `command_timeout` limits a whole vcontrold read cycle or one setter (1–3600 seconds,
  default 120). Increase it if a large command list or slow device needs more time.
  MQTT publications have a separate 10-second timeout, followed by forced termination
  after another 5 seconds if needed. A failed poll is retried; setter writes are not
  automatically replayed because their result can be uncertain after a timeout.
- The internal MQTT service is optional when `mqtt_host` specifies an external broker.
  Without `mqtt_host`, the extension waits for Supervisor's MQTT service and refreshes
  its credentials after connection failures. Install/start Mosquitto or configure an
  external broker if that waiting message persists.
- States are published with QoS 1 and retain enabled. Home Assistant receives the last
  known value when it reconnects. This value can be old if the boiler is offline:
  consider `expire_after` on MQTT sensors, adjusted to your polling interval.
  MQTT setter messages must be sent **without retain**; retained setters are ignored
  on reconnect. Send one setter per message, without commas or control characters.
- Enable **Start on boot** and **Watchdog** in the extension's information tab.
  Existing user choices are preserved by an update. The Docker healthcheck tracks
  actual MQTT publications, not merely a running process or open TCP port. With the
  watchdog enabled, Supervisor can restart an unhealthy container.
- The health budget is `max(300, 3 × (refresh + command_timeout + 15))` seconds since
  the last successful MQTT publication, or since initial startup before the first
  publication. Docker checks every 30 seconds with three consecutive failures and
  a five-minute initial grace period. At least one published value establishes
  progress; unsupported individual commands still appear in the logs.

### If values stop after a Home Assistant update

1. Check the extension log. `Published N values to MQTT` confirms broker receipt.
   `MQTT publication failed` identifies the broker/authentication side;
   `vclient read timed out` identifies the daemon/Optolink side;
   `Waiting for serial device` identifies USB enumeration or a changed device path.
2. Check the Mosquitto and Supervisor logs at the same timestamp. Distinguish a Core
   restart from an OS/host restart: only the latter normally re-enumerates USB devices.
3. Check the configured `state_topic`, `mqtt_topic` and broker address. The daemon
   can keep running while publication fails. Enable Watchdog for sustained failures.
4. For a support report, include Core, Supervisor, OS and extension versions; local
   USB, network Optolink or remote daemon mode; and relevant logs with credentials removed.

For maintainers, see the [local test instructions](../README.md#development).
