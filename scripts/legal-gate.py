import json
from pathlib import Path
import sys

errors = []

required = [
    "legal/index.html",
    "legal/wettelijke-vermeldingen.html",
    "legal/voorwaarden.html",
    "legal/herroeping.html",
    "legal/garantie.html",
    "legal/levering.html",
    "legal/privacy.html",
    "legal/cookies.html",
    "legal/productveiligheid.html",
    "legal/klachten.html",
    "LICENSE",
    "CONTENT-LICENSE.md",
    "THIRD_PARTY_NOTICES.md",
    "data/store-config.json",
]

for item in required:
    path = Path(item)

    if not path.is_file() or path.stat().st_size == 0:
        errors.append(
            f"Ontbrekend verplicht bestand: {item}"
        )

products_path = Path("data/products.json")

if not products_path.exists():
    errors.append(
        "data/products.json ontbreekt"
    )

else:
    products = json.loads(
        products_path.read_text(
            encoding="utf-8"
        )
    )

    if len(products) != 50:
        errors.append(
            f"Verwacht 50 producten, gevonden {len(products)}"
        )

config_path = Path(
    "data/store-config.json"
)

if config_path.exists():

    config = json.loads(
        config_path.read_text(
            encoding="utf-8"
        )
    )

    print(
        "Business ready:",
        config.get("business_ready")
    )

    print(
        "GPSR ready:",
        config.get("gpsr_ready")
    )

    print(
        "Commerce ready:",
        config.get("commerce_ready")
    )

    # Een site mag online blijven in catalogusmodus.
    # Echte verkoop mag enkel geactiveerd worden
    # als beide controles klaar zijn.

    if config.get("commerce_ready") is True:

        if not config.get("business_ready"):
            errors.append(
                "Commerce actief zonder bedrijfsgegevens"
            )

        if not config.get("gpsr_ready"):
            errors.append(
                "Commerce actief zonder GPSR-data"
            )

if errors:

    for error in errors:
        print(
            f"::error::{error}"
        )

    sys.exit(1)

print("Legal gate PASS")
