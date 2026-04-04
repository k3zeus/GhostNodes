from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import jwt
import os
import time

router = APIRouter()
security = HTTPBearer()

# Chave secreta nativa do GhostNodes (em caso de produção, isso virá de secrets docker/env)
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "ghostnodes_sovereign_secret_2026")
ALGORITHM = "HS256"
EXPIRATION_TIME = 86400 # 24 Horas em segundos

class LoginRequest(BaseModel):
    username: str
    password: str

def verify_jwt(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """
    Dependência central para proteger rotas. Valida se o Token JWT é autêntico e não expirado.
    """
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Session has expired. Please login again.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

@router.post("/login")
def login(creds: LoginRequest):
    """
    Autentica usuário e retorna token JWT expirando em 24h caso a credencial case com as do Ghost Nodes.
    """
    # Em produção real estes dados são mapeados num banco SQLite seguro ou env do S.O
    REAL_USER = os.getenv("GHOST_WEB_USER", "pleb").lower()
    REAL_PASS = os.getenv("GHOST_WEB_PASS", "Mudar123")

    if creds.username.lower() == REAL_USER and creds.password == REAL_PASS:
        # Assina payload de segurança
        payload = {
            "sub": creds.username,
            "role": "admin",
            "exp": time.time() + EXPIRATION_TIME
        }
        token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
        return {"access_token": token, "token_type": "bearer"}
    
    # Simula latência anti-bruteforce trivial
    time.sleep(0.5)
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Incorrect username or password",
        headers={"WWW-Authenticate": "Bearer"},
    )
