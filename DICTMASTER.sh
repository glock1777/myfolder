#!/bin/bash
# ------------------------------------------------------------------------------
# DICTMASTER - GENERATORE INTELLIGENTE DI WORDLIST
# ------------------------------------------------------------------------------

# Configurazione
BASE_DIR="$HOME/.dictmaster"
WORDLIST_DIR="$BASE_DIR/wordlists"
CONFIG_DIR="$BASE_DIR/config"
LOG_FILE="$BASE_DIR/dictmaster.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Inizializzazione ambiente
init_environment() {
    mkdir -p "$WORDLIST_DIR" "$CONFIG_DIR"
    touch "$LOG_FILE"
}

# Menu principale
show_menu() {
    clear
    echo -e "${GREEN}"
    echo " ██████╗ ██╗ ██████╗████████╗███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ "
    echo "██╔════╝ ██║██╔════╝╚══██╔══╝████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗"
    echo "██║  ███╗██║██║        ██║   ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝"
    echo "██║   ██║██║██║        ██║   ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗"
    echo "╚██████╔╝██║╚██████╗   ██║   ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║"
    echo " ╚═════╝ ╚═╝ ╚═════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "${BLUE}1) Crea nuova wordlist"
    echo "2) Gestisci wordlist esistenti"
    echo "3) Impostazioni avanzate"
    echo "4) Esci"
    echo -e "${NC}"
}

# Generatore di wordlist
generate_wordlist() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local output_dir="$WORDLIST_DIR/$timestamp"
    mkdir -p "$output_dir"
    
    echo -e "${YELLOW}[+] Configurazione nuova wordlist${NC}"
    
    # Selezione parametri
    read -p "Lunghezza minima (default 6): " min_len
    read -p "Lunghezza massima (default 8): " max_len
    read -p "Includere maiuscole? (s/n): " uppercase
    read -p "Includere numeri? (s/n): " numbers
    read -p "Includere simboli? (s/n): " symbols
    read -p "Parole chiave specifiche (separate da virgola): " keywords
    
    # Costruzione pattern
    local charset="abcdefghijklmnopqrstuvwxyz"
    [[ $uppercase == "s" ]] && charset+="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    [[ $numbers == "s" ]] && charset+="0123456789"
    [[ $symbols == "s" ]] && charset+="!@#$%^&*()_+-="
    
    # Nome file
    local counter=1
    while [[ -f "$output_dir/wl_${timestamp}_${counter}.txt" ]]; do
        ((counter++))
    done
    local output_file="$output_dir/wl_${timestamp}_${counter}.txt"
    
    # Generazione con crunch
    echo -e "${GREEN}[+] Generazione in corso...${NC}"
    crunch ${min_len:-6} ${max_len:-8} "$charset" -o "$output_file" >/dev/null 2>&1
    
    # Aggiunta keyword
    if [[ -n "$keywords" ]]; then
        echo "$keywords" | tr ',' '\n' >> "$output_file"
    fi
    
    # Ordinamento e rimozione duplicati
    sort -u "$output_file" -o "$output_file"
    
    echo -e "${GREEN}[✓] Wordlist generata: ${output_file}${NC}"
    echo "$(date) - Generated: $output_file" >> "$LOG_FILE"
}

# Gestione wordlist esistenti
manage_wordlists() {
    echo -e "${YELLOW}[+] Wordlist disponibili:${NC}"
    local i=1
    declare -a wordlists
    for wl in $(find "$WORDLIST_DIR" -name "*.txt"); do
        wordlists[$i]=$wl
        echo "$i) $wl"
        ((i++))
    done
    
    read -p "Seleziona wordlist (numero) o 0 per tornare indietro: " choice
    [[ $choice -eq 0 ]] && return
    
    selected_wl=${wordlists[$choice]}
    echo -e "\n${BLUE}Operazioni disponibili per: ${selected_wl}${NC}"
    echo "1) Mostra statistiche"
    echo "2) Filtra contenuto"
    echo "3) Unisci con altra wordlist"
    echo "4) Elimina"
    
    read -p "Scelta: " operation
    case $operation in
        1) show_stats "$selected_wl" ;;
        2) filter_wordlist "$selected_wl" ;;
        3) merge_wordlists "$selected_wl" ;;
        4) delete_wordlist "$selected_wl" ;;
        *) echo -e "${RED}Scelta non valida${NC}" ;;
    esac
}

# Main loop
init_environment
while true; do
    show_menu
    read -p "Scelta: " choice
    
    case $choice in
        1) generate_wordlist ;;
        2) manage_wordlists ;;
        3) advanced_settings ;;
        4) exit 0 ;;
        *) echo -e "${RED}Scelta non valida${NC}" ;;
    esac
    
    read -p "Premi invio per continuare..."
done