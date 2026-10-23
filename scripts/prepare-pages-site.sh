#!/usr/bin/env bash
set -Eeuo pipefail

site_dir="_site"
rm -rf -- "$site_dir"
mkdir -p "$site_dir/legal" "$site_dir/assets" "$site_dir/downloads"

pages=(
  index.html
  apps.html
  binnenkort.html
  media.html
  devtools.html
  control-plane.html
  contact.html
  privacy.html
  voorwaarden.html
  robots.txt
  CNAME
)

for page in "${pages[@]}"; do
  if [[ ! -s "$page" ]]; then
    echo "Ontbrekend websitebestand: $page" >&2
    exit 1
  fi
  cp -- "$page" "$site_dir/$page"
done

legal_pages=(
  legal/index.html
  legal/privacy.html
  legal/cookies.html
  legal/voorwaarden.html
  legal/wettelijke-vermeldingen.html
)
for page in "${legal_pages[@]}"; do
  if [[ ! -s "$page" ]]; then
    echo "Ontbrekende juridische pagina: $page" >&2
    exit 1
  fi
  cp -- "$page" "$site_dir/$page"
done

cp -a assets/. "$site_dir/assets/"
cp -- downloads/Mikis13Stream.apk "$site_dir/downloads/Mikis13Stream.apk"

cat > "$site_dir/sitemap.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://www.mikis13.nl/</loc></url>
  <url><loc>https://www.mikis13.nl/apps.html</loc></url>
  <url><loc>https://www.mikis13.nl/binnenkort.html</loc></url>
  <url><loc>https://www.mikis13.nl/media.html</loc></url>
  <url><loc>https://www.mikis13.nl/devtools.html</loc></url>
  <url><loc>https://www.mikis13.nl/control-plane.html</loc></url>
  <url><loc>https://www.mikis13.nl/contact.html</loc></url>
  <url><loc>https://www.mikis13.nl/legal/privacy.html</loc></url>
  <url><loc>https://www.mikis13.nl/legal/voorwaarden.html</loc></url>
</urlset>
XML
