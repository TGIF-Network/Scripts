#!/bin/bash

if [ ! "$1" ]; then
    echo "Usage GetRadioId Callsign"
exit
fi

inp="$1"
call=$(echo "${inp^^}")

 grep "$call", /usr/local/etc/stripped2.csv | cut -d ',' -f1,2
