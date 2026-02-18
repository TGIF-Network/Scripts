#!/bin/bash
#######################################################################
# gitcopy.sh - Nextion Screen Support Script
# Downloads EA7KDO / TGIF-Network Nextion files from GitHub
# Supports: NX3224K024, NX4832K035 (KDO/KDO-Beta/KDO-RD/Original), NX8048K070, NX8048P070
#
# New: NX4832K035-Original → loads stable/default https://github.com/TGIF-Network/NX4832K035-KDO
#
# Examples:
#   ./gitcopy.sh NX4832K035 EA7KDO FF          → default -KDO + verbose
#   ./gitcopy.sh NX4832K035-Original EA7KDO FF → same as above (stable -KDO + verbose)
#   ./gitcopy.sh NX4832K035-KDO-RD FF          → RD variant + verbose
#   ./gitcopy.sh NX4832K035 Beta               → -KDO-Beta, silent
#
# Fixed & extended 2026
#######################################################################

VALID_BASE_MODELS=("NX3224K024" "NX4832K035" "NX8048K070" "NX8048P070")

TEMP_DIR="/home/pi-star/Nextion_Temp"
TFT_DIR="/usr/local/etc"
SUPPORT_DIR="$TFT_DIR/Nextion_Support"
LOG_FILE="/home/pi-star/gc.log"

REPO_BASE="https://github.com/TGIF-Network"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"; }

error_exit() {
    echo "ERROR: $*" | tee -a "$LOG_FILE" >&2
    exit 1
}

clean_dirs() {
    sudo rm -rf "$TEMP_DIR" 2>/dev/null && log "Cleaned $TEMP_DIR"
    sudo rm -f "$TFT_DIR"/*.tft 2>/dev/null && log "Removed old .tft files"
}

usage() {
    cat <<EOF

Usage: $0 <screen> [EA7KDO|Beta|Upgrade] [FF]

Examples:
  $0 NX4832K035 EA7KDO FF              → default KDO + verbose
  $0 NX4832K035-Original EA7KDO FF     → default KDO (stable/original) + verbose
  $0 NX4832K035 Beta                   → KDO-Beta, silent
  $0 NX4832K035-KDO-RD FF              → KDO-RD + verbose

Valid base models: ${VALID_BASE_MODELS[*]}

EOF
    exit 1
}

normalize_screen() {
    local input=$(echo "$1" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')
    local base="" suffix=""
    for b in "${VALID_BASE_MODELS[@]}"; do
        if [[ "$input" == "$b"* ]]; then
            base="$b"
            suffix="${input#"$b"}"
            break
        fi
    done
    [[ -z "$base" ]] && error_exit "Invalid screen model: $1"
    echo "$base $suffix"   # Space separated → safer parsing
}

get_repo_url() {
    local model="$1"
    local suffix="$2"
    local release_flag="$3"

    case "$model" in
        "NX3224K024")
            echo "${REPO_BASE}/NX3224K024-KDO"
            ;;
        "NX4832K035")
            suffix_upper=$(echo "$suffix" | tr '[:lower:]' '[:upper:]')
            if [[ "$suffix_upper" == *"-KDO-RD"* || "$suffix_upper" == *"-RD"* ]]; then
                echo "${REPO_BASE}/NX4832K035-KDO-RD"
            elif [[ "$release_flag" == "Upgrade" || "$suffix_upper" == *"-KDO-BETA"* || "$suffix_upper" == *"-BETA"* ]]; then
                echo "${REPO_BASE}/NX4832K035-KDO-Beta"
            elif [[ "$suffix_upper" == *"-ORIGINAL"* ]]; then
                # Explicitly map -Original to stable/default KDO
                echo "${REPO_BASE}/NX4832K035-KDO"
            else
                # Default / stable
                echo "${REPO_BASE}/NX4832K035-KDO"
            fi
            ;;
        "NX8048K070")
            echo "${REPO_BASE}/NX8048K070-KDO-Beta"
            ;;
        "NX8048P070")
            echo "${REPO_BASE}/NX8048P070-KDO-Beta"
            ;;
        *)
            error_exit "No repo defined for model: $model"
            ;;
    esac
}

# ────────────────────────────────────────────────
# Parse arguments
# ────────────────────────────────────────────────
[[ -z "$1" ]] && usage

read -r BASE SUFFIX < <(normalize_screen "$1")

RELEASE_FLAG=""
FEEDBACK=""

if [[ -n "$2" ]]; then
    case "${2^^}" in
        BETA|UPGRADE)
            RELEASE_FLAG="Upgrade"
            ;;
        *) ;;  # EA7KDO or other → ignored for release
    esac
fi

# Feedback if third arg or (second arg present and not beta/upgrade)
if [[ -n "$3" || ( -n "$2" && "$RELEASE_FLAG" != "Upgrade" ) ]]; then
    FEEDBACK=1
fi

TFT_FILE="${BASE}.tft"

log "Starting: ${BASE}${SUFFIX:+-$SUFFIX} | TFT: $TFT_FILE | Release: ${RELEASE_FLAG:-no} | Feedback: ${FEEDBACK:-off}"

# ────────────────────────────────────────────────
# Main execution
# ────────────────────────────────────────────────
main() {
    local start=$(date +%s.%N)

    echo "$(date '+%Y-%m-%d %H:%M:%S') Started for ${BASE}${SUFFIX:+-$SUFFIX}" > "$LOG_FILE"

    [[ $FEEDBACK ]] || exec 2>/dev/null

    sudo mount -o remount,rw / || error_exit "remount rw failed"
    sudo systemctl stop cron.service 2>/dev/null

    clean_dirs

    local repo=$(get_repo_url "$BASE" "$SUFFIX" "$RELEASE_FLAG")

    # Safety fallback (should rarely trigger now)
    if [[ -z "$repo" && "$BASE" == "NX4832K035" ]]; then
        repo="${REPO_BASE}/NX4832K035-KDO"
        log "Fallback: forced NX4832K035-KDO"
    fi

    [[ -z "$repo" ]] && error_exit "Could not determine repo URL"

    log "Cloning: $repo"

    sudo git clone --depth 1 "$repo" "$TEMP_DIR" || error_exit "git clone failed → $repo"

    [[ ! -f "$TEMP_DIR/$TFT_FILE" ]] && error_exit "TFT file missing: $TFT_FILE"

    log "TFT found: $TFT_FILE"

    sudo mkdir -p "$SUPPORT_DIR"
    sudo chmod +x "$TEMP_DIR"/*.sh 2>/dev/null

    sudo rsync -qru --exclude='*.tft' --exclude='ColorThemes.ini' \
        --exclude='profiles.ini' --exclude='wifiprofiles.ini' \
        "$TEMP_DIR/" "$SUPPORT_DIR/" || error_exit "rsync failed"

    sudo cp "$TEMP_DIR/$TFT_FILE" "$TFT_DIR/" || error_exit "copy TFT failed"

    for f in ColorThemes.ini profiles.ini wifiprofiles.ini; do
        if [[ ! -f "/etc/$f" && -f "$TEMP_DIR/$f" ]]; then
            sudo cp "$TEMP_DIR/$f" /etc/
            [[ $FEEDBACK ]] && echo "Copied $f to /etc/"
        elif [[ $FEEDBACK ]]; then
            echo "$f already exists in /etc/ – skipped"
        fi
    done

    if [[ "$BASE" == NX8048* ]]; then
        log "Installing NextionDriver v1.27"
        sudo /home/pi-star/Scripts/installND127.sh 2>/dev/null
        [[ $FEEDBACK ]] && echo "Installed NextionDriver Version 1.27"
    fi

    sudo systemctl start cron.service 2>/dev/null

    local duration=$(echo "$(date +%s.%N) - $start" | bc)
    local tag=$(git -C "$TEMP_DIR" describe --tags --always 2>/dev/null || echo "unknown")

    [[ $FEEDBACK ]] && {
        echo "Repo cloned: $repo"
        echo "Git tag/branch: $tag"
    }

    printf "%s Ready to Flash!\r %s %.2f secs\n" "${BASE}${SUFFIX:+-${SUFFIX}}" "$tag" "$duration"
}

main
exit 0
