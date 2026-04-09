# Web App Deployment Guide (GhostNodes Dashboard)

This guide provides step-by-step instructions for running the GhostNodes Web Interface in both development and production (Docker) environments.

---

## 🌐 English

### Prerequisites
- **Backend**: Python 3.10+
- **Frontend**: Node.js 18+ & npm
- **Alternative**: Docker & Docker Compose (Recommended)

### 1. Manual Execution (Development Mode)

#### Backend
```bash
cd web/backend
# (Optional) Create venv
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```
*API will be available at `http://127.0.0.1:8000/api`*

#### Frontend
```bash
cd web/frontend
npm install
npm run dev
```
*Access the UI via the URL provided by Vite (usually `http://127.0.0.1:5173`)*

### 2. Docker Deployment (Recommended)
```bash
cd web
docker-compose up --build -d
```
*The Dashboard will be accessible on port `80`.*

---

## 🇧🇷 Português

### Pré-requisitos
- **Backend**: Python 3.10+
- **Frontend**: Node.js 18+ & npm
- **Alternativa**: Docker & Docker Compose (Recomendado)

### 1. Execução Manual (Modo Desenvolvedor)

#### Backend
```bash
cd web/backend
# (Opcional) Criar venv
python -m venv venv
source venv/bin/activate  # No Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```
*API disponível em `http://127.0.0.1:8000/api`*

#### Frontend
```bash
cd web/frontend
npm install
npm run dev
```
*Acesse a UI via URL do Vite (geralmente `http://127.0.0.1:5173`)*

### 2. Deploy via Docker (Recomendado)
```bash
cd web
docker-compose up --build -d
```
*O Dashboard estará acessível na porta `80`.*

---
> [!TIP]
> **CORS Issues**: If you run the frontend and backend on different IPs, update the CORS settings in `web/backend/main.py`.
