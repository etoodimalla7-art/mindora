#!/usr/bin/env bash
# Tests the credits + admin moderation flow.
set -euo pipefail

API="${API:-http://localhost:8000/api/v1}"
EMAIL="${TEST_EMAIL:-demo@mindora.dev}"
PASS="${TEST_PASSWORD:-DemoPass123!}"

login() {
  curl -s -X POST "$API/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$1\",\"password\":\"$2\"}" \
    | python3 -c "import sys, json; print(json.load(sys.stdin)['tokens']['access_token'])"
}

echo "▶ Logging in as $EMAIL..."
TOKEN=$(login "$EMAIL" "$PASS")
[ -n "$TOKEN" ] || { echo "✗ Login failed"; exit 1; }
echo "✓ Token acquired (${#TOKEN} chars)"

echo ""
echo "▶ Credit balance:"
curl -s "$API/credits" -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo ""
echo "▶ Admin: pending documents (under_review):"
curl -s "$API/admin/documents?status=under_review" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool | head -30
