#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd "$HOME/mikis13-site"

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo
  echo "OPENAI_API_KEY is nog niet ingesteld."
  echo "Voer eerst uit:"
  echo
  echo "  export OPENAI_API_KEY='plak-hier-je-eigen-api-sleutel'"
  echo
  exit 1
fi

pkill -f "node server.mjs" 2>/dev/null || true

export PORT=4500
export HOST=127.0.0.1

nohup node server.mjs \
  > "$HOME/mikis13-site/server-4500.log" \
  2>&1 &

echo $! > "$HOME/mikis13-site/server-4500.pid"

sleep 2

echo
echo "✅ Mikis13 gestart"
echo "🎰 Gokpagina: http://127.0.0.1:4500/goksites.html"
echo "🤖 AI-console: http://127.0.0.1:4500/ai-console.html"
echo

termux-open-url "http://127.0.0.1:4500/ai-console.html"
