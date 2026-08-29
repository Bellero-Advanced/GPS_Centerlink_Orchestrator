#!/bin/bash
# ═══════════════════════════════════════════════════════
# Fix GT06 Timezone — Set decoder.timezone per device
# Usage: TRACCAR_USER=admin TRACCAR_PASS=xxx ./fix-gt06-timezone.sh
# ═══════════════════════════════════════════════════════

set -e

API_URL="${TRACCAR_API_URL:-https://api.centerlink.co.th}"
USER="${TRACCAR_USER}"
PASS="${TRACCAR_PASS}"

if [ -z "$USER" ] || [ -z "$PASS" ]; then
  echo "❌ Missing TRACCAR_USER or TRACCAR_PASS"
  exit 1
fi

# GT06 devices ที่ต้องแก้ (จากการสำรวจ)
GT06_DEVICES=(128 229 219 123 248 220 242 136 91 205 80 142 116 180 69 88 117)

echo "🔧 Fix GT06 Timezone — Per-Device Attribute"
echo ""
echo "API: $API_URL"
echo "User: $USER"
echo "Devices: ${#GT06_DEVICES[@]}"
echo ""

success=0
failed=0

for deviceId in "${GT06_DEVICES[@]}"; do
  echo -n "Device $deviceId: "

  # 1. ดึง device ปัจจุบัน
  device_json=$(curl -s -u "$USER:$PASS" "$API_URL/api/devices/$deviceId")

  # 2. เพิ่ม decoder.timezone attribute
  updated_json=$(echo "$device_json" | jq '.attributes["decoder.timezone"] = "-07:00"')

  # 3. Update device
  response=$(curl -s -u "$USER:$PASS" \
    -X PUT \
    -H "Content-Type: application/json" \
    -d "$updated_json" \
    "$API_URL/api/devices/$deviceId" \
    -w "\n%{http_code}")

  http_code=$(echo "$response" | tail -1)

  if [ "$http_code" = "200" ]; then
    device_name=$(echo "$device_json" | jq -r '.name')
    echo "✅ $device_name (decoder.timezone = -07:00)"
    ((success++))
  else
    echo "❌ HTTP $http_code"
    ((failed++))
  fi

  # Delay 200ms
  sleep 0.2
done

echo ""
echo "📊 Summary:"
echo "✅ Success: $success/${#GT06_DEVICES[@]}"
echo "❌ Failed: $failed"
