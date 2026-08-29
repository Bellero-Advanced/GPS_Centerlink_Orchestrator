#!/bin/bash
# Deployment Script
# Phase 13: CI/CD Pipeline Hardening
# Date: 2026-08-25

set -e  # Exit on error

echo "🚀 Bellerox GPS - Deployment Script"
echo "===================================="

# Variables
REPO_DIR="/opt/bellerox-gps"
API_DIR="$REPO_DIR/server"
WEB_DIR="$REPO_DIR/bellerox-gps-web"
BACKUP_DIR="/opt/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run with sudo"
  exit 1
fi

echo "📦 Step 1: Backup current version"
mkdir -p "$BACKUP_DIR/deployments"
tar -czf "$BACKUP_DIR/deployments/backup_$TIMESTAMP.tar.gz" \
  -C "$REPO_DIR" \
  --exclude=node_modules \
  --exclude=.git \
  . || echo "⚠️  Backup failed (continuing anyway)"

echo "📥 Step 2: Pull latest code"
cd "$REPO_DIR"
git fetch origin
git pull origin main

echo "📦 Step 3: Install dependencies"
cd "$WEB_DIR"
npm ci --production

echo "🏗️  Step 4: Build frontend"
npm run build

echo "🗄️  Step 5: Run database migrations"
for migration in "$REPO_DIR"/migrations/*.sql; do
  echo "Running $(basename "$migration")..."
  sudo -u postgres psql -U traccar -d traccar -f "$migration" 2>&1 | grep -v "already exists" || true
done

echo "🔄 Step 6: Restart services"
pm2 restart bellerox-api || pm2 start "$API_DIR/index.js" --name bellerox-api

echo "✅ Step 7: Verify deployment"
sleep 3
curl -f http://localhost:3001/health || {
  echo "❌ Health check failed! Rolling back..."
  ./rollback.sh
  exit 1
}

echo ""
echo "✅ Deployment completed successfully!"
echo "📊 Check logs: pm2 logs bellerox-api"
echo "📈 Monitor: pm2 monit"
