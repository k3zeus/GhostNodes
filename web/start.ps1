# ╔══════════════════════════════════════════════════════════════╗
# ║  web/start.ps1 — GhostNodes Dashboard Launcher (Windows)      ║
# ╚══════════════════════════════════════════════════════════════╝

$WEB_DIR = $PSScriptRoot
$FRONTEND_DIR = "$WEB_DIR\frontend"
$BACKEND_DIR = "$WEB_DIR\backend"

Write-Host "Starting GhostNodes Dashboard on Windows..." -ForegroundColor Cyan

# 1. Check Frontend Build
if (-not (Test-Path "$FRONTEND_DIR\dist")) {
    Write-Host "Frontend build not found. Building now..." -ForegroundColor Yellow
    Set-Location $FRONTEND_DIR
    npm install
    npm run build
}

# 2. Check Backend Venv
Set-Location $BACKEND_DIR
if (-not (Test-Path ".venv")) {
    Write-Host "Creating Python virtual environment..." -ForegroundColor Yellow
    python -m venv .venv
}

# 3. Install Requirements
Write-Host "Ensuring Python dependencies..." -ForegroundColor Green
& ".\.venv\Scripts\pip.exe" install -r requirements.txt

# 4. Start Backend
Write-Host "Launching Dashboard on Port 80..." -ForegroundColor Green
Write-Host "NOTE: Running on Port 80 may require Administrator privileges." -ForegroundColor Gray
& ".\.venv\Scripts\python.exe" main.py
