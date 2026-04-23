#!/usr/bin/env bash

set -e
set -u

FRONTEND_URL="http://localhost:8000"
INVENTORY_URL="http://localhost:3000"
NOTIFICATION_URL="http://localhost:3002"

PASS=0
FAIL=0


test_case(){

    local name="$1"
    local command="$2"

    echo -n "----$name"
    if eval "$command" > /dev/null 2>&1; then
        echo "PASS"
        PASS=$((PASS+1))
    else
        echo "FAIL"
        FAIL=$((FAIL+1))
    fi
}
echo "------------------------"
echo "  StockWatch Integration Tests"
echo "------------------------"
echo ""

echo " Health Checks"

test_case "Inventory /health responds 200" \
  "curl -sf $INVENTORY_URL/health | grep -q 'inventory'"

test_case "Notification /health responds 200" \
  "curl -sf $NOTIFICATION_URL/health | grep -q 'notification'"

test_case "Frontend serves HTML" \
  "curl -sf $FRONTEND_URL/ | grep -q '<html'"



echo ""
echo " Inventory CRUD"

test_case "GET /products returns JSON array" \
  "curl -sf $INVENTORY_URL/products | grep -qE '^\['"


echo ""
echo " Notification Validation"

test_case "POST /notify without 'to' returns 400" \
  "[[ \$(curl -s -o /dev/null -w '%{http_code}' -X POST $NOTIFICATION_URL/notify \
    -H 'Content-Type: application/json' \
    -d '{\"subject\":\"test\"}') == '400' ]]"

echo "  Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  echo " Integration tests FAILED"
  exit 1
fi

echo "All integration tests passed"
exit 0