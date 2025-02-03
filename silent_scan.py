#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SILENT STEALTH SCANNER - SCANSIONE NON RILEVABILE E VULN ANALYSIS
"""

import os
import sys
import subprocess
import time
from multiprocessing import Pool
import requests
import re

# Configurazione
TOR_PROXY = "socks5://127.0.0.1:9050"
TIMING = "T0"  # Timing paranoid per nmap
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; rv:102.0) Gecko/20100101 Firefox/102.0"

def check_dependencies():
    required = ['nmap', 'nikto', 'nuclei', 'searchsploit']
    missing = [pkg for pkg in required if not shutil.which(pkg)]
    if missing:
        print(f"[!] Strumenti mancanti: {', '.join(missing)}")
        sys.exit(1)

def stealth_scan(target):
    print(f"\n\033[94m[⚡] Avvio scansione stealth su {target}\033[0m")
    
    # Scansione porte con tecniche evasive
    nmap_cmd = [
        'nmap', '-sS', '-Pn', '-n', '-T', TIMING,
        '--data-length', '25', '-f', '-D', 'RND:5',
        '-oX', 'scan.xml', target
    ]
    subprocess.run(nmap_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Estrai porte aperte
    ports = []
    with open('scan.xml', 'r') as f:
        ports = re.findall(r'portid="(\d+)"', f.read())
    
    return ports

def vulnerability_check(target, ports):
    print("\033[93m[🔍] Ricerca vulnerabilità silenziosa...\033[0m")
    
    # Scansione vulnerabilità attraverso Tor
    vuln_checks = []
    with Pool(3) as p:
        vuln_checks.append(p.apply_async(nikto_scan, (target,)))
        vuln_checks.append(p.apply_async(nuclei_scan, (target,)))
        vuln_checks.append(p.apply_async(search_exploits, (target, ports)))
    
    results = [res.get() for res in vuln_checks]
    return results

def nikto_scan(target):
    try:
        cmd = [
            'nikto', '-host', target, '-Format', 'xml',
            '-output', 'nikto.xml', '-useragent', USER_AGENT,
            '-maxtime', '2m', '-nointeractive'
        ]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return parse_nikto()
    except:
        return []

def nuclei_scan(target):
    try:
        cmd = [
            'nuclei', '-u', target, '-silent', '-severity', 'critical,high',
            '-exclude-severity', 'info,low,medium', '-j', '-proxy', TOR_PROXY
        ]
        result = subprocess.check_output(cmd).decode()
        return [line for line in result.split('\n') if line]
    except:
        return []

def search_exploits(target, ports):
    try:
        exploits = []
        cmd = ['searchsploit', '--nmap', 'scan.xml', '-j']
        result = subprocess.check_output(cmd).decode()
        exploits += re.findall(r'"Title":"(.*?)"', result)
        
        # Verifica moduli Metasploit
        msf_modules = check_msf_modules(target, ports)
        return exploits + msf_modules
    except:
        return []

def check_msf_modules(target, ports):
    modules = []
    if '80' in ports or '443' in ports:
        modules.append('exploit/multi/http/rails_json_processing')
    if '22' in ports:
        modules.append('auxiliary/scanner/ssh/ssh_login')
    return modules

def print_results(vulns, exploits):
    print("\n\033[91m[💣] RISULTATI CRITICI:\033[0m")
    for v in vulns[0] + vulns[1]:
        print(f" - {v}")
    
    print("\n\033[92m[🔓] POSSIBILI EXPLOIT:\033[0m")
    for e in vulns[2]:
        print(f" - {e}")
    
    print("\n\033[95m[💡] SUGGERIMENTI DI ACCESSO:\033[0m")
    if any('ssh' in e.lower() for e in vulns[2]):
        print(" - Prova brute-force SSH con Hydra: hydra -l user -P wordlist.txt ssh://" + target)
    if any('http' in e.lower() for e in vulns[2]):
        print(" - Verifica SQLi manuale: ' OR 1=1 --")

def cleanup():
    for f in ['scan.xml', 'nikto.xml']:
        try: os.remove(f)
        except: pass

if __name__ == "__main__":
    check_dependencies()
    target = input("[?] Inserisci target (IP/URL): ").strip()
    
    try:
        ports = stealth_scan(target)
        vulns = vulnerability_check(target, ports)
        print_results(vulns, [])
    except Exception as e:
        print(f"[!] Errore: {str(e)}")
    finally:
        cleanup()