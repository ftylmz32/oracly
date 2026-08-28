"""Build high-quality Home runtime assets from master/source PNGs."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ASSETS_SRC = Path(
    r"C:\Users\FATİH TAHA\.cursor\projects\c-Dev-oracly-new\assets"
)
OUT = ROOT / "lib" / "assets" / "images" / "home"
MASTER = ROOT / "_inspect" / "master_home_ref.png"

_HERO_SLOT_ASPECT = 360 / 122
TARGETS = {
    "module_portrait": (900, 1350),
    "hero": (int(415 * _HERO_SLOT_ASPECT), 415),
    "premium": (1350, 900),
    "gems": (1020, 420),
}
WEBP_QUALITY = 92


def save_webp(img: Image.Image, path: Path) -> int:
    rgb = img.convert("RGB")
    rgb.save(path, "WEBP", quality=WEBP_QUALITY, method=6)
    return path.stat().st_size


def resize_cover(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    tw, th = size
    w, h = img.size
    scale = max(tw / w, th / h)
    nw, nh = int(w * scale + 0.5), int(h * scale + 0.5)
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - tw) // 2
    top = (nh - th) // 2
    return resized.crop((left, top, left + tw, top + th))


def sharpen(img: Image.Image, radius: float, percent: int) -> Image.Image:
    return img.filter(ImageFilter.UnsharpMask(radius=radius, percent=percent, threshold=3))


def resize_to_banner(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    tw, th = size
    return img.resize((tw, th), Image.Resampling.LANCZOS)


def feather_fill_left_zone(
    img: Image.Image,
    *,
    src_start: float,
    src_end: float,
    fill_width_ratio: float,
) -> Image.Image:
    """Replace baked reference copy with feathered sky — one continuous scene."""
    tw, th = img.size
    column = img.crop((int(tw * src_start), 0, int(tw * src_end), th))
    left_w = int(tw * fill_width_ratio)
    fill = column.resize((left_w, th), Image.Resampling.LANCZOS)
    feather = max(2, int(tw * 0.045))
    blend_start = max(0, left_w - feather)
    mask = Image.new("L", (left_w, th), 255)
    px = mask.load()
    for x in range(blend_start, left_w):
        alpha = int(255 * (1 - (x - blend_start) / feather))
        for y in range(th):
            px[x, y] = alpha
    out = img.copy()
    out.paste(fill, (0, 0), mask)
    return out


def process_hero(master: Image.Image) -> tuple[str, tuple[int, int], int]:
    w, h = master.size
    box = (int(w * 0.023), int(h * 0.077), int(w * 0.977), int(h * 0.266))
    band = master.crop(box)
    tw, th = TARGETS["hero"]
    # Sample clean starfield just left of the crescent; never the baked UI band.
    wide = feather_fill_left_zone(
        resize_to_banner(band, (1400, th)),
        src_start=0.50,
        src_end=0.60,
        fill_width_ratio=0.54,
    )
    img = sharpen(resize_to_banner(wide, (tw, th)), 0.85, 72)
    out = OUT / "home_hero_moon.webp"
    return "home_hero_moon.webp", img.size, save_webp(img, out)


def process_module(src_name: str, out_name: str) -> tuple[str, tuple[int, int], int]:
    img = sharpen(
        resize_cover(Image.open(ASSETS_SRC / src_name).convert("RGB"), TARGETS["module_portrait"]),
        0.9,
        70,
    )
    out = OUT / out_name
    return out_name, img.size, save_webp(img, out)


def process_premium() -> tuple[str, tuple[int, int], int]:
    img = sharpen(
        resize_cover(Image.open(ASSETS_SRC / "home_premium.png").convert("RGB"), TARGETS["premium"]),
        0.9,
        70,
    )
    out = OUT / "home_premium.webp"
    return "home_premium.webp", img.size, save_webp(img, out)


def process_gems(master: Image.Image) -> tuple[str, tuple[int, int], int]:
    w, h = master.size
    box = (int(w * 0.50), int(h * 0.798), int(w * 0.98), int(h * 0.928))
    base = resize_cover(master.crop(box), TARGETS["gems"])
    img = sharpen(
        feather_fill_left_zone(
            base,
            src_start=0.58,
            src_end=0.74,
            fill_width_ratio=0.40,
        ),
        0.7,
        55,
    )
    out = OUT / "home_gems_banner.webp"
    return "home_gems_banner.webp", img.size, save_webp(img, out)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    master = Image.open(MASTER).convert("RGB")
    rows = [
        process_hero(master),
        process_module("home_or_guide.png", "home_or_guide.webp"),
        process_module("home_tarot.png", "home_tarot.webp"),
        process_module("home_dream.png", "home_dream.webp"),
        process_module("home_astrology.png", "home_astrology.webp"),
        process_module("home_yildizname.png", "home_yildizname.webp"),
        process_premium(),
        process_gems(master),
    ]
    for old in OUT.glob("*.jpg"):
        old.unlink()
    total = sum(r[2] for r in rows)
    print("ASSET REPORT")
    for name, dim, sz in rows:
        print(f"{name}: {dim[0]}x{dim[1]} WEBP {sz / 1024:.1f}KB")
    print(f"TOTAL: {total / 1024:.1f}KB ({total / 1024 / 1024:.2f}MB)")


if __name__ == "__main__":
    main()
