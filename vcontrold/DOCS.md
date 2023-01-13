# Home Assistant Add-on: Vcontrol add-on

## How to use
Once installed, the plugin fetches data from `vcontrold` and pushes it to the MQTT topic `openv` by executing the commands provided in the configuration and pushing the returned values into a correnspoding topic for that specific command. A list of all possible commands and formats can be found in **/etc/vcontrold/vito.xml**.

Example: Command `getTempA` is executed and its return value is pushed into topic `openv/getTempA`.

If you want to set values / write to Vitodens, simply write to a topic that has the man of the setter command as specified in **/etc/vcontrold/vito.xml**.

Example: Writing a value to the topic `openv/setTempWWSoll` will set the target temperature for hot water to a new value. You will be able to see it in `opemv/getTempWWSoll` in the next readout cycle.

## Configuration
In the configuration section, you need to set the USB/TTY device that uses an **Optolink** interface to connect to the **Vitodens** device. Select a _refresh rate_ that defines the interval used for polling your device and the _device id_ (typically also seen in the device identifier string) which is used to select the correct mapping for the commands that are executed.

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
