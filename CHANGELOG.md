# Changelog - GhostNodes Dashboard

All notable changes to the GhostNodes Sovereign Dashboard will be documented in this file.

## [1.2.2] - 2026-04-19
### Fixed
- **TUI Immediate Crash (set -e trap):** Fixed critical exit logic in `_menu_read()` and `check_preinstall_exists()` where short-circuit evaluation (`[[ ... ]] && cmd`) caused silent termination of the GhostNodes installer when selecting user options under `set -e` strict rules.
- **nodenation:** Substituído short-circuit (`[[ ... ]] && cmd`) nas funções _menu_read e check_preinstall_exists por `if/then/fi` explícito, prevenindo que o `set -e` mate o script após seleção normal de menu e resolvendo o erro de queda imediata.
- **nodenation (github cache):** Variável de link de download (`GN_REPO_URL`) alterada internamente na base dev para `dev.tar.gz` ao invés de usar o artefato da tag "Beta", rompendo o ciclo de downloads infinitos da versão com defeito.
- **nodenation (docker spawn):** Execução remota orquestrada do `docker-compose up -d` engatilhada apenas após mover `GN_TMP_DIR` para definitivo, prevenindo destruição do bind-path por diretórios desfeitos (`/tmp/ghostnodes_staging`).
- **ghostnode (tui):** Fixação estrutural do `HALFIN_DIR` para `nodenation/halfin` em substituição da arquitetura `dirname`, revivendo os menus dinâmicos e contornando a exclusão de pastas globais root.
- **pre_install.sh (paths temporarios):** Injeção dinâmica de escopo onde `HALFIN_DIR` assume `/tmp/...` durante bootstrap automado, garantindo que os scripts secundários (Fail2ban, Pi-hole, Docker) rodem e achem seus .sh correlatos antes da fusão final.
- **docker.sh (bypass):** Implementado modo silencioso `GN_AUTO_INSTALL` ignorando perguntas iterativas de terminal, estabilizando a automatização base curl e silenciando falhas do pre_install.

## [1.2.1] - 2026-04-15
### Fixed
- **[q] Quit broken:** `_menu_read()` ran `_sair()`/`exit 0` inside a `$()` subshell. Refactored to global `$_MENU_OPT`.
- **Download case-sensitivity:** `find -iname` + fallback to exact repo dir name.
- **Halfin hardware detection:** Expanded OS regex + added `any` arch fallback.

### Added
- **Dashboard Web submenu:** Full management (deps/service/start/stop/logs).
- **Deploy options in Manual Config:** `[6]` install, `[7]` dashboard, `[8]` pre_install.sh.
- **Automated Webapp Installation:** Created `halfin/extras/webapp.sh` to fill the gap in the Halfin pre_install.sh flow.

## [1.2.0] - 2026-04-10
### Added
- **Unified Web Dashboard:** Full integration of FastAPI backend and React frontend.
- **Sovereign UI (V13.0):** Enhanced visuals with cyan/dev-green color schemes and premium glassmorphism.
- **NodeNation Integration:** The dashboard is now the primary entry point for node orchestration.
- **RBAC Auth:** Refined role-based access control for system safety.

## [1.1.0] - 2026-04-09
### Added
- **Power Management System:** Integrated icon-based power menu with Reboot and Halt functions.
- **Safety Modals:** Framer-motion confirmation modals for destructive system actions.
- **Hierarchical Access Control (RBAC):** Added `admin` and `viewer` roles to JWT authentication.
- **User Persistence:** Backend now saves dashboard users in `data/users.json`.
- **System User Management:** New sub-tab in *Services* allowing the creation of Linux OS accounts via the web UI.
- **Hardware Agnostic Logic:** Backend now detects OS and hardware paths, falling back to mocks on non-Linux systems (development support).
- **Guardian Reports:** Placeholder structures for forensic host analysis and attacker identification.

### Changed
- **Branding:** Official system identity updated to "SOVEREIGNTY" (removed the trailing dot).
- **Vitals UI:** Memory usage now includes a gradient progress bar; Ethernet/WLAN cards are hidden when offline.
- **Applications UI:** Enhanced cards with official logos and frosted glass (blur) backgrounds.
- **Pi-hole Branding:** Updated tab label to "Pi-hole DNS" for clarity.

### Fixed
- Fixed an issue where the Applications tab would fail to render due to missing image references.
- Corrected Framer Motion `AnimatePresence` reference in `App.jsx`.
- Standardized API headers to include Authorization Bearer tokens across all calls.

---
*GhostNodes - Building the gate to the hyperbitcoinized future.*
