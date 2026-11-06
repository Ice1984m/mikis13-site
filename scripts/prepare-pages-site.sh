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
  jobs.html
  robots.txt
  CNAME
)

legal_pages=(
  legal/index.html
  legal/privacy.html
  legal/cookies.html
  legal/voorwaarden.html
  legal/wettelijke-vermeldingen.html
)

copy_required_files() {
  local file
  for file in "$@"; do
    if [[ ! -s "$file" ]]; then
      echo "Ontbrekend of leeg websitebestand: $file" >&2
      exit 1
    fi
    cp -- "$file" "$site_dir/$file"
  done
}

copy_required_files "${pages[@]}" "${legal_pages[@]}"

if [[ ! -d assets ]]; then
  echo "Ontbrekende assets-map: assets" >&2
  exit 1
fi
cp -a assets/. "$site_dir/assets/"

apk="downloads/Mikis13Stream.apk"
if [[ ! -s "$apk" ]]; then
  echo "Ontbrekend of leeg downloadbestand: $apk" >&2
  exit 1
fi
cp -- "$apk" "$site_dir/downloads/Mikis13Stream.apk"

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
  <url><loc>https://www.mikis13.nl/jobs.html</loc></url>
  <url><loc>https://www.mikis13.nl/legal/</loc></url>
  <url><loc>https://www.mikis13.nl/legal/privacy.html</loc></url>
  <url><loc>https://www.mikis13.nl/legal/cookies.html</loc></url>
  <url><loc>https://www.mikis13.nl/legal/voorwaarden.html</loc></url>
  <url><loc>https://www.mikis13.nl/legal/wettelijke-vermeldingen.html</loc></url>
</urlset>
XML
