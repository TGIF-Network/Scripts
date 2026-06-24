# Scripts-TGIF — Pi-Star / TGIF Network Utility Scripts

A collection of Bash (and one Python) scripts for managing Pi-Star hotspots
connected to the TGIF DMR network, specifically supporting Nextion touchscreen
displays and associated configuration tasks.

All scripts are designed to run on a Pi-Star image (Raspberry Pi or ODROID).
Pi-Star mounts the filesystem read-only by default; these scripts use
`sudo mount -o remount,rw /` as needed before writing any files.

---

## Nextion Screen — File Download

These scripts pull TFT firmware and support files from the TGIF-Network GitHub
repositories and install them into the correct Pi-Star directories, ready for
flashing.

| Script | Description |
|--------|-------------|
| `gitcopy.sh` | **Primary / current version.** Downloads the correct screen package from TGIF-Network GitHub based on model and variant. Supports NX3224K024, NX4832K035 (KDO / KDO-Beta / KDO-RD), NX8048K070, and NX8048P070. Accepts model, variant, and verbosity flags. Logs to `/home/pi-star/gc.log`. |
| `gitcopy9.sh` | Expanded refactor of `gitcopy.sh` adding support for NX4832K025. Uses helper functions for cloning, rsyncing support files, and copying `.ini` config files. |
| `gitcopygrok.sh` | AI-assisted refactor of the gitcopy family; functionally similar to `gitcopy9.sh`. |
| `gitcopy2.sh` | Older interactive version. Presents a `dialog` menu to pick a 2.4" or 3.5" EA7KDO screen, then clones and installs the package. Also runs `NextionDriver4M17.sh`. |
| `gitcopy3.sh` | Extended interactive version. Adds VE3ZRD screen variants (3.5", 3.2", 2.4") alongside EA7KDO choices. |
| `gitcopyall.sh` | Downloads all supported TGIF-Network screen packages at once. |
| `gitzrd.sh` | Downloads VE3ZRD-branded screen packages (NX4832K035-ZRD, NX4024K032-ZRD, NX3224K024-ZRD) from TGIF-Network GitHub by passing the screen model as `$1`. |
| `gitcopy-orig.sh` | Original/baseline version of the gitcopy scripts; preserved for reference. |
| `gitcopytest.sh` | Test/development version; do not use in production. |

---

## Nextion Screen — Flashing

| Script / File | Description |
|---------------|-------------|
| `flash.sh` | **Current flash utility.** Interactive `dialog` menu that scans `/usr/local/etc/` for `.tft` files, lets you select one, stops required services (pistar-watchdog, mmdvmhost, nextiondriver), and calls `nextion.py` via Python 3 to flash the screen. Reboots when done. |
| `flash-bak.sh` | Backup / older version of `flash.sh`. Uses Python 2 instead of Python 3. Limited to two screen file choices. |
| `nextion.py` | Python 2 serial utility (by Alex Koren, GPL). Negotiates baud rate with the Nextion screen over serial, then transfers the `.tft` binary. Called by `flash.sh` / `flash-bak.sh`. Requires `python-serial`. |

---

## Nextion Driver — Installation & Maintenance

| Script | Description |
|--------|-------------|
| `IND.sh` | **Nextion Driver Installation Utility.** Main interactive installer. Menu options: Pi-Star update + install, install only, continue after reboot, check installation, update `stripped.csv`, remove driver config, and download screen support files. Configures port (USB or GPIO), temperature units, DMRid fields, and firewall rule. |
| `INDGrok.sh` | Refactored version of `IND.sh` with cleaner function structure. Functionally equivalent. |
| `installND127.sh` | Installs the pre-compiled `NextionDriver` v1.27 binary (included in this repo as `NextionDriver`) directly into `/usr/local/bin/`, replacing the running version. |
| `updatend.sh` | Builds NextionDriver from source: clones the ON7LDS/NextionDriver repository, compiles it with `make`, and installs the resulting binary. |
| `nfudt.sh` | Updates the Nextion support files in place: runs `git pull` in `/home/pi-star/Nextion_Temp`, then rsyncs changes to `/usr/local/etc/Nextion_Support`. |
| `nslog.sh` | Sets the NextionDriver `LogLevel` in `/etc/mmdvmhost`. Accepts `2` (normal) or `4` (debug) as the argument. |
| `NextionDriver` | Pre-compiled NextionDriver v1.27 binary (patched). Used by `installND127.sh`. |

---

## Host File & Network Management

| Script | Description |
|--------|-------------|
| `prime.sh` | Installs a TGIF Network "Secured" entry into `/root/DMR_Hosts.txt` using a 16-character security password supplied on the command line or read from `/home/pi-star/Prime.txt`. Runs `HostFilesUpdate.sh` afterward. |
| `mnet.sh` | Installs an MNet_Network entry into `/root/DMR_Hosts.txt` using a 15-character password from the command line or `/home/pi-star/MNet.txt`. Runs `HostFilesUpdate.sh` afterward. |
| `mnetcom.sh` | Updates `/etc/DMR_Hosts.txt` to replace the old MNet hostname (`mnet.hopto.org`) with the current one (`mnetdmr.com`). Creates a `.bak` backup of the file. |
| `p25mnet.sh` | Adds MNet P25 talk group entries (TG 10210, TG 10211) to `/root/P25Hosts.txt` if they are not already present. Runs `HostFilesUpdate.sh`. |
| `nss.sh` | Interactive DMR hosts editor. Prompts for a server hostname, searches both the main and custom `DMR_Hosts.txt` files, and presents an editable form to add or update the entry. **Obsolete.** |
| `nss2.sh` | Same as `nss.sh` but pre-populated for the `prime.tgif.network` entry specifically. **Obsolete.** |
| `uhf.sh` | Calls `HostFilesUpdate.sh` to refresh all Pi-Star host files. Quick utility when a manual host file update is needed. |
| `releasetg.sh` | Sends a curl request to the TGIF API to release the current talk group and switch to TG4000 (unlink). Reads the user's DMR ID from `/etc/mmdvmhost` or `/etc/dmrgateway` to build the API URL. |
| `nss.info` | Help/instruction text displayed by `nss.sh` before the editor opens. |
| `nss2.info` | Help/instruction text displayed by `nss2.sh`. |

---

## User Database

| Script / File | Description |
|---------------|-------------|
| `getstripped.sh` | Downloads the RadioID user database (`user.csv`) from `database.radioid.net` and saves it as `/usr/local/etc/stripped.csv`. Applies country/state name abbreviations (e.g. "United States" → "USA", "North Carolina" → "NC"). Also copies the file to `users.csv` and `stripped2.csv`. |
| `getuserinfo.sh` | Looks up a callsign or DMR ID in `stripped.csv` / `stripped2.csv` and returns selected fields. Pass the call as `$1` and a field code as `$2` (e.g. `3` = first name, `567` = city/state/country). Used by other scripts. |
| `queryradioid.sh` | Queries the RadioID.net REST API for a single callsign and outputs a CSV row (radio_id, callsign, name, city, state, country, last-heard info). Pure bash — no `jq` dependency. |
| `convert_long.sh` | Reads `stripped.csv` line by line, looks up full country names against `country.csv`, and replaces them with short codes in place. |
| `2getstripped.sh` | Test/experimental version of `getstripped.sh`. **Do not use.** |
| `stripped2.csv` | Supplemental user database pre-filled with YSF user entries. |
| `user.csv` | User database file; NextionDriver v1.27+ uses this as its default lookup file. |
| `country.csv` | Mapping table of full country names to 2–3 letter abbreviations; used by `convert_long.sh`. |
| `groups.txt` | DMR talk group definitions list. |

---

## Pi-Star Configuration

| Script | Description |
|--------|-------------|
| `modes.sh` | Interactive checklist (`dialog`) to enable or disable any combination of D-Star, DMR, YSF, NXDN, and P25 in `/etc/mmdvmhost`. Displays current state as ON/OFF for each mode. |
| `hsconfig.sh` | Comprehensive MMDVMHost configurator. Provides interactive `dialog` menus to view and edit modes, DMRGateway network sections (up to 6 networks), RF/net timers, display type, running services, and log file viewer. |
| `lookup.sh` | Sets the user lookup service in `/etc/pistar-css.ini` to either `QRZ` or `RadioID`. Pass `Q` (or nothing) for QRZ, `R` for RadioID. |
| `getversions.sh` | Displays the Pi-Star version string from `/etc/pistar-release`. |
| `restartMMDVM.sh` | Restarts `mmdvmhost.service`. |
| `netlog.sh` | Real-time DMR net logging tool. Tails the MMDVM log, identifies new calls vs. duplicates, looks up caller info from `stripped.csv`, tracks the net controller, and writes a timestamped log to `/home/pi-star/netlog.log`. Run with `netlog.sh [NetControlCall] [NEW] [NODUPES]`. |
| `update.sh` | Pulls the latest scripts from the git repository and runs `getstripped.sh` to refresh the user database. |

---

## WiFi Management

| Script | Description |
|--------|-------------|
| `wifi.sh` | Interactive WiFi utility. Scans for SSIDs using `iwlist`, shows a `dialog` radio-button list, prompts for a password, and connects via `nmcli`. Also supports shortcut arguments `Home` and `Phone` to connect to pre-defined networks. |
| `startwifi.sh` | Simple one-liner template to connect to a specified SSID/password via `nmcli`. Edit the `ssid` and `pwd` variables before use. |
| `createwpasupplicant.sh` | Prompts for an SSID and password, then creates a `wpa_supplicant.conf` file in `/home/pi-star/`. Run with the `install` argument to copy it to `/etc/wpa_supplicant/`. Must be run as root. |

---

## Security & Firewall

| Script | Description |
|--------|-------------|
| `setfw.sh` | Adds an `iptables` rule to allow outbound TCP port 5040 (required for the NextionDriver to communicate with the TGIF network) and runs `pistar-firewall` to apply rules. |
| `encodepw.sh` | Prompts for the Pi-Star password, Base64-encodes it, and writes the encoded string to `/etc/pspass` for later use by other utilities. |

---

## P25 Reflector

| Script / File | Description |
|---------------|-------------|
| `P25R-Install.sh` | Clones the `g4klx/P25Clients` repository, compiles `P25Reflector`, installs the binary to `/usr/local/bin`, copies the `.ini` config to `/etc/`, and adds an auto-start entry to `/etc/rc.local`. |
| `p25reflector.service` | Startup/stop/restart/status wrapper script for the P25Reflector daemon. Installed to `/usr/local/sbin/`. |

---

## Pi-Star Dashboard Fix

| File | Description |
|------|-------------|
| `functions.php` | PHP patch for the Pi-Star web dashboard that corrects the "Not Linked" display issue on P25. Drop this file into the appropriate Pi-Star web directory to apply the fix. |
