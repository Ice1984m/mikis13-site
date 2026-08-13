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

TMPFILE="$(mktemp "${TMPDIR:-$PREFIX/tmp}/mikis-secret-scan.XXXXXX")" || {
  echo "❌ Tijdelijk bestand kon niet worden gemaakt"
  FAIL=1
  TMPFILE=""
}

if [ -n "$TMPFILE" ]; then

  set +e

  git grep -nE "$PATTERN" -- \
       ':!*.md' \
       ':!.github/workflows/*' \
       ':!backup/*' \
       ':!backup/**/*' \
       ':!backups/*' \
       ':!backups/**/*' \
       ':!archive/*' \
       ':!archive/**/*' \
       >"$TMPFILE" 2>/dev/null

  SCAN_RC=$?

  set -e

  case "$SCAN_RC" in

    0)
      echo "❌ Mogelijk geheim gevonden"
      cat "$TMPFILE"
      FAIL=1
      ;;

    1)
      echo "✅ Geen herkenbare secrets"
      ;;

    *)
      echo "❌ Secret scanner foutcode: $SCAN_RC"
      FAIL=1
      ;;

  esac

  rm -f "$TMPFILE"
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
