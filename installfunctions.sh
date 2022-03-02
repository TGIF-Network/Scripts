#!/bin/bash

sudo mount -o remount,rw /
if [ ! -f /var/www/dashboard/mmdvmhost/functions.php.orig ]; then
	cp /var/www/dashboard/mmdvmhost/functions.php /var/www/dashboard/mmdvmhost/functions.php.orig 
fi
cp /home/pi-star/Scripts/functions.php /var/www/dashboard/mmdvmhost/

echo ""
echo "This script has replaced /var/www/dashboard/mmdvmhost/functions.php"
echo "If this is the first run it has created a backup file"
echo "/var/www/dashboard/mmdvmhost/functions.php.orig"
echo ""
echo "The original file would time out and put 'Not Linked' "
echo "in the P25 TG Box on the pi-star Dashboard"
echo "The time out was approximately 45 minutes to 1 hour"
echo ""
echo "This new file will store the current TG in a file and "
echo "when the time out occurs it will read the file and grab the stored TG"
echo "It will then write 'LH TG ' plus the stored TG into the P25 TG box on the Pi-Star Dashboard"
echo ""
echo "For first Tme Use - Key Up on a different TG to initalize the storage file"
echo "A keyup on the same TG will NOT put the required data into the P25 Log File which"
echo "is required to update the current TG and the storage file"
echo "" 
echo "Phil VE3RD"
echo ""
