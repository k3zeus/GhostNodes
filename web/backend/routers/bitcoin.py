import os
import requests
import subprocess
from fastapi import APIRouter, Depends
from .auth import verify_jwt

router = APIRouter()

BITCOIN_CONF = "/home/bitcoin/.bitcoin/bitcoin.conf"
BITCOIN_SERVICE = "satoshi-bitcoind.service"


def is_satoshi_installed():
    """Verifica se o subprojeto Satoshi Node esta presente no sistema."""
    gn_root = os.getenv("GN_ROOT", os.path.expanduser("~/nodenation"))
    paths = [
        os.path.join(gn_root, "satoshi"),
        "/home/pleb/nodenation/satoshi",
        os.path.expanduser("~/nodenation/satoshi"),
    ]
    has_cli = subprocess.call(["which", "bitcoin-cli"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0
    return any(os.path.exists(path) for path in paths) or has_cli


def load_rpc_env():
    gn_root = os.getenv("GN_ROOT", os.path.expanduser("~/nodenation"))
    env_paths = [
        os.path.join(gn_root, "var", "bitcoin-rpc.env"),
        "/home/pleb/nodenation/var/bitcoin-rpc.env",
    ]
    values = {}
    for path in env_paths:
        if not os.path.exists(path):
            continue
        try:
            with open(path, "r", encoding="utf-8") as env_file:
                for line in env_file:
                    line = line.strip()
                    if not line or line.startswith("#") or "=" not in line:
                        continue
                    key, value = line.split("=", 1)
                    values[key] = value.strip().strip('"')
        except OSError:
            continue
        break
    return values


def read_bitcoin_mode():
    if not os.path.exists(BITCOIN_CONF):
        return {"mode": "unknown", "prune_mb": None, "txindex": None}

    mode = "full"
    prune_mb = None
    txindex = None
    try:
        with open(BITCOIN_CONF, "r", encoding="utf-8") as conf_file:
            for line in conf_file:
                line = line.strip()
                if line.startswith("prune="):
                    try:
                        prune_mb = int(line.split("=", 1)[1])
                        mode = "pruned" if prune_mb > 0 else "full"
                    except ValueError:
                        mode = "unknown"
                elif line.startswith("txindex="):
                    txindex = line.split("=", 1)[1]
    except OSError:
        return {"mode": "unknown", "prune_mb": None, "txindex": None}
    return {"mode": mode, "prune_mb": prune_mb, "txindex": txindex}


def service_state():
    try:
        result = subprocess.run(
            ["systemctl", "is-active", BITCOIN_SERVICE],
            capture_output=True,
            text=True,
            timeout=2,
            check=False,
        )
        return result.stdout.strip() or "unknown"
    except Exception:
        return "unknown"


def rpc_call(method, params=None):
    if params is None:
        params = []

    rpc_env = load_rpc_env()
    RPC_URL = os.getenv("BITCOIN_RPC_URL", rpc_env.get("BITCOIN_RPC_URL", "http://127.0.0.1:8332"))
    RPC_USER = os.getenv("BITCOIN_RPC_USER", rpc_env.get("BITCOIN_RPC_USER", "satoshi"))
    RPC_PASS = os.getenv("BITCOIN_RPC_PASS", rpc_env.get("BITCOIN_RPC_PASS", "changeme"))

    payload = {
        "jsonrpc": "1.0",
        "id": "ghostnodes_ui",
        "method": method,
        "params": params,
    }

    try:
        req = requests.post(
            RPC_URL,
            json=payload,
            auth=(RPC_USER, RPC_PASS),
            timeout=2,
        )
        if req.status_code == 200:
            return req.json().get("result")
        return {"error": f"HTTP {req.status_code}", "detail": req.text}
    except Exception as exc:
        return {"error": "Connection Failed", "detail": str(exc)}


@router.get("/status", dependencies=[Depends(verify_jwt)])
def bitcoin_status():
    config = read_bitcoin_mode()
    service = service_state()

    if not is_satoshi_installed() and os.name != "nt":
        return {
            "status": "waiting_install",
            "message": "Aguardando instalacao e conexao com Bitcoin Node",
            "service": service,
            "config": config,
        }

    info = rpc_call("getblockchaininfo")
    net = rpc_call("getnetworkinfo")

    if isinstance(info, dict) and "error" in info:
        return {
            "status": "offline",
            "message": "Node instalado, mas conexao RPC falhou",
            "details": info,
            "service": service,
            "config": config,
        }

    if info and net:
        return {
            "status": "online",
            "blocks": info.get("blocks"),
            "headers": info.get("headers"),
            "verificationprogress": info.get("verificationprogress"),
            "connections": net.get("connections"),
            "version": net.get("subversion"),
            "service": service,
            "config": config,
        }

    return {"status": "error", "message": "Dados invalidos retornados pelo RPC central.", "service": service, "config": config}
