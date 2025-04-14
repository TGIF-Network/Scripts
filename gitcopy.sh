#!/bin/bash
#################################################################
# Nextion Screen Support for 2.4", 3.5", and 7.0" Screens       #
# Downloads scripts/support files from GitHub                   #
# Copies to Nextion_Support and NX??? tft to /usr/local/etc     #
# Returns script duration as completion flag                   #
# KF6S/VE3RD                               2021-12-21           #
#################################################################

# Valid screen models
VALID_SCREENS=("NX3224K024" "NX4832K035" "NX8048K070" "NX8048P070")

# Check for screen name parameter
if [ -z "$1" ]; then
    clear
    echo -e "\nNo Screen Name Provided\n\nValid Screens - EA7KDO: ${VALID_SCREENS[*]}\n"
    echo "Syntax: $0 NX????K??? [Beta|Upgrade] [feedback]"
    exit 1
fi

# Configuration
SCN=$(echo "$1" | tr '[:lower:]' '[:upper:]' | cut -c1-10)
RELEASE=$([ "$2" = "Beta" ] || [ "$2" = "Upgrade" ] || [ "$2" = "RD" ]  && echo "Upgrade" || echo "0")
FEEDBACK=$3
CALL_TXT="EA7KDO"
TEMP_DIR="/home/pi-star/Nextion_Temp"
SUPPORT_DIR="/usr/local/etc/Nextion_Support"
TFT_DIR="/usr/local/etc"

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

# Check if screen is valid
is_valid_screen() {
    for screen in "${VALID_SCREENS[@]}"; do
        [ "$SCN" = "$screen" ] && return 0
    done
    return 1
}

# Clone and process repository
clone_repo() {
    local repo_url="$1" model="$2"
    clean_dirs
    sudo git clone --depth 1 "$repo_url" "$TEMP_DIR" || exit_error "Git clone failed"
    [ ! -f "$TEMP_DIR/$model.tft" ] && exit_error "TFT file not found"
    logit "Git clone successful for $model"
}

# Copy support files
copy_support_files() {
    local model="$1"
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

# Process 7.0" screens
process_7inch() {
    local repo_base="https://github.com/TGIF-Network"
    local repo_suffix="-KDO-Beta"  # Preserving Beta as requested
    case "$SCN" in
        "NX8048K070")
            clone_repo "$repo_base/NX8048K070$repo_suffix" "$SCN"
            ;;
        "NX8048P070")
            clone_repo "$repo_base/NX8048P070$repo_suffix" "$SCN"
            ;;
    esac
    copy_support_files "$SCN"
    copy_config_files
    sudo /home/pi-star/Scripts/installND127.sh
    [ "$FEEDBACK" ] && echo "Installed NextionDriver Version 1.27"
}

# Process smaller screens
process_smaller() {
    local repo_base="https://github.com/TGIF-Network"
    case "$SCN" in
        "NX3224K024")
            clone_repo "$repo_base/NX3224K024-KDO" "$SCN"
            ;;
        "NX4832K035")
            local suffix=$([ "$RELEASE" = "Upgrade" ] && echo "-KDO-Beta" || echo "-KDO-RD" || echo "-KDO")
            clone_repo "$repo_base/NX4832K035$suffix" "$SCN"
            ;;
    esac
    copy_support_files "$SCN"
    copy_config_files
}

# Main execution
main() {
    echo "$(date)" > /home/pi-star/gc.log
    [ "$FEEDBACK" ] && ! is_valid_screen && exit_error "Invalid screen name"

    local start=$(date +%s.%N)
    [ "$FEEDBACK" ] || exec 2>/dev/null
    sudo mount -o remount,rw /
    sleep 1
    sudo systemctl stop cron.service

    case "$SCN" in
        NX8048*) process_7inch ;;
        *) process_smaller ;;
    esac

    [ ! -f "$TFT_DIR/$SCN.tft" ] && exit_error "Missing TFT file"
    sudo systemctl start cron.service

    local duration=$(echo "$(date +%s.%N) - $start" | bc)
    local tag=$(git -C "$TEMP_DIR" tag)
    printf "%s %s Ready to Flash!\r %.2f secs\n" "$SCN" "$tag" "$duration"
}

# Validate and run
if ! is_valid_screen; then
    echo "Screen must be one of: ${VALID_SCREENS[*]}"
    exit 1
fi
main

