#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
cd "$HOME/mikis13-site"

mkdir -p logs reports assets/css assets/js data

ERRORS=0

echo "=== 🔧 REPAIR BOT ==="

# Syntax
for f in server.mjs assets/js/*.js
do
  [ -f "$f" ] || continue
  if node --check "$f"
  then
    echo "✅ JS: $f"
  else
    echo "❌ JS: $f"
    ERRORS=$((ERRORS+1))
  fi
done

# HTML: lege links + ontbrekende lokale bestanden
python <<'PY'
from pathlib import Path
import re,sys

errors=0

for f in Path(".").glob("*.html"):
    s=f.read_text(errors="ignore")

    # lege href automatisch repareren
    n=re.sub(r'href=["\']\s*["\']','href="index.html"',s)

    if n != s:
        f.write_text(n)
        s=n
        print("🔧 lege href hersteld:",f)

    # lege buttons tekst geven
    n=re.sub(
        r'<button([^>]*)>\s*</button>',
        r'<button\1>Open</button>',
        s
    )

    if n != s:
        f.write_text(n)
        s=n
        print("🔧 lege knop hersteld:",f)

    # lokale href/src check
    links=re.findall(
        r'(?:href|src)=["\']([^"\']+)["\']',
        s
    )

    for link in links:
        if (
            link.startswith(("http:","https:","#","mailto:","tel:","data:"))
        ):
            continue

        target=link.split("?")[0].split("#")[0]

        if target and not Path(target).exists():
            print("❌ ontbreekt:",f,"->",target)
            errors+=1

sys.exit(1 if errors else 0)
PY

if [ $? -ne 0 ]
then
  ERRORS=$((ERRORS+1))
fi

# Secrets
if grep -RIE \
'sk_live_[A-Za-z0-9_-]{16,}|sk-proj-[A-Za-z0-9_-]{20,}|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}' \
. \
--exclude-dir=.git \
--exclude-dir=node_modules \
--exclude-dir=logs \
--exclude=.env \
>/dev/null 2>&1
then
  echo "❌ Mogelijke secret gevonden"
  ERRORS=$((ERRORS+1))
else
  echo "✅ Secret scan"
fi

echo
if [ "$ERRORS" -eq 0 ]
then
  echo "✅ REPAIR BOT: ALLES OK"
else
  echo "❌ Nog $ERRORS probleem/problemen"
fi

exit "$ERRORS"
