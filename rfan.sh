#!/bin/bash

# ----------------------------------------------------------------------------------
# Script for setting low fan speds/noise on Dell R710 servers.
#
# This should be run as a cron job every 1 minute:
#
# * * * * * /path/to/rfan.sh
#
# On launch, if the detected ambient temperature is below the defined threshold, a static fan speed of 1560 RPM.
#
# If deemed too high send the raw IPMI command to enable dynamic fan control. Dynamic fan control will ramp up
# the fan speed to bring the temperatures down.
#
# When the temperature is detected to be back below the defined threshold, then the static speeds are re-enabled 
# to reduce fan speed/noise.
#
# Monitoring and Alerting:
#
# Every time the script runs, a ping is sent to healthcheck.io Each ping contains the temperature to be included in logging.
# Whenevr the temperature rises above the threshold, it'll set a FAIL status in the ping to allow for notifications
# and other integrations.
#
# Requires:
# ipmitool & curl
# An account and registered check from https://healthchecks.io (take note of the unique ID)
#
# Search for and replace:
# [ip-of-drac]: The IP address of your IPMI server, your DRAC management IP
# [drac-user]: Username for DRAC (default is root)
# [drac-password]: Password for DRAC (default is calvin)
# [ipmiek]: IPMI over LAN encryption key (default is 0000000000000000000000000000000000000000)
# [hc-uuid]: With the unique ID from a registered check at https://healthchecks.io
# [temp]: With the temperature threshold in degrees celcius, for example 32
#
# ----------------------------------------------------------------------------------

# IPMI SETTINGS:
# Modify to suit your needs.
IPMIHOST=[ip-of-drac]
IPMIUSER=[drac-user]
IPMIPW=[drac-password]
IPMIEK=[ipmiek]

# TEMPERATURE
# Change this to the temperature in celcius you are comfortable with.
# If the temperature goes above the set degrees it will send raw IPMI command to enable dynamic fan control
MAXTEMP=[temp]

# This variable sends a IPMI command to get the temperature, and outputs it as two digits.
# Do not edit unless you know what you do.
TEMP=$(ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK sdr type temperature |grep Ambient |grep degrees |grep -Po '\d{2}' | tail -1)


if [[ $TEMP > $MAXTEMP ]];
  then
    printf "Warning: Temperature is too high! Activating dynamic fan control! ($TEMP C)" | systemd-cat -t R710-IPMI-TEMP
    curl -A "Warning: Temperature is too high! Activating dynamic fan control! ($TEMP C)" -fsS --retry 3 https://hc-ping.com/[hc-uuid]/fail >/dev/null 2>&1
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw 0x30 0x30 0x01 0x01
  else
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw 0x30 0x30 0x01 0x00
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw 0x30 0x30 0x02 0xff 0x09
    # healthchecks.io
    curl -A "Temperature is OK ($TEMP C)" -fsS --retry 3 https://hc-ping.com/[hc-uuid] >/dev/null 2>&1
    printf "Temperature is OK ($TEMP C) (Static fan speed 1560 RPM)" | systemd-cat -t R710-IPMI-TEMP
    echo "Temperature is OK ($TEMP C)"
fi