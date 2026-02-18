#!/bin/bash
#################################################################
# Nextion Screen Support – flexible model + variant selection  #
# Downloads scripts/support files from GitHub                  #
# Copies to Nextion_Support and NX????.tft to /usr/local/etc   #
# Returns script duration as completion flag                   #
# KF6S/VE3RD 2021 → updated 2026                               #
#################################################################

# Base models we officially recognize
VALID_BASE_MODELS=("NX3224K024" "NX4832K035" "NX4832K025" "NX8048K070" "NX8048P070")

# ────────────────────────────────────────────────
# Helper: Normalize user input → base + suffix
# Examples:
#   NX4832K035-KDO      → base=NX4832K035  suffix=-KDO
#   nx4832k025-kdo-rd   → base=NX4832K025  suffix=-KDO-RD
#   NX4832K035          → base=NX4832K035  suffix=""
# ────────────────────────────────────────────────
normalize_screen() {
    local input=$(echo "$1" | tr '[:lower:]' '[:upper:]' | tr -d ' ')
    local base=""
    local suffix=""

    # Try to match known base models first
    for model in "${VALID_BASE_MODELS[@]}"; do
        if [[ "$input" == "$model"* ]]; then
            base="$model"
            suffix="${input#"$model"}"   # everything after base
            break
        fi
    done

    # If no match → invalid
    if [[ -z "$base" ]]; then
        echo "Invalid screen model: $1" >&2
        return 1
    fi

    echo "$base|$suffix"
    return 0
}

# ────────────────────────────────────────────────
# Main variables
# ────────────────────────────────────────────────
if [ -z "$1" ]; then
    clear
    echo -e "\nNo screen name provided\n"
    echo "Valid base models: ${VALID_BASE_MODELS[*]}"
    echo "You may append -KDO, -KDO-RD, -KDO-Beta etc."
    echo
    echo "Syntax: $0 NX4832K035[-KDO|-KDO-RD] [Beta|Upgrade] [feedback]"
    echo "    or: $0 NX4832K025-KDO-RD ..."
    exit 1
fi

# Normalize input
read -r SCN SUFFIX < <(normalize_screen "$1")
if [[ $? -ne 0 ]]; then exit 1; fi

RELEASE=$([ "$2" = "Beta" ] || [ "$2" = "Upgrade" ] || [ "$2" = "RD" ] && echo "Upgrade" || echo "0")
FEEDBACK=$3
CALL_TXT="EA7KDO"
TEMP_DIR="/home/pi-star/Nextion_Temp"
SUPPORT_DIR="/usr/local/etc/Nextion_Support"
TFT_DIR="/usr/local/etc"

# Logging & error helpers
logit()    { echo "$1" &>> /home/pi-star/gc.log; }
exit_error() {
    echo "Script Execution Failed: $SCN$SUFFIX - $1" >&2
    exit 1
}

clean_dirs() {
    sudo rm -rf "$TEMP_DIR"          && logit "Removed $TEMP_DIR"
    sudo rm -f  "$TFT_DIR"/*.tft     && logit "Removed existing TFT files"
}

clone_repo() {
    local url="$1" tft_name="$2"
    clean_dirs
    sudo git clone --depth 1 "$url" "$TEMP_DIR" || exit_error "Git clone failed: $url"
    [ ! -f "$TEMP_DIR/$tft_name.tft" ] && exit_error "TFT file not found: $tft_name.tft"
    logit "Cloned $url → $tft_name.tft"
}

copy_support_files() {
    local tft_name="$1"
    sudo mkdir -p "$SUPPORT_DIR"
    sudo chmod +x "$TEMP_DIR"/*.sh 2>/dev/null

    # Copy everything except some special files
    sudo rsync -qru --exclude='NX*.tft' --exclude='*.ini' \
        "$TEMP_DIR"/ "$SUPPORT_DIR/"

    sudo cp "$TEMP_DIR/$tft_name.tft" "$TFT_DIR/" || exit_error "Copy TFT failed"

    [ "$FEEDBACK" ] && echo -e "Downloaded package → $tft_name.tft\nCopied to $TFT_DIR/"
}

copy_config_files() {
    local configs=("ColorThemes.ini" "profiles.ini" "wifiprofiles.ini")
    for cfg in "${configs[@]}"; do
        if [[ ! -f "/etc/$cfg" && -f "$TEMP_DIR/$cfg" ]]; then
            sudo cp "$TEMP_DIR/$cfg" /etc/
            [ "$FEEDBACK" ] && echo "Copied $cfg → /etc/"
        elif [[ "$FEEDBACK" ]]; then
            echo "$cfg already exists in /etc/ – skipped"
        fi
    done
}

# ────────────────────────────────────────────────
# 7-inch family (original logic preserved)
# ────────────────────────────────────────────────
process_7inch() {
    local repo_base="https://github.com/TGIF-Network"
    local repo_suffix="-KDO-Beta"

    case "$SCN" in
        NX8048K070)  clone_repo "$repo_base/NX8048K070$repo_suffix"  "$SCN" ;;
        NX8048P070)  clone_repo "$repo_base/NX8048P070$repo_suffix"  "$SCN" ;;
        *) exit_error "Unknown 7-inch model: $SCN";;
    esac

    copy_support_files "$SCN"
    copy_config_files
    sudo /home/pi-star/Scripts/installND127.sh 2>/dev/null
    [ "$FEEDBACK" ] && echo "Installed NextionDriver v1.27"
}

# ────────────────────────────────────────────────
# 3.5-inch family – now supports variant suffixes
# ────────────────────────────────────────────────
process_3inch() {
    local repo_base="https://github.com/TGIF-Network"
    local repo=""

    case "$SCN" in
        NX4832K035)
            if [[ "$SUFFIX" == *-KDO-RD* ]]; then
                repo="$repo_base/NX4832K035-KDO-RD"
            elif [[ "$RELEASE" == "Upgrade" || "$SUFFIX" == *-KDO-Beta* ]]; then
                repo="$repo_base/NX4832K035-KDO-Beta"
            else
                repo="$repo_base/NX4832K035-KDO"
            fi
            ;;

        NX4832K025)
            # Assuming NX4832K025 uses -KDO-RD or similar variant
            # Adjust repo name if your actual repo is different
            if [[ "$SUFFIX" == *-KDO-RD* ]]; then
                repo="$repo_base/NX4832K025-KDO-RD"
            else
                repo="$repo_base/NX4832K025-KDO"      # fallback / default
            fi
            ;;

        *) exit_error "Unhandled 3.5-inch model: $SCN";;
    esac

    clone_repo "$repo" "$SCN"
    copy_support_files "$SCN"
    copy_config_files
}

# ────────────────────────────────────────────────
# 2.4-inch (original logic)
# ────────────────────────────────────────────────
process_24inch() {
    local repo_base="https://github.com/TGIF-Network"
    clone_repo "$repo_base/NX3224K024-KDO" "$SCN"
    copy_support_files "$SCN"
    copy_config_files
}

# ────────────────────────────────────────────────
# Main logic
# ────────────────────────────────────────────────
main() {
    echo "$(date)" > /home/pi-star/gc.log
    local start=$(date +%s.%N)

    [ "$FEEDBACK" ] || exec 2>/dev/null

    sudo mount -o remount,rw /
    sleep 1
    sudo systemctl stop cron.service 2>/dev/null

    case "$SCN" in
        NX8048*)    process_7inch   ;;
        NX4832K*)   process_3inch   ;;
        NX3224K*)   process_24inch  ;;
        *) exit_error "No processor for model $SCN";;
    esac

    [ ! -f "$TFT_DIR/$SCN.tft" ] && exit_error "Missing final TFT file"

    sudo systemctl start cron.service 2>/dev/null

    local duration=$(echo "$(date +%s.%N) - $start" | bc)
    local tag=$(git -C "$TEMP_DIR" describe --tags --always 2>/dev/null || echo "unknown")

    printf "%s%s Ready to Flash!\r %.2f secs\n" "$SCN" "$SUFFIX" "$duration"
    [ "$FEEDBACK" ] && echo "Tag/branch: $tag"
}

# ────────────────────────────────────────────────
# Entry point
# ────────────────────────────────────────────────
main

