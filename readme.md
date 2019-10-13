# rfan

`rfan.sh` is a dangerous bash script for working with the fans on a Dell R710. It is based on the scripts found in the `NoLooseEnds/Scripts` repo, modified versions of which are included in this repository. The changes I've made to the original scripts are:

- Created the combo script `rfan.sh`.
- enhanced monitoring and failure alerts with healthcheck.io.
- updated some of the journalctl logging.
- added temperatures to the healthcheck.io reporting
- added failure reporting for integrations with healthcheck.io
- removed the slack integration

Both scripts require the ipmitool package to be installed and IPMI over LAN enabled on the server DRAC.

### `rfan.sh`

The beautiful monster. I take no responsibility if this script causes your server to **catch fire**. Seriously. **There's a chance this will make things catch fire**. I am not an expert. I took some other scripts, mashed them together and added some nice reporting. Do not trust me with your life.

This is the all in one script, if you are lazy AND BRAVE, this is what you want. This combines the features of `setfan.sh` and `monitor.sh`. It is designed to be scheduled with `cron` to run *every minute*.

With the default configuration (and taking no heed to all the notes below and all the options you have), on launch it will:

- Check the temperature from the server.
- If it's below the defined threshold, it'll set the static speed of the fans to 1560 RPM, which should be pretty quiet.
- It'll check on each run for the temperature, and should the temperature rise above the threshold, it'll re-enable automatic fan control (nice and noisy) to reduce the temperatures
- Once the temperatue is back below the threshold, static fan speeds will be re-enabled back to 1560 RPM
- Includes all of the monitoring features described below in `monitor.sh`

### `monitor.sh`
monitor.sh should be scheduled with cron.

Every time it runs, it reads the current system temp. If the temp is above a set threshold, it immediately disables static fan control. This has the effect of enabling automatic controls, which will allow the fans to ramp up to the required speed to cool the server down.

Additionally, pings to healthcheck.io are made. The current system temperature is sent using the curl `User Agent` header. healthcheck.io extracts this data for logging. For a healthy temperature, a healthy ping is sent along with the current system temperature. In the event of a high temp detection, a failure alert is sent to healthcheck.io - this can be combined with automations from email alerts to slack. Because of the way healthcheck.io extracts the `User Agent` string, this data is available to your automations.

![screenshot](/media/sshot.PNG)

### `setfans.sh`
a simple script which sets the fans to a static pre-defined speed (1560 RPM).
It first enables static control, and then sets a static speed

#### Some of the notes from the original repo:
(I found super useful in understanding how the IPMI parts works. I've edited bits, so please accept any mistakes as mine.)

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

Disable/return to automatic fan control: `raw 0x30 0x30 0x01 0x01

List all output from IPMI: `sdr elist all`
