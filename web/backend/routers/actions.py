from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
import subprocess
import os

from .auth import verify_jwt

router = APIRouter()

# ⚠️ WHITELIST DE SEGURANÇA ⚠️
# Apenas os scripts listados aqui podem ser executados pelo Dashboard.
# O caminho relativo deve partir da raiz do repositório.
ALLOWED_SCRIPTS = [
    "halfin/routing.sh",
    "halfin/tools/wifi_scan.sh",
    "halfin/tools/wifi_show.sh",
    "halfin/tools/fixers/fix_docker.sh"
]

class ActionRequest(BaseModel):
    script_path: str

@router.post("/execute", dependencies=[Depends(verify_jwt)])
def execute_script(action: ActionRequest):
    if action.script_path not in ALLOWED_SCRIPTS:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Execution of '{action.script_path}' is strictly forbidden by Whitelist."
        )

    # Determina o caminho base com base na estrutura da API.
    # A API está em web/backend, a raiz está 2 níveis acima.
    BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
    
    target_file = os.path.join(BASE_DIR, action.script_path)
    target_file = os.path.normpath(target_file)
    
    if not os.path.exists(target_file):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Script file not found: {action.script_path}"
        )

    # Prepara o runtime
    try:
        # Se estiver no Windows rodando em Dev, o .sh vai bater no Bash do Windows Subsystem ou Git Bash.
        # Usa sh para evocar (Linux ready)
        process = subprocess.run(
            ["bash", target_file],
            cwd=BASE_DIR,
            capture_output=True,
            text=True,
            timeout=30 # Timeout para evitar scripts infinitos travando o worker web
        )
        
        return {
            "status": "success" if process.returncode == 0 else "error",
            "exit_code": process.returncode,
            "stdout": process.stdout,
            "stderr": process.stderr
        }
    except subprocess.TimeoutExpired:
        raise HTTPException(
            status_code=status.HTTP_408_REQUEST_TIMEOUT,
            detail="Process timed out out after 30 seconds."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
