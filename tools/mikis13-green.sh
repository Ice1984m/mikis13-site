#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

R="$HOME/mikis13-site"
PORT=4500
TMP="${TMPDIR:-$PREFIX/tmp}"

cd "$R"

mkdir -p \
  "$TMP" \
  logs \
  reports \
  data \
  tools \
  .github/workflows

echo "=================================="
echo "🟣 MIKIS13 GREEN REPAIR"
echo "=================================="

# ---------------------------------
# 1. Termux /tmp definitief fixen
# ---------------------------------


echo "✅ TMPDIR = $TMP"

# ---------------------------------
# 2. Runtime bestanden
# ---------------------------------

[ -f data/orders.json ] || echo '[]' > data/orders.json

# ---------------------------------
# 3. Syntax
# ---------------------------------

node --check server.mjs

for f in assets/js/*.js
do
  [ -f "$f" ] || continue
  node --check "$f"
done

echo "✅ JavaScript syntax"

# ---------------------------------
# 4. Repair-bot
# ---------------------------------

if [ -x tools/repair.sh ]; then
  bash tools/repair.sh
fi

# ---------------------------------
# 5. Oude server stoppen
# ---------------------------------

if [ -f .server.pid ]; then
  kill "$(cat .server.pid)" 2>/dev/null || true
  rm -f .server.pid
fi

pkill -f "node server.mjs" 2>/dev/null || true

sleep 1

# ---------------------------------
# 6. ENV laden
# ---------------------------------

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

# ---------------------------------
# 7. Server starten
# ---------------------------------

nohup env \
  PORT="$PORT" \
  HOST=0.0.0.0 \
  node server.mjs \
  > logs/console.log 2>&1 &

echo $! > .server.pid

sleep 3

# ---------------------------------
# 8. Health
# ---------------------------------

if ! curl -fsS \
  "http://127.0.0.1:$PORT/health" \
  > "$TMP/health.json"
then
  echo "❌ SERVER START FOUT"
  tail -80 logs/console.log
  exit 1
fi

cat "$TMP/health.json" | jq .

echo "✅ server online"

# ---------------------------------
# 9. Belangrijke URLs
# ---------------------------------

ERRORS=0

for URL in \
  / \
  /index.html \
  /shop.html \
  /success.html \
  /status.html \
  /health \
  /api/status \
  /api/products \
  /api/orders
do
  CODE="$(
    curl -s \
      -o "$TMP/http-test" \
      -w '%{http_code}' \
      "http://127.0.0.1:$PORT$URL"
  )"

  if [[ "$CODE" =~ ^2 ]]; then
    echo "✅ $URL HTTP $CODE"
  else
    echo "❌ $URL HTTP $CODE"
    ERRORS=$((ERRORS+1))
  fi
done

# ---------------------------------
# 10. Lege cart moet 400 zijn
# ---------------------------------

CODE="$(
  curl -s \
    -o "$TMP/empty.json" \
    -w '%{http_code}' \
    -H 'Content-Type: application/json' \
    -d '{"items":[]}' \
    "http://127.0.0.1:$PORT/api/checkout/create"
)"

if [ "$CODE" = "400" ]; then
  echo "✅ lege winkelmand correct geweigerd"
else
  echo "❌ lege winkelmand HTTP $CODE"
  ERRORS=$((ERRORS+1))
fi

# ---------------------------------
# 11. Demo checkout
# ---------------------------------

curl -fsS \
  -H 'Content-Type: application/json' \
  -d '{"items":[{"id":"repair","quantity":1}]}' \
  "http://127.0.0.1:$PORT/api/checkout/create" \
  > "$TMP/order.json"

cat "$TMP/order.json" | jq .

if jq -e '.url and .orderId' \
  "$TMP/order.json" >/dev/null
then
  echo "✅ orderbot checkout werkt"
else
  echo "❌ orderbot checkout fout"
  ERRORS=$((ERRORS+1))
fi

# ---------------------------------
# 12. Order werkelijk opgeslagen?
# ---------------------------------

curl -fsS \
  "http://127.0.0.1:$PORT/api/orders" \
  > "$TMP/orders.json"

ORDERID="$(jq -r '.orderId' "$TMP/order.json")"

if jq -e \
  --arg id "$ORDERID" \
  '.orders[] | select(.id==$id)' \
  "$TMP/orders.json" >/dev/null
then
  echo "✅ order opgeslagen: $ORDERID"
else
  echo "❌ order niet opgeslagen"
  ERRORS=$((ERRORS+1))
fi

# ---------------------------------
# 13. Bestaande complete test
# ---------------------------------

if [ -x tools/test-all.sh ]; then
  if bash tools/test-all.sh; then
    echo "✅ complete test geslaagd"
  else
    echo "❌ complete test faalt"
    ERRORS=$((ERRORS+1))
  fi
fi

# ---------------------------------
# 14. Secrets
# ---------------------------------

PATTERN='sk_live_[A-Za-z0-9_-]{16,}|sk-proj-[A-Za-z0-9_-]{20,}|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}'

if grep -RIE \
  "$PATTERN" \
  . \
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  --exclude-dir=logs \
  --exclude=.env \
  >/dev/null 2>&1
then
  echo "❌ mogelijke secret in repository"
  ERRORS=$((ERRORS+1))
else
  echo "✅ secret scan"
fi

# ---------------------------------
# 15. Resultaat
# ---------------------------------

echo
echo "=================================="
echo "FOUTEN: $ERRORS"
echo "=================================="

if [ "$ERRORS" -ne 0 ]; then
  echo "❌ NIET PUSHEN: eerst fouten oplossen"
  echo
  echo "Laatste serverlog:"
  tail -80 logs/console.log || true
  exit 1
fi

echo "✅ ALLES LOKAAL GROEN"

# ---------------------------------
# 16. GitHub bewaren
# ---------------------------------

git add -A

if ! git diff --cached --quiet; then
  git commit \
    -m "repair: keep website checkout and orderbot green"

  git push origin main
else
  echo "✅ GitHub reeds actueel"
fi

echo
echo "=================================="
echo "✅ MIKIS13 VOLLEDIG ACTIEF"
echo "=================================="
echo "Home:"
echo "http://127.0.0.1:$PORT/"
echo
echo "Shop:"
echo "http://127.0.0.1:$PORT/shop.html"
echo
echo "Orders:"
echo "http://127.0.0.1:$PORT/api/orders"
echo
echo "Repair opnieuw:"
echo "bash ~/mikis13-green.sh"
echo
echo "Serverlog:"
echo "tail -100 $R/logs/console.log"
