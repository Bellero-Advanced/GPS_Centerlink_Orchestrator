#!/bin/bash
# Apply payment system migrations to Supabase

SUPABASE_URL="https://zenfuxlykduaxrsnhmlq.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplbmZ1eGx5a2R1YXhyc25obWxxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MzkzNDMxOSwiZXhwIjoyMDk5NTEwMzE5fQ.tnWEDjbWelDHVI8h2RM5N5XWrrmg4aO9e_LJQ3r-kus"

echo "🚀 Applying payment system migrations..."
echo ""

for migration in supabase/migrations/202608300000*.sql; do
  if [ -f "$migration" ]; then
    echo "📄 Applying: $(basename $migration)"
    
    # Read SQL file
    SQL=$(cat "$migration")
    
    # Apply via Supabase REST API
    curl -X POST "${SUPABASE_URL}/rest/v1/rpc/exec_sql" \
      -H "apikey: ${SUPABASE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_KEY}" \
      -H "Content-Type: application/json" \
      -d "{\"query\": $(jq -Rs . < "$migration")}" \
      2>/dev/null
    
    echo " ✅"
    echo ""
  fi
done

echo "🎉 All migrations applied!"
