from fastapi import APIRouter, Depends
import requests
import os

from .auth import verify_jwt

router = APIRouter()

def rpc_call(method, params=None):
    if params is None:
        params = []
    
    # Credenciais devem vir de um arquivo config central (ou lido dinamicamente via dotenv)
    # Por segurança em desenvolvimento, vamos usar localhost na bridge docker
    RPC_URL = os.getenv("BITCOIN_RPC_URL", "http://172.17.0.1:8332")
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
            timeout=3
        )
        if req.status_code == 200:
            return req.json().get("result")
        return {"error": f"HTTP {req.status_code}", "detail": req.text}
    except Exception as e:
        return {"error": "Connection Failed", "detail": str(e)}

@router.get("/status", dependencies=[Depends(verify_jwt)])
def bitcoin_status():
    """
    Inquérito restrito: Obtém altura dos blocos, conexões e versão puramente via RPC.
    """
    info = rpc_call("getblockchaininfo")
    net = rpc_call("getnetworkinfo")

    if isinstance(info, dict) and "error" in info:
        return {"status": "offline", "details": info}
    
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
