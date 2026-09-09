# Mikis13 Supplier & GPSR onboarding

## Voor ieder product invullen

- supplier
- supplier_url
- echte leverancier-SKU
- fabrikantnaam
- fabrikant postadres
- fabrikant elektronisch adres
- EU verantwoordelijke persoon indien vereist
- EU verantwoordelijke postadres
- EU verantwoordelijke elektronisch adres
- product identifier/model/EAN
- land van oorsprong
- materialen indien relevant
- waarschuwingen en veiligheidsinformatie
- CE vereist: ja/nee
- CE gecontroleerd indien vereist
- commerciële rechten voor gebruikte productafbeeldingen
- retouradres en retourprocedure
- werkelijke levertijd

## Regels

Zet `gpsr_ready` nooit automatisch op true.

Dit mag pas nadat de gegevens voor dat specifieke product
aan de echte leverancier/documentatie zijn gecontroleerd.

`commerce_ready` mag pas true worden wanneer:

1. business_ready true is;
2. alle actieve verkoopproducten aantoonbaar compliant zijn;
3. betaling server-side veilig is;
4. centrale orderopslag aanwezig is;
5. retour- en orderproces operationeel is.

Geen Stripe secret keys, API secrets of wachtwoorden
in GitHub, HTML of browser-JavaScript opslaan.
