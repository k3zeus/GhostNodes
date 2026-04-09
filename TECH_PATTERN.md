# Technical Patterns & Coding Guidelines 🛠️

## 1. Technology Stack
- **Dashboard Frontend:** React 18+ (Vite), Framer Motion (Animations), Lucide (Icons).
- **Dashboard Backend:** FastAPI (Asynchronous Python), Pydantic (Validation).
- **System Layer:** Shell Script (Bash) for low-level orchestration.
- **Database/Persistence:** File-based (`/var/lib/ghostnodes`) and **JSON Persistence** (`web/backend/data/`) for configuration and users.
- **Security:** JWT (JSON Web Tokens) for API Auth with **Role-Based Access Control (RBAC)**.

---

## 2. API Design Patterns
- **Resource-Based Routing:** Endpoints grouped by domain (`/system`, `/bitcoin`, `/apps`, `/auth`).
- **Graceful Failure:** Backend MUST provide a "status" field in responses to indicate if sub-services are reachable.
- **Service Isolation:** Trigger specific scripts via a security-hardened `actions.py` router. Administrative actions (power, user creation) MUST use the `verify_admin` dependency.

---

## 3. Frontend Architecture
- **Tab-Based Navigation:** Single Page Application (SPA).
- **Premium Aesthetics:**
  - **Glassmorphism:** Use `backdrop-filter: blur()`, variable translucency, and thin borders.
  - **Dynamic Theming:** Dark/Light mode support via CSS variables.
  - **Identidade Soberana:** Use "SOVEREIGNTY" branding (Bold, 2.4rem, gradient-text).
- **UI Safety Guards:** Use high-visibility **Confirmation Modals** (AnimatePresence) for destructive system actions (Reboot/Halt).

---

## 4. Hardware Abstraction (Hardware Agnostic)
Follow the **"Detect-Verify-Fallback"** pattern for cross-platform support:
1. **Detect OS:** Use `platform.system()` or `os.name`.
2. **Linux Path:** Search for hardware-specific paths (e.g., OrangePi thermal zones, `nmcli` for wifi).
3. **Windows/Other Path:** Provide **Mocked/Simulated Data** or alternative commands (e.g., `psutil` or `wmic`) to ensure the system remains functional during development.
4. **Visibility:** Hide hardware cards (like Ethernet/WLAN) if no connection or valid IP is detected.

---

## 5. Security & RBAC
- **Roles:** 
  - `admin`: Full authority, can execute system scripts, manage users, and control power.
  - `viewer`: Read-only access, restricted from administrative UI sections and endpoints.
- **No Direct Shell Execution:** Abstract through Python wrappers with parameter sanitization.
- **System User Creation:** Use `subprocess` with `useradd` for real OS accounts, maintaining a clear separation between Dashboard and System identities.

---

## 6. Development Workflow
1. **Persistence First:** Ensure all configuration is stored in the `data/` folder for easy backup/restore.
2. **Visual Consistency:** Use official logos with `backdrop-filter: blur(10px)` for Application cards to maintain a premium feel.
3. **Bilingual Docs:** Core documentation must be maintained in English (Primary) and Portuguese (Secondary).

---
*GhostNodes - Engineering Sovereignty.*
