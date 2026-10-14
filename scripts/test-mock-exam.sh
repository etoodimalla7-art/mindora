#!/usr/bin/env bash
# Test the mock exam flow end-to-end via curl.
# Usage: bash scripts/test-mock-exam.sh
set -euo pipefail

API="${API:-http://localhost:8000/api/v1}"
EMAIL="${TEST_EMAIL:-demo@mindora.dev}"
PASS="${TEST_PASSWORD:-DemoPass123!}"

echo "▶ Logging in..."
TOKEN=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['tokens']['access_token'])")
[ -n "$TOKEN" ] || { echo "✗ Login failed"; exit 1; }
echo "✓ Token acquired (${#TOKEN} chars)"

echo ""
echo "▶ Creating mock exam (3 questions on Mathematics)..."
EXAM_JSON=$(curl -s -X POST "$API/mock-exams" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Quick DE test",
    "subject": "Mathematics",
    "academic_level": "GCE_AL",
    "question_count": 3,
    "duration_minutes": 15,
    "difficulty": "medium"
  }')

echo "$EXAM_JSON" | python3 -m json.tool | head -40

EXAM_ID=$(echo "$EXAM_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
QUESTION_IDS=$(echo "$EXAM_JSON" | python3 -c "
import sys,json
d = json.load(sys.stdin)
for q in d['questions']:
    print(q['id'])
")

echo ""
echo "✓ Exam ID: $EXAM_ID"

echo ""
echo "▶ Starting exam..."
curl -s -X POST "$API/mock-exams/$EXAM_ID/start" \
  -H "Authorization: Bearer $TOKEN" | python3 -c "import sys,json; d=json.load(sys.stdin); print('Status:', d['status'])"

echo ""
echo "▶ Answering each question with 'A'..."
for QID in $QUESTION_IDS; do
  curl -s -X POST "$API/mock-exams/$EXAM_ID/answer" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"question_id\":\"$QID\",\"answer\":\"A\",\"time_spent_seconds\":10}" \
    > /dev/null
  echo "  ✓ $QID"
done

echo ""
echo "▶ Submitting exam..."
curl -s -X POST "$API/mock-exams/$EXAM_ID/submit" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool | head -60

echo ""
echo "▶ Fetching results..."
curl -s "$API/mock-exams/$EXAM_ID/results" \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys,json
d = json.load(sys.stdin)
print('Score:', d['score'], '%')
print('Correct:', d['correct_count'], '/', d['correct_count']+d['wrong_count']+d['skipped_count'])
print('Feedback:', d['feedback_summary'])
print('Topics:', d.get('topic_breakdown', {}))
"
