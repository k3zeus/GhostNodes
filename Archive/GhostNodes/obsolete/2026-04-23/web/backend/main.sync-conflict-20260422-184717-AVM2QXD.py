from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from routers import system, bitcoin, auth, actions, services

app = FastAPI(title="GhostNodes Dashboard API")

# Setup CORS para permitir conexão front-end Vite local/rede local
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Será restrito em prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registra Roteadores
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(system.router, prefix="/api/system", tags=["System"])
app.include_router(bitcoin.router, prefix="/api/bitcoin", tags=["Bitcoin"])
app.include_router(actions.router, prefix="/api/actions", tags=["Actions"])
app.include_router(services.router, prefix="/api/services", tags=["Services"])

# Serve Static Files (Frontend)
frontend_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "frontend", "dist"))

if os.path.exists(frontend_path):
    app.mount("/", StaticFiles(directory=frontend_path, html=True), name="frontend")
else:
    @app.get("/")
    def read_root():
        return {"message": "GhostNodes Dashboard API. Frontend build (dist) not found. Please run 'npm run build' in web/frontend."}

@app.get("/api/health")
def root_health():
    return {"status": "ok", "message": "GhostNodes Backend Online"}

if __name__ == "__main__":
    import uvicorn
    # Port 80 for primary dashboard access
    uvicorn.run("main:app", host="0.0.0.0", port=80, reload=True)
