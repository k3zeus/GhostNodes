from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import jwt
import os
import time
import json

router = APIRouter()
security = HTTPBearer()

# Pasta de dados e arquivo de usuários
DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
USERS_FILE = os.path.join(DATA_DIR, "users.json")

# Chave secreta nativa do GhostNodes
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "ghostnodes_sovereign_secret_2026")
ALGORITHM = "HS256"
EXPIRATION_TIME = 86400 # 24 Horas em segundos

class LoginRequest(BaseModel):
    username: str
    password: str

class UserCreate(BaseModel):
    username: str
    password: str
    role: str # admin or viewer

def load_users():
    if not os.path.exists(USERS_FILE):
        return [{"username": "pleb", "password": "Mudar123", "role": "admin"}]
    with open(USERS_FILE, "r") as f:
        return json.load(f)

def save_users(users):
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(USERS_FILE, "w") as f:
        json.dump(users, f, indent=2)

def verify_jwt(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """
    Dependência central para proteger rotas. Valida se o Token JWT é autêntico e não expirado.
    """
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Session expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

def verify_admin(user: dict = Depends(verify_jwt)):
    if user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Acesso restrito a administradores.")
    return user

@router.post("/login")
def login(creds: LoginRequest):
    users = load_users()
    user = next((u for u in users if u["username"].lower() == creds.username.lower() and u["password"] == creds.password), None)
    
    if user:
        payload = {
            "sub": user["username"],
            "role": user["role"],
            "exp": time.time() + EXPIRATION_TIME
        }
        token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
        return {
            "access_token": token, 
            "token_type": "bearer",
            "role": user["role"],
            "username": user["username"]
        }
    
    time.sleep(0.5)
    raise HTTPException(status_code=401, detail="Incorrect username or password")

@router.get("/users")
def list_users(admin: dict = Depends(verify_admin)):
    users = load_users()
    # Remove senhas do retorno por segurança
    return [{"username": u["username"], "role": u["role"]} for u in users]

@router.post("/users")
def create_user(user_data: UserCreate, admin: dict = Depends(verify_admin)):
    users = load_users()
    if any(u["username"].lower() == user_data.username.lower() for u in users):
        raise HTTPException(status_code=400, detail="Usuário já existe")
    
    users.append({
        "username": user_data.username,
        "password": user_data.password,
        "role": user_data.role
    })
    save_users(users)
    return {"message": "Usuário criado com sucesso"}

@router.delete("/users/{username}")
def delete_user(username: str, admin: dict = Depends(verify_admin)):
    if username.lower() == admin["sub"].lower():
        raise HTTPException(status_code=400, detail="Você não pode deletar a si mesmo")
    
    users = load_users()
    new_users = [u for u in users if u["username"].lower() != username.lower()]
    
    if len(new_users) == len(users):
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
        
    save_users(new_users)
    return {"message": "Usuário removido"}
