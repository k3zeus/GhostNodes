# System Architecture: GhostNodes

## 🏗 High-Level Overview
GhostNodes is a multi-layered orchestration platform. It combines low-level shell scripting for system-level bootstrap with high-level Python/React for user-facing service management.

### Stack Components
- **Core Layer (Bash)**: `nodenation`, `ghostnode`, and sub-modules managing hardware detection, user creation, and binary installation.
- **Service Layer (Docker)**: Orchestration of isolated services (Bitcoin, Pi-hole, Syncthing) using `docker-compose`.
- **Management Layer (Python/FastAPI)**: A backend Hub that proxies service APIs and provides a unified control plane.
- **Presentation Layer (React)**: A modern, glassmorphic web dashboard for remote service monitoring.

## 🔄 Execution Flow (Bootstrap)
1. **The One-Liner**: `curl | bash` triggers the remote load.
2. **TTY Hijacking**: The script detects if it's being piped and re-executes itself via `/dev/tty` to allow interactive menus.
3. **Hardware Evaluation**: Reads CPU cores, RAM, and Disk space to suggest optimized configurations (e.g., Bitcoin Pruning).
4. **Environment Setup**: Pulls the `main.tar.gz` snapshot from the verified GitHub repository.
5. **Interactive Selection**: Uses the corrected `_menu_read` (stderr redirection) to allow project selection (Halfin, Satoshi, etc.).

## 🔐 Security Model
- **Isolated Execution**: Services run in Docker containers with limited volume mounts.
- **Reverse Proxy**: All service access is proxied through the FastAPI backend to enforce authentication.
- **Sudo Masking**: Critical system steps are clearly flagged, ensuring no silent elevation.

## 📂 Project Structure
- `/bin`: Core executable utilities.
- `/lib`: Reusable bash libraries (`core_lib.sh`, etc.).
- `/halfin`: Networking and AP Router sub-project.
- `/satoshi`: Bitcoin Node sub-project.
- `/web`: Management Hub (FastAPI + React).

---
*Standards observed: SDD (Spec Driven Development)*
