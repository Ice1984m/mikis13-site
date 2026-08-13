#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

PIDFILE="$HOME/.mikis13/state/supervisor.pid"

termux-wake-lock || true

if [ -f "$PIDFILE" ]; then
  PID="$(cat "$PIDFILE" 2>/dev/null || true)"

  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    echo "✅ Supervisor draait al: PID=$PID"
    exit 0
  fi
fi

nohup "$HOME/mikis13-site/scripts/mikis-supervisor.sh" \
  >/dev/null 2>&1 &

echo "$!" > "$PIDFILE"

echo "✅ MIKIS13 supervisor gestart PID=$!"
