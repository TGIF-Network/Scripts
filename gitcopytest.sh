#!/bin/bash
#################################################################
# Nextion Screen Support NX4832K035 Test Package                #
# Downloads scripts/support files from GitHub                   #
# Copies to Nextion_Support and NX??? tft to /usr/local/etc     #
# Returns script duration as completion flag                    #
# VE3RD                               2025-07-21                #
#################################################################

# Valid screen models
VALID_SCREENS=("NX4832K035")

# Configuration
SCN=$(echo "$1" | tr '[:lower:]' '[:upper:]' | cut -c1-10)
RELEASE="TEST"
FEEDBACK="XX"
CALL_TXT="EA7KDO"
TEMP_DIR="/home/pi-star/Nextion_Temp"
SUPPORT_DIR="/usr/local/etc/Nextion_Support"
TFT_DIR="/usr/local/etc"
Model="NX4832K035"

# Logging function
logit() { echo "$1" &>> /home/pi-star/gc.log; }

# Error exit function
exit_error() {
    echo "Script Execution Failed: $SCN - $1"
    exit 1
}

# Clean directories
clean_dirs() {
    sudo rm -rf "$TEMP_DIR" && logit "Removed $TEMP_DIR"
    sudo rm -f "$TFT_DIR"/*.tft && logit "Removed existing TFT files"
}

# Clone and process repository
clone_repo() {
    clean_dirs
    sudo git clone --depth 1 "https://www.github.com/TGIF-Network/NX4832K035-KDO-Test" "/home/pi-star/Nextion_Temp"
    logit "Git clone successful for $model"
}

# Copy support files
copy_support_files() {
    local model="NX4832K035"
    sudo mkdir -p "$SUPPORT_DIR"
    sudo chmod +x "$TEMP_DIR"/*.sh
    sudo rsync -qru --exclude='NX*' --exclude='ColorThemes.ini' --exclude='profiles.ini' \
        --exclude='wifiprofiles.ini' "$TEMP_DIR"/* "$SUPPORT_DIR/"
    sudo cp "$TEMP_DIR/$model.tft" "$TFT_DIR/"
    [ "$FEEDBACK" ] && echo -e "Downloaded package for $model.tft\nCopied TFT to $TFT_DIR/"
}

# Copy config files if needed
copy_config_files() {
    local configs=("ColorThemes.ini" "profiles.ini" "wifiprofiles.ini")
    for config in "${configs[@]}"; do
        if [ ! -f "/etc/$config" ] && [ -f "$TEMP_DIR/$config" ]; then
            cp "$TEMP_DIR/$config" /etc/
            [ "$FEEDBACK" ] && echo "Copied $config to /etc/"
        elif [ "$FEEDBACK" ]; then
            echo "$config found in /etc/ - Not copied"
        fi
    done
}

# Process smaller screens
Get_Screen_Package() {
    clone_repo "http://www.github.com/TGIF-Netword/NX4832K035-KDO-Test"
    copy_support_files 
    copy_config_files
}

# Main execution
main() {
    echo "$(date)" > /home/pi-star/gc.log
    Get_Screen_Package
    local start=$(date +%s.%N)
    [ "$FEEDBACK" ] || exec 2>/dev/null
    sudo mount -o remount,rw /
    sleep 1
    sudo systemctl stop cron.service


    [ ! -f "/usr/local/etc/NX4832K035.tft" ] && exit_error "Missing TFT file"
    sudo systemctl start cron.service

    local duration=$(echo "$(date +%s.%N) - $start" | bc)
    local tag=$(git -C "$TEMP_DIR" tag)
    printf "%s %s Ready to Flash!\r %.2f secs\n" "$SCN" "$tag" "$duration"
}

main

