#!/bin/bash
# Database Restore Script
# Phase 14: Disaster Recovery
# Date: 2026-08-25

set -e

echo "♻️  Bellerox GPS - Database Restore"
echo "===================================="

DB_NAME="traccar"
DB_USER="traccar"
BACKUP_DIR="/opt/backups/postgres"

# Check if backup file provided
if [ -z "$1" ]; then
  echo "Usage: ./restore-database.sh <backup-file>"
  echo ""
  echo "Available backups:"
  ls -lh "$BACKUP_DIR" | grep ".sql.gz" | tail -10
  exit 1
fi

BACKUP_FILE="$1"

# Check if file exists
if [ ! -f "$BACKUP_FILE" ]; then
  # Try looking in backup directory
  if [ -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
  else
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
  fi
fi

echo "⚠️  WARNING: This will replace the current database!"
echo "Backup file: $BACKUP_FILE"
echo ""
read -p "Are you sure? (type 'yes' to continue): " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ Restore cancelled"
  exit 0
fi

echo "📦 Step 1: Creating safety backup of current database"
SAFETY_BACKUP="$BACKUP_DIR/before_restore_$(date +%Y%m%d_%H%M%S).sql.gz"
sudo -u postgres pg_dump "$DB_NAME" | gzip > "$SAFETY_BACKUP"
echo "✅ Safety backup: $SAFETY_BACKUP"

echo "🛑 Step 2: Stopping API server"
pm2 stop bellerox-api || true

echo "🗄️  Step 3: Dropping existing database"
sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;"

echo "🆕 Step 4: Creating fresh database"
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

echo "📥 Step 5: Restoring from backup"
gunzip -c "$BACKUP_FILE" | sudo -u postgres psql -d "$DB_NAME"

echo "🔄 Step 6: Restarting API server"
pm2 restart bellerox-api

echo "✅ Step 7: Verifying restore"
sleep 3
curl -f http://localhost:3001/health || echo "⚠️  Health check failed"

echo ""
echo "✅ Database restored successfully!"
echo "📁 Restored from: $BACKUP_FILE"
echo "🔒 Safety backup: $SAFETY_BACKUP"
