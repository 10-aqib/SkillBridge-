"""Generates every SkillBridge icon and logo image from the official logo.

Source: tool/brand/skillbridge_logo_source.png (the full logo on white: the
"SB" monogram with the briefcase, the SkillBridge wordmark and the tagline).

The monogram ("the mark") is the app icon everywhere; the full logo is used
where there is room for the name (login, welcome, admin login).

Run from the repository root:  python -I tool/brand/generate_icons.py
Writes:
  assets/brand/skillbridge_mark.png   transparent mark (in-app SbLogoMark)
  assets/brand/skillbridge_logo.png   transparent full logo (SbFullLogo)
  Android  mipmap-*/ic_launcher.png (legacy), adaptive icon (foreground,
           monochrome, white background), launch_logo / splash_icon
  iOS      AppIcon.appiconset, LaunchImage.imageset
  Web      web/icons/*, web/favicon.png
  Admin    super_admin_web/public/brand/*, super_admin_web/src/app/favicon.ico
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image

SOURCE = "tool/brand/skillbridge_logo_source.png"
# Regions of the source (pixels, inclusive), found by scanning for ink.
MARK_BOX = (427, 209, 1120, 543)
LOGO_BOX = (288, 209, 1248, 799)
PAD = 6

WHITE = (255, 255, 255, 255)
RES = "android/app/src/main/res"
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}

# Mark width as a share of a square icon.
ICON_MARK = 0.80          # launcher icons (legacy Android, iOS, web)
ADAPTIVE_MARK = 62 / 108  # inside the 66dp safe circle of the 108dp canvas
MASKABLE_MARK = 0.66      # web maskable (80% safe circle)
# Launch screens: the mark alone on white, this wide (dp). The in-app splash
# draws it at the same width (SplashScreen: SbLogoMark(size: 160, tile: false)).
SPLASH_MARK_DP = 160
SPLASH_CANVAS_DP = 288    # Android 12+ icon canvas (192dp circle visible)


def color_to_alpha(img: Image.Image) -> Image.Image:
    """Turns the white background transparent, keeping anti-aliased edges
    (the exact inverse of compositing the logo over white)."""
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    alpha = np.max((255.0 - a) / 255.0, axis=2)
    alpha[alpha < 0.02] = 0.0
    safe = np.where(alpha > 0, alpha, 1.0)[..., None]
    rgb = np.clip(255.0 - (255.0 - a) / safe, 0, 255)
    out = np.dstack([rgb, alpha[..., None] * 255.0]).round().astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def crop(src: Image.Image, box) -> Image.Image:
    x0, y0, x1, y1 = box
    return color_to_alpha(src.crop((x0 - PAD, y0 - PAD, x1 + 1 + PAD, y1 + 1 + PAD)))


def fit(img: Image.Image, width: int) -> Image.Image:
    h = max(1, round(img.height * width / img.width))
    return img.resize((width, h), Image.LANCZOS)


def on_square(mark: Image.Image, size: int, share: float, bg=WHITE) -> Image.Image:
    """The mark centred on a square (white, or transparent with bg=None)."""
    canvas = Image.new("RGBA", (size, size), bg if bg else (0, 0, 0, 0))
    m = fit(mark, max(1, round(size * share)))
    canvas.alpha_composite(m, ((size - m.width) // 2, (size - m.height) // 2))
    return canvas


def silhouette(img: Image.Image) -> Image.Image:
    """White shape with the mark's alpha (Android 13 themed icon)."""
    a = img.getchannel("A")
    out = Image.new("RGBA", img.size, (255, 255, 255, 0))
    out.putalpha(a)
    return out


def save(img: Image.Image, path: str, *, rgb: bool = False) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (img.convert("RGB") if rgb else img).save(path, optimize=True)
    print("wrote", path)


def write(path: str, text: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("wrote", path)


def main() -> int:
    if not os.path.exists("pubspec.yaml"):
        print("run from the repository root", file=sys.stderr)
        return 1
    src = Image.open(SOURCE).convert("RGB")
    mark = crop(src, MARK_BOX)
    logo = crop(src, LOGO_BOX)

    # In-app images.
    save(mark, "assets/brand/skillbridge_mark.png")
    save(logo, "assets/brand/skillbridge_logo.png")

    # Android legacy launcher icons (before 8.0): mark on white.
    for d, k in DENSITIES.items():
        save(on_square(mark, round(48 * k), ICON_MARK), f"{RES}/mipmap-{d}/ic_launcher.png", rgb=True)
        # Android 8+ adaptive icon: 108dp layers, white background colour.
        fg = on_square(mark, round(108 * k), ADAPTIVE_MARK, bg=None)
        save(fg, f"{RES}/mipmap-{d}/ic_launcher_foreground.png")
        save(silhouette(fg), f"{RES}/mipmap-{d}/ic_launcher_monochrome.png")
        # Launch screens.
        lm = fit(mark, round(SPLASH_MARK_DP * k))
        save(lm, f"{RES}/drawable-{d}/launch_logo.png")
        canvas = Image.new("RGBA", (round(SPLASH_CANVAS_DP * k),) * 2, (0, 0, 0, 0))
        canvas.alpha_composite(lm, ((canvas.width - lm.width) // 2, (canvas.height - lm.height) // 2))
        save(canvas, f"{RES}/drawable-{d}/splash_icon.png")
    adaptive = ('<?xml version="1.0" encoding="utf-8"?>\n'
                '<!-- Generated by tool/brand/generate_icons.py. Do not edit by hand. -->\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@color/ic_launcher_background" />\n'
                '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
                '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
                '</adaptive-icon>\n')
    write(f"{RES}/mipmap-anydpi-v26/ic_launcher.xml", adaptive)
    write(f"{RES}/values/ic_launcher_background.xml",
          '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
          '    <color name="ic_launcher_background">#FFFFFF</color>\n</resources>\n')

    # iOS: square and opaque (iOS rounds the corners itself).
    ios = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for name in os.listdir(ios):
        if name.endswith(".png"):
            with Image.open(os.path.join(ios, name)) as cur:
                px = cur.size[0]
            save(on_square(mark, px, ICON_MARK), os.path.join(ios, name), rgb=True)
    launch = "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for name, k in (("LaunchImage.png", 1), ("LaunchImage@2x.png", 2), ("LaunchImage@3x.png", 3)):
        save(fit(mark, SPLASH_MARK_DP * k), os.path.join(launch, name))

    # Web app.
    save(on_square(mark, 192, ICON_MARK), "web/icons/Icon-192.png", rgb=True)
    save(on_square(mark, 512, ICON_MARK), "web/icons/Icon-512.png", rgb=True)
    save(on_square(mark, 192, MASKABLE_MARK), "web/icons/Icon-maskable-192.png", rgb=True)
    save(on_square(mark, 512, MASKABLE_MARK), "web/icons/Icon-maskable-512.png", rgb=True)
    save(on_square(mark, 64, 0.94), "web/favicon.png", rgb=True)

    # Admin website.
    save(fit(mark, 512), "super_admin_web/public/brand/skillbridge-mark.png")
    save(fit(logo, 960), "super_admin_web/public/brand/skillbridge-logo.png")
    on_square(mark, 256, 0.94).save("super_admin_web/src/app/favicon.ico", sizes=[(16, 16), (32, 32), (48, 48), (64, 64)])
    print("wrote super_admin_web/src/app/favicon.ico")
    return 0


if __name__ == "__main__":
    sys.exit(main())
