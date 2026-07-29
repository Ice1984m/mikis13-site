#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
cd "$(git rev-parse --show-toplevel)"
node scripts/mikis13-repair.mjs
git status --short
