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
EXPECTED_CSP="default-src 'self' data: blob: 'unsafe-inline' 'unsafe-eval' https://www.apachecon.com/ https://www.communityovercode.org/ https://*.apache.org/ https://apache.org/ https://*.scarf.sh/  ; script-src 'self' data: blob: 'unsafe-inline' 'unsafe-eval' https://www.apachecon.com/ https://www.communityovercode.org/ https://*.apache.org/ https://apache.org/ https://*.scarf.sh/  ; style-src 'self' data: blob: 'unsafe-inline' 'unsafe-eval' https://www.apachecon.com/ https://www.communityovercode.org/ https://*.apache.org/ https://apache.org/ https://*.scarf.sh/  ; frame-ancestors 'self'; frame-src 'self' data: blob: 'unsafe-inline' 'unsafe-eval' https://www.apachecon.com/ https://www.communityovercode.org/ https://*.apache.org/ https://apache.org/ https://*.scarf.sh/  ; worker-src 'self' data: blob:;"

CSP=$(echo "$DATA" | jq -r '.csp')
if [ "$CSP" = "$EXPECTED_CSP" ]; then
  echo "PASS: csp matches expected DEFAULT_CSP"
else
  echo "FAIL: csp does not match expected DEFAULT_CSP"
  echo "  actual:   $CSP"
  echo "  expected: $EXPECTED_CSP"
  FAILED=1
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