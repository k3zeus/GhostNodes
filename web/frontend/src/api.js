const rawBase = import.meta.env.VITE_GHOSTNODES_API_BASE || "";

export const API_BASE = rawBase.replace(/\/$/, "");

export function apiUrl(path) {
  if (!path.startsWith("/")) {
    throw new Error(`API path must start with '/': ${path}`);
  }
  return `${API_BASE}${path}`;
}

export function apiFetch(path, options) {
  return fetch(apiUrl(path), options);
}
