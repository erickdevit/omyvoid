#!/usr/bin/env python3
"""Generate every Omyvoid brand asset from the canonical Void mark."""

from __future__ import annotations

import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.basePen import BasePen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import parse_path


ROOT = Path(__file__).resolve().parents[2]
CANONICAL_SVG = ROOT / "logo.svg" if (ROOT / "logo.svg").exists() else ROOT / "Void_Linux_logo.svg"
SOURCE_DIR = ROOT / "tools" / "branding" / "sources"
OSAKA = {
    "background": "#111c18",
    "dark": "#090f0d",
    "accent": "#509475",
    "foreground": "#C1C497",
    "bright": "#F7E8B2",
}
SVG_PATH_RE = re.compile(r'<path\s+[^>]*d="([^"]+)"', re.IGNORECASE)
COLOR_RE = re.compile(r'^\s*([a-zA-Z0-9_]+)\s*=\s*["\'](#[0-9a-fA-F]{6})["\']')
WORDMARK = {
    "O": ("01110", "10001", "10001", "10001", "10001", "10001", "01110"),
    "M": ("10001", "11011", "10101", "10101", "10001", "10001", "10001"),
    "Y": ("10001", "10001", "01010", "00100", "00100", "00100", "00100"),
    "V": ("10001", "10001", "10001", "10001", "10001", "01010", "00100"),
    "I": ("11111", "00100", "00100", "00100", "00100", "00100", "11111"),
    "D": ("11110", "10001", "10001", "10001", "10001", "10001", "11110"),
}


class FlattenPen(BasePen):
    """Flatten SVG cubic curves into polygons for deterministic raster output."""

    def __init__(self) -> None:
        super().__init__(None)
        self.contours: list[list[tuple[float, float]]] = []

    def _moveTo(self, point: tuple[float, float]) -> None:
        self.contours.append([point])

    def _lineTo(self, point: tuple[float, float]) -> None:
        self.contours[-1].append(point)

    def _curveToOne(
        self,
        point1: tuple[float, float],
        point2: tuple[float, float],
        point3: tuple[float, float],
    ) -> None:
        point0 = self.contours[-1][-1]
        for step in range(1, 25):
            t = step / 24
            u = 1 - t
            x = (
                u**3 * point0[0]
                + 3 * u**2 * t * point1[0]
                + 3 * u * t**2 * point2[0]
                + t**3 * point3[0]
            )
            y = (
                u**3 * point0[1]
                + 3 * u**2 * t * point1[1]
                + 3 * u * t**2 * point2[1]
                + t**3 * point3[1]
            )
            self.contours[-1].append((x, y))

    def _closePath(self) -> None:
        return

    def _endPath(self) -> None:
        return


def canonical_path() -> str:
    match = SVG_PATH_RE.search(CANONICAL_SVG.read_text(encoding="utf-8"))
    if not match:
        raise RuntimeError(f"No SVG path found in {CANONICAL_SVG}")
    return match.group(1)


def rgba(value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = value.removeprefix("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4)) + (alpha,)


def render_mark(
    size: int,
    color: str,
    *,
    padding: int = 0,
    alpha: int = 255,
) -> Image.Image:
    supersample = 4
    canvas_size = size * supersample
    pen = FlattenPen()
    parse_path(canonical_path(), pen)
    image = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    available = (size - 2 * padding) * supersample
    scale = available / 24
    offset = padding * supersample
    for contour in pen.contours:
        points = [(offset + x * scale, offset + y * scale) for x, y in contour]
        draw.polygon(points, fill=rgba(color, alpha))
    return image.resize((size, size), Image.Resampling.LANCZOS)


def composite_mark(
    image: Image.Image,
    *,
    size: int,
    position: tuple[int, int],
    color: str,
    alpha: int = 255,
    glow: int = 0,
) -> None:
    mark = render_mark(size, color, alpha=alpha)
    if glow:
        padding = glow * 3
        halo_mask = Image.new("L", (size + padding * 2, size + padding * 2), 0)
        halo_mask.paste(mark.getchannel("A"), (padding, padding))
        halo_mask = halo_mask.filter(ImageFilter.GaussianBlur(glow))
        halo_color = Image.new("RGBA", halo_mask.size, rgba(color, min(alpha, 120)))
        halo_color.putalpha(halo_mask)
        image.alpha_composite(
            halo_color,
            (position[0] - padding, position[1] - padding),
        )
    image.alpha_composite(mark, position)


def render_wordmark(width: int, height: int, color: str) -> Image.Image:
    text = "OMYVOID"
    columns = len(text) * 5 + len(text) - 1
    cell = max(1, min((width - 48) // columns, (height - 32) // 7))
    mark_width = columns * cell
    mark_height = 7 * cell
    left = (width - mark_width) // 2
    top = (height - mark_height) // 2
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    x_offset = left
    for character in text:
        for row, pattern in enumerate(WORDMARK[character]):
            for column, bit in enumerate(pattern):
                if bit == "1":
                    x = x_offset + column * cell
                    y = top + row * cell
                    draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=rgba(color))
        x_offset += 6 * cell
    return image


def parse_palette(path: Path) -> dict[str, str]:
    palette: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = COLOR_RE.match(line)
        if match:
            palette[match.group(1)] = match.group(2)
    for required in ("background", "foreground", "accent"):
        if required not in palette:
            raise RuntimeError(f"Missing {required} in {path}")
    return palette


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True)


def branded_background(background: str, accent: str) -> Image.Image:
    image = Image.new("RGBA", (3840, 2160), rgba(background))
    position = ((image.width - 360) // 2, (image.height - 360) // 2)
    composite_mark(image, size=360, position=position, color=accent, glow=0)
    return image


def branded_background_text(background: str, foreground: str) -> Image.Image:
    image = Image.new("RGBA", (3840, 2160), rgba(background))
    wordmark = render_wordmark(2200, 520, foreground)
    position = ((image.width - wordmark.width) // 2, (image.height - wordmark.height) // 2)
    image.alpha_composite(wordmark, position)
    return image


def unlock_preview(background: str, foreground: str, accent: str) -> Image.Image:
    image = Image.new("RGBA", (1920, 1080), rgba(background))
    composite_mark(image, size=270, position=(825, 225), color=accent, glow=0)
    image.alpha_composite(render_wordmark(920, 216, foreground), (500, 620))
    return image


def generate_theme_assets() -> None:
    for theme_dir in sorted(path for path in (ROOT / "themes").iterdir() if path.is_dir()):
        palette_file = theme_dir / "colors.toml"
        if not palette_file.exists():
            continue
        palette = parse_palette(palette_file)
        if theme_dir.name != "omyvoid":
            background = branded_background(palette["background"], palette["accent"])
            save_png(background, theme_dir / "backgrounds" / "omyvoid.png")
            save_png(
                ImageOps.fit(background, (1800, 1012), method=Image.Resampling.LANCZOS),
                theme_dir / "preview.png",
            )
            background_text = branded_background_text(palette["background"], palette["foreground"])
            save_png(background_text, theme_dir / "backgrounds" / "omyvoid-text.png")
        save_png(render_wordmark(800, 188, palette["foreground"]), theme_dir / "unlock.png")
        save_png(
            unlock_preview(palette["background"], palette["foreground"], palette["accent"]),
            theme_dir / "preview-unlock.png",
        )


def source_wallpaper(filename: str) -> Image.Image:
    path = SOURCE_DIR / filename
    if not path.exists():
        raise RuntimeError(f"Missing wallpaper source: {path}")
    with Image.open(path) as source:
        return ImageOps.fit(source.convert("RGBA"), (3840, 2160), method=Image.Resampling.LANCZOS)


def generate_primary_wallpapers() -> None:
    minimal_icon = source_wallpaper("minimal-osaka-jade.png")
    composite_mark(minimal_icon, size=500, position=(1670, 830), color=OSAKA["accent"], alpha=230, glow=0)
    save_png(minimal_icon, ROOT / "themes" / "omyvoid" / "backgrounds" / "omyvoid.png")
    save_png(minimal_icon, ROOT / "themes" / "omyvoid" / "backgrounds" / "omyvoid-icon.png")
    save_png(
        ImageOps.fit(minimal_icon, (1800, 1012), method=Image.Resampling.LANCZOS),
        ROOT / "themes" / "omyvoid" / "preview.png",
    )

    minimal_text = source_wallpaper("minimal-osaka-jade.png")
    wordmark = render_wordmark(2200, 520, OSAKA["foreground"])
    position = ((minimal_text.width - wordmark.width) // 2, (minimal_text.height - wordmark.height) // 2)
    minimal_text.alpha_composite(wordmark, position)
    save_png(minimal_text, ROOT / "themes" / "omyvoid" / "backgrounds" / "omyvoidBackground.png")

    rescue = source_wallpaper("rescue-osaka-jade.png")
    composite_mark(
        rescue,
        size=170,
        position=(3560, 1880),
        color=OSAKA["foreground"],
        alpha=115,
        glow=0,
    )
    save_png(rescue, ROOT / "themes" / "omyvoid" / "backgrounds" / "InRescue.png")

    boot = source_wallpaper("minimal-osaka-jade.png")
    composite_mark(boot, size=430, position=(2920, 865), color=OSAKA["accent"], alpha=220, glow=0)
    save_png(
        ImageOps.fit(boot, (1920, 1080), method=Image.Resampling.LANCZOS),
        ROOT / "default" / "limine" / "omyvoid-boot.png",
    )
    save_png(boot, ROOT / "default" / "limine" / "omyvoid-boot-source.png")


def generate_login_assets() -> None:
    wordmark = render_wordmark(800, 188, OSAKA["foreground"])
    for path in (
        ROOT / "default" / "sddm" / "omyvoid" / "logo.png",
        ROOT / "default" / "plymouth" / "logo.png",
    ):
        save_png(wordmark, path)
    preview = unlock_preview(OSAKA["background"], OSAKA["foreground"], OSAKA["accent"])
    save_png(preview, ROOT / "default" / "plymouth" / "preview-unlock.png")

    lockup = Image.new("RGBA", (1920, 1080), rgba(OSAKA["dark"]))
    composite_mark(lockup, size=300, position=(810, 190), color=OSAKA["accent"], glow=0)
    lockup.alpha_composite(render_wordmark(920, 216, OSAKA["foreground"]), (500, 630))
    save_png(lockup, ROOT / "default" / "limine" / "omyvoid-wordmark.png")


def generate_icon_font() -> None:
    units_per_em = 1000
    glyph_pen = TTGlyphPen(None)
    quadratic_pen = Cu2QuPen(glyph_pen, max_err=1.0, reverse_direction=False)
    transform = TransformPen(quadratic_pen, (34, 0, 0, -34, 92, 908))
    parse_path(canonical_path(), transform)
    glyphs = {
        ".notdef": TTGlyphPen(None).glyph(),
        "space": TTGlyphPen(None).glyph(),
        "omyvoid": glyph_pen.glyph(),
    }
    builder = FontBuilder(units_per_em, isTTF=True)
    builder.setupGlyphOrder([".notdef", "space", "omyvoid"])
    builder.setupCharacterMap({0x20: "space", 0xE900: "omyvoid"})
    builder.setupGlyf(glyphs)
    builder.setupHorizontalMetrics(
        {".notdef": (1000, 0), "space": (500, 0), "omyvoid": (1000, 0)}
    )
    builder.setupHorizontalHeader(ascent=950, descent=-100)
    builder.setupOS2(
        sTypoAscender=950,
        sTypoDescender=-100,
        usWinAscent=950,
        usWinDescent=100,
    )
    builder.setupNameTable(
        {
            "familyName": "Omyvoid Icons",
            "styleName": "Regular",
            "uniqueFontIdentifier": "Omyvoid Icons Regular 0.1.0",
            "fullName": "Omyvoid Icons Regular",
            "psName": "OmyvoidIcons-Regular",
            "version": "Version 0.1.0",
        }
    )
    builder.setupPost()
    builder.setupMaxp()
    output = ROOT / "default" / "fonts" / "OmyvoidIcons.ttf"
    output.parent.mkdir(parents=True, exist_ok=True)
    builder.save(output)


def main() -> int:
    save_png(render_mark(512, OSAKA["accent"], padding=40), ROOT / "icon.png")
    generate_icon_font()
    generate_theme_assets()
    generate_primary_wallpapers()
    generate_login_assets()
    print("Generated Omyvoid branding assets from Void_Linux_logo.svg")
    return 0


if __name__ == "__main__":
    sys.exit(main())
