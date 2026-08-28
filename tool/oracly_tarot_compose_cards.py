"""ORACLY locked tarot face frame + title composite.

Master 1024×1792 (4:7). Runtime 512×896. Illustration is cover-cropped
into the oracle window. Titles live on the obsidian plaque.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
W, H = 1024, 1792
NEAR = (4, 3, 10, 255)
GOLD = (231, 197, 109, 255)
GOLD_L = (245, 217, 138, 255)
GOLD_D = (201, 168, 78, 255)
GOLD_G = (154, 116, 32, 255)
CREAM = (240, 230, 216, 255)
WIN = (64, 132, 960, 1568)
PLAQUE = (120, 1572, 904, 1728)


def _font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    names = (
        ["georgiab.ttf", "timesbd.ttf"] if bold else ["georgia.ttf", "times.ttf"]
    )
    for name in names:
        path = Path("C:/Windows/Fonts") / name
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def _trim_void(src: Image.Image) -> Image.Image:
    gray = src.convert("L")
    mask = gray.point(lambda p: 255 if p > 22 else 0)
    bbox = mask.getbbox()
    if bbox is None:
        return src
    left, top, right, bottom = bbox
    inset_x = int((right - left) * 0.05)
    inset_y = int((bottom - top) * 0.06)
    left = min(left + inset_x, right - 8)
    top = min(top + inset_y, bottom - 8)
    right = max(right - inset_x, left + 8)
    bottom = max(bottom - inset_y, top + 8)
    return src.crop((left, top, right, bottom))


def _cover(src: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    src = _trim_void(src)
    left, top, right, bottom = box
    tw, th = right - left, bottom - top
    sw, sh = src.size
    scale = max(tw / sw, th / sh)
    nw, nh = max(1, int(sw * scale)), max(1, int(sh * scale))
    resized = src.convert("RGB").resize((nw, nh), Image.Resampling.LANCZOS)
    x = (nw - tw) // 2
    y = max(0, int((nh - th) * 0.28))
    return resized.crop((x, y, x + tw, y + th))


def draw_frame(base: Image.Image) -> Image.Image:
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    d.rounded_rectangle((18, 18, W - 18, H - 18), radius=28, outline=GOLD_G, width=3)
    d.rounded_rectangle((28, 28, W - 28, H - 28), radius=24, outline=GOLD, width=2)
    d.rounded_rectangle((42, 42, W - 42, H - 42), radius=20, outline=(*GOLD_L[:3], 90), width=1)
    for cx, cy in ((56, 56), (W - 56, 56), (56, H - 56), (W - 56, H - 56)):
        d.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), outline=GOLD, width=2)
        d.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=GOLD_D)
    vx, vy = W // 2, 96
    d.ellipse((vx - 34, vy - 18, vx + 2, vy + 18), outline=GOLD, width=2)
    d.ellipse((vx - 2, vy - 18, vx + 34, vy + 18), outline=GOLD, width=2)
    d.polygon([(vx, vy - 26), (vx - 9, vy + 4), (vx + 9, vy + 4)], outline=GOLD_L)
    d.ellipse((vx - 4, vy - 4, vx + 4, vy + 4), fill=GOLD_L)
    left, top, right, bottom = WIN
    d.rounded_rectangle((left - 8, top - 8, right + 8, bottom + 8), radius=16, outline=GOLD_D, width=2)
    d.rounded_rectangle((left - 3, top - 3, right + 3, bottom + 3), radius=14, outline=(*GOLD[:3], 140), width=1)
    d.rounded_rectangle((left, top, right, bottom), radius=12, outline=(74, 54, 176, 28), width=2)
    for y in range(top + 40, bottom - 40, 86):
        d.line((36, y, 52, y), fill=(*GOLD[:3], 70), width=1)
        d.line((W - 52, y, W - 36, y), fill=(*GOLD[:3], 70), width=1)
    pl, pt, pr, pb = PLAQUE
    d.rounded_rectangle((pl, pt, pr, pb), radius=12, fill=(8, 6, 16, 235), outline=GOLD, width=2)
    d.rounded_rectangle((pl + 6, pt + 6, pr - 6, pb - 6), radius=8, outline=(*GOLD_L[:3], 70), width=1)
    return Image.alpha_composite(base.convert("RGBA"), overlay)


def compose(illustration: Image.Image, numeral: str, title: str) -> Image.Image:
    canvas = Image.new("RGBA", (W, H), NEAR)
    haze = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    hd = ImageDraw.Draw(haze)
    for i in range(H):
        alpha = int(26 * (1 - abs(i - H * 0.32) / (H * 0.7)))
        hd.line((0, i, W, i), fill=(26, 22, 48, max(0, alpha)))
    canvas = Image.alpha_composite(canvas, haze)
    window = _cover(illustration, WIN)
    canvas.paste(window, (WIN[0], WIN[1]))
    framed = draw_frame(canvas)
    d = ImageDraw.Draw(framed)
    d.text((W // 2, 138), numeral, font=_font(22, bold=True), fill=GOLD_L, anchor="mm")
    tf = _font(34, bold=True)
    pl, pt, _, pb = PLAQUE
    d.text((W // 2, (pt + pb) // 2), title, font=tf, fill=CREAM, anchor="mm")
    tw = d.textlength(title, font=tf)
    d.line(
        (
            W // 2 - tw / 2,
            (pt + pb) // 2 + 24,
            W // 2 + tw / 2,
            (pt + pb) // 2 + 24,
        ),
        fill=(*GOLD[:3], 90),
        width=1,
    )
    return framed


def export_runtime(src: Image.Image, dest_webp: Path) -> None:
    dest_webp.parent.mkdir(parents=True, exist_ok=True)
    source_dir = ROOT / "design" / "tarot" / "source" / "cards" / dest_webp.parent.name
    source_dir.mkdir(parents=True, exist_ok=True)
    master = src.convert("RGB")
    master.save(source_dir / f"{dest_webp.stem}.png", "PNG", optimize=True)
    runtime = master.resize((512, 896), Image.Resampling.LANCZOS)
    runtime.save(dest_webp, "WEBP", quality=82, method=6)


def _load_meta() -> dict[tuple[str, str], tuple[str, str]]:
    raw = json.loads((ROOT / "design" / "tarot" / "generation" / "card_registry.json").read_text(encoding="utf-8"))
    out: dict[tuple[str, str], tuple[str, str]] = {}
    for row in raw["majors"]:
        out[("major", row["id"])] = (row["numeral"], row["titleEn"])
    for row in raw.get("minors", []):
        out[(row["suit"], row["id"])] = (row["numeral"], row["titleEn"])
    return out


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--ill", type=Path, required=True, help="Folder of raw illustrations")
    p.add_argument("--out", type=Path, required=True, help="Runtime folder (suit or major)")
    args = p.parse_args()
    meta = _load_meta()
    group = args.out.name
    for src in sorted(args.ill.glob("*.png")):
        key = (group, src.stem)
        if key not in meta:
            raise SystemExit(f"unknown illustration: {group}/{src.stem}")
        numeral, title = meta[key]
        art = compose(Image.open(src), numeral, title)
        export_runtime(art, args.out / f"{src.stem}.webp")
        print("wrote", group, src.stem)


if __name__ == "__main__":
    main()
