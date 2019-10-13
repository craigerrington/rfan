# rfan

rfan is a pair of bash scripts for working with the fans on a Dell R710. They are based on the scripts found in the `NoLooseEnds/Scripts` repo. Other than some cleanup and changed defaults, so far most of the changes I've made personally are around the monitoring and enhanced failure alerts with healthcheck.io.

Both scripts require the ipmitool package to be installed and IPMI over LAN enabled on the server DRAC.

### setfans.sh
a simple script which sets the fans to a static pre-defined speed (1560 RPM).
It first enables static control, and then sets a static speed

### monitor.sh
monitor.sh is designed to be scheduled with cron.

Every time it runs, it reads the current system temp. If the temp is above a set threshold, it immediately disables static fan control. This has the effect of enabling automatic controls, which will allow the fans to ramp up to the required speed to cool the server down.

Additionally, ping to healthcheck.io. The current system temperature is sent using the curl User Agent header. healthcheck.io extracts this data for logging. For a healthy temperature, a healthy ping is sent along with the current system temperature. In the event of a high temp detection, a failure alert is sent to healthcheck.io - this can be combined with automations from email alerts to slack. Because of the way healthcheck.io extracts the User Agent string, you can also use the current system temp in the automations.

#### Some of the notes from the original repo I found super useful in understanding how the IPMI parts works.
(I've edited bits, so please accept any mistakes as mine) 

#### Howto: Manually set the fan speed of the Dell R610/R710

1. Enable IPMI in iDrac
2. Install ipmitool on linux, win or mac os
3. Run the following command to issue IPMI commands: 
`ipmitool -I lanplus -H <iDracip> -U root -P <rootpw> <command>`

#### Commands

Enable manual/static fan speed: `raw 0x30 0x30 0x01 0x00`

Set fan speed (use something like http://www.hexadecimaldictionary.com/hexadecimal/0x14/ to calculate speed from decimal to hex):
 - *3000 RPM*: `rw 0x30 0x30 0x02 0xff 0x10`
 - *2160 RPM*: `raw 0x30 0x30 0x02 0xff 0x0a`
 - *1560 RPM*: `raw 0x30 0x30 0x02 0xff 0x09`
 - _Note: The RPM may differ from model to model_

Disable / Return to automatic fan control: `raw 0x30 0x30 0x01 0x01

List all output from IPMI: `sdr elist all`
