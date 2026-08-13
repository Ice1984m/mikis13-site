#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd "$HOME/mikis13-site"

python <<'PY'
from pathlib import Path
import re

ROOT = Path(".")
created = []

for htmlfile in ROOT.glob("*.html"):
    text = htmlfile.read_text(encoding="utf-8", errors="ignore")

    links = re.findall(
        r'href=["\']([^"\']+\.html(?:#[^"\']*)?(?:\?[^"\']*)?)["\']',
        text,
        flags=re.I
    )

    for link in links:
        clean = link.split("?")[0].split("#")[0]
        clean = clean.lstrip("./")

        if not clean or "/" in clean:
            continue

        target = ROOT / clean

        if target.exists():
            continue

        title = (
            Path(clean)
            .stem
            .replace("-", " ")
            .replace("_", " ")
            .title()
        )

        target.write_text(f'''<!doctype html>
<html lang="nl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title} | Mikis13</title>
<link rel="stylesheet" href="assets/style.css">
</head>

<body>

<main style="
width:min(900px,calc(100% - 30px));
margin:auto;
padding:70px 0;
text-align:center;
">

<p style="
color:#53ffa3;
letter-spacing:.15em;
font-weight:800;
">
MIKIS13
</p>

<h1>{title}</h1>

<p>
Deze pagina is automatisch door de Mikis13 Repair Bot
aangemaakt en kan verder ingevuld worden.
</p>

<nav style="
display:flex;
gap:12px;
justify-content:center;
flex-wrap:wrap;
margin-top:30px;
">

<a href="index.html">
Home
</a>

<a href="projecten.html">
Projecten
</a>

<a href="shop.html">
Shop
</a>

<a href="status.html">
Status
</a>

</nav>

</main>

</body>
</html>
''', encoding="utf-8")

        created.append(clean)

print()
print("=== AUTO REPAIR ===")

if created:
    for page in sorted(set(created)):
        print("✅ aangemaakt:", page)
else:
    print("✅ Geen ontbrekende HTML-pagina's")

PY

echo
echo "=== TEST OPNIEUW ==="

bash tools/repair.sh || true

echo
echo "=== SERVER TEST ==="

if curl -fsS http://127.0.0.1:4500/health >/dev/null 2>&1
then
    echo "✅ server online"
else
    echo "⚠️ server opnieuw starten"

    pkill -f "node server.mjs" 2>/dev/null || true

    nohup env PORT=4500 HOST=0.0.0.0 \
      node server.mjs \
      > logs/server.log 2>&1 &

    echo $! > .server.pid
    sleep 3
fi

curl -fsS http://127.0.0.1:4500/health | jq . || {
    echo "❌ serverfout"
    tail -50 logs/server.log
    exit 1
}

echo
echo "=== GIT ==="

git add -A

if ! git diff --cached --quiet
then
    git commit -m "repair: auto create missing linked pages" || true
    git push origin main || true
fi

echo
echo "✅ REPAIR KLAAR"
