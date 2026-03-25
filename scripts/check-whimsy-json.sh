#!/usr/bin/env bash
# Checks whimsy site-scan.json for fineract compliance
# Usage: ./scripts/check-whimsy-json.sh
# Source: https://whimsy.apache.org/public/site-scan.json

set -euo pipefail

echo "Fetching whimsy site-scan.json..."
DATA=$(curl -s https://whimsy.apache.org/public/site-scan.json | jq '.fineract')

echo "Whimsy scan results for fineract:"
echo "$DATA" | jq .

FAILED=0

check_field() {
  FIELD=$1
  VALUE=$(echo "$DATA" | jq -r ".$FIELD")
  if [ "$VALUE" = "null" ] || [ -z "$VALUE" ]; then
    echo "FAIL: $FIELD is null/missing"
    FAILED=1
  else
    echo "PASS: $FIELD = $VALUE"
  fi
}

check_field "uri"
check_field "foundation"
check_field "events"
check_field "license"
check_field "thanks"
check_field "security"
check_field "sponsorship"
check_field "trademarks"
check_field "copyright"
check_field "privacy"
check_field "resources"
check_field "image"

# csp_check is done differently - whimsy sets it to "OK" if csp matches
# the expected DEFAULT_CSP pattern from sitestandards.rb
# See: https://infra.apache.org/tools/csp.html
CSP_CHECK=$(echo "$DATA" | jq -r '.csp_check')
if [ "$CSP_CHECK" = "OK" ]; then
  echo "PASS: csp_check = OK"
else
  echo "WARN: csp_check = $CSP_CHECK (not OK but not blocking)"
  echo "See https://infra.apache.org/tools/csp.html for details"
fi

# Check errors array is empty
ERRORS=$(echo "$DATA" | jq -r '.errors')
if [ "$ERRORS" != "[]" ] && [ "$ERRORS" != "null" ]; then
  echo "FAIL: whimsy reported errors: $ERRORS"
  FAILED=1
fi

if [ "$FAILED" = "1" ]; then
  echo ""
  echo "One or more whimsy checks failed!"
  echo "See https://whimsy.apache.org/site/project/fineract for details"
  exit 1
fi

echo ""
echo "All whimsy checks passed!"