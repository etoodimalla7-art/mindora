#!/usr/bin/env bash
# Runs Alembic migrations against the running Postgres container.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/backend/python_api"

if ! command -v poetry >/dev/null 2>&1; then
  echo "✖ Poetry not found. Install: pip install poetry"
  exit 1
fi

echo "▶ Running Alembic migrations..."
poetry run alembic upgrade head
echo "✅ Database is up to date."
