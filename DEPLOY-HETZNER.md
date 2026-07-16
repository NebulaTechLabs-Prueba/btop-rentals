# Deploy BTOP Rentals to Hetzner (Nginx + HTTPS)

The app is a **static Vite + React SPA** (no backend required for the demo — the
`server/` folder is a local-only dev API). Deployment = build static files and serve
them with Nginx, with automatic HTTPS from Let's Encrypt.

**Method chosen:** Nginx directly on a Hetzner Cloud VPS · Domain + automatic HTTPS.

---

## 0. Prerequisites

- A **Hetzner Cloud** server (Ubuntu 24.04 LTS, the smallest CX22 is plenty).
- A **domain** you control (e.g. `rentals.example.com`).
- SSH access to the server as a sudo user.

## 1. Point the domain at the server

In your DNS provider, create records to the server's public IP:

| Type | Name        | Value            |
|------|-------------|------------------|
| A    | `@` or sub  | `<SERVER_IPv4>`  |
| AAAA | `@` or sub  | `<SERVER_IPv6>`  |

Wait until `dig +short your-domain.com` returns the server IP before requesting a certificate.

## 2. Install Node.js, Nginx, Certbot, Git

```bash
sudo apt update && sudo apt upgrade -y
# Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs nginx git
# Certbot (Let's Encrypt) via snap
sudo snap install core && sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot
```

## 3. Firewall (optional but recommended)

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'   # opens 80 + 443
sudo ufw --force enable
```

## 4. Get the code and build

```bash
# Pick a location for the checkout (build happens here; only dist/ is served)
sudo mkdir -p /opt && cd /opt
sudo git clone https://github.com/NebulaTechLabs-Prueba/btop-admin-demo.git btop
sudo chown -R "$USER":"$USER" /opt/btop
cd /opt/btop

npm ci
BASE_PATH=/ npm run build      # domain root → base "/"
```

This produces `/opt/btop/dist`.

## 5. Configure Nginx

```bash
# Publish the built files
sudo mkdir -p /var/www/btop-rentals
sudo rsync -a --delete dist/ /var/www/btop-rentals/

# Install the site config (edit the domain first!)
sudo cp deploy/nginx/btop-rentals.conf /etc/nginx/sites-available/btop-rentals.conf
sudo sed -i 's/your-domain.com/rentals.example.com/g' /etc/nginx/sites-available/btop-rentals.conf
sudo ln -sf /etc/nginx/sites-available/btop-rentals.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default   # remove the default welcome site

sudo nginx -t && sudo systemctl reload nginx
```

At this point the site is live over **HTTP**.

## 6. Enable HTTPS (automatic, Let's Encrypt)

```bash
sudo certbot --nginx -d rentals.example.com -d www.rentals.example.com
```

Certbot obtains the certificate, rewrites the Nginx config to add the `443` block, and
sets up an HTTP→HTTPS redirect. Renewal is automatic (a systemd timer runs `certbot renew`);
test it with `sudo certbot renew --dry-run`.

Your site is now live at `https://rentals.example.com`.

## 7. Updating after new commits

From `/opt/btop`:

```bash
bash deploy/deploy.sh
```

The script pulls `main`, reinstalls deps, rebuilds with `BASE_PATH=/`, syncs `dist/` to
`/var/www/btop-rentals`, and reloads Nginx. Override the webroot or base path if needed:

```bash
WEBROOT=/var/www/btop-rentals BASE_PATH=/ bash deploy/deploy.sh
```

---

## Notes

- **State/persistence:** the demo stores data in the browser's `localStorage` (no server DB).
  Each visitor has their own data; it is not shared across devices. A real backend
  (e.g. Supabase or a small API on the same VPS) is the next step when needed.
- **`BASE_PATH`:** always `/` on the domain root. GitHub Pages keeps working because its
  workflow sets `BASE_PATH=/btop-admin-demo/` — the two deploys don't conflict.
- **No Docker needed** for this setup. If you later prefer containers, the same `dist/`
  can be served by an `nginx:alpine` image.
