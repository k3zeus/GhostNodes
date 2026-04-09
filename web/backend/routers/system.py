import psutil
import os
import time
import subprocess
import socket
import platform
from .auth import verify_jwt, verify_admin
from fastapi import APIRouter, Depends, HTTPException

router = APIRouter()

def is_port_open(port):
    """Verifica se uma porta está aberta no localhost."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(0.5)
        return s.connect_ex(('127.0.0.1', port)) == 0

@router.get("/apps", dependencies=[Depends(verify_jwt)])
def list_apps():
    """Retorna lista de aplicações externas e seus status."""
    apps = [
        {
            "id": "cockpit",
            "name": "Cockpit",
            "description": "System Administration & Terminal",
            "port": 9090,
            "url_path": ":9090",
            "icon": "terminal"
        },
        {
            "id": "pihole",
            "name": "Pi-hole DNS",
            "description": "Network-wide Ad Blocking",
            "port": 80,
            "url_path": "/admin",
            "icon": "shield"
        },
        {
            "id": "syncthing",
            "name": "Syncthing",
            "description": "Continuous File Synchronization",
            "port": 8384,
            "url_path": ":8384",
            "icon": "refresh-cw"
        },
        {
            "id": "portainer",
            "name": "Portainer",
            "description": "Docker Container Management GUI",
            "port": 9443,
            "url_path": ":9443",
            "icon": "box"
        }
    ]
    
    # Adiciona status real via verificação de porta
    for app in apps:
        app["status"] = "online" if is_port_open(app["port"]) else "offline"
        
    return apps

_CACHE = {}
_CACHE_TTL = 3  # Segundos

def get_cpu_temp():
    """Detecta a temperatura de forma adaptativa conforme o S.O."""
    os_name = platform.system()
    
    if os_name == 'Windows':
        try:
            output = subprocess.check_output(
                ["powershell", "-Command", "Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace 'root/wmi' | Select -ExpandProperty CurrentTemperature"],
                stderr=subprocess.STDOUT, timeout=2
            ).decode().strip()
            if output and output.isdigit():
                return round((float(output) / 10.0) - 273.15, 1)
        except Exception:
            pass
        return 0.0

    if os_name == 'Darwin': # macOS
        try:
            res = subprocess.check_output(["sysctl", "-n", "machdep.xcpm.cpu_thermal_level"], timeout=1).decode().strip()
            return float(res)
        except Exception:
            return 0.0

    # Padrão Linux (Debian, Arch, Ubuntu, OrangePi)
    thermal_paths = [
        "/sys/class/thermal/thermal_zone0/temp",
        "/sys/devices/virtual/thermal/thermal_zone1/temp",
        "/sys/class/hwmon/hwmon0/temp1_input",
        "/sys/class/thermal/thermal_zone1/temp"
    ]
    
    try:
        if hasattr(psutil, "sensors_temperatures"):
            temps = psutil.sensors_temperatures()
            if temps:
                for name, entries in temps.items():
                    if entries: return entries[0].current
        
        for path in thermal_paths:
            if os.path.exists(path):
                with open(path, "r") as f:
                    t = float(f.read().strip())
                    return t / 1000.0 if t > 1000 else t
    except Exception:
        pass
    return 0.0

def get_connected_hosts_count(interface="wlan0"):
    if os.name == 'nt': return 1 
    
    try:
        res = subprocess.check_output(["hostapd_cli", "-i", interface, "all_sta"], stderr=subprocess.STDOUT, timeout=1).decode()
        return res.count("dot11RSNAStatsSTAAddress")
    except Exception:
        try:
            with open("/proc/net/arp", "r") as f:
                lines = f.readlines()[1:] 
                return sum(1 for line in lines if interface in line)
        except Exception:
            return 0

def get_network_info():
    net_data = {
        "wired": {"status": "offline", "ip": "N/A", "iface": "none"},
        "wlan0": {"status": "offline", "ip": "N/A", "connected_hosts": 0, "iface": "none"},
        "wlan1": {"status": "offline", "ip": "N/A", "connected_hosts": 0, "iface": "none"}
    }
    
    try:
        addrs = psutil.net_if_addrs()
        stats = psutil.net_if_stats()
        
        for iface, if_info in addrs.items():
            ipv4 = "N/A"
            for snic in if_info:
                if snic.family == 2: # AF_INET
                    ipv4 = snic.address
                    break
            
            is_up = stats[iface].isup if iface in stats else False
            
            if iface.startswith(("eth", "end", "enp")) or "Ethernet" in iface:
                net_data["wired"] = {"status": "online" if is_up else "offline", "ip": ipv4, "iface": iface}
            elif iface == "wlan0" or "Wi-Fi" in iface:
                if net_data["wlan0"]["status"] == "online" and ("Wi-Fi" in iface or "Wireless" in iface) and iface != net_data["wlan0"]["iface"]:
                    net_data["wlan1"] = {"status": "online" if is_up else "offline", "ip": ipv4, "connected_hosts": get_connected_hosts_count(iface), "iface": iface}
                else:
                    net_data["wlan0"] = {"status": "online" if is_up else "offline", "ip": ipv4, "connected_hosts": get_connected_hosts_count(iface), "iface": iface}
            elif iface == "wlan1":
                net_data["wlan1"] = {"status": "online" if is_up else "offline", "ip": ipv4, "connected_hosts": get_connected_hosts_count("wlan1"), "iface": "wlan1"}
            elif iface.startswith("wlan"):
                if net_data["wlan1"]["status"] == "offline":
                    target = "wlan1" if net_data["wlan0"]["status"] == "online" else "wlan0"
                    net_data[target] = {"status": "online" if is_up else "offline", "ip": ipv4, "connected_hosts": get_connected_hosts_count(iface), "iface": iface}

    except Exception:
        pass
    return net_data

@router.get("/hardware", dependencies=[Depends(verify_jwt)])
def hardware_stats():
    now = time.time()
    if "hw" in _CACHE and (now - _CACHE["hw"]["timestamp"]) < _CACHE_TTL:
        return _CACHE["hw"]["data"]

    cpu_usage = psutil.cpu_percent(interval=None) 
    mem_info = psutil.virtual_memory()

    data = {
        "cpu_percent": cpu_usage,
        "temperature_c": get_cpu_temp(),
        "memory_percent": mem_info.percent,
        "memory_used_mb": round(mem_info.used / (1024*1024), 2),
        "memory_total_mb": round(mem_info.total / (1024*1024), 2),
        "network": get_network_info()
    }

    _CACHE["hw"] = {"timestamp": now, "data": data}
    return data

@router.post("/power", dependencies=[Depends(verify_admin)])
def system_power(action: str):
    """Executa comandos de Reboot ou Shutdown (Admin apenas)."""
    if action not in ["reboot", "shutdown"]:
        return {"status": "error", "message": "Invalid action"}
    
    os_name = platform.system()
    try:
        if os_name == 'Linux':
            cmd = "sudo reboot" if action == "reboot" else "sudo halt"
            subprocess.Popen(cmd.split())
            return {"status": "success", "message": f"System will {action} now"}
        else:
            print(f"[MOCK] System {action} triggered via API")
            return {"status": "success", "message": f"Action {action} simulated in development mode."}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@router.post("/users/linux", dependencies=[Depends(verify_admin)])
def create_linux_user(payload: dict):
    """Cria um novo usuário comum no sistema operacional Linux."""
    username = payload.get("username")
    password = payload.get("password")
    
    if not username or not password:
        raise HTTPException(status_code=400, detail="Username and Password required")
    
    if os.name == 'nt':
        print(f"[MOCK] Created Linux user: {username}")
        return {"status": "success", "message": f"Linux user {username} creation simulated."}
        
    try:
        subprocess.run(["sudo", "useradd", "-m", "-s", "/bin/bash", username], check=True)
        # Define senha via stdin pipe para segurança rudimentar
        p1 = subprocess.Popen(["echo", f"{username}:{password}"], stdout=subprocess.PIPE)
        subprocess.run(["sudo", "chpasswd"], stdin=p1.stdout, check=True)
        return {"status": "success", "message": f"User {username} created successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
