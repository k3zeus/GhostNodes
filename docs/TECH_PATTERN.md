# Tech Patterns & Development Standards

## 🧠 Spec-Driven Development (SDD)
All features in GhostNodes must follow the SDD workflow:
1. **Requirements**: Define user stories and EARS-notation requirements.
2. **Design**: Architect the solution before coding.
3. **Tasks**: Breakdown the work into atomic, testable units.

*Never implement code that lacks a corresponding spec in `.agent/SPECS/`.*

## 🐚 Bash Coding Standards
- **Strict Mode**: Every script must start with `set -euo pipefail`.
- **Variable Scoping**: Use `local` for all variables inside functions.
- **UI/UX**: Prompts using command substitution must redirect to `stderr` (`>&2`) to avoid capture.
- **Naming**: Use `GN_` prefix for global constants and variables to avoid namespace collisions.

## 🐍 Python/FastAPI Standards
- **Type Hinting**: Mandatory for all function signatures.
- **Async-First**: Prioritize async operations for I/O and reverse proxies.
- **Mocking**: Services that interact with Linux hardware must have a Mock mode for development on Windows/Mac.

## ⚛️ React/Frontend Standards
- **Component Localization**: Use atomic components with predefined styling.
- **Glassmorphism**: Follow the unified design tokens for a premium, modern feel.

## 📦 Repository Hygiene
- **.gitignore**: AI-generated artifacts, environment variables, and large binaries must never be committed.
- **Version Control**: Follow semantic versioning for tags (e.g., `v1.0.0-beta`).

---
*Maintained by the GhostNodes Core Team*
