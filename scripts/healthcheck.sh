#!/usr/bin/env bash
set -Eeuo pipefail

URLS=(
  "https://ice1984m.github.io/mikis13-site/"
  "https://mikis13.nl/"
  "https://www.mikis13.nl/"
)

FAILED=0

for URL in "${URLS[@]}"; do
  CODE="$(
    curl \
      --silent \
      --show-error \
      --location \
      --connect-timeout 15 \
      --max-time 45 \
      --output /dev/null \
      --write-out '%{http_code}' \
      "$URL" || true
  )"

  case "$CODE" in
    200|204)
      echo "✅ $CODE $URL"
      ;;
    *)
      echo "❌ ${CODE:-onbereikbaar} $URL"
      FAILED=1
      ;;
  esac
done

exit "$FAILED"
