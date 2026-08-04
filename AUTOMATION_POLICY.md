# Beleid voor automatisering

Er draaien maximaal vijf lokale workers:

1. Scout
2. Analyse
3. Build
4. Test
5. Review

De workers mogen:

- lokale bestanden lezen;
- publieke GitHub-metadata controleren via een aangemelde GitHub CLI;
- voorstellen opslaan;
- lokale patches voorbereiden;
- lokale tests uitvoeren;
- logbestanden maken.

De workers mogen niet automatisch:

- een pull request mergen;
- code naar productie deployen;
- GitHub-beveiligingsregels uitschakelen;
- betalingen goedkeuren of vrijgeven;
- geheimen uitlezen of publiceren;
- repositories verwijderen;
- gebruikers uitnodigen;
- licenties of juridische rechten namens derden toekennen.

Iedere uitvoer krijgt de status `menselijke_goedkeuring_nodig`.
