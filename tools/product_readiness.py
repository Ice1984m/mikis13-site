#!/usr/bin/env python3
"""Controleert per product of alle verplichte leveranciers- en GPSR-gegevens
echt ingevuld zijn, en kan een CSV-invulblad maken of inlezen.

Gebruik:
  python3 tools/product_readiness.py check           # rapport per product
  python3 tools/product_readiness.py export-csv      # maakt data/supplier-sheet.csv
  python3 tools/product_readiness.py import-csv      # leest ingevuld blad terug

Het script zet gpsr_ready NOOIT zelf op true. Dat blijft een bewuste,
handmatige beslissing nadat de gegevens bij de echte leverancier zijn
gecontroleerd (zie SUPPLIER-GPSR-ONBOARDING.md).
"""
import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PRODUCTS = ROOT / "data" / "products.json"
SHEET = ROOT / "data" / "supplier-sheet.csv"

# Velden die voor elk product ingevuld moeten zijn.
REQUIRED_TEXT = [
    "supplier",
    "supplier_url",
    "manufacturer_name",
    "manufacturer_address",
    "manufacturer_email",
    "product_identifier",
    "country_of_origin",
    "warnings",
    "shipping",
]
# Veld dat expliciet ja/nee moet zijn (niet leeg/None).
REQUIRED_BOOL = ["ce_required"]
# Optioneel, maar verplicht zodra de fabrikant buiten de EU zit.
EU_REP = [
    "eu_responsible_person_name",
    "eu_responsible_person_address",
    "eu_responsible_person_email",
]
SHEET_FIELDS = (
    ["id", "sku", "name"]
    + REQUIRED_TEXT
    + EU_REP
    + ["materials", "ce_required", "ce_verified"]
)


def load():
    data = json.loads(PRODUCTS.read_text(encoding="utf-8"))
    return data if isinstance(data, list) else data["products"]


def missing_fields(p):
    gaps = [f for f in REQUIRED_TEXT if not str(p.get(f) or "").strip()]
    for f in REQUIRED_BOOL:
        if p.get(f) is None:
            gaps.append(f)
    if p.get("ce_required") is True and not p.get("ce_verified"):
        gaps.append("ce_verified")
    return gaps


def cmd_check():
    products = load()
    klaar = 0
    for p in products:
        gaps = missing_fields(p)
        if not gaps:
            klaar += 1
        print(f"{p['sku']:<10} {p['name'][:38]:<38} "
              f"{'COMPLEET' if not gaps else 'mist: ' + ', '.join(gaps)}")
    print(f"\n{klaar}/{len(products)} producten hebben alle verplichte gegevens.")
    print("gpsr_ready blijft handmatig; dit script zet het nooit zelf.")


def cmd_export():
    with SHEET.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=SHEET_FIELDS, extrasaction="ignore")
        w.writeheader()
        for p in load():
            row = {k: ("" if p.get(k) is None else p.get(k)) for k in SHEET_FIELDS}
            w.writerow(row)
    print(f"Invulblad geschreven: {SHEET.relative_to(ROOT)}")


def to_bool(value):
    v = str(value).strip().lower()
    if v in ("ja", "yes", "true", "1"):
        return True
    if v in ("nee", "no", "false", "0"):
        return False
    return None


def cmd_import():
    if not SHEET.exists():
        sys.exit("Geen data/supplier-sheet.csv gevonden. Draai eerst export-csv.")
    products = load()
    by_id = {str(p["id"]): p for p in products}
    changed = 0
    with SHEET.open(newline="", encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            p = by_id.get(row["id"])
            if not p:
                continue
            for k in REQUIRED_TEXT + EU_REP + ["materials"]:
                if k in row and row[k].strip() != str(p.get(k) or ""):
                    p[k] = row[k].strip()
                    changed += 1
            for k in ("ce_required", "ce_verified"):
                val = to_bool(row.get(k, ""))
                if val is not None and val != p.get(k):
                    p[k] = val
                    changed += 1
    PRODUCTS.write_text(
        json.dumps(products, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"{changed} velden bijgewerkt. gpsr_ready is niet aangepast.")


if __name__ == "__main__":
    cmds = {"check": cmd_check, "export-csv": cmd_export, "import-csv": cmd_import}
    if len(sys.argv) != 2 or sys.argv[1] not in cmds:
        sys.exit(__doc__)
    cmds[sys.argv[1]]()
