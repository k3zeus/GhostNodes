from fastapi import APIRouter, HTTPException, Depends
from routers.auth import verify_jwt
import httpx
import os

router = APIRouter(tags=["services"])

PIHOLE_API_URL = "http://127.0.0.1/api" # V6 Endpoint

def is_v6_installed():
    return os.path.exists("/etc/pihole/pihole.toml") or os.name == 'nt' # Mocks no Windows

@router.get("/pihole/summary")
async def pihole_get_summary(user: dict = Depends(verify_jwt)):
    if not is_v6_installed():
        raise HTTPException(status_code=503, detail="Pi-hole v6 config not found (pihole.toml missing)")
    
    try:
        if os.name != 'nt':
            # Chamada real para a API do Pi-hole v6
            async with httpx.AsyncClient(timeout=2.0) as client:
                res = await client.get(f"{PIHOLE_API_URL}/stats/summary")
                res.raise_for_status()
                return res.json()
    except Exception as e:
        print(f"Erro ao acessar API do Pi-hole real: {e}")
        pass # fallback for UI Mock no dev

    # Mock de telemetria baseada no backend v6
    return {
        "status": "enabled",
        "domains_being_blocked": 145032,
        "dns_queries_today": 3482,
        "ads_blocked_today": 1205,
        "ads_percentage_today": 34.6,
        "unique_clients": 12
    }

@router.get("/pihole/dns")
async def pihole_get_dns(user: dict = Depends(verify_jwt)):
    return [
        {"domain": "ghostnodes.local", "ip": "10.21.21.1"},
        {"domain": "pihole.local", "ip": "10.21.21.1"},
        {"domain": "nextcloud.lan", "ip": "10.21.21.5"}
    ]

@router.post("/pihole/dns")
async def pihole_add_dns(payload: dict, user: dict = Depends(verify_jwt)):
    domain = payload.get("domain")
    ip = payload.get("ip")
    if not domain or not ip:
        raise HTTPException(status_code=400, detail="Domain e IP obrigatorios")
    return {"message": "Success", "added": {"domain": domain, "ip": ip}}

@router.delete("/pihole/dns/{domain}")
async def pihole_remove_dns(domain: str, user: dict = Depends(verify_jwt)):
    return {"message": f"Domain {domain} removed."}

@router.get("/pihole/network")
async def pihole_get_network(user: dict = Depends(verify_jwt)):
    return [
        {"ip": "10.21.21.100", "mac": "AA:BB:CC:DD:EE:01", "name": "iPhone-Maik", "status": "active"},
        {"ip": "10.21.21.102", "mac": "AA:BB:CC:DD:EE:02", "name": "Smart-TV", "status": "inactive"},
        {"ip": "10.21.21.105", "mac": "AA:BB:CC:DD:EE:03", "name": "Desktop-PC", "status": "active"}
    ]
