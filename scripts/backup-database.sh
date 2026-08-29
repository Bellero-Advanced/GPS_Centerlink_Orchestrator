#!/bin/bash
# Database Backup Script
# Phase 14: Disaster Recovery
# Date: 2026-08-25

set -e

echo "💾 Bellerox GPS - Database Backup"
echo "=================================="

# Configuration
DB_NAME="traccar"
DB_USER="traccar"
BACKUP_DIR="/opt/backups/postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE=$(date +%Y%m%d)
BACKUP_FILE="$BACKUP_DIR/traccar_$TIMESTAMP.sql.gz"

# Retention
DAILY_RETENTION=7    # Keep 7 daily backups
WEEKLY_RETENTION=4   # Keep 4 weekly backups
MONTHLY_RETENTION=3  # Keep 3 monthly backups

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "📦 Creating backup: $BACKUP_FILE"

# Dump database with compression
sudo -u postgres pg_dump "$DB_NAME" | gzip > "$BACKUP_FILE"

# Verify backup
if [ -f "$BACKUP_FILE" ]; then
  SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
  echo "✅ Backup created: $SIZE"
else
  echo "❌ Backup failed!"
  exit 1
fi

# Create symlinks for latest backups
ln -sf "$BACKUP_FILE" "$BACKUP_DIR/latest.sql.gz"

# Weekly backup (Sunday)
if [ "$(date +%u)" -eq 7 ]; then
  cp "$BACKUP_FILE" "$BACKUP_DIR/weekly_$DATE.sql.gz"
  echo "📅 Weekly backup created"
fi

# Monthly backup (1st of month)
if [ "$(date +%d)" -eq 01 ]; then
  cp "$BACKUP_FILE" "$BACKUP_DIR/monthly_$DATE.sql.gz"
  echo "📅 Monthly backup created"
fi

# Cleanup old backups
echo "🧹 Cleaning up old backups..."

# Remove daily backups older than retention
find "$BACKUP_DIR" -name "traccar_*.sql.gz" -mtime +$DAILY_RETENTION -delete

# Remove weekly backups older than retention
find "$BACKUP_DIR" -name "weekly_*.sql.gz" -mtime +$((WEEKLY_RETENTION * 7)) -delete

# Remove monthly backups older than retention
find "$BACKUP_DIR" -name "monthly_*.sql.gz" -mtime +$((MONTHLY_RETENTION * 30)) -delete

echo ""
echo "✅ Backup completed successfully!"
echo "📁 Backup location: $BACKUP_FILE"
echo "📊 Total backups:"
ls -lh "$BACKUP_DIR" | grep -E "(traccar_|weekly_|monthly_)" | wc -l
