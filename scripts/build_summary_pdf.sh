#!/usr/bin/env bash
# Builds Isogie_Emike_301896878_FinalSummary.pdf from the Markdown summary.
# Needs pandoc and Google Chrome/Chromium. "<!-- PAGE BREAK -->" in the
# Markdown becomes a page break in the PDF.
set -euo pipefail
cd "$(dirname "$0")/.."
name=Isogie_Emike_301896878_FinalSummary
tmp="$(mktemp -d)"
sed 's|<!-- PAGE BREAK -->|<div style="page-break-after: always"></div>|' "$name.md" > "$tmp/summary.md"
cp -r images "$tmp/"
cat > "$tmp/style.css" <<'CSS'
@page { size: A4; margin: 16mm 17mm; }
body { font-family: "DejaVu Serif", Georgia, serif; font-size: 10.4pt; line-height: 1.42; color: #1a202c; max-width: none; }
h1 { font-family: "DejaVu Sans", sans-serif; font-size: 17pt; color: #1f3a5f; margin: 0 0 2pt; }
h1 + p { margin: 0; color: #4a5568; }
h1 + p + p { margin: 0 0 4pt; font-size: 9.6pt; color: #4a5568; }
h2 { font-family: "DejaVu Sans", sans-serif; font-size: 11.5pt; color: #1f3a5f; border-bottom: 1px solid #cbd5e0; padding-bottom: 2pt; margin: 12pt 0 4pt; }
p { margin: 0 0 6pt; text-align: justify; }
img { max-width: 100%; display: block; margin: 4pt auto; }
p:has(> img) + p { font-size: 8.8pt; color: #4a5568; text-align: center; }
ul { margin: 0; padding-left: 16pt; font-size: 9.2pt; columns: 2; column-gap: 18pt; }
a { color: #1f3a5f; }
CSS
pandoc -f markdown-implicit_figures "$tmp/summary.md" -s --metadata title="$name" --css style.css -o "$tmp/summary.html"
# pandoc's default template adds a title block; hide it
sed -i 's|<header id="title-block-header">|<header id="title-block-header" style="display:none">|' "$tmp/summary.html"
chrome="$(command -v google-chrome || command -v chromium || command -v chromium-browser)"
"$chrome" --headless --no-sandbox --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$PWD/$name.pdf" "file://$tmp/summary.html" 2>/dev/null
rm -rf "$tmp"
echo "Built $name.pdf"
