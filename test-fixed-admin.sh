#!/bin/bash
echo "=== Testing testadmin with corrected hash ==="
RESPONSE=$(curl -s -X POST "https://api.centerlink.co.th/api/session" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=testadmin&password=password" \
  -c cookies.txt \
  -w "\n---HTTP_CODE:%{http_code}---")

echo "$RESPONSE" | grep -v "^---HTTP" | head -20
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
echo "HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
  echo ""
  echo "✅ LOGIN SUCCESS!"
  echo ""
  echo "=== Getting session info ==="
  curl -s -X GET "https://api.centerlink.co.th/api/session" \
    -b cookies.txt | head -10
fi

rm -f cookies.txt
