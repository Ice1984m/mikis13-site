#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$HOME/mikis13-site" || exit 1

PORT="${PORT:-4500}"
TMP="${TMPDIR:-$PREFIX/tmp}"

mkdir -p "$TMP" logs

ERRORS=0

LOG="logs/test-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG") 2>&1

echo "================================"
echo " MIKIS13 COMPLETE TEST"
echo "================================"
echo "TMP=$TMP"

test_url()
{
    URL="$1"

    CODE="$(
      curl \
        -sS \
        -o "$TMP/mikis-http-test" \
        -w '%{http_code}' \
        "http://127.0.0.1:${PORT}${URL}" \
        2>/dev/null
    )"

    if [[ "$CODE" =~ ^2 ]]
    then
        echo "✅ $URL HTTP $CODE"
    else
        echo "❌ $URL HTTP $CODE"
        ERRORS=$((ERRORS+1))
    fi
}

for URL in \
  "/" \
  "/index.html" \
  "/shop.html" \
  "/success.html" \
  "/status.html" \
  "/health" \
  "/api/status" \
  "/api/products" \
  "/api/orders"
do
    test_url "$URL"
done

echo
echo "=== LEGE CART ==="

CODE="$(
  curl \
    -sS \
    -o "$TMP/empty.json" \
    -w '%{http_code}' \
    -H 'Content-Type: application/json' \
    -d '{"items":[]}' \
    "http://127.0.0.1:${PORT}/api/checkout/create"
)"

if [ "$CODE" = "400" ]
then
    echo "✅ lege cart correct geweigerd"
else
    echo "❌ lege cart HTTP $CODE"
    cat "$TMP/empty.json" 2>/dev/null || true
    ERRORS=$((ERRORS+1))
fi

echo
echo "=== DEMO ORDER ==="

rm -f "$TMP/order.json"

if curl \
  -fsS \
  -H 'Content-Type: application/json' \
  -d '{"items":[{"id":"repair","quantity":1}]}' \
  "http://127.0.0.1:${PORT}/api/checkout/create" \
  > "$TMP/order.json"
then
    cat "$TMP/order.json" | jq . || true
else
    echo "❌ checkout request mislukt"
    ERRORS=$((ERRORS+1))
fi

if jq -e \
  '.ok == true and .orderId and .url' \
  "$TMP/order.json" \
  >/dev/null 2>&1
then
    echo "✅ orderbot checkout werkt"
else
    echo "❌ checkout URL/orderId ontbreekt"
    ERRORS=$((ERRORS+1))
fi

echo
echo "=== ORDER OPSLAG TEST ==="

ORDERID="$(
  jq -r \
    '.orderId // empty' \
    "$TMP/order.json" \
    2>/dev/null
)"

curl \
  -fsS \
  "http://127.0.0.1:${PORT}/api/orders" \
  > "$TMP/orders.json"

if [ -n "$ORDERID" ] &&
   jq -e \
     --arg id "$ORDERID" \
     '.orders[] | select(.id == $id)' \
     "$TMP/orders.json" \
     >/dev/null
then
    echo "✅ order opgeslagen: $ORDERID"
else
    echo "❌ testorder niet teruggevonden"
    ERRORS=$((ERRORS+1))
fi

echo
echo "=== ORDERS ==="

cat "$TMP/orders.json" | jq . || true

echo
echo "=== SERVER LOG FOUTEN ==="

if grep -Ei \
  'uncaught|syntaxerror|referenceerror|typeerror|eaddrinuse|fatal' \
  logs/console.log \
  2>/dev/null
then
    echo "⚠️ Mogelijke serverfout gevonden in log"
else
    echo "✅ geen kritieke serverfouten in log"
fi

echo
echo "================================"
echo "FOUTEN: $ERRORS"
echo "================================"

if [ "$ERRORS" -eq 0 ]
then
    echo "✅ ALLE HOOFDTESTS GESLAAGD"
fi

exit "$ERRORS"
