#!/usr/bin/env bash
# One-shot session starter for Codespaces.
set -euo pipefail

cd /workspaces/mindora

echo "▶ 1. Ensuring Docker is running..."
if ! docker ps | grep -q mindora-postgres; then
  bash scripts/dev-up.sh
else
  echo "   ✓ Docker already running"
fi

echo ""
echo "▶ 2. Backend and Frontend must be started manually in separate terminals:"
echo ""
echo "   Terminal A (backend):"
echo "     cd /workspaces/mindora/backend/python_api"
echo "     poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
echo ""
echo "   Terminal B (frontend):"
echo "     cd /workspaces/mindora/frontend/flutter_app"
echo "     export PATH=\$HOME/flutter/bin:\$PATH"
echo "     flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0"
echo ""
