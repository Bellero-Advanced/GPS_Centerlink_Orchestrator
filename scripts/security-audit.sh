#!/bin/bash
# Security Audit Script
# Phase 15: Security Hardening
# Date: 2026-08-25

echo "🔒 Bellerox GPS - Security Audit"
echo "================================="
echo ""

PASS=0
WARN=0
FAIL=0

check_pass() {
  echo "✅ $1"
  ((PASS++))
}

check_warn() {
  echo "⚠️  $1"
  ((WARN++))
}

check_fail() {
  echo "❌ $1"
  ((FAIL++))
}

echo "1. Checking sensitive files..."
if [ ! -f ".env" ] || grep -q "sk_live_" .env 2>/dev/null; then
  check_fail "Production secrets in .env file"
else
  check_pass "No hardcoded secrets found"
fi

echo ""
echo "2. Checking file permissions..."
if [ -f ".env" ]; then
  PERM=$(stat -f "%Lp" .env 2>/dev/null || stat -c "%a" .env)
  if [ "$PERM" = "600" ] || [ "$PERM" = "400" ]; then
    check_pass ".env has secure permissions ($PERM)"
  else
    check_fail ".env has insecure permissions ($PERM)"
  fi
fi

echo ""
echo "3. Checking dependencies..."
npm audit --audit-level=high 2>&1 | grep -q "found 0 vulnerabilities" && \
  check_pass "No high/critical vulnerabilities in dependencies" || \
  check_warn "Vulnerabilities found in dependencies (run: npm audit)"

echo ""
echo "4. Checking HTTPS configuration..."
if grep -q "https://" vite.config.ts 2>/dev/null; then
  check_pass "HTTPS configured"
else
  check_warn "HTTPS not configured (development mode?)"
fi

echo ""
echo "5. Checking database security..."
if docker ps | grep -q postgres; then
  check_pass "PostgreSQL running in Docker"
else
  check_warn "PostgreSQL not containerized"
fi

echo ""
echo "6. Checking rate limiting..."
if grep -q "rateLimit" server/middleware/*.js 2>/dev/null; then
  check_pass "Rate limiting middleware found"
else
  check_fail "Rate limiting not implemented"
fi

echo ""
echo "7. Checking CORS configuration..."
if grep -q "cors" server/index.js 2>/dev/null; then
  check_pass "CORS configured"
else
  check_warn "CORS not configured"
fi

echo ""
echo "8. Checking authentication..."
if grep -q "apiKeyAuth" server/index.js 2>/dev/null; then
  check_pass "API key authentication found"
else
  check_warn "API key authentication not found"
fi

echo ""
echo "9. Checking SQL injection prevention..."
if grep -q '\$[0-9]' server/routes/*.js 2>/dev/null; then
  check_pass "Parameterized queries found"
else
  check_fail "No parameterized queries detected"
fi

echo ""
echo "10. Checking audit logging..."
if grep -q "auditLog" server/middleware/*.js 2>/dev/null; then
  check_pass "Audit logging middleware found"
else
  check_fail "Audit logging not implemented"
fi

echo ""
echo "================================="
echo "Security Audit Summary"
echo "================================="
echo "✅ Passed:  $PASS"
echo "⚠️  Warnings: $WARN"
echo "❌ Failed:  $FAIL"
echo ""

if [ $FAIL -gt 0 ]; then
  echo "❌ Security audit failed! Address critical issues."
  exit 1
elif [ $WARN -gt 0 ]; then
  echo "⚠️  Security audit passed with warnings."
  exit 0
else
  echo "✅ Security audit passed!"
  exit 0
fi
