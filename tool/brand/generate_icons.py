"""Generates the SkillBridge launch-screen logos and the admin site favicon.

The official SkillBridge app icon is the logo in the launcher icon files
(Android mipmap-*/ic_launcher.png, iOS AppIcon.appiconset, web/icons,
web/favicon.png). Those files are kept as they are; this script does not
touch them.

Everything else shows that same logo, drawn from one geometry:
* in the app, `SbLogoMark` (lib/shared/widgets/brand/sb_logo.dart) draws it
  with Flutter's `FlutterLogo` on a white rounded tile;
* this script draws the same shapes (copied from Flutter's FlutterLogo
  painter, packages/flutter/lib/src/painting/flutter_logo.dart) on the same
  tile, for the launch screens:
    - Android before 12: drawable-*/launch_logo.png (launch_background.xml)
    - Android 12+:       drawable-*/splash_icon.png (values-v31/styles.xml)
    - iOS:               LaunchImage.imageset
  and the admin website favicon (super_admin_web/src/app/favicon.ico).
* the admin website draws it as SVG (super_admin_web/src/components/sb/brand-mark.tsx).

Run from the repository root:  python -I tool/brand/generate_icons.py
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image, ImageDraw

SS = 4  # supersampling factor

# Tile around the logo, as in SbLogoMark.
TILE_RADIUS = 0.22
TILE_BORDER = (0, 0, 0, 0x14)
LOGO_FRACTION = 0.86

# Launch screens show the mark at the size the in-app splash uses
# (SbBrandMark(size: 72)), on white, so nothing jumps when the app takes over.
SPLASH_MARK_DP = 72
# Android 12+ splash icon canvas (icon without background: 288dp, of which a
# 192dp circle is visible; the 72dp mark sits well inside it).
SPLASH_CANVAS_DP = 288
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}

# FlutterLogo geometry: a 202 x 202 box, logo 166 wide, centred.
LIGHT = (0x54, 0xC5, 0xF8, 255)
MEDIUM = (0x29, 0xB6, 0xF6, 255)
DARK = (0x01, 0x57, 0x9B, 255)
TOP_BEAM = [(37.7, 128.9), (9.8, 101.0), (100.4, 10.4), (156.2, 10.4)]
MIDDLE_BEAM = [(156.2, 94.0), (100.4, 94.0), (78.5, 115.9), (106.4, 143.8)]
BOTTOM_BEAM = [(79.5, 170.7), (100.4, 191.6), (156.2, 191.6), (107.4, 142.8)]
OVERLAP = (59.8, 123.1, 39.4, 39.4)  # rect, drawn rotated (matrix below)
OVERLAP_M = (0.7071, -0.7071, 0.7071, 0.7071, -77.697, 98.057)  # a b c d tx ty
TRIANGLE = [(79.5, 170.7), (120.9, 156.4), (107.4, 142.8)]
TRI_FROM = (87.2623 + 37.9092, 28.8384 + 123.4389)  # transparent end
TRI_TO = (42.9205 + 37.9092, 35.0952 + 123.4389)  # 40% indigo end
TRI_COLOR = (0x1A, 0x23, 0x7E)


def draw_logo(img: Image.Image, ox: float, oy: float, size: float) -> None:
    """Draws the logo into `img` in the size x size square at (ox, oy)."""
    k = size / 202.0
    P = lambda x, y: (ox + (x + 18.0) * k, oy + y * k)  # noqa: E731
    d = ImageDraw.Draw(img)
    d.polygon([P(*p) for p in TOP_BEAM], fill=LIGHT)
    d.polygon([P(*p) for p in MIDDLE_BEAM], fill=LIGHT)
    d.polygon([P(*p) for p in BOTTOM_BEAM], fill=DARK)
    a, b, c, dd, tx, ty = OVERLAP_M
    x, y, w, h = OVERLAP
    corners = [(x, y), (x + w, y), (x + w, y + h), (x, y + h)]
    d.polygon([P(a * cx + c * cy + tx, b * cx + dd * cy + ty) for cx, cy in corners], fill=MEDIUM)

    # Shadow triangle: a linear gradient from transparent to 40% indigo.
    W, H = img.size
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).polygon([P(*p) for p in TRIANGLE], fill=255)
    (fx, fy), (tx_, ty_) = P(*TRI_FROM), P(*TRI_TO)
    gx, gy = tx_ - fx, ty_ - fy
    ys, xs = np.mgrid[0:H, 0:W].astype(np.float32)
    t = np.clip(((xs - fx) * gx + (ys - fy) * gy) / (gx * gx + gy * gy), 0, 1)
    alpha = (t * 0x66).astype(np.float32) * (np.asarray(mask, dtype=np.float32) / 255.0)
    overlay = np.zeros((H, W, 4), dtype=np.uint8)
    overlay[..., 0], overlay[..., 1], overlay[..., 2] = TRI_COLOR
    overlay[..., 3] = alpha.round().astype(np.uint8)
    img.alpha_composite(Image.fromarray(overlay, "RGBA"))


def render_mark(size: int) -> Image.Image:
    """SbLogoMark: the logo on a white rounded tile with a hairline border."""
    S = size * SS
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, S - 1, S - 1), radius=S * TILE_RADIUS, fill=TILE_BORDER)
    bw = max(1.0, S / 72.0)
    d.rounded_rectangle((bw, bw, S - 1 - bw, S - 1 - bw), radius=S * TILE_RADIUS - bw, fill=(255, 255, 255, 255))
    logo = S * LOGO_FRACTION
    draw_logo(img, (S - logo) / 2, (S - logo) / 2, logo)
    return img.resize((size, size), Image.LANCZOS)


def on_canvas(mark: Image.Image, canvas: int) -> Image.Image:
    """The mark centred on a transparent square canvas."""
    img = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    off = (canvas - mark.size[0]) // 2
    img.paste(mark, (off, off), mark)
    return img


def save(img: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)
    print("wrote", path)


def main() -> int:
    if not os.path.exists(os.path.join(os.getcwd(), "pubspec.yaml")):
        print("run from the repository root", file=sys.stderr)
        return 1

    res = "android/app/src/main/res"
    for d, k in DENSITIES.items():
        mark = render_mark(round(SPLASH_MARK_DP * k))
        save(mark, f"{res}/drawable-{d}/launch_logo.png")
        save(on_canvas(mark, round(SPLASH_CANVAS_DP * k)), f"{res}/drawable-{d}/splash_icon.png")

    launch = "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for name, k in (("LaunchImage.png", 1), ("LaunchImage@2x.png", 2), ("LaunchImage@3x.png", 3)):
        save(render_mark(SPLASH_MARK_DP * k), os.path.join(launch, name))

    ico = "super_admin_web/src/app/favicon.ico"
    render_mark(256).save(ico, sizes=[(16, 16), (32, 32), (48, 48), (64, 64)])
    print("wrote", ico)
    return 0


if __name__ == "__main__":
    sys.exit(main())
