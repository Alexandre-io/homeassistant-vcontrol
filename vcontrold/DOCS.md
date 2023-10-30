# Home Assistant Add-on: Vcontrol add-on

## How to use
Once installed, the plugin fetches data from `vcontrold` and pushes it to the MQTT topic `openv` by executing the commands provided in the configuration and pushing the returned values into a correnspoding topic for that specific command. A list of all possible commands and formats can be found in **/etc/vcontrold/vito.xml**.

Example: Command `getTempA` is executed and its return value is pushed into topic `openv/getTempA`.

If you want to set values / write to Vitodens, simply write to a topic that has the man of the setter command as specified in **/etc/vcontrold/vito.xml**.

Example: Writing a value to the topic `openv/setTempWWSoll` will set the target temperature for hot water to a new value. You will be able to see it in `opemv/getTempWWSoll` in the next readout cycle.

## Configuration

### Add-On Configuration
In the configuration section, you have 2 choices to connect to your **Vitodens** device using an an **Optolink** interface:
1. For a locally connected **Optolink** cable, set the USB/TTY device. The add-on will pass through that USB port run **vcontrold** locally inside docker.
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

### Integration into Home Assistant
To create entities in Home Assistant, you need to configure MQTT sensors - short example with getters and setters (taken from https://github.com/Alexandre-io/homeassistant-vcontrol/issues/7):
```yaml
mqtt:
  binary_sensor:
    - name: "Status Zirklulationspumpe"
      unique_id: "vcontroldgetPumpeStatusZirku"
      state_topic: "openv/getPumpeStatusZirku"
      device_class: running
      value_template: "{% if(value|int == '0') %}OFF{% else %}ON{% endif %}"
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
        {{ value | round(2) }}
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
        {{ value|round(0) }}
      payload_on: 1
      payload_off: 0
      state_on: 1
      state_off: 0
```
### Custom vito.xml configuration file

The module use the `config` option (refer to https://developers.home-assistant.io/docs/add-ons/configuration/#add-on-advanced-options) for mounting a custom configuration file. It verifies the existence of a 'vito.xml' file during startup.

Ensure the file is placed in the specified path:
```
config/vcontrold/vito.xml
```

