#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$HOME/mikis13-site"

PORT=4500
ERRORS=0

LOG="logs/test-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG") 2>&1

echo "================================"
echo " MIKIS13 COMPLETE TEST"
echo "================================"

test_url(){

 URL="$1"

 CODE="$(
  curl -s \
   -o /data/data/com.termux/files/usr/tmp/mikis-test \
   -w '%{http_code}' \
   "http://127.0.0.1:$PORT$URL"
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
 curl -s \
  -o /data/data/com.termux/files/usr/tmp/empty.json \
  -w '%{http_code}' \
  -H 'Content-Type: application/json' \
  -d '{"items":[]}' \
  "http://127.0.0.1:$PORT/api/checkout/create"
)"

if [ "$CODE" = "400" ]
then
 echo "✅ lege cart correct geweigerd"
else
 echo "❌ lege cart HTTP $CODE"
 ERRORS=$((ERRORS+1))
fi

echo
echo "=== DEMO ORDER ==="

curl -fsS \
 -H 'Content-Type: application/json' \
 -d '{"items":[{"id":"repair","quantity":1}]}' \
 "http://127.0.0.1:$PORT/api/checkout/create" \
 > /data/data/com.termux/files/usr/tmp/order.json

cat /data/data/com.termux/files/usr/tmp/order.json | jq .

if jq -e '.url' /data/data/com.termux/files/usr/tmp/order.json >/dev/null
then
 echo "✅ orderbot checkout werkt"
else
 echo "❌ checkout URL ontbreekt"
 ERRORS=$((ERRORS+1))
fi

echo
echo "=== ORDERS ==="

curl -fsS \
 "http://127.0.0.1:$PORT/api/orders" \
 | jq .

echo
echo "================================"
echo "FOUTEN: $ERRORS"
echo "================================"

exit "$ERRORS"
