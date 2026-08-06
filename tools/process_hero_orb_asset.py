from __future__ import annotations

import math
from pathlib import Path

from PIL import Image

SRC = Path(
    r"C:\Users\FATİH TAHA\.cursor\projects\c-Dev-oracly-new\assets\hero_orb_premium.png"
)
DST = Path(__file__).resolve().parents[1] / "lib" / "assets" / "images" / "hero_orb_premium.png"


def _median(values: list[float]) -> float:
    ordered = sorted(values)
    mid = len(ordered) // 2
    if len(ordered) % 2:
        return ordered[mid]
    return (ordered[mid - 1] + ordered[mid]) / 2


def main() -> None:
    DST.parent.mkdir(parents=True, exist_ok=True)

    img = Image.open(SRC).convert("RGBA")
    width, height = img.size
    pixels = img.load()

    edge_r: list[float] = []
    edge_g: list[float] = []
    edge_b: list[float] = []

    for x in range(width):
        for y in (0, height - 1):
            r, g, b, _ = pixels[x, y]
            edge_r.append(r)
            edge_g.append(g)
            edge_b.append(b)
    for y in range(height):
        for x in (0, width - 1):
            r, g, b, _ = pixels[x, y]
            edge_r.append(r)
            edge_g.append(g)
            edge_b.append(b)

    bg_r = _median(edge_r)
    bg_g = _median(edge_g)
    bg_b = _median(edge_b)

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            dist = math.sqrt((r - bg_r) ** 2 + (g - bg_g) ** 2 + (b - bg_b) ** 2)
            if dist < 12:
                alpha = 0
            else:
                alpha = min(255, max(0, int((dist - 18) * 16)))
            pixels[x, y] = (r, g, b, alpha)

    bbox = img.getbbox()
    if bbox:
        cropped = img.crop(bbox)
        side = max(cropped.size)
        canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        offset = ((side - cropped.width) // 2, (side - cropped.height) // 2)
        canvas.paste(cropped, offset, cropped)
        img = canvas

    img = img.resize((4096, 4096), Image.Resampling.LANCZOS)
    img.save(DST, format="PNG", optimize=True)

    print(f"saved: {DST}")
    print(f"size: {img.size}, mode: {img.mode}")


if __name__ == "__main__":
    main()
