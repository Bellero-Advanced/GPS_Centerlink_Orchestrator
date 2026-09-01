#!/bin/bash
# ═══════════════════════════════════════════════════════
# Run Vehicle Enrollment Script — Bellerox GPS
# Usage: ./scripts/run-enrollment.sh
# ═══════════════════════════════════════════════════════

set -e

# Load environment variables
if [ -f .env.local ]; then
  export $(cat .env.local | grep -v '^#' | xargs)
fi

# Check required environment variables
if [ -z "$TRACCAR_ADMIN_EMAIL" ]; then
  echo "❌ Error: TRACCAR_ADMIN_EMAIL not set"
  echo "   Add to .env.local or export it"
  exit 1
fi

if [ -z "$TRACCAR_ADMIN_PASSWORD" ]; then
  echo "❌ Error: TRACCAR_ADMIN_PASSWORD not set"
  echo "   Add to .env.local or export it"
  exit 1
fi

if [ -z "$SUPABASE_URL" ]; then
  echo "❌ Error: SUPABASE_URL not set"
  echo "   Add to .env.local or export it"
  exit 1
fi

if [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
  echo "❌ Error: SUPABASE_SERVICE_ROLE_KEY not set"
  echo "   Add to .env.local or export it"
  exit 1
fi

echo "🚀 Running enrollment script..."
echo ""

# Run with tsx (TypeScript execution)
npx tsx scripts/enroll-all-vehicles.ts

echo ""
echo "✅ Done!"
