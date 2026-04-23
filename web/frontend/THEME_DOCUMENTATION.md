# GhostNodes SDK - Design System & Customization Guide
**Version:** 1.0 (Ag-Kit Standardized)

This guide documents the UI configuration architecture used by the GhostNodes Web Dashboard, allowing developers to seamlessly create custom layouts, adjust color palettes, and handle different responsive modes (Mobile/Desktop) efficiently without breaking backend integrations.

---

## 1. Theming Architecture (Dark/Light Modes)

The GhostNodes Dashboard utilizes a CSS Variables-based design system rooted in `%project-root%/web/frontend/src/index.css`. 
This guarantees all components react seamlessly across standard states without rewriting React JS logic.

### 1.1 CSS Custom Properties (Tokens)
Themes are toggled by altering the `data-theme` attribute at the HTML `<html data-theme="...">` level. By default, **Dark Mode** is root.

#### Dark Mode Base (Root)
```css
:root {
  --bg-main: #191c20;
  --bg-sidebar: #22262b;
  --bg-panel: #22262b;
  --glass-border: rgba(255, 255, 255, 0.04);
  --glass-shadow: 0 4px 30px rgba(0, 0, 0, 0.4);
  
  --text-main: #f0f2f5;
  --text-dim: #9ca3af;
  
  /* Brand Acents */
  --accent-base: #0abf9f; /* Ghostnodes Neon Teal/Mint */
  --accent-glow: #3cd3ad;
  
  /* Status Colors */
  --success: #1beaa2;
  --danger: #ef4444;
}
```

#### Light Mode (Target)
The Light Theme triggers via `[data-theme="light"]`. If you need to add custom daytime palettes, edit this branch in `index.css`:
```css
[data-theme="light"] {
  --bg-main: #f0f2f5;
  --bg-sidebar: #ffffff;
  --bg-panel: #ffffff;
  --glass-border: rgba(0, 0, 0, 0.08); 
  --text-main: #1e293b;
  /* Customize below */
}
```

---

## 2. Component Blueprint

### 2.1 The "Glass Panel" Structure
All primary blocks (cards, charts, widgets) are instantiated with the `.glass-panel` class.
- **Behavior:** This automatically applies uniform margins, padded borders, and the glassmorphism shadow logic found globally.
- **Interactions:** Built-in floating `translateY(-2px)` during hovered states. Use this class wrapping standard `<motion.div>` objects when extracting new react modules.

### 2.2 Text Hierarchies
- Main Titles uses `<h1/h2>` native scaling.
- Decorative headings must use class `.gradient-text` mapping correctly to the Teal/Emerald gradients.
- Auxiliary notes or "inactive" placeholders should invoke `.text-dim` for perfect contrast attenuation.

---

## 3. Responsive Adapters (Mobile)

GhostNodes uses a minimal grid system explicitly focused on physical device adaptability, specifically for the internal WLAN management layer where users log in from smartphones.

**Media Queries:** Breakpoints trigger natively under `@media (max-width: 768px)`
- **Sidebar Drop**: The navigation shrinks from a persistent left-docked 200px column into an overflowing top header/navigation row.
- **Vitals Arrays**: Flexible `gridTemplateColumns: minmax(200px, 1fr)` scales perfectly up to 4x wide cards natively snapping to single-columns on iPhone or Android screens.

### 3.1 Mobile / Desktop Targeting Classes
If a customized component or menu item is needed **exclusively** on a device variant:
- Use class `.desktop-only-footer` to enforce `display: none` under 768px.
- Use class `.mobile-only-footer` to enforce `display: none` unless viewed on mobile.

---

## 4. UI Integrations & Authentication Hooks

The Ghostnodes Header reserves the top right corner specifically for sovereign management tasks. In `App.jsx`, these features sit natively without breaking existing state machines:

- **Theme Switcher:** Toggles the state hook `['dark', 'light']` syncing flawlessly with `index.css`.
- **User Avatar Node:** Future integrations will map the `<UserCircle />` icon (top right corner) to load the login/password splash-layer ensuring the System relies on physical Node Key pairing to authenticate standard routes.

*Warning:* Changing core routing components requires editing `App.jsx`. Use the shared helpers in `src/api.js` and keep every request relative to `/api/...` or to `VITE_GHOSTNODES_API_BASE` when an external API base is required.
