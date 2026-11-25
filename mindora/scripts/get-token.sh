#!/usr/bin/env bash
# Fetch a fresh JWT access token for the demo user.
# Usage: source scripts/get-token.sh
set -euo pipefail
API="${API:-http://localhost:8000/api/v1}"
EMAIL="${TEST_EMAIL:-demo@mindora.dev}"
PASS="${TEST_PASSWORD:-DemoPass123!}"

# Ensure the user exists (idempotent).
curl -s -X POST "$API/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"full_name\":\"Demo Student\",\"preferred_language\":\"fr\",\"country_code\":\"CM\"}" \
  > /dev/null 2>&1 || true

TOKEN=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['tokens']['access_token'])")

export TOKEN
echo "✓ TOKEN set (${#TOKEN} chars)"
