/// <reference types="vite/client" />

interface ImportMetaEnv {
  /**
   * Absolute URL of the backend, e.g. https://jsp-defects-api.onrender.com.
   * Unset in development, where Vite proxies /api instead. Read at build
   * time, so changing it needs a rebuild.
   */
  readonly VITE_API_BASE?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
