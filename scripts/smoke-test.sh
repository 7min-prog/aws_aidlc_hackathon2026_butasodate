#!/bin/bash
# Post-deploy smoke test: verify APIs return expected status codes and CORS headers
set -euo pipefail

AUTH_API="${AUTH_API_URL:-https://ubw8w4wnp7.execute-api.ap-northeast-1.amazonaws.com/dev}"
RECORDING_API="${RECORDING_API_URL:-https://tlw1w8knh7.execute-api.ap-northeast-1.amazonaws.com/dev}"
AVATAR_API="${AVATAR_API_URL:-https://dgjfsg2e9b.execute-api.ap-northeast-1.amazonaws.com/dev}"

FAILED=0
TOTAL=0

check() {
  local label="$1"
  local expected_status="$2"
  local url="$3"
  shift 3
  TOTAL=$((TOTAL + 1))

  local response
  response=$(curl -s -o /dev/null -w "%{http_code}|%{header_json}" "$url" "$@" 2>/dev/null || echo "000|")
  local status="${response%%|*}"

  if [ "$status" = "$expected_status" ]; then
    echo "  ✅ $label → $status"
  else
    echo "  ❌ $label → $status (expected $expected_status)"
    FAILED=$((FAILED + 1))
  fi
}

check_cors() {
  local label="$1"
  local url="$2"
  TOTAL=$((TOTAL + 1))

  local cors_header
  cors_header=$(curl -s -I -X OPTIONS "$url" \
    -H "Origin: https://example.com" \
    -H "Access-Control-Request-Method: GET" 2>/dev/null | grep -i "access-control-allow-origin" || echo "")

  if echo "$cors_header" | grep -qi "access-control-allow-origin"; then
    echo "  ✅ $label CORS → present"
  else
    echo "  ❌ $label CORS → missing Access-Control-Allow-Origin"
    FAILED=$((FAILED + 1))
  fi
}

echo ""
echo "🔍 Smoke Test - Auth API ($AUTH_API)"
echo "─────────────────────────────────────"
check "POST /auth/login (no body)"  "400" "$AUTH_API/auth/login" -X POST -H "Content-Type: application/json" -d '{}'
check "GET /users/me (no token)"    "401" "$AUTH_API/users/me"
check "GET /nonexistent"            "404" "$AUTH_API/nonexistent"
check_cors "OPTIONS /auth/login"    "$AUTH_API/auth/login"

echo ""
echo "🔍 Smoke Test - Recording API ($RECORDING_API)"
echo "─────────────────────────────────────"
check "GET /activities (no token)"  "401" "$RECORDING_API/activities"
check "POST /activities (no token)" "401" "$RECORDING_API/activities" -X POST -H "Content-Type: application/json" -d '{}'
check_cors "OPTIONS /activities"    "$RECORDING_API/activities"

echo ""
echo "🔍 Smoke Test - Avatar API ($AVATAR_API)"
echo "─────────────────────────────────────"
check "GET /avatar (no token)"      "401" "$AVATAR_API/avatar"
check "POST /avatar (no token)"     "401" "$AVATAR_API/avatar" -X POST -H "Content-Type: application/json" -d '{"name":"test"}'
check_cors "OPTIONS /avatar"        "$AVATAR_API/avatar"

echo ""
echo "─────────────────────────────────────"
echo "Results: $((TOTAL - FAILED))/$TOTAL passed"

if [ $FAILED -ne 0 ]; then
  echo "❌ $FAILED check(s) failed!"
  exit 1
fi
echo "✅ All smoke tests passed!"
