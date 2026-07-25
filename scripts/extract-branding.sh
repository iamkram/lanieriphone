#!/usr/bin/env bash
#
# Extracts the website's branding into branding-export/ so it can be dropped
# into the app.
#
# Run this on any machine that can actually reach lanierproperties.net — the
# Claude Code environment cannot (its network egress allowlist blocks the
# domain). Then hand the branding-export/ folder back, or apply it yourself
# following docs/BRANDING.md.
#
#   chmod +x scripts/extract-branding.sh
#   ./scripts/extract-branding.sh
#
# Requires: curl. Everything else is optional and degrades gracefully.

set -uo pipefail

SITE="${1:-https://lanierproperties.net}"
OUT="branding-export"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

mkdir -p "$OUT"/{pages,css,images}

fetch() { curl -sSL --compressed -A "$UA" --max-time 30 "$1"; }

PAGES=(
  "/"
  "/about/"
  "/our-team/"
  "/our-properties/"
  "/contact/"
  "/buy-home-middleton-tn/"
)

echo "==> Saving pages"
for path in "${PAGES[@]}"; do
  name=$(echo "$path" | sed 's|^/||; s|/$||; s|/|_|g')
  [ -z "$name" ] && name="home"
  fetch "${SITE}${path}" > "$OUT/pages/${name}.html"
  printf '    %-28s %s bytes\n' "$name.html" "$(wc -c < "$OUT/pages/${name}.html" | tr -d ' ')"
done

echo
echo "==> Sitemap (reveals any pages missed above)"
fetch "${SITE}/sitemap.xml" > "$OUT/sitemap.xml" 2>/dev/null
grep -oE '<loc>[^<]+</loc>' "$OUT/sitemap.xml" 2>/dev/null \
  | sed 's|</\?loc>||g' | tee "$OUT/all-urls.txt" | head -40
echo "    (full list in $OUT/all-urls.txt)"

echo
echo "==> Stylesheets"
grep -oE 'href="[^"]+\.css[^"]*"' "$OUT/pages/home.html" \
  | cut -d'"' -f2 | sort -u > "$OUT/css-urls.txt"
i=0
while read -r css; do
  [ -z "$css" ] && continue
  case "$css" in
    //*) css="https:$css" ;;
    /*)  css="${SITE}${css}" ;;
    http*) ;;
    *) css="${SITE}/${css}" ;;
  esac
  i=$((i+1))
  fetch "$css" > "$OUT/css/style-${i}.css"
done < "$OUT/css-urls.txt"
echo "    saved $i stylesheet(s)"

echo
echo "==> Colours, most frequent first"
cat "$OUT/css"/*.css 2>/dev/null \
  | grep -oE '#[0-9a-fA-F]{6}\b|rgba?\([0-9, .]+\)' \
  | tr 'A-F' 'a-f' | sort | uniq -c | sort -rn | head -25 \
  | tee "$OUT/colors.txt"

echo
echo "==> Font families"
{
  cat "$OUT/css"/*.css 2>/dev/null | grep -oE 'font-family:[^;}]+' | sort -u
  echo "--- @font-face sources ---"
  cat "$OUT/css"/*.css 2>/dev/null | grep -oE 'src:[^;}]+' | sort -u
  echo "--- Google Fonts links ---"
  grep -ohE 'fonts\.googleapis\.com[^"'"'"']*' "$OUT/pages"/*.html | sort -u
} | tee "$OUT/fonts.txt"

echo
echo "==> Downloading font files"
cat "$OUT/css"/*.css 2>/dev/null \
  | grep -oE 'url\([^)]*\.(woff2?|ttf|otf)[^)]*\)' \
  | sed 's/url(//; s/)//; s/["'"'"']//g' | sort -u > "$OUT/font-urls.txt"
mkdir -p "$OUT/fonts"
while read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    //*) f="https:$f" ;;
    /*)  f="${SITE}${f}" ;;
    http*) ;;
    *) continue ;;
  esac
  curl -sSL -A "$UA" --max-time 30 -O --output-dir "$OUT/fonts" "$f" 2>/dev/null
done < "$OUT/font-urls.txt"
ls -1 "$OUT/fonts" 2>/dev/null | sed 's/^/    /'

echo
echo "==> Logo and hero images"
grep -ohE 'src="[^"]+\.(png|jpe?g|svg|webp)[^"]*"' "$OUT/pages"/*.html \
  | cut -d'"' -f2 | sort -u > "$OUT/image-urls.txt"
grep -iE 'logo|hero|banner|header|team|agent|office|about' "$OUT/image-urls.txt" \
  > "$OUT/key-image-urls.txt"
while read -r img; do
  [ -z "$img" ] && continue
  case "$img" in
    //*) img="https:$img" ;;
    /*)  img="${SITE}${img}" ;;
    http*) ;;
    *) continue ;;
  esac
  curl -sSL -A "$UA" --max-time 30 -O --output-dir "$OUT/images" "$img" 2>/dev/null
done < "$OUT/key-image-urls.txt"
ls -1 "$OUT/images" 2>/dev/null | head -30 | sed 's/^/    /'

echo
echo "==> Which IDX plugin is in use"
grep -iohE 'idxbroker|ihomefinder|showcaseidx|simplyrets|realtyna|dsidxpress|optima-express|wpl_|idx-broker' \
  "$OUT/pages"/*.html | sort | uniq -c | sort -rn | tee "$OUT/idx-vendor.txt"
[ -s "$OUT/idx-vendor.txt" ] || echo "    no known IDX plugin signature found — check WP Admin > Plugins"

echo
echo "==> Page text (for copy comparison)"
for f in "$OUT/pages"/*.html; do
  name=$(basename "$f" .html)
  sed -e 's/<script[^>]*>.*<\/script>//g' -e 's/<style[^>]*>.*<\/style>//g' -e 's/<[^>]*>/ /g' "$f" \
    | tr -s ' \n' ' \n' > "$OUT/pages/${name}.txt"
done
echo "    wrote .txt alongside each .html"

echo
echo "Done. Everything is in ./$OUT"
echo "Next: see docs/BRANDING.md — colours go in Assets.xcassets/Colors,"
echo "fonts and families in Brand.swift + Info.plist, images in the imagesets."
