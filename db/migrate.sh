#!/usr/bin/env bash
# Bu script host makine üzerinde (Docker DIŞINDA) doğrudan çalıştırılır.
# Local'de de sunucuda da aynı şekilde kullanılır.
#
# Kullanım: ./db/migrate.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "HATA: .env dosyası bulunamadı ($ENV_FILE). Önce .env.example'dan kopyalayıp doldurun." >&2
  exit 1
fi

# .env dosyasını yükle
set -o allexport
source "$ENV_FILE"
set +o allexport

if ! command -v psql >/dev/null 2>&1; then
  echo "HATA: psql bulunamadı. PostgreSQL client kurulu olmalı (sudo apt install postgresql-client)." >&2
  exit 1
fi

echo "-> Veritabanına bağlanılıyor: ${DB_HOST_LOCAL}:${DB_PORT}/${DB_NAME}"

PGPASSWORD="$DB_PASSWORD" psql \
  -h "$DB_HOST_LOCAL" \
  -p "$DB_PORT" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  -v ON_ERROR_STOP=1 \
  -f "$SCRIPT_DIR/init.sql"

echo "-> Migration tamamlandı."
