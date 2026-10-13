#!/usr/bin/env bash
# End-to-end document upload test against the local backend.
# Usage: bash scripts/test-upload.sh
set -euo pipefail

API="${API:-http://localhost:8000/api/v1}"
EMAIL="${TEST_EMAIL:-demo@mindora.dev}"
PASS="${TEST_PASSWORD:-DemoPass123!}"
FIXTURES="/workspaces/mindora/backend/python_api/tests/fixtures"

# Make the fixture unique on each run to avoid triggering dedup.
STAMP=$(date +%s)
TMP_DOC="/tmp/mindora_test_doc_${STAMP}.txt"
TMP_DESC="/tmp/mindora_test_desc_${STAMP}.txt"

cp "$FIXTURES/sample_doc.txt" "$TMP_DOC"
echo -e "\n<!-- run ${STAMP} -->" >> "$TMP_DOC"
cp "$FIXTURES/sample_description.txt" "$TMP_DESC"

echo "▶ Ensuring demo account exists..."
curl -s -X POST "$API/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"full_name\":\"Demo Student\",\"preferred_language\":\"fr\",\"country_code\":\"CM\"}" \
  > /dev/null 2>&1 || true

echo "▶ Logging in..."
TOKEN=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['tokens']['access_token'])")

if [ -z "$TOKEN" ]; then
  echo "✗ Login failed"
  exit 1
fi
echo "✓ Token acquired (${#TOKEN} chars)"

echo "▶ Uploading document..."
UPLOAD_RESPONSE=$(curl -s -X POST "$API/documents/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@${TMP_DOC};type=text/plain" \
  -F "title=Test differential equations notes ${STAMP}" \
  -F "description=$(cat ${TMP_DESC})")

DOC_ID=$(echo "$UPLOAD_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))")

if [ -z "$DOC_ID" ]; then
  echo "✗ Upload failed:"
  echo "$UPLOAD_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$UPLOAD_RESPONSE"
  exit 1
fi
echo "✓ Uploaded, DOC_ID=$DOC_ID"

echo "▶ Submitting document for analysis..."
SUBMIT_RESPONSE=$(curl -s -X POST "$API/documents/$DOC_ID/submit" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "category": "Mathematics",
    "academic_level": "GCE_AL",
    "language": "en",
    "is_exam_related": false,
    "document_type": "course_notes"
  }')

echo "$SUBMIT_RESPONSE" | python3 -m json.tool | head -50

echo ""
echo "▶ Fetching status..."
curl -s "$API/documents/$DOC_ID/status" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

rm -f "$TMP_DOC" "$TMP_DESC"
echo ""
echo "✅ End-to-end test complete. DOC_ID=$DOC_ID"
