#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="${1:-$HOME/mikis13-site}"
cd "$ROOT"

FAIL=0

echo
echo "=== MIKIS13 DOCTOR ==="

required=(
  index.html
  contact.html
  privacy.html
  voorwaarden.html
  jobs.html
)

for f in "${required[@]}"; do
  if [ -s "$f" ]; then
    echo "✅ $f"
  else
    echo "❌ $f"
    FAIL=1
  fi
done

echo
echo "=== JavaScript ==="

while IFS= read -r file; do
  node --check "$file" >/dev/null || FAIL=1
done < <(
  find . \
    -type f \
    -name '*.js' \
    ! -path './node_modules/*' \
    ! -path './archive/*'
)

echo "✅ JavaScript controle klaar"

echo
echo "=== Secrets ==="

PATTERN='sk-proj-[A-Za-z0-9_-]{20,}|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}'

if git grep -nE "$PATTERN" -- \
     ':!*.md' \
     ':!.github/workflows/*' \
     >/tmp/mikis-secret-scan.$$ 2>/dev/null
then
  echo "❌ Mogelijk geheim gevonden"
  cat /tmp/mikis-secret-scan.$$
  rm -f /tmp/mikis-secret-scan.$$
  FAIL=1
else
  rm -f /tmp/mikis-secret-scan.$$ || true
  echo "✅ Geen herkenbare secrets"
fi

echo
echo "=== Git ==="

git status -sb

echo
echo "=== Resultaat ==="

if [ "$FAIL" -eq 0 ]; then
  echo "✅ DOCTOR PASS"
else
  echo "❌ DOCTOR FAIL"
fi

exit "$FAIL"
