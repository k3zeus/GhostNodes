# Web App Setup Guide 🌐🚀

This document provides a comprehensive step-by-step guide to installing, configuring, and running the GhostNodes Web Dashboard.

---

## 1. Prerequisites
Before starting, ensure your system has the following dependencies:
- **Python 3.14+** (Earlier versions 3.10+ may work but are not officially supported).
- **Node.js 18+** & **npm**.
- **Virtualenv** (for Python dependency isolation).
- **Git** (for repository synchronization).

---

## 2. Backend Installation (FastAPI)

1. **Navigate to the backend directory:**
   ```bash
   cd web/backend
   ```
2. **Create and activate a virtual environment:**
   ```bash
   python -m venv .venv
   # Linux/macOS
   source .venv/bin/activate
   # Windows
   .\.venv\Scripts\activate
   ```
3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```
4. **Environment Configuration:**
   Create a `.env` file (optional) to override default settings:
   ```env
   BITCOIN_RPC_URL=http://localhost:8332
   BITCOIN_RPC_USER=satoshi
   BITCOIN_RPC_PASS=changeme
   JWT_SECRET=your_custom_secret_key
   ```
5. **Run the server:**
   ```bash
   python main.py
   # Or using uvicorn directly:
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```
   *The API will be available at `http://localhost:8000`.*

---

## 3. Frontend Installation (React)

1. **Navigate to the frontend directory:**
   ```bash
   cd web/frontend
   ```
2. **Install Node dependencies:**
   ```bash
   npm install
   ```
3. **Run in Development Mode:**
   ```bash
   npm run dev
   ```
   *The dashboard will be available at `http://localhost:3000` (or 3001 if 3000 is occupied).*

4. **Production Build (Optional):**
   To generate a static bundle for deployment:
   ```bash
   npm run build
   ```

---

## 4. Production Deployment (OrangePi Zero 3)

In the official GhostNodes environment, the Web App is managed by **NodeNation**.

### Automated Start
```bash
./nodenation web-start
```

### Systemd Integration (Recommended)
GhostNodes uses a systemd service to ensure the dashboard starts on boot.
- Service Name: `ghostnodes-web.service`
- Path: `/etc/systemd/system/`

---

## 5. Troubleshooting / FAQ

- **Backend fails to detect temperature:** Ensure your user has read access to `/sys/class/thermal/`.
- **Bitcoin Node shows offline:** Check if `bitcoind` is running and the RPC credentials in `bitcoin.py` match your `bitcoin.conf`.
- **401 Unauthorized:** Your login session has expired. Log out and log in again to refresh the JWT token.
- **Port 8000 already in use:** You can change the port in `web/backend/main.py`.

---
*GhostNodes - Sovereignty through Technology.*
*Português: Este guia cobre a instalação do servidor web e interface. Para automação total, use o script `./nodenation`.*
