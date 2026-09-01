#!/bin/bash
# Apply Payment System Migrations via Supabase Management API

SUPABASE_PROJECT_ID="zenfuxlykduaxrsnhmlq"
SUPABASE_ACCESS_TOKEN="${SUPABASE_ACCESS_TOKEN}"
MIGRATION_NAME="payment_system_$(date +%Y%m%d_%H%M%S)"

if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
  echo "❌ Error: SUPABASE_ACCESS_TOKEN not set"
  echo ""
  echo "Get your access token from:"
  echo "https://supabase.com/dashboard/account/tokens"
  echo ""
  echo "Then run:"
  echo "export SUPABASE_ACCESS_TOKEN='your-token-here'"
  echo "./apply-migrations-mgmt.sh"
  exit 1
fi

echo "🚀 Applying Payment System Migrations via Management API"
echo ""

# Combine all migrations into one
COMBINED_SQL=$(cat supabase/migrations/20260830000000_payment_slots.sql \
                    supabase/migrations/20260830000001_payment_queue.sql \
                    supabase/migrations/20260830000002_slot_cleanup.sql)

# Apply via Management API
echo "📤 Uploading migration: $MIGRATION_NAME"

curl -X POST \
  "https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_ID}/database/migrations/apply" \
  -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"${MIGRATION_NAME}\",
    \"statements\": $(echo "$COMBINED_SQL" | jq -Rs .)
  }" 2>&1

echo ""
echo "✅ Migration request sent"
echo ""
echo "📊 Verify in Supabase Dashboard:"
echo "   https://supabase.com/dashboard/project/${SUPABASE_PROJECT_ID}"
