from fastapi import APIRouter, Depends
import psutil
import os
import time

from .auth import verify_jwt

router = APIRouter()

_CACHE = {}
_CACHE_TTL = 3 # Segundos

def get_cpu_temp():
    try:
        if hasattr(psutil, "sensors_temperatures"):
            temps = psutil.sensors_temperatures()
            if temps:
                for name, entries in temps.items():
                    if entries:
                        return entries[0].current
        thermal_path = "/sys/class/thermal/thermal_zone0/temp"
        if os.path.exists(thermal_path):
            with open(thermal_path, "r") as f:
                return float(f.read().strip()) / 1000.0
    except Exception:
        pass
    return 0.0

def get_network_info():
    net_info = {"wlan0": {"status": "offline", "ip": "N/A", "connected_hosts": 0}, 
                "wlan1": {"status": "offline", "ip": "N/A", "connected_hosts": 0}}
    try:
        addrs = psutil.net_if_addrs()
        stats = psutil.net_if_stats()
        
        for iface in ["wlan0", "wlan1"]:
            if iface in addrs:
                # Is interface up?
                is_up = stats[iface].isup if iface in stats else False
                if is_up:
                    net_info[iface]["status"] = "online"
                    
                # Find IPv4
                for addr in addrs[iface]:
                    if addr.family == 2: # AF_INET
                        net_info[iface]["ip"] = addr.address
                        
                # Mock connected hosts since it requires arp/hostapd cli to read real hosts reliably
                # If online and has IP, we simulate 1-3 connections for layout showcase for now
                if net_info[iface]["status"] == "online" and net_info[iface]["ip"] != "N/A":
                     net_info[iface]["connected_hosts"] = 2 if iface == "wlan1" else 1

    except Exception:
        pass
        
    return net_info

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
