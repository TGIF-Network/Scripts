#!/bin/bash
############################################################
#  This script will install NextionDriver Version 1.27     #
#  Currently this is patch with a pull rewuest submitted   #
#                                                          #
#  VE3RD                              Created 2025-03-31   #
############################################################
set -o errexit
set -o pipefail

sudo mount -o remount,rw /

systemctl stop nextiondriver
cp /home/pi-star/Scripts/NextionDriver /usr/local/bin/
systemctl start nextiondriver
