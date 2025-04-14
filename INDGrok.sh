#!/bin/bash
############################################################
# Script to automate Nextion Driver installation           #
# VE3RD                                      2020/10/04    #
############################################################
set -o errexit
set -o pipefail

# Constants
VER="20200512"
CONFIG_FILE="/etc/mmdvmhost"
HOME_DIR="/home/pi-star"
NEXTION_DIR="/Nextion"
TEMP_DIR="/temp"
DIALOGRC="$HOME_DIR/.dialogrc"

# Ensure filesystem is writable
ensure_rw() {
    sudo mount -o remount,rw / || { echo "Failed to remount filesystem"; exit 1; }
}

# Setup dialog configuration
setup_dialog() {
    export NCURSES_NO_UTF8_ACS=1
    [[ ! -f "$DIALOGRC" ]] && sudo dialog --create-rc "$DIALOGRC"
    sed -i -e '/use_colors = /c\use_colors = ON' \
           -e '/screen_color = /c\screen_color = (WHITE,BLUE,ON)' \
           -e '/title_color = /c\title_color = (YELLOW,RED,ON)' "$DIALOGRC"
}

# Remove NextionDriver configuration
cleandriver() {
    sed -i '/\[NextionDriver/,/^$/d' "$CONFIG_FILE"
    echo "Removing Nextion Driver Configuration"
    local tport="/dev/ttyUSB0"
    local escaped_port=$(echo "$tport" | sed 's|/|\\/|g')
    echo "Setting Nextion Port to $tport for Pi-Star"
    sudo sed -i "/^\[/h;G;/Nextion]/s/\(Port=\).*/\1$escaped_port/m;P;d" "$CONFIG_FILE"
    [[ -f "$CONFIG_FILE.old" ]] && sudo rm -f "$CONFIG_FILE.old" && echo "Removed old $CONFIG_FILE.old"
    echo "Configuration Removed - Restarting Script"
    sleep 2
}

# Prepare Nextion directory (full cleanup)
prepare_dir() {
    [[ -d "$NEXTION_DIR" ]] && sudo rm -R "$NEXTION_DIR"
    sudo git clone https://github.com/on7lds/NextionDriverInstaller.git "$NEXTION_DIR"
}

# Prepare Nextion directory (if missing)
prepare_dir_if_missing() {
    if [[ ! -d "$NEXTION_DIR" ]]; then
        echo "Downloading Files to create $NEXTION_DIR Directory"
        sudo git clone https://github.com/on7lds/NextionDriverInstaller.git "$NEXTION_DIR"
    fi
}

# Install Nextion Driver
install_nxd() {
    echo -e "\nSTARTING NEXTION DRIVER INSTALLATION\n"
    ensure_rw
    [[ -f /usr/local/bin/NextionDriver ]] && sudo rm -f /usr/local/bin/NextionDriver && echo "Removed existing Nextion Driver"
    echo "Preparing fresh $NEXTION_DIR directory"
    prepare_dir
    if [[ ! -d "$NEXTION_DIR" ]]; then
        echo "Failed to create $NEXTION_DIR - Check permissions"
        exit 1
    fi
    echo "Install Directory created successfully"
    echo "Running the Install Script"
    ensure_rw
    sudo "$NEXTION_DIR/install.sh"
    exit
}

# Main menu dialog
show_main_menu() {
    local height=15 width=60 choice_height=10
    local backtitle="Nextion Driver Installation - VE3RD $VER"
    local title="Main Menu"
    local menu="Select Installation Mode"

    dialog --clear --backtitle "$backtitle" --title "$title" --menu "$menu" \
        $height $width $choice_height \
        1 "Pi-Star Update + Install Nextion Driver" \
        2 "Install Nextion Driver - No Update" \
        3 "Continue after Reboot" \
        4 "Check Nextion Driver Installation" \
        5 "Update stripped.csv" \
        6 "Remove NextionDriver Configuration" \
        7 "Download & Install Screen Support Files" \
        8 "Quit" \
        2>&1 >/dev/tty
}

# Interface selection menu
show_interface_menu() {
    local height=15 width=60 choice_height=10
    local backtitle="Nextion Driver Installation - VE3RD $VER"
    local title="Screen-to-Pi Interface"
    local menu="Choose your Interface"

    dialog --clear --backtitle "$backtitle" --title "$title" --menu "$menu" \
        $height $width $choice_height \
        1 "USB to TTL Interface" \
        2 "GPIO Pins" \
        3 "Quit" \
        2>&1 >/dev/tty
}

# Temperature selection menu
show_temp_menu() {
    local height=15 width=60 choice_height=10
    local backtitle="Nextion Driver Installation - VE3RD $VER"
    local title="Temperature Display"
    local menu="Select Temperature Type"

    dialog --clear --backtitle "$backtitle" --title "$title" --menu "$menu" \
        $height $width $choice_height \
        1 "Fahrenheit" \
        2 "Celsius" \
        3 "Quit" \
        2>&1 >/dev/tty
}

# Main execution
main() {
    ensure_rw
    setup_dialog
    clear
    echo -e '\e[1;44m'
    echo "This script installs the Nextion Driver. A reboot is required midway."
    echo "After reboot, run this script again and select 'Continue'"
    echo -e '\e[0m'
    sleep 3

    [[ ! -d "$TEMP_DIR" ]] && sudo mkdir "$TEMP_DIR"

    CHOICE=$(show_main_menu)
    clear
    echo -e '\e[1;37m'

    case "$CHOICE" in
        1) echo "Pi-Star Update + Install"; sudo systemctl stop cron.service; sudo pistar-update; install_nxd ;;
        2) echo "Install - No Update"; install_nxd ;;
        3) echo "Continue after Reboot" ;;
        4) echo "Checking Installation"; prepare_dir_if_missing; sudo "$NEXTION_DIR/check_installation.sh"; sleep 7; exec "$0" ;;
        5) sudo wget -O /usr/local/etc/stripped2.csv https://database.radioid.net/static/user.csv; exec "$0" ;;
        6) cleandriver; exec "$0" ;;
        7) echo "Installing Screen Support Files"; sudo ./gitcopy2.sh; exec "$0" ;;
        8) echo "Quit"; exit 0 ;;
    esac

    # Post-installation steps
    echo "Checking Nextion Driver Installation"
    prepare_dir_if_missing
    sudo "$NEXTION_DIR/check_installation.sh"
    sleep 3

    ensure_rw
    sudo chmod 755 /usr/local/sbin/nextion* 2>/dev/null || true
    sed -i -e "/^\[/h;G;/Nextion]/s/\(Brightness=\).*/\199/m;P;d" \
           -e "/^\[/h;G;/Nextion]/s/\(IdleBrightness=\).*/\199/m;P;d" \
           -e "/^\[/h;G;/NextionDriver]/s/\(LogLevel=\).*/\12/m;P;d" \
           -e "/^\[/h;G;/Nextion]/s/\(Port=\).*/\1\/dev\/ttyNextionDriver/m;P;d" "$CONFIG_FILE"

    # Platform-specific port settings
    if [[ -d "/home/rock/" ]]; then
        tport="/dev/ttyAML0"
        echo "Setting NextionDriver Port to $tport for RadXA Board"
    else
        tport="/dev/ttyUSB0"
        echo "Setting NextionDriver Port to $tport for Pi-Star"
    fi
    escaped_port=$(echo "$tport" | sed 's|/|\\/|g')
    sudo sed -i -e "/^\[/h;G;/NextionDriver]/s/\(Port=\).*/\1$escaped_port/m;P;d" \
                -e "/^\[/h;G;/NextionDriver]/s/\(WaitForLan=\).*/\11/m;P;d" "$CONFIG_FILE"
    sleep 2

    # Interface selection
    CHOICE=$(show_interface_menu)
    clear
    ensure_rw
    case "$CHOICE" in
        1) echo "Setting USB to TTL Interface, ScreenLayout 4"
           sudo sed -i -e "/^\[/h;G;/Nextion]/s/\(Port=\).*/\1\/dev\/ttyNextionDriver/m;P;d" \
                      -e "/^\[/h;G;/NextionDriver]/s/\(Port=\).*/\1\/dev\/ttyUSB0/m;P;d" \
                      -e "/^\[/h;G;/Nextion/s/\(ScreenLayout=\).*/\14/m;P;d" \
                      -e "/^\[/h;G;/NextionDriver/s/\(WaitForLan=\).*/\10/m;P;d" "$CONFIG_FILE"
           [[ -d "/home/rock/" ]] && sudo sed -i "/^\[/h;G;/NextionDriver]/s/\(Port=\).*/\1\/dev\/ttyAML0/m;P;d" "$CONFIG_FILE"
           sleep 3 ;;
        2) echo "Setting GPIO Interface, ScreenLayout 3"
           sudo sed -i -e "/^\[/h;G;/Nextion]/s/\(Port=\).*/\1\/dev\/ttyNextionDriver/m;P;d" \
                      -e "/^\[/h;G;/NextionDriver]/s/\(Port=\).*/\1\/dev\/ttyAMA0/m;P;d" \
                      -e "/^\[/h;G;/Nextion/s/\(ScreenLayout=\).*/\13/m;P;d" "$CONFIG_FILE"
           sleep 3 ;;
        3) exit 0 ;;
    esac

    # Temperature setting
    if ! grep -q "DisplayTempInFahrenheit" "$CONFIG_FILE"; then
        ensure_rw
        sed -i "/^\[Nextion\]/a DisplayTempInFahrenheit=0" "$CONFIG_FILE"
    fi
    CHOICE=$(show_temp_menu)
    clear
    case "$CHOICE" in
        1) echo "Fahrenheit Selected"; sudo sed -i "/^\[/h;G;/Nextion/s/\(DisplayTempInFahrenheit=\).*/\11/m;P;d" "$CONFIG_FILE"; sleep 3 ;;
        2) echo "Celsius Selected"; sudo sed -i "/^\[/h;G;/Nextion/s/\(DisplayTempInFahrenheit=\).*/\10/m;P;d" "$CONFIG_FILE"; sleep 3 ;;
        3) exit 0 ;;
    esac

    # Final configuration
    ensure_rw
    [[ "$1" != "Bata" ]] && sudo sed -i -e '/DMRid/s/^#//g' \
                                    -e "/^\[/h;G;/NextionDriver/s/\(DMRidX1=\).*/\15/m;P;d" \
                                    -e "/^\[/h;G;/NextionDriver/s/\(DMRidX2=\).*/\16/m;P;d" \
                                    -e "/^\[/h;G;/NextionDriver/s/\(DMRidFile=\).*/\1stripped2.csv/m;P;d" "$CONFIG_FILE"

    if grep -q "SendUserDataMask" "$CONFIG_FILE"; then
        sudo sed -i "/^\[/h;G;/NextionDriver/s/\(SendUserDataMask=\).*/\10b01011111/m;P;d" "$CONFIG_FILE"
    else
        sed -i '/^\[NextionDriver\]/a SendUserDataMask=0b01011111' "$CONFIG_FILE"
    fi

    # Install dependencies and configure
    sudo apt-get install -y bc
    echo "iptables -A OUTPUT -p tcp --dport 5040 -j ACCEPT" | sudo tee /root/ipv4.fw >/dev/null
    [[ -d "$TEMP_DIR" ]] && sudo rm -R "$TEMP_DIR"

    if [[ ! -f /etc/cron.daily/getstripped ]]; then
        echo "Setting up daily getstripped cron job"
        sudo cp "$HOME_DIR/Scripts/getstripped.sh" /etc/cron.daily/getstripped
    fi

    sudo pistar-firewall
    [[ -f "$HOME_DIR/ndis.txt" ]] && sudo rm -f "$HOME_DIR/ndis.txt"
    sudo "$HOME_DIR/Scripts/getstripped.sh"

    echo -e '\e[1;37m'
    echo "Nextion Driver Installation Completed"
    echo "Rebooting in 5 seconds..."
    sleep 5
    sudo reboot
}

main
