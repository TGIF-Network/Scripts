#!/bin/bash

# radioid_callsign_to_csv.sh
# Bash script to query RadioID.net API for a single callsign and output CSV
# NO dependency on jq – pure bash + curl + grep + sed + awk

if [ $# -ne 1 ]; then
    echo "Usage: $0 <CALLSIGN>"
    echo "Example: $0 VE3RD"
    echo "Output: CSV to stdout (redirect if needed: $0 VE3RD > ve3rd.csv)"
    exit 1
fi

CALLSIGN=$(echo "$1" | tr '[:lower:]' '[:upper:]' | xargs)

API_URL="https://radioid.net/api/dmr/user/?callsign=${CALLSIGN}"

echo "Querying RadioID.net for callsign ${CALLSIGN}..." >&2

#JSON=$(curl -s --fail-with-body "${API_URL}")
JSON=$(curl -s "${API_URL}")

## curl -s https://radioid.net/api/dmr/user/?callsign=VE3RD | cut -d '{' -f3 |tr -d '"' |  cut -d ',' -f1


if [ $? -ne 0 ] || [ -z "$JSON" ]; then
    echo "Error: Failed to reach API or invalid response." >&2
    exit 1
fi

# Check for no results
if echo "$JSON" | grep -q '"count":0'; then
    echo "No results found for callsign ${CALLSIGN}." >&2
    exit 1
fi

COUNT=$(echo "$JSON" | grep -o '"count":[0-9]*' | cut -d: -f2)
if [ -z "$COUNT" ] || [ "$COUNT" -eq 0 ]; then
    echo "No results found for callsign ${CALLSIGN}." >&2
    exit 1
fi

#if [ "$COUNT" -gt 1 ]; then
#    echo "Warning: Multiple ($COUNT) results found for ${CALLSIGN}." >&2
#fi

# CSV header – matches actual API fields (no separate fname/surname)
echo "radio_id,callsign,name,city,state,country,lastheard,lastmaster,lastsource,lasttg"


# Extract each result object {...}
echo "$JSON" | grep -o '{[^}]*}' | while IFS= read -r block; do
    radio_id=$(echo "$block" | sed -n 's/.*"radio_id":\([0-9]*\).*/\1/p')
    callsign=$(echo "$block" | sed -n 's/.*"callsign":"\([^"]*\)".*/\1/p')
    name=$(echo "$block" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
    city=$(echo "$block" | sed -n 's/.*"city":"\([^"]*\)".*/\1/p')
    state=$(echo "$block" | sed -n 's/.*"state":"\([^"]*\)".*/\1/p')
    country=$(echo "$block" | sed -n 's/.*"country":"\([^"]*\)".*/\1/p')
    lastheard=$(echo "$block" | sed -n 's/.*"lastheard":"\([^"]*\)".*/\1/p')
    lastmaster=$(echo "$block" | sed -n 's/.*"lastmaster":"\([^"]*\)".*/\1/p')
    lastsource=$(echo "$block" | sed -n 's/.*"lastsource":"\([^"]*\)".*/\1/p')
    lasttg=$(echo "$block" | sed -n 's/.*"lasttg":"\([^"]*\)".*/\1/p')

    # Output CSV row (empty if field missing)
    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "${radio_id:-}"  "${callsign:-}"  "${name:-}"  "${city:-}" \
        "${state:-}"  "${country:-}"  "${lastheard:-}"  "${lastmaster:-}" \
        "${lastsource:-}"  "${lasttg:-}"
done

exit 0
