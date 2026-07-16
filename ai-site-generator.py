import json
import os
import re
import sys
import urllib.error
import urllib.request

API_KEY = os.environ.get("GEMINI_API_KEY")

if not API_KEY:
    print("FOUT: GEMINI_API_KEY is niet ingesteld.")
    sys.exit(1)

prompt = """
Maak een complete professionele single-page website voor Mikis13.

Vereisten:
- Nederlandse taal
- Alleen één volledig index.html-bestand
- HTML, CSS en JavaScript in hetzelfde bestand
- Donker futuristisch ontwerp
- Mobiel responsive
- Navigatie
- Hero-sectie
- Diensten: websites, Android-apps, AI en automatisering
- Projectensectie
- Contactsectie
- Geen externe libraries
- Geen markdown
- Begin rechtstreeks met <!doctype html>
"""

url = (
    "https://generativelanguage.googleapis.com/v1beta/"
    "models/gemini-3-flash-preview:generateContent"
)

payload = {
    "contents": [
        {
            "parts": [
                {"text": prompt}
            ]
        }
    ]
}

request = urllib.request.Request(
    url,
    data=json.dumps(payload).encode("utf-8"),
    headers={
        "Content-Type": "application/json",
        "x-goog-api-key": API_KEY,
    },
    method="POST",
)

try:
    with urllib.request.urlopen(request, timeout=180) as response:
        result = json.loads(response.read().decode("utf-8"))
except urllib.error.HTTPError as error:
    print("API-fout:", error.code)
    print(error.read().decode("utf-8", errors="replace"))
    sys.exit(1)
except Exception as error:
    print("Verbindingsfout:", error)
    sys.exit(1)

try:
    html = result["candidates"][0]["content"]["parts"][0]["text"]
except (KeyError, IndexError):
    print("Onverwacht antwoord:")
    print(json.dumps(result, indent=2))
    sys.exit(1)

html = re.sub(r"^```(?:html)?\s*", "", html.strip())
html = re.sub(r"\s*```$", "", html)

if "<html" not in html.lower():
    print("AI gaf geen geldige HTML terug.")
    sys.exit(1)

if os.path.exists("index.html"):
    os.replace("index.html", "index.backup.html")

with open("index.html", "w", encoding="utf-8") as file:
    file.write(html)

print("KLAAR: nieuwe AI-site opgeslagen als index.html")
print("Backup: index.backup.html")
