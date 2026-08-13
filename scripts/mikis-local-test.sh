#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="${1:-$HOME/mikis13-site}"
PORT="${PORT:-4545}"

cd "$ROOT"

PIDFILE="$HOME/.mikis13/state/http.pid"
LOG="$HOME/.mikis13/logs/http.log"

if [ -f "$PIDFILE" ]; then
  OLD="$(cat "$PIDFILE" 2>/dev/null || true)"
  kill "$OLD" >/dev/null 2>&1 || true
fi

python -m http.server "$PORT" \
  --bind 127.0.0.1 \
  >>"$LOG" 2>&1 &

PID=$!

echo "$PID" > "$PIDFILE"

cleanup() {
  kill "$PID" >/dev/null 2>&1 || true
}

trap cleanup EXIT

for _ in $(seq 1 20); do
  if curl -fsS \
    "http://127.0.0.1:$PORT/" \
    >/dev/null
  then
    echo "✅ Local HTTP 200"
    exit 0
  fi

  sleep 1
done

echo "❌ Lokale webserver reageert niet"
exit 1
