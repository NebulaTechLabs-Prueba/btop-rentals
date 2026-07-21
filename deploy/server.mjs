// Servidor estático de producción para la SPA (dist/), gestionado por PM2.
// Caddy hace reverse_proxy a este proceso en localhost:PORT y añade HTTPS + gzip.
import express from 'express';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dist = path.join(__dirname, '..', 'dist');
const port = process.env.PORT || 3000;

const app = express();

// Assets con hash → cache larga; index.html nunca se cachea (deploys inmediatos).
app.use(
  express.static(dist, {
    setHeaders(res, filePath) {
      if (filePath.endsWith('index.html')) {
        res.setHeader('Cache-Control', 'no-store, must-revalidate');
      } else if (filePath.includes(`${path.sep}assets${path.sep}`)) {
        res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
      }
    },
  })
);

// Fallback SPA: cualquier ruta sirve index.html (el router es del lado cliente).
app.get('*', (_req, res) => res.sendFile(path.join(dist, 'index.html')));

app.listen(port, () => console.log(`BTOP static server escuchando en :${port}`));
