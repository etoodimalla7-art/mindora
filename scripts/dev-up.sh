#!/usr/bin/env bash
# =========================================================
# MINDORA — Bring up local development environment
# =========================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RED="\033[0;31m"; NC="\033[0m"

info()  { echo -e "${GREEN}▶ $*${NC}"; }
warn()  { echo -e "${YELLOW}⚠ $*${NC}"; }
error() { echo -e "${RED}✖ $*${NC}" >&2; }

if [ ! -f .env ]; then
  warn ".env not found — creating from .env.example"
  cp .env.example .env
fi

info "Starting Docker infrastructure (Postgres, Redis, MinIO)..."
docker compose -f infrastructure/docker-compose.yml --env-file .env up -d

info "Waiting for Postgres to be healthy..."
until docker inspect --format='{{.State.Health.Status}}' mindora-postgres 2>/dev/null | grep -q healthy; do
  sleep 1
done
info "Postgres is healthy."

info "Waiting for Redis..."
until docker exec mindora-redis redis-cli ping >/dev/null 2>&1; do
  sleep 1
done
info "Redis is ready."

info "Waiting for MinIO..."
until curl -sf http://localhost:9000/minio/health/live >/dev/null 2>&1; do
  sleep 1
done
info "MinIO is ready."

echo
echo -e "${GREEN}✅ Development infrastructure is up.${NC}"
echo
echo "  Postgres    → localhost:5432"
echo "  Redis       → localhost:6379"
echo "  MinIO API   → http://localhost:9000"
echo "  MinIO UI    → http://localhost:9001  (minioadmin / minioadmin)"
echo
echo "Next:"
echo "  1. cd backend/python_api && poetry install && poetry run alembic upgrade head"
echo "  2. poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
echo "  3. In another terminal: cd frontend/flutter_app && flutter pub get && flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0"
