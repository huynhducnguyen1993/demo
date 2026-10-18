#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Thieu homelab/.env"
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

stamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p backups

docker compose exec -T postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > "backups/postgres-${stamp}.sql"
docker compose exec -T redis redis-cli -a "$REDIS_PASSWORD" --no-auth-warning SAVE >/dev/null
docker compose cp redis:/data/dump.rdb "backups/redis-${stamp}.rdb"

project="$(docker compose config --format json | python3 -c 'import json,sys; print(json.load(sys.stdin)["name"])')"
docker run --rm \
  -v "${project}_adguard_conf:/from:ro" \
  -v "$ROOT/backups:/to" \
  alpine:3.22 \
  tar czf "/to/adguard-conf-${stamp}.tgz" -C /from .

echo "Da ghi backups/postgres-${stamp}.sql"
echo "Da ghi backups/redis-${stamp}.rdb"
echo "Da ghi backups/adguard-conf-${stamp}.tgz"
