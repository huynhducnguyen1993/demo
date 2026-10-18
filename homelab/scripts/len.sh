#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Da tao .env tu .env.example. Doi mat khau roi chay lai."
  exit 1
fi

if grep -q 'doi-mat-khau' .env; then
  echo "Hay doi POSTGRES_PASSWORD va REDIS_PASSWORD trong homelab/.env truoc khi len stack."
  exit 1
fi

profiles=()
for arg in "$@"; do
  case "$arg" in
    --quan-tri) profiles+=(--profile quan-tri) ;;
    --rustdesk) profiles+=(--profile rustdesk) ;;
    *)
      echo "Tham so khong ho tro: $arg"
      exit 1
      ;;
  esac
done

set -a
# shellcheck disable=SC1091
source .env
set +a

if ((${#profiles[@]})); then
  docker compose "${profiles[@]}" up -d
  docker compose "${profiles[@]}" ps
else
  docker compose up -d
  docker compose ps
fi

echo "Trang chu: http://127.0.0.1:${HTTP_PORT:-80}/"
echo "Cai DNS lan dau: http://127.0.0.1:${ADGUARD_SETUP_PORT:-3000}/"
echo "Neu mo bang IP, them IP do vao HOMEPAGE_ALLOWED_HOSTS."
