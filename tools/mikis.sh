#!/data/data/com.termux/files/usr/bin/bash

set -u

SITE_DIR="$HOME/mikis13-site"
PORT="${PORT:-4500}"

cd "$SITE_DIR" || {
  echo "FOUT: $SITE_DIR bestaat niet."
  exit 1
}

case "${1:-help}" in
  start)
    echo "Mikis13 starten op http://127.0.0.1:$PORT"
    python -m http.server "$PORT"
    ;;

  check)
    echo "=== Mikis13 controle ==="

    for file in index.html assets/style.css assets/js/app.js
    do
      if [ -f "$file" ]; then
        echo "OK: $file"
      else
        echo "ONTBREEKT: $file"
      fi
    done

    echo
    git status --short
    ;;

  save)
    git add .
    git commit -m "${2:-Mikis13 website bijgewerkt}" || true
    git push origin main
    ;;

  status)
    curl -I --max-time 15 \
      https://ice1984m.github.io/mikis13-site/
    ;;

  *)
    echo "Gebruik:"
    echo "  ./tools/mikis.sh start"
    echo "  ./tools/mikis.sh check"
    echo "  ./tools/mikis.sh save \"Beschrijving\""
    echo "  ./tools/mikis.sh status"
    ;;
esac
