#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "▶ Stopping MINDORA infrastructure..."
docker compose -f infrastructure/docker-compose.yml down

echo "✅ Stopped. Data volumes preserved."
echo "   To also delete data: docker compose -f infrastructure/docker-compose.yml down -v"
