#!/usr/bin/env bash
# ============================================================
# SUNUCUDA çalıştırılır. Ya elle (SSH ile bağlanıp ./deploy.sh)
# ya da bir CI/CD pipeline'ının SSH adımı tarafından tetiklenir.
#
# Ne yapar:
#   1) En güncel kodu git'ten çeker
#   2) (Opsiyonel) Veritabanı migration'larını çalıştırır
#   3) Docker imajlarını yeniden build edip container'ları günceller
#   4) Eski/kullanılmayan imajları temizler
# ============================================================

set -euo pipefail

BRANCH="${1:-main}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> [1/4] Git pull (branch: $BRANCH)"
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"

if [ ! -f ".env" ]; then
  echo "HATA: .env dosyası sunucuda bulunamadı!" >&2
  echo "      .env.example'ı kopyalayıp sunucuya özel değerlerle doldurun." >&2
  exit 1
fi

echo "==> [2/4] Veritabanı migration'ları çalıştırılıyor"
chmod +x db/migrate.sh
./db/migrate.sh

echo "==> [3/4] Docker imajları build ediliyor ve container'lar güncelleniyor"
docker compose --env-file .env down
docker compose --env-file .env up -d --build

echo "==> [4/4] Kullanılmayan Docker imajları temizleniyor"
docker image prune -f

echo "==> Deploy tamamlandı. Servis durumu:"
docker compose ps

echo "==> Health check:"
sleep 3
APP_PORT=$(grep -E '^APP_PORT=' .env | cut -d '=' -f2)
curl -sf "http://localhost:${APP_PORT}/health" || echo "UYARI: health check başarısız oldu, logları kontrol edin (docker compose logs -f backend)"
