#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  halfin/extras/webapp.sh — GhostNodes Web App Installer      ║
# ║  Handles Build and Service Orchestration (Linux/SBC)         ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

# Load Globals
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WEB_DIR="$GN_ROOT/web"
FRONTEND_DIR="$WEB_DIR/frontend"
BACKEND_DIR="$WEB_DIR/backend"

echo "🚀 Starting GhostNodes Web Dashboard Setup..."

# 1. Install Dependencies
echo "📦 Installing System dependencies (Node.js & Python)..."
sudo apt-get update && sudo apt-get install -y nodejs npm python3-venv python3-pip

# 2. Frontend Build
echo "⚛️ Building Frontend (this may take 1-2 mins on OrangePi)..."
cd "$FRONTEND_DIR"
if [ ! -d "node_modules" ]; then
    npm install
fi
npm run build

# 3. Backend Setup
echo "🐍 Setting up Backend Virtual Environment..."
cd "$BACKEND_DIR"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

# 4. Systemd Service Creation
echo "⚙️ Configuring Systemd unit (ghostnodes-web.service)..."
SERVICE_PATH="/etc/systemd/system/ghostnodes-web.service"

cat <<EOF | sudo tee "$SERVICE_PATH" > /dev/null
[Unit]
Description=GhostNodes Sovereign Dashboard
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$BACKEND_DIR
ExecStart=$BACKEND_DIR/.venv/bin/python main.py
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=ghostnodes-web

[Install]
WantedBy=multi-user.target
EOF

# 5. Enable and Start
echo "🔄 Enabling and Starting Service..."
sudo systemctl daemon-reload
sudo systemctl enable ghostnodes-web.service
sudo systemctl restart ghostnodes-web.service

echo "✅ Web Dashboard is now running on Port 80!"
echo "📍 Access it via: http://$(hostname).local or http://$(hostname -I | awk '{print $1}')"
