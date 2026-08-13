#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$HOME/mikis13-site"
LOG="$HOME/.mikis13/logs/repair.log"

mkdir -p "$(dirname "$LOG")"

exec >>"$LOG" 2>&1

cd "$ROOT"

echo
echo "======================================="
echo "Repair $(date -Iseconds)"
echo "======================================="

git fetch origin main || true

if ! ./scripts/mikis-doctor.sh "$ROOT"; then
  echo "Doctor vond een probleem."

  # Veilig automatisch herstel:
  # alleen ontbrekende directories en bekende workflowfixes.
  mkdir -p assets/css assets/js

  python - <<'PY'
from pathlib import Path

p = Path(".github/workflows/pages.yml")

if p.exists():
    s = p.read_text(encoding="utf-8")

    s = s.replace(
        "actions/upload-pages-artifact@v3",
        "actions/upload-pages-artifact@v4"
    )

    p.write_text(s, encoding="utf-8")
PY
fi

./scripts/mikis-local-test.sh "$ROOT"

echo "Repair cycle voltooid."
