#!/usr/bin/env bash
# Complete MINDORA setup + start commands.
# Usage: bash scripts/setup-all.sh
set -euo pipefail

cd /workspaces/mindora

echo "═══════════════════════════════════════════════════════════"
echo "  MINDORA — Full Setup Check"
echo "═══════════════════════════════════════════════════════════"

# 1. Ensure paths are on PATH
export PATH="$HOME/flutter/bin:$HOME/.local/bin:$PATH"

echo ""
echo "▶ 1/6 Flutter"
if ! command -v flutter &> /dev/null; then
  echo "   ⚠ Flutter not found. Installing..."
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$HOME/flutter"
fi
flutter --version | head -1
echo "   ✓ Flutter ready"

echo ""
echo "▶ 2/6 Poetry"
if ! command -v poetry &> /dev/null; then
  echo "   ⚠ Poetry not found. Installing..."
  curl -sSL https://install.python-poetry.org | python3 -
fi
poetry --version
echo "   ✓ Poetry ready"

echo ""
echo "▶ 3/6 Docker infrastructure"
if ! docker ps --format '{{.Names}}' | grep -q '^mindora-postgres$'; then
  echo "   ▶ Starting Docker..."
  bash scripts/dev-up.sh
else
  echo "   ✓ Docker already running"
fi

echo ""
echo "▶ 4/6 Backend dependencies"
cd backend/python_api
poetry install --quiet 2>/dev/null || poetry install
echo "   ✓ Backend deps ready"

echo ""
echo "▶ 5/6 Frontend dependencies"
cd /workspaces/mindora/frontend/flutter_app
flutter pub get > /dev/null
echo "   ✓ Frontend deps ready"

echo ""
echo "▶ 6/6 Migrations"
cd /workspaces/mindora/backend/python_api
poetry run alembic upgrade head 2>&1 | tail -3
echo "   ✓ Migrations applied"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ Setup complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  Now start these in SEPARATE terminals:"
echo ""
echo "  Terminal A — Backend"
echo "    cd /workspaces/mindora/backend/python_api"
echo "    poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
echo ""
echo "  Terminal B — Frontend"
echo "    cd /workspaces/mindora/frontend/flutter_app"
echo "    export PATH=\$HOME/flutter/bin:\$PATH"
echo "    flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0"
echo ""
echo "  Navigateur: Codespaces → Ports → 3000 → globe"
echo ""
