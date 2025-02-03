#!/bin/bash
# ------------------------------------------------------------------------------
# TITANO - ANTI-FORENSICS PARANOID TOOL
# Elimina ogni traccia digitale in modo irreversibile (livello NSA)
# ------------------------------------------------------------------------------

# ====================== CONFIGURAZIONE PARANOICA ======================
declare -a TARGET_PATHS=(
  "/var/log"                    # Log di sistema
  "/home/*/.bash_history"       # Cronologie shell
  "/home/*/.zsh_history"        
  "/home/*/.cache"              # Cache utente
  "/home/*/.local/share/Trash"  # Cestini utente
  "/tmp"                        # File temporanei
  "/var/tmp"
  "/dev/shm"
  "/run/user/*"
  "/root/.*_history"            # Cronologia root
  "/var/lib/systemd/random-seed"# Semi crittografici
  "/swapfile"                   # File swap
  "/var/swap"
  "/proc/kcore"                 # Dump memoria
)

declare -a HIDDEN_TRACES=(
  "Journal"                     # Journal systemd
  "NTFS Metadata"               # Filesystem metadata
  "Bad Blocks"                  # Settori danneggiati
  "SMART Data"                  # Dati hardware
  "BIOS Logs"                   # Log firmware
)
# ======================================================================

# ---------------------------- FUNZIONI PARANOICHE ----------------------------
wipe_metadata() {
  # Sovrascrittura metadati con pattern DoD 7-pass + Gutmann
  echo "[+] Sovrascrittura metadati filesystem (EXT4/XFS/NTFS)"
  find / -type f -name "*.swp" -exec shred -f -n 7 -z -u {} \;
  find / -type f -name "*.swx" -exec shred -f -n 7 -z -u {} \;
  dd if=/dev/urandom of=/boot/vmlinuz bs=1k count=512 conv=notrunc 2>/dev/null
  exiftool -all= -overwrite_original -r /home 2>/dev/null
}

destroy_journal() {
  # Distruzione totale del journal systemd
  echo "[+] Annichilimento journal systemd"
  journalctl --flush --rotate --vacuum-time=1ms
  shred -f -n 7 /var/log/journal/*/*.journal
  rm -rf /var/log/journal/*
  echo -n "no" > /etc/systemd/journald.conf
  systemctl kill -s SIGKILL systemd-journald
}

purge_memory() {
  # Pulizia memoria fisica e virtuale
  echo "[+] Cancellazione memoria volatile"
  sync && echo 3 > /proc/sys/vm/drop_caches
  dd if=/dev/zero of=/dev/mem bs=1M count=1024 2>/dev/null
  swapoff -a && shred -f -n 7 /swapfile && mkswap /swapfile && swapon -a
}

nuke_ssd() {
  # Secure Erase per SSD (richiede accesso hardware)
  echo "[+] Innesco Secure Erase SSD"
  for disk in $(lsblk -d -o NAME -n); do
    hdparm --user-master u --security-erase-enhanced NULL /dev/$disk
    nvme format /dev/$disk -s 2
  done
}

kill_bios() {
  # Cancellazione log firmware (richiede reboot)
  echo "[+] Pulizia log BIOS/UEFI"
  dmidecode --type 0 | grep -q 'BIOS Information' && 
  echo "echo 1 > /sys/class/dmi/id/log" | at now + 1 minute
}

obliterate_network() {
  # Cancellazione tracce di rete
  echo "[+] Sterminio tracce network"
  conntrack -F
  ip link set dev eth0 down
  macchanger -r eth0
  shred -f -n 7 /var/lib/NetworkManager/* 2>/dev/null
  rm -rf /var/lib/dhcp/*
}

# ---------------------------- ESECUZIONE ----------------------------
if [[ $EUID -ne 0 ]]; then
  echo "[!] Esegui come root: sudo ./titan.sh"
  exit 1
fi

# Avviso apocalittico
cat << "EOF"

████████╗ ██╗████████╗  █████╗  ███╗   ██╗ ██████╗ 
╚══██╔══╝███║╚══██╔══╝██╔══██╗████╗  ██║██╔═══██╗
   ██║   ╚██║   ██║   ███████║██╔██╗ ██║██║   ██║
   ██║    ██║   ██║   ██╔══██║██║╚██╗██║██║   ██║
   ██║    ██║   ██║   ██║  ██║██║ ╚████║╚██████╔╝
   ╚═╝    ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
EOF

echo -e "\n\033[91m[!!!] QUESTO SCRIPT DISTRUGGERÀ OGNI TRACCIA DIGITALE\033[0m"
for i in {3..1}; do
  echo -ne "\r[!] Conferma finale tra $i secondi (CTRL+C per annullare)..."
  sleep 1
done

# ---------------------------- OPERAZIONI FINALI ----------------------------
echo -e "\n\n[+] Fase 1 - Sovrascrittura dati sensibili"
find "${TARGET_PATHS[@]}" -type f -exec shred -f -n 7 -z -u {} \; 2>/dev/null

echo "[+] Fase 2 - Cancellazione tracce avanzate"
wipe_metadata
destroy_journal
purge_memory
obliterate_network

echo "[+] Fase 3 - Attacco hardware"
nuke_ssd
kill_bios

echo "[+] Fase 4 - Copertura temporale"
timedatectl set-ntp false
date -s "1970-01-01 00:00:00"
hwclock --systohc

echo -e "\n\033[92m[✓] Sistema sterilizzato. Riavvia e distruggi fisicamente l'hardware!\033[0m"