#!/usr/bin/env bash
# Deploy Quranku (Flutter web) ke VPS 43.134.175.87
# Prasyarat: tunnel SSH aktif (~/workspace/tools/vps-ssh 'echo ok')
#            DNS quran.examku.my.id -> 43.134.175.87 (atur di Cloudflare)
set -euo pipefail

cd "$(dirname "$0")"
export PATH="$HOME/workspace/tools/flutter/bin:$PATH"

echo "==> Cek tunnel SSH..."
~/workspace/tools/vps-ssh 'echo OK' | grep -q OK || {
  echo "TUNNEL DOWN: deploy dibatalkan."
  exit 1
}

echo "==> Build web release..."
# Default build web = JavaScript (kompatibel penuh dengan semua plugin incl. TTS).
# Jangan tambah --wasm: flutter_tts web belum lolos wasm dry-run.
flutter build web --release

echo "==> Upload ke /var/www/quranku ..."
tar czf - -C build/web . | ~/workspace/tools/vps-ssh \
  'sudo mkdir -p /var/www/quranku && sudo tar xzf - -C /var/www/quranku && sudo chown -R www-data:www-data /var/www/quranku'

echo "==> Konfigurasi Caddy (conf.d)..."
~/workspace/tools/vps-ssh 'sudo tee /etc/caddy/conf.d/quranku.caddy > /dev/null <<EOF
quran.examku.my.id {
    root * /var/www/quranku
    try_files {path} /index.html
    file_server
    encode gzip zstd
    log {
        output file /var/log/caddy/quranku_access.log
    }
}
EOF
sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile'

echo "==> Reload Caddy..."
~/workspace/tools/vps-ssh 'sudo systemctl reload caddy && sleep 2 && curl -s -o /dev/null -w "HTTP %{http_code}\n" https://quran.examku.my.id/'

echo "==> Selesai. Buka https://quran.examku.my.id/"
