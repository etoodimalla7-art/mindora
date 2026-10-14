#!/usr/bin/env bash
# Relance l'infra + affiche les commandes à lancer.
set -euo pipefail

export PATH="$HOME/flutter/bin:$HOME/.local/bin:$PATH"
cd /workspaces/mindora

echo "▶ Vérification Docker..."
if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q mindora-postgres; then
  echo "   Redémarrage des conteneurs..."
  docker rm -f mindora-postgres mindora-redis mindora-minio 2>/dev/null || true
  bash scripts/dev-up.sh
else
  echo "   ✓ Docker déjà actif"
fi

echo ""
echo "▶ Vérification base de données..."
docker exec -it mindora-postgres psql -U mindora -d mindora -P pager=off -c "
SELECT
  (SELECT COUNT(*) FROM users) AS users,
  (SELECT COUNT(*) FROM documents WHERE status = 'approved') AS approved_docs,
  (SELECT COUNT(*) FROM mock_exams) AS mock_exams;
"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Maintenant, dans deux terminaux séparés :"
echo "═══════════════════════════════════════════════════════════"
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
echo "  Login: demo@mindora.dev / DemoPass123!"
