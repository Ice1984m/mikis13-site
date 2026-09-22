#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== Shellcontrole ==="

while IFS= read -r -d '' FILE; do
  bash -n "$FILE"
  echo "✅ $FILE"
done < <(
  find scripts \
    -type f \
    -name '*.sh' \
    -print0
)

echo "=== Pythoncontrole ==="

while IFS= read -r -d '' FILE; do
  python -m py_compile "$FILE"
  echo "✅ $FILE"
done < <(
  find scripts \
    -type f \
    -name '*.py' \
    -print0
)

echo "=== Projecttests ==="

if [ -f package-lock.json ]; then
  npm ci
  npm test --if-present
elif [ -f package.json ]; then
  npm install --ignore-scripts
  npm test --if-present
else
  echo "Geen Node-project gevonden."
fi

if [ -f requirements.txt ]; then
  python -m pip install \
    --disable-pip-version-check \
    --requirement requirements.txt

  if [ -d tests ]; then
    python -m pytest -q
  fi
fi

echo "✅ Lokale validatie geslaagd."
