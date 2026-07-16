import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Base path is configurable so the same build works on a domain root (Hetzner/Nginx → "/")
// and under a subpath (GitHub Pages → "/btop-admin-demo/"). Set BASE_PATH in the environment.
export default defineConfig(() => ({
  base: process.env.BASE_PATH ?? '/',
  plugins: [react()],
  server: {
    port: 5173,
    host: true,
    allowedHosts: true,
    hmr: { clientPort: 443 },
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true,
      },
    },
  },
}));
