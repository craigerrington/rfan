#!/bin/bash
https://github.com/craigerrington/rfan/blob/initial-changes/R710-IPMI-TEMP/monitor.sh
# ----------------------------------------------------------------------------------
# Script for checking the temperature reported by the ambient temperature sensor,
# and if deemed too high send the raw IPMI command to enable dynamic fan control.
#
# This is designed to be run as a cron job, subsequent to manually lowering fan speeds
# with the sister script "set_temp.sh".
#
# The script checks for the current system temperature. If it's above the set threshold,
# it will enable dynamic fan control to speed up the fans. It'll also send a FAIL alert to healthcheck.io
# You can configure automations such as email or slack notifications from there to be notified of the event.
# If all is OK, a healthy ping is sent to healthcheck.io
#
# In either case, the current system temperature is sent by curl using the User Agent field. 
# This is extracted by healthcheck.io, shown in the logs, and can be used in your automations.
#
# Requires:
# ipmitool – apt-get install ipmitool
# An account and registered check at https://healthchecks.io (take note of the unique ID)
#
# Search for and replace:
# [ip-of-drac]: The IP address of your IPMI server, your DRAC management IP
# [drac-user]: Username for DRAC (default is root)
# [drac-password]: Password for DRAC (default is calvin)
# [ipmiek]: IPMI over LAN encryption key (default is 0000000000000000000000000000000000000000)
# [hc-uuid]: With the unique ID from a registered check at https://healthchecks.io
#
# ----------------------------------------------------------------------------------

# IPMI SETTINGS:
# Modify to suit your needs.
IPMIHOST=[ip-of-drac]
IPMIUSER=[drac-user]
IPMIPW=[drac-password]
IPMIEK=0000000000000000000000000000000000000000

# TEMPERATURE
# Change this to the temperature in celcius you are comfortable with.
# If the temperature goes above the set degrees it will send raw IPMI command to enable dynamic fan control
MAXTEMP=32

# This variable sends a IPMI command to get the temperature, and outputs it as two digits.
# Do not edit unless you know what you do.
TEMP=$(ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK sdr type temperature |grep Ambient |grep degrees |grep -Po '\d{2}' | tail -1)


if [[ $TEMP > $MAXTEMP ]];
  then
    printf "Warning: Temperature is too high! Activating dynamic fan control! ($TEMP C)" | systemd-cat -t R710-IPMI-TEMP
    curl -A "Warning: Temperature is too high! Activating dynamic fan control! ($TEMP C)" -fsS --retry 3 https://hc-ping.com/[hc-uuid]/fail >/dev/null 2>&1
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw 0x30 0x30 0x01 0x01
  else
    # healthchecks.io
    curl -A "Temperature is OK ($TEMP C)" -fsS --retry 3 https://hc-ping.com/[hc-uuid] >/dev/null 2>&1
    printf "Temperature is OK ($TEMP C)" | systemd-cat -t R710-IPMI-TEMP
    echo "Temperature is OK ($TEMP C)"
fi
