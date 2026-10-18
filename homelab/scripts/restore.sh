#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Dung: scripts/restore.sh backups/postgres-YYYYMMDD-HHMMSS.sql"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
sql="$1"

if [[ ! -f "$sql" ]]; then
  echo "Khong thay file ${sql}"
  exit 1
fi
if [[ ! -f .env ]]; then
  echo "Thieu homelab/.env"
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

echo "Phuc hoi ${sql} vao database ${POSTGRES_DB}. Du lieu hien tai trong database se bi ghi de boi noi dung file dump."
docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 < "$sql"
echo "Phuc hoi PostgreSQL xong."
