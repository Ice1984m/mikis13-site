#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$HOME/mikis13-site"
LOG="$HOME/.mikis13/logs/supervisor.log"
PIDFILE="$HOME/.mikis13/state/supervisor.pid"

mkdir -p \
  "$HOME/.mikis13/logs" \
  "$HOME/.mikis13/state"

echo "$$" > "$PIDFILE"

exec >>"$LOG" 2>&1

echo
echo "Supervisor gestart: $(date -Iseconds)"

while true
do
  cd "$ROOT" || {
    sleep 300
    continue
  }

  echo
  echo "Check: $(date -Iseconds)"

  timeout 180 \
    ./scripts/mikis-repair.sh \
    || echo "Repair gaf foutcode $?"

  sleep 1800
done
