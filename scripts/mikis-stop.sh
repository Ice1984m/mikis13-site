#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

PIDFILE="$HOME/.mikis13/state/supervisor.pid"

if [ -f "$PIDFILE" ]; then
  PID="$(cat "$PIDFILE" 2>/dev/null || true)"

  kill "$PID" >/dev/null 2>&1 || true

  rm -f "$PIDFILE"
fi

termux-wake-unlock || true

echo "✅ MIKIS13 supervisor gestopt"
