# Deploy BTOP Rentals to Hetzner (Nginx + HTTPS)

The app is a **static Vite + React SPA** (no backend required for the demo — the
`server/` folder is a local-only dev API). Deployment = build static files and serve
them with Nginx, with automatic HTTPS from Let's Encrypt.

**Method chosen:** Nginx directly on a Hetzner Cloud VPS · Domain + automatic HTTPS.

---

## 0. Prerequisites

- A **Hetzner Cloud** server (Ubuntu 24.04 LTS, the smallest CX22 is plenty).
- The domain **btop-rentals.com** (already registered on Spaceship).
- SSH access to the server as a sudo user.

## 1. Point the domain at the server (DNS on Spaceship)

In the **Spaceship** dashboard → your domain → **Advanced DNS / DNS records**, add records
pointing to the Hetzner server's public IP (from the Hetzner Cloud console):

| Type  | Host (Name) | Value / Points to | TTL  |
|-------|-------------|-------------------|------|
| A     | `@`         | `<SERVER_IPv4>`   | Auto |
| A     | `www`       | `<SERVER_IPv4>`   | Auto |
| AAAA  | `@`         | `<SERVER_IPv6>`   | Auto |
| AAAA  | `www`       | `<SERVER_IPv6>`   | Auto |

- Serve at the **apex** `btop-rentals.com` (host `@`) plus `www`.
- Remove any Spaceship "parking" / forwarding record that also targets `@`, or it will conflict.
- Propagation is usually minutes. Verify before requesting the certificate:

```bash
dig +short btop-rentals.com     # must return <SERVER_IPv4>
```

> If Spaceship shows "nameservers not set to Spaceship DNS", switch the domain to **Spaceship
> default nameservers** first, otherwise the records above won't take effect.

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
sudo git clone https://github.com/NebulaTechLabs-Prueba/btop-rentals.git btop
sudo chown -R "$USER":"$USER" /opt/btop
cd /opt/btop

# Supabase (public keys — safe in the frontend; RLS protects the data)
export VITE_SUPABASE_URL=https://onpvhedeinpsggdanylg.supabase.co
export VITE_SUPABASE_ANON_KEY=sb_publishable_Ra9k4PKwOv5qRiyTwGO26Q_kDvIWdCc

npm ci
BASE_PATH=/ npm run build      # domain root → base "/"
```

This produces `/opt/btop/dist`.

## 5. Configure Nginx

```bash
# Publish the built files
sudo mkdir -p /var/www/btop-rentals
sudo rsync -a --delete dist/ /var/www/btop-rentals/

# Install the site config (already set to btop-rentals.com)
sudo cp deploy/nginx/btop-rentals.conf /etc/nginx/sites-available/btop-rentals.conf
sudo ln -sf /etc/nginx/sites-available/btop-rentals.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default   # remove the default welcome site

sudo nginx -t && sudo systemctl reload nginx
```

At this point the site is live over **HTTP**.

## 6. Enable HTTPS (automatic, Let's Encrypt)

```bash
sudo certbot --nginx -d btop-rentals.com -d www.btop-rentals.com
```

Certbot obtains the certificate, rewrites the Nginx config to add the `443` block, and
sets up an HTTP→HTTPS redirect. Renewal is automatic (a systemd timer runs `certbot renew`);
test it with `sudo certbot renew --dry-run`.

Your site is now live at `https://btop-rentals.com`.

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
