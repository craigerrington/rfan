#!/usr/bin/env bash

# ----------------------------------------------------------------------------------
# Script for setting manual fan speed to 1560 RPM (on my R710) (get real numbers..)
#
# Requires:
# ipmitool – apt-get install ipmitool
# (eventually) a healthcheck.io check (shared with the sister script)
# Search for and replace:
# [ip-of-drac]: The IP address of your IPMI server, your DRAC management IP
# [drac-user]: Username for DRAC (default is root)
# [drac-password]: Password for DRAC (default is calvin)
# [ipmiek]: IPMI over LAN encryption key (default is 0000000000000000000000000000000000000000)
# [hc-uuid]: With the unique ID from a registered check at https://healthchecks.io (when implemented)
#
# ----------------------------------------------------------------------------------


# IPMI SETTINGS:
# Modify to suit your needs.
IPMIHOST=[ip-of-drac]
IPMIUSER=[drac-user]
IPMIPW=[drac-password]
IPMIEK=[ipmiek]

printf "Activating manual fan speeds! (1560 RPM)" | systemd-cat -t R710-IPMI-TEMP
ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw 0x30 0x30 0x01 0x00
ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw 0x30 0x30 0x02 0xff 0x09
