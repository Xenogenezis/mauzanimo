#!/usr/bin/env bash
# Pull latest code and redeploy. Run on the VPS from the repo root.
set -euo pipefail
cd "$(dirname "$0")/.."
git pull --ff-only
[ -f deploy/.env ] || { echo "Create deploy/.env from deploy/.env.example first"; exit 1; }
docker compose -f deploy/docker-compose.yml --env-file deploy/.env up -d --build
docker image prune -f >/dev/null
echo "Deployed. Admin: https://$(grep ^DOMAIN deploy/.env | cut -d= -f2)/admin/"
