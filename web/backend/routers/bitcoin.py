import os
import requests
import subprocess
from fastapi import APIRouter, Depends
from .auth import verify_jwt

router = APIRouter()

def is_satoshi_installed():
    """Verifica se o subprojeto Satoshi Node está presente no sistema."""
    # Locais comuns de instalação no GhostNodes
    paths = [
        "/home/pleb/nodenation/satoshi",
        os.path.expanduser("~/nodenation/satoshi")
    ]
    # Também checa se o binário bitcoin-cli existe (Linux only)
    has_cli = False
    if os.name != 'nt':
        has_cli = subprocess.call(["which", "bitcoin-cli"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0
    return any(os.path.exists(p) for p in paths) or has_cli

def rpc_call(method, params=None):
    if params is None:
        params = []
    
    # Prioriza variáveis de ambiente, fallback para bridge Docker ou Localhost
    RPC_URL = os.getenv("BITCOIN_RPC_URL", "http://127.0.0.1:8332")
    RPC_USER = os.getenv("BITCOIN_RPC_USER", "satoshi")
    RPC_PASS = os.getenv("BITCOIN_RPC_PASS", "changeme")

    payload = {
        "jsonrpc": "1.0",
        "id": "ghostnodes_ui",
        "method": method,
        "params": params
    }

    try:
        req = requests.post(
            RPC_URL, 
            json=payload, 
            auth=(RPC_USER, RPC_PASS),
            timeout=2 # Timeout curto para não travar UI
        )
        if req.status_code == 200:
            return req.json().get("result")
        return {"error": f"HTTP {req.status_code}", "detail": req.text}
    except Exception as e:
        return {"error": "Connection Failed", "detail": str(e)}

@router.get("/status", dependencies=[Depends(verify_jwt)])
def bitcoin_status():
    """
    Retorna o status detalhado do Node Bitcoin.
    Diferencia entre: não instalado, erro de conexão, e sincronizando/online.
    """
    if not is_satoshi_installed() and os.name != 'nt':
        return {
            "status": "waiting_install",
            "message": "Aguardando instalação e conexão com Bitcoin Node"
        }

    info = rpc_call("getblockchaininfo")
    net = rpc_call("getnetworkinfo")

    # Se falhou a conexão mas está instalado (ou em dev Windows)
    if isinstance(info, dict) and "error" in info:
        return {
            "status": "offline", 
            "message": "Node instalado, mas conexão RPC falhou",
            "details": info
        }
    
    if info and net:
        return {
            "status": "online",
            "blocks": info.get("blocks"),
            "headers": info.get("headers"),
            "verificationprogress": info.get("verificationprogress"),
            "connections": net.get("connections"),
            "version": net.get("subversion")
        }
    
    return {"status": "error", "message": "Dados inválidos retornados pelo RPC central."}
