#!/usr/bin/env python3

from pathlib import Path
import json
import re
import sys

ROOT = Path(".")
ALLOWED = {".html", ".htm", ".css", ".js", ".mjs", ".cjs", ".json", ".md"}
SKIP_PARTS = {".git", "node_modules", "vendor", "dist", "build"}

replacements = {
    "2K%3Fpage=1.html#top": "2K.html?page=1#top",
    "Products/2K?page=1.html": "Products/2K.html?page=1",
}

changed = []

for path in ROOT.rglob("*"):
    if not path.is_file():
        continue

    if any(part in SKIP_PARTS for part in path.parts):
        continue

    if path.suffix.lower() not in ALLOWED:
        continue

    try:
        original = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        continue

    updated = original

    for incorrect, correct in replacements.items():
        updated = updated.replace(incorrect, correct)

    # Alleen veilig herkenbare verkeerde paginalinks herstellen:
    # Products/item?page=1.html -> Products/item.html?page=1
    updated = re.sub(
        r'(?P<path>(?:Products/)?[A-Za-z0-9_-]+)'
        r'\?page=(?P<page>[0-9]+)\.html'
        r'(?P<fragment>#[A-Za-z0-9_-]+)?',
        lambda match: (
            f"{match.group('path')}.html?page={match.group('page')}"
            f"{match.group('fragment') or ''}"
        ),
        updated,
    )

    if updated != original:
        path.write_text(updated, encoding="utf-8")
        changed.append(str(path))

report = {
    "changed": bool(changed),
    "files": changed,
    "count": len(changed),
}

Path("repair-report.json").write_text(
    json.dumps(report, indent=2),
    encoding="utf-8",
)

print(json.dumps(report, indent=2))

if len(changed) > 20:
    print("Te veel bestanden gewijzigd; reparatie gestopt.", file=sys.stderr)
    sys.exit(2)
