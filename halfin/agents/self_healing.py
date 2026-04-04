#!/usr/bin/env python3
# ╔══════════════════════════════════════════════════════════════╗
# ║  Ghost Nodes — Self Healing Daemon (Extensivo)               ║
# ╚══════════════════════════════════════════════════════════════╝

import os
import time
import subprocess
import logging

GN_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LOG_FILE = os.path.expanduser("~/nodenation/halfin/logs/self_healing.log")
os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

# Path to the library of standard bash fixers
FIXERS_DIR = os.path.join(GN_ROOT, "halfin", "tools", "fixers")

logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] GhostHealing: %(message)s'
)

# Required network interfaces for the node to function
CRITICAL_IFACES = ["br0", "wlan0"]


def ping_container(container_name):
    """ Verifica se o container está rodando e saudável. """
    try:
        output = subprocess.check_output(
            ["docker", "inspect", "-f", "{{.State.Running}}", container_name],
            stderr=subprocess.DEVNULL
        )
        return output.decode('utf-8').strip() == "true"
    except Exception:
        return False

def check_interface(iface_name):
    """ Verifica se a interface de rede existe e está UP. """
    try:
        output = subprocess.check_output(
            ["ip", "link", "show", iface_name],
            stderr=subprocess.DEVNULL
        )
        return "state UP" in output.decode('utf-8')
    except Exception:
        return False

def check_gateway():
    """ Verifica se existe uma rota default de internet (Gateway ativo). """
    try:
        output = subprocess.check_output(
            ["ip", "route"],
            stderr=subprocess.DEVNULL
        )
        return "default via" in output.decode('utf-8')
    except Exception:
        return False


def call_fixer(fixer_name, *args):
    """ Chama um script modular em vez de corrigir manualmente no python """
    fixer_path = os.path.join(FIXERS_DIR, f"{fixer_name}.sh")
    if not os.path.exists(fixer_path):
        logging.error(f"Fixer '{fixer_name}' not found at {fixer_path}")
        return False

    logging.warning(f"Triggering fixer: {fixer_name} {' '.join(args)}")
    try:
        subprocess.check_call([fixer_path, *args])
        logging.info(f"Fixer '{fixer_name}' succeeded.")
        return True
    except subprocess.CalledProcessError as e:
        logging.error(f"Fixer '{fixer_name}' failed with code {e.returncode}")
        return False

def scan_health():
    """ Procura falhas na rede e nos containers vitais """
    
    # 1. Checa a saúde da rede
    for iface in CRITICAL_IFACES:
        if not check_interface(iface):
            logging.error(f"Interface {iface} is DOWN or MISSING!")
            call_fixer("fix_network", iface)
            return # Aguarda o próximo ciclo para não embolar
            
    if not check_gateway():
        logging.error("No default gateway detected!")
        call_fixer("fix_gateway", "default")
    
    # 2. Checa containers apenas se a rede estiver ok
    critical_containers = ["wireguard", "syncthing", "cloudflared", "pihole"]
    for c in critical_containers:
        if not ping_container(c):
            call_fixer("fix_docker", c)

def main():
    if not os.path.exists(FIXERS_DIR):
        os.makedirs(FIXERS_DIR)
        
    logging.info("Healing Daemon inicializado. Latência: 5 min")
    # Low footprint sleep cycle
    while True:
        try:
            scan_health()
        except Exception as e:
            logging.critical(f"Healing loop crashed: {e}")
        time.sleep(300)

if __name__ == "__main__":
    main()
