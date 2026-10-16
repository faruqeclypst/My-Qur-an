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

echo "==> Build web release (root, untuk quran.examku.my.id)..."
# Default build web = JavaScript (kompatibel penuh dengan semua plugin incl. TTS).
# Jangan tambah --wasm: flutter_tts web belum lolos wasm dry-run.
flutter build web --release

echo "==> Build web release (base-href /quran/, untuk path fallback)..."
flutter build web --release --base-href /quran/ --output build/web-quran

echo "==> Upload ke /var/www/quranku (root build) ..."
tar czf - -C build/web . | ~/workspace/tools/vps-ssh \
  'sudo tar xzf - -C /var/www/quranku'
~/workspace/tools/vps-ssh \
  'sudo chown -R caddy:caddy /var/www/quranku && sudo chmod -R u=rwX,go=rX /var/www/quranku'

echo "==> Upload ke /var/www/quranku-path (base-href /quran/) ..."
tar czf - -C build/web-quran . | ~/workspace/tools/vps-ssh \
  'sudo tar xzf - -C /var/www/quranku-path'
~/workspace/tools/vps-ssh \
  'sudo chown -R caddy:caddy /var/www/quranku-path && sudo chmod -R u=rwX,go=rX /var/www/quranku-path'

echo "==> Konfigurasi Caddy (conf.d, idempoten)..."
~/workspace/tools/vps-ssh 'sudo tee /etc/caddy/conf.d/quranku.caddy' << 'CEOF' > /dev/null
quran.examku.my.id {
    root * /var/www/quranku
    try_files {path} /index.html
    file_server
    encode gzip zstd
    log {
        output file /var/log/caddy/quranku_access.log
    }
}
CEOF
~/workspace/tools/vps-ssh 'sudo touch /var/log/caddy/quranku_access.log && sudo chown caddy:caddy /var/log/caddy/quranku_access.log && sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile 2>&1 | tail -1'

echo "==> Reload Caddy..."
~/workspace/tools/vps-ssh 'sudo systemctl reload caddy && sleep 2 && sudo systemctl is-active caddy'

echo "==> Verifikasi..."
~/workspace/tools/vps-ssh 'curl -sk --resolve perseverance.my.id:443:127.0.0.1 -o /dev/null -w "https://perseverance.my.id/quran/ -> HTTP %{http_code}\n" https://perseverance.my.id/quran/'

echo "==> Selesai."
echo "    Langsung bisa dibuka : https://perseverance.my.id/quran/"
echo "    Setelah DNS A record quran -> 43.134.175.87 aktif di Cloudflare:"
echo "                         https://quran.examku.my.id/ (sertifikat otomatis via Caddy)"
