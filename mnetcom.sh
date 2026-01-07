#!/bin/bash
#########################################################################
#  MNet_Network Support                                                 #
#  This Script will install The MNet Security Password into             #
#  /root/DMR_Hosts.txt and run the Pi-Star Host File Updatde Routine    #
#  and add the required line to /root/DMR_Hosts.txt if it was           #
#  not found in ether file.						#
#  Place the Security Password into /home/pi-star/MNet.txt		#
#                                                                       #
#  VE3RD                                                2020-08-22      #
#########################################################################
export NCURSES_NO_UTF8_ACS=1


set -euo pipefail

FILE="/etc/DMR_Hosts.txt"
OLD="mnet.hopto.org"
NEW="mnetdmr.com"
BACKUP="${FILE}.bak"

if [ ! -f "$FILE" ]; then
  echo "Error: $FILE not found." >&2
  exit 1
fi

# choose sed -i style that works on both GNU and macOS: create a backup explicitly
# If file is writable do it directly, otherwise run with sudo.
if [ -w "$FILE" ]; then
  sed -i.bak "s/${OLD}/${NEW}/g" "$FILE"
else
  sudo sed -i.bak "s/${OLD}/${NEW}/g" "$FILE"
fi

echo "Replaced '$OLD' → '$NEW' in $FILE"
echo "Backup saved as $BACKUP"
