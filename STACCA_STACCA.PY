#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
STACCA_STACCA.PY - SCRIPT DI PULIZIA SICURA PER PARROT OS - VERSIONE 5.0
*** USO ESCLUSIVO IN AMBIENTI AUTORIZZATI ***
"""

import os
import sys
import shutil
import subprocess
from pathlib import Path

# ================= CONFIGURAZIONE =================
LOG_PATHS = [
    # Log di sistema
    "/var/log",
    "/var/backups",
    "/var/cache",
    
    # Log utente
    "~/.bash_history",
    "~/.zsh_history",
    "~/.cache",
    "~/.local/share/Trash",
    "~/.thumbnails",
    "~/.recently-used",
    
    # Tracce applicazioni
    "~/.msf4",
    "~/.sqlite_history",
    "~/.wget-hsts",
    "~/.npm",
    "~/.ssh/known_hosts",
    
    # Browser
    "~/.config/chromium",
    "~/.config/google-chrome",
    "~/.mozilla/firefox",
    
    # File temporanei
    "/tmp",
    "/var/tmp",
    "/dev/shm"
]

OVERWRITE_ITERATIONS = 3  # Iterazioni di sovrascrittura
# ===================================================

def check_root():
    """Verifica i privilegi di root"""
    if os.getuid() != 0:
        print("\n[!] Esegui con: sudo python3 stacca_stacca.py\n")
        sys.exit(1)

def secure_delete(path):
    """Elimina file/directory in modo sicuro"""
    try:
        target = Path(path)
        if not target.exists():
            return
            
        if target.is_file():
            subprocess.run(["shred", "-f", "-u", f"-n{OVERWRITE_ITERATIONS}", str(target)])
            print(f"[✓] File sovrascritto: {path}")
            
        elif target.is_dir():
            shutil.rmtree(str(target), ignore_errors=True)
            print(f"[✓] Directory eliminata: {path}")
            
    except Exception as e:
        print(f"[!] Errore su {path}: {str(e)}")

def clean_journal():
    """Pulizia avanzata del journal systemd"""
    if not shutil.which("journalctl"):
        return
        
    try:
        subprocess.run(["journalctl", "--flush", "--rotate"])
        subprocess.run(["journalctl", "--vacuum-time=1s"])
        subprocess.run(["shred", "-f", "-u", "-n2", "/var/log/journal/*"])
        print("[✓] Journal systemd pulito")
    except Exception as e:
        print(f"[!] Errore journal: {str(e)}")

def clean_logs():
    """Pulizia totale dei log"""
    for path in LOG_PATHS:
        expanded_path = os.path.expanduser(path)
        secure_delete(expanded_path)

def clean_ram():
    """Pulizia memoria volatile"""
    try:
        subprocess.run(["sync"])
        subprocess.run(["echo 3 > /proc/sys/vm/drop_caches"], shell=True)
        subprocess.run(["swapoff", "-a"])
        subprocess.run(["swapon", "-a"])
        print("[✓] RAM/swap puliti")
    except Exception as e:
        print(f"[!] Errore RAM: {str(e)}")

def main():
    check_root()
    
    # Avviso drammatico
    print("\n\033[91m" + "═"*60)
    print("⚠️  ATTENZIONE: OPERAZIONE IRREVERSIBILE ⚠️".center(60))
    print("═"*60 + "\033[0m")
    
    # Conferma a 3 step
    for i in range(3):
        res = input(f"\nCONFERMA {i+1}/3 (s/n): ").lower()
        if res != 's':
            print("\n[✓] Operazione annullata\n")
            sys.exit(0)
    
    # Esecuzione
    print("\n\033[93m[🚀] Avvio pulizia totale...\033[0m")
    clean_logs()
    clean_journal()
    clean_ram()
    
    # Finale
    print("\n\033[92m[✓] Sistema pulito! Riavvia ora!\033[0m\n")

if __name__ == "__main__":
    main()