#!/usr/bin/env bash
# BTOP Rentals — build & publish to Nginx webroot on the Hetzner VPS.
# Run from the repo root ON the server:  bash deploy/deploy.sh
set -euo pipefail

WEBROOT="${WEBROOT:-/var/www/btop-rentals}"
# Domain root → base path "/". Override BASE_PATH only if serving under a subpath.
export BASE_PATH="${BASE_PATH:-/}"
# Supabase public keys (safe in the frontend bundle; RLS protects the data).
export VITE_SUPABASE_URL="${VITE_SUPABASE_URL:-https://onpvhedeinpsggdanylg.supabase.co}"
export VITE_SUPABASE_ANON_KEY="${VITE_SUPABASE_ANON_KEY:-sb_publishable_Ra9k4PKwOv5qRiyTwGO26Q_kDvIWdCc}"

echo "==> Pulling latest main"
git pull --ff-only origin main

echo "==> Installing dependencies (npm ci)"
npm ci

echo "==> Building (BASE_PATH=$BASE_PATH)"
npm run build

echo "==> Publishing dist/ -> $WEBROOT"
sudo mkdir -p "$WEBROOT"
sudo rsync -a --delete dist/ "$WEBROOT/"

echo "==> Reloading Nginx"
sudo nginx -t
sudo systemctl reload nginx

echo "==> Done. Live at your configured domain."
