#!/usr/bin/env python3
"""Regenerate every SecurIoT launcher icon, splash mark and web icon.

Source of truth: assets/brand/icono-2.svg (teal #1FD3C4 mark, transparent).
Ground: #0B0E14 (--noche). Requires `rsvg-convert` (brew install librsvg)
and Pillow (pip install pillow, only used to drop the alpha channel on the
iOS icons, which App Store Connect rejects).

Run from the repo root:  python3 tool/generate_icons.py
"""
import io
import re
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/brand/icono-2.svg"
MASTER = ROOT / "tool/brand/app-icon-1024.png"
NOCHE = "#0B0E14"
MARCA = "#1FD3C4"

_raw = SRC.read_text()
_mark = re.sub(r"<\?xml.*?\?>|<!DOCTYPE.*?>", "", _raw, flags=re.S).strip()
_mark = _mark.replace('width="100%" height="100%"', 'width="1024" height="1024"', 1)


def svg(scale, bg=True, color=None, round_bg=False):
    """1024 canvas, mark centered at `scale` of the canvas width."""
    size = 1024 * scale
    off = (1024 - size) / 2
    mark = _mark.replace('width="1024" height="1024"', f'x="{off}" y="{off}" width="{size}" height="{size}"', 1)
    if color:
        mark = mark.replace("rgb(31,211,196)", color)
    rect = ""
    if bg:
        rect = f'<rect width="1024" height="1024" fill="{NOCHE}"/>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">{rect}{mark}</svg>'


def render(svg_text, px, out, opaque=False):
    out = Path(out)
    out.parent.mkdir(parents=True, exist_ok=True)
    png = subprocess.run(
        ["rsvg-convert", "-w", str(px), "-h", str(px)],
        input=svg_text.encode(), capture_output=True, check=True,
    ).stdout
    if opaque:
        Image.open(io.BytesIO(png)).convert("RGB").save(out, optimize=True)
    else:
        out.write_bytes(png)


# Master + variants -------------------------------------------------------
FULL = svg(0.62)  # legacy / iOS / web "any": mark inside the central 62 %
FG = svg(0.56, bg=False)  # adaptive foreground, safe zone is 66 %
MONO = svg(0.56, bg=False, color="#FFFFFF")  # themed-icon layer
MASKABLE = svg(0.56)  # web maskable, safe zone is the central 80 % circle
SPLASH = svg(1.0, bg=False)

render(FULL, 1024, MASTER, opaque=True)

# Android -----------------------------------------------------------------
res = ROOT / "android/app/src/main/res"
for d, f in {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}.items():
    render(FULL, int(48 * f), res / f"mipmap-{d}/ic_launcher.png")
    render(FG, int(108 * f), res / f"mipmap-{d}/ic_launcher_foreground.png")
    render(MONO, int(108 * f), res / f"mipmap-{d}/ic_launcher_monochrome.png")
    render(SPLASH, int(96 * f), res / f"drawable-{d}/launch_logo.png")
render(svg(0.62, bg=False), 576, res / "drawable-nodpi/splash_icon.png")

# iOS ---------------------------------------------------------------------
icons = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
for f in sorted(icons.glob("Icon-App-*.png")):
    m = re.match(r"Icon-App-([\d.]+)x[\d.]+@(\d)x\.png", f.name)
    render(FULL, round(float(m[1]) * int(m[2])), f, opaque=True)
launch = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
for n, s in {"LaunchImage.png": 1, "LaunchImage@2x.png": 2, "LaunchImage@3x.png": 3}.items():
    render(SPLASH, 120 * s, launch / n)

# Web ---------------------------------------------------------------------
web = ROOT / "web"
render(svg(0.78), 32, web / "favicon.png")
render(svg(0.70), 192, web / "icons/Icon-192.png")
render(svg(0.70), 512, web / "icons/Icon-512.png")
render(MASKABLE, 192, web / "icons/Icon-maskable-192.png")
render(MASKABLE, 512, web / "icons/Icon-maskable-512.png")
print("done")
