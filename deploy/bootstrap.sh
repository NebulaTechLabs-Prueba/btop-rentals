#!/usr/bin/env bash
# Bootstrap completo del server (Hetzner/Ubuntu) para BTOP Rentals.
# Uso (como root):
#   curl -fsSL https://raw.githubusercontent.com/NebulaTechLabs-Prueba/btop-rentals/main/deploy/bootstrap.sh | sudo bash
# Idempotente: se puede re-ejecutar sin problema.
set -euo pipefail

REPO="https://github.com/NebulaTechLabs-Prueba/btop-rentals.git"
APPDIR="/opt/btop"
SUPA_URL="https://onpvhedeinpsggdanylg.supabase.co"
SUPA_KEY="sb_publishable_Ra9k4PKwOv5qRiyTwGO26Q_kDvIWdCc"

echo "==> [1/8] Swap (evita OOM en el build con 2GB de RAM)"
if ! swapon --show | grep -q .; then
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "==> [2/8] Node.js 24 + git + ufw"
curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
apt-get install -y nodejs git ufw

echo "==> [3/8] PM2"
npm install -g pm2

echo "==> [4/8] Caddy"
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --yes --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
apt-get update && apt-get install -y caddy

echo "==> [5/8] Usuario deploy + carpeta app"
id deploy >/dev/null 2>&1 || adduser --disabled-password --gecos "" deploy
usermod -aG sudo deploy
echo 'deploy ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/deploy
mkdir -p "$APPDIR"
chown -R deploy:deploy "$APPDIR"

echo "==> [6/8] Clonar/actualizar repo, .env.local, build, PM2 (como deploy)"
sudo -u deploy bash -lc "
  set -e
  if [ -d '$APPDIR/.git' ]; then cd '$APPDIR' && git pull --ff-only origin main; else git clone '$REPO' '$APPDIR' && cd '$APPDIR'; fi
  printf 'VITE_SUPABASE_URL=%s\nVITE_SUPABASE_ANON_KEY=%s\n' '$SUPA_URL' '$SUPA_KEY' > .env.local
  npm ci
  npm run build
  pm2 start ecosystem.config.cjs || pm2 restart btop-rentals --update-env
  pm2 save
"

echo "==> [7/8] PM2 en arranque (boot)"
env PATH="$PATH" pm2 startup systemd -u deploy --hp /home/deploy >/dev/null

echo "==> [8/8] Caddy (reverse proxy + HTTPS) + firewall"
cp "$APPDIR/deploy/Caddyfile" /etc/caddy/Caddyfile
caddy validate --config /etc/caddy/Caddyfile
systemctl reload caddy
ufw allow OpenSSH >/dev/null || true
ufw allow 80 >/dev/null || true
ufw allow 443 >/dev/null || true
ufw --force enable >/dev/null || true

echo
echo "==================================================================="
echo " LISTO. Verifica:"
echo "   pm2 status"
echo "   curl -I localhost:3000        # HTTP 200"
echo "   https://btop-rentals.com      # en el navegador (con candado)"
echo "==================================================================="
