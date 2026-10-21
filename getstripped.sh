#!/bin/bash
############################################################
#  Get User ID Database from radioid.net                   #
#  Save it to /usr/local/etc/stripped.csv                  #
#  Convert 'United States' to 'USA'                        #
#  					                   #
#  VE3RD                                      2022-01-12   #
############################################################
set -o errexit
set -o pipefail
sudo mount -o remount,rw /
echo "Started Update Sequence for Stripped.csv"
sudo wget https://database.radioid.net/static/user.csv -O /usr/local/etc/stripped.csv
cp /usr/local/etc/stripped.csv /usr/local/etc/stripped2.csv
sudo sed -i 's/United States/USA/g' /usr/local/etc/stripped2.csv
sudo sed -i 's/Australia/Aus/g' /usr/local/etc/stripped2.csv
sudo sed -i 's/Canada/Can/g' /usr/local/etc/stripped2.csv
#sudo sed -i 's/Alabama/AL/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Alaska/AK/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Arizona/AZ/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Arkansas/AR/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/California/CA/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Colorado/CO/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Connecticut/CT/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Delaware/DE/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Florida/FL/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Georgia/GA/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Hawaii/HI/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Idaho/ID/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Illinois/IL/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Indiana/IN/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Iowa/IA/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Kansas/KS/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Kentucky/KY/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Louisiana/LA/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Maine/ME/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Maryland/MD/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Massachusetts/MA/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Michigan/MI/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Minnesota/MN/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Mississippi/MS/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Missouri/MO/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Montana/MT/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Nebraska/NE/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Nevada/NV/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/New Hampshire/NH/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/New Jersey/NJ/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/New Mexico/NM/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/New York/NY/g' /usr/local/etc/stripped.csv
sudo sed -i 's/North Carolina/NC/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/North Dakota/ND/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Ohio/OH/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Oklahoma/OK/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Oregon/OR/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Pennsylvania/PA/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Puerto Rico/PR/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Rhode Island/RI/g' /usr/local/etc/stripped.csv
sudo sed -i 's/South Carolina/SC/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Tennessee/TN/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Texas/TX/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Utah/UT/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Vermont/VT/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Virginia/VA/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Washington/WA/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/West Virginia/WV/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Wisconsin/WI/g' /usr/local/etc/stripped.csv
#sudo sed -i 's/Wyoming/WY/g' /usr/local/etc/stripped.csv
sudo sed -i 's/DMR Mental Ward/TGIF Mothership/g' /usr/local/etc/groups.txt
sudo sed -i 's/DMR Campfire/TGIF Mothership/g' /usr/local/etc/groups.txt
cp /usr/local/etc/stripped2.csv /usr/local/etc/users.csv
sudo mount -o remount,ro /

