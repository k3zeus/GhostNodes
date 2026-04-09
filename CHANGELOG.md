# Changelog - GhostNodes Dashboard

All notable changes to the GhostNodes Sovereign Dashboard will be documented in this file.

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
