"""Render a saved text output as a PNG image, for the evidence folders.

The images are terminal output drawn as pictures, not screenshots of a
desktop. The text files they come from sit next to them in results/.

    python3 scripts/render_evidence.py <input.txt> <output.png> "<title>"

Needs Google Chrome or Chromium on PATH (used headless).
"""
import html
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def main(src: str, dst: str, title: str) -> None:
    text = Path(src).read_text(encoding="utf-8").rstrip("\n")
    lines = text.splitlines()
    width_chars = max(60, min(max(len(l) for l in lines), 200))
    width = int(width_chars * 7.9) + 60
    height = len(lines) * 17 + 90

    page = f"""<!doctype html><meta charset="utf-8">
<style>
 body{{margin:0;background:#0f1720;font:13px/17px 'DejaVu Sans Mono',monospace;color:#d8dee9}}
 .bar{{background:#1f2933;color:#9aa5b1;padding:8px 14px;font:12px 'DejaVu Sans',sans-serif}}
 .bar b{{color:#e4e7eb}}
 pre{{margin:0;padding:12px 14px;white-space:pre}}
</style>
<div class="bar"><b>{html.escape(title)}</b></div>
<pre>{html.escape(text)}</pre>"""

    chrome = shutil.which("google-chrome") or shutil.which("chromium") or shutil.which("chromium-browser")
    if not chrome:
        sys.exit("Chrome or Chromium not found")
    with tempfile.TemporaryDirectory() as tmp:
        page_path = Path(tmp) / "page.html"
        page_path.write_text(page, encoding="utf-8")
        subprocess.run(
            [chrome, "--headless", "--no-sandbox", "--disable-gpu", "--hide-scrollbars",
             f"--window-size={width},{height}", f"--screenshot={Path(dst).resolve()}",
             page_path.as_uri()],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
