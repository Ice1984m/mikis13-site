# Betalingen (Mollie) en orderopslag

De betaalflow staat in `cloud-backend/payments.js` en is **standaard dicht**.
Niets wordt verkocht zolang `COMMERCE_READY` niet op `true` staat in de
backend-omgeving én het product `gpsr_ready` en `commerce_ready` heeft.

## Eindpunten

| Methode | Pad | Doel |
|---|---|---|
| POST | `/checkout` | Maakt bestelling + Mollie-betaling, geeft `checkoutUrl` terug |
| POST | `/mollie/webhook` | Mollie meldt een statuswijziging; de status wordt bij Mollie opgehaald |
| GET | `/orders/:id/status` | Publieke status (geen persoonsgegevens) |

Prijzen komen altijd uit `data/products.json` op de server. Prijzen die de
browser meestuurt worden genegeerd.

## Omgevingsvariabelen (nooit in GitHub of HTML zetten)

- `MOLLIE_API_KEY`: begin met een `test_`-sleutel
- `COMMERCE_READY`: `true` pas als alles hieronder klopt
- `PUBLIC_API_URL`: publieke URL van de backend, nodig voor de webhook
- `SITE_URL`, `PRODUCTS_URL`, `ALLOWED_ORIGIN`: standaard de GitHub Pages-site
- `SHIPPING_CENTS`: verzendkosten in eurocent (standaard 0)

Bestellingen worden opgeslagen in Firestore (collectie `orders`) in hetzelfde
Google Cloud-project als de backend.

## Vóór je live gaat

1. Producten volledig invullen: `python3 tools/product_readiness.py check`
2. `gpsr_ready` en `commerce_ready` per product handmatig op `true` zetten
3. Testbetaling met een `test_`-sleutel, daarna pas de `live_`-sleutel
4. `checkout.html` laten verwijzen naar `POST /checkout` (nu slaat die pagina
   bestellingen nog lokaal in de browser op)
5. Pagina `order-status.html` maken (Mollie stuurt de klant daarheen terug)
6. Retourproces, factuur en orderbevestiging regelen (zie `LEGAL-CHECKLIST.md`)

Status: de code is syntactisch gecontroleerd maar nog niet end-to-end getest.
