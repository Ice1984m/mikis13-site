#!/usr/bin/env bash
set -Eeuo pipefail

PATTERN='gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-proj-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}'

RESULT="$(
  git grep \
    -nE "$PATTERN" \
    -- \
    ':!scripts/security-check.sh' \
    ':!node_modules' \
    ':!vendor' \
    2>/dev/null || true
)"

if [ -n "$RESULT" ]; then
  echo "❌ Mogelijke geheime sleutel gevonden:"
  printf '%s\n' "$RESULT"
  exit 1
fi

if [ -f package-lock.json ]; then
  npm audit --audit-level=high
fi

echo "✅ Securityscan geslaagd."
