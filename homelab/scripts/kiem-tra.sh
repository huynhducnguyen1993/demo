#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Thieu homelab/.env"
  exit 1
fi

docker compose --profile quan-tri --profile rustdesk config >/dev/null
echo "Compose hop le, gom ca profile quan-tri va rustdesk."

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon chua chay. Moi dung o buoc kiem tra cu phap."
  exit 0
fi

docker compose ps

port="$(grep -E '^HTTP_PORT=' .env | cut -d= -f2-)"
port="${port:-80}"
if curl -fsS --max-time 5 "http://127.0.0.1:${port}/" >/dev/null; then
  echo "Caddy tra loi o cong ${port}."
else
  echo "Caddy chua tra loi o cong ${port}. Xem log: docker compose logs caddy homepage"
  exit 1
fi
