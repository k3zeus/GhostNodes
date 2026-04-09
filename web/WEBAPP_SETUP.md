# Web App Setup Guide 🌐🚀

This document provides a comprehensive guide to installing, configuring, and running the **GhostNodes Sovereign Dashboard**.

---

## 1. Prerequisites
Before starting, ensure your system has the following dependencies:
- **Python 3.10+** (Recommended: 3.11+ for performance).
- **Node.js 18+** & **npm**.
- **Virtualenv** (for Python dependency isolation).
- **Git** (for repository synchronization).

---

## 2. Fast Track (Production Deployment)

In the official GhostNodes environment (OrangePi Zero 3), the Web App is managed automatically by **NodeNation**.

### Unified Architecture
The dashboard now uses a **Unified Serving Architecture**:
- **Backend:** FastAPI (Python)
- **Frontend:** React (Vite)
- **Port:** 80 (Standard HTTP)

The backend directly serves the compiled frontend assets from the `web/frontend/dist` directory. This minimizes RAM usage and complexity.

### Automated Management
```bash
# Start the dashboard service
sudo ./nodenation --web-start

# Stop the dashboard service
sudo ./nodenation --web-stop

# Check health and logs
sudo ./nodenation --web-status
```

---

## 3. Manual Installation (Development)

### A. Frontend Build
1. **Navigate to the frontend directory:**
   ```bash
   cd web/frontend
   ```
2. **Install dependencies and build:**
   ```bash
   npm install
   npm run build
   ```
   *This creates the `dist` folder used by the backend.*

### B. Backend Setup
1. **Navigate to the backend directory:**
   ```bash
   cd web/backend
   ```
2. **Setup virtual environment:**
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Windows: .\.venv\Scripts\activate
   pip install -r requirements.txt
   ```
3. **Run the server:**
   ```bash
   # Note: Binding to Port 80 requires sudo/Admin privileges
   sudo .venv/bin/python main.py
   ```

---

## 4. Hardware Agnostic Execution

### Linux (Systemd)
The installation script `halfin/extras/webapp.sh` automatically configures the `ghostnodes-web.service`.

### Windows (PowerShell)
For local testing on Windows, use the provided script:
```powershell
# Open PowerShell as Administrator
cd web
.\start.ps1
```

---

## 5. Troubleshooting / FAQ

- **Port 80 already in use:** Use `sudo netstat -tulanp | grep :80` to identify the conflicting service. (Usually Nginx or Apache).
- **Static Files Not Found:** Ensure you have run `npm run build` in the `web/frontend` directory before starting the backend.
- **Permission Denied:** Most system operations (like reading CPU temp or binding to port 80) require `sudo`.
- **Heimdall Conflict:** If you had Heimdall running on port 80, it has been moved to **Port 8080** by the GhostNodes installer.

---
*GhostNodes - Sovereignty through Technology.*
