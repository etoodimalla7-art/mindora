#!/usr/bin/env bash
# Complete recovery after Codespaces restart.
set -euo pipefail

export PATH="$HOME/flutter/bin:$HOME/.local/bin:$PATH"
cd /workspaces/mindora

echo "▶ 1. Docker..."
if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q mindora-postgres; then
  docker rm -f mindora-postgres mindora-redis mindora-minio 2>/dev/null || true
  bash scripts/dev-up.sh
else
  echo "   ✓ Docker running"
fi

echo "▶ 2. Database check..."
docker exec -it mindora-postgres psql -U mindora -d mindora -P pager=off -c "
SELECT
  (SELECT COUNT(*) FROM users) AS users,
  (SELECT COUNT(*) FROM documents WHERE status='approved') AS approved_docs,
  (SELECT COUNT(*) FROM plans) AS plans,
  (SELECT COUNT(*) FROM mock_exams) AS exams;
"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Run these in 2 separate terminals:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  Terminal A — Backend"
echo "    export PATH=\$HOME/.local/bin:\$PATH"
echo "    cd /workspaces/mindora/backend/python_api"
echo "    lsof -ti :8000 | xargs -r kill -9 || true"
echo "    poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
echo ""
echo "  Terminal B — Frontend"
echo "    export PATH=\$HOME/flutter/bin:\$PATH"
echo "    cd /workspaces/mindora/frontend/flutter_app"
echo "    flutter pub get"
echo "    flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0"
echo ""
echo "  Browser: Codespaces → Ports → 3000 → globe"
echo "  Login: demo@mindora.dev / DemoPass123!"
