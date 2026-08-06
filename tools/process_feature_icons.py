"""Resize Oracly feature icons to 512x512 and remove dark cosmic background."""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image

ALT_SRC = Path(r"C:\Users\FATİH TAHA\.cursor\projects\c-Dev-oracly-new\assets")
DEST_DIR = Path(r"c:\Dev\oracly_new\lib\assets\icons")

NAMES = [
    "feature_tarot.png",
    "feature_dream.png",
    "feature_astrology.png",
    "feature_star_map.png",
    "feature_ai_crystal.png",
]

SIZE = 512
TOLERANCE = 44
FEATHER = 30


def _color_dist(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2) ** 0.5


def _bg_color(pixels, width: int, height: int) -> tuple[int, int, int]:
    samples = [
        pixels[2, 2],
        pixels[width - 3, 2],
        pixels[2, height - 3],
        pixels[width - 3, height - 3],
        pixels[width // 2, 2],
        pixels[2, height // 2],
    ]
    rs = [s[0] for s in samples]
    gs = [s[1] for s in samples]
    bs = [s[2] for s in samples]
    return (sum(rs) // len(rs), sum(gs) // len(gs), sum(bs) // len(bs))


def _flood_background_mask(
    pixels,
    width: int,
    height: int,
    bg: tuple[int, int, int],
    tolerance: float,
) -> list[list[bool]]:
    mask = [[False] * width for _ in range(height)]
    queue: deque[tuple[int, int]] = deque()

    def try_push(x: int, y: int) -> None:
        if x < 0 or y < 0 or x >= width or y >= height or mask[y][x]:
            return
        r, g, b, _ = pixels[x, y]
        if _color_dist((r, g, b), bg) <= tolerance:
            mask[y][x] = True
            queue.append((x, y))

    for x in range(width):
        try_push(x, 0)
        try_push(x, height - 1)
    for y in range(height):
        try_push(0, y)
        try_push(width - 1, y)

    while queue:
        x, y = queue.popleft()
        try_push(x - 1, y)
        try_push(x + 1, y)
        try_push(x, y - 1)
        try_push(x, y + 1)

    return mask


def process_icon(src: Path, dest: Path) -> None:
    img = Image.open(src).convert("RGBA")
    img = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    pixels = img.load()
    width, height = img.size
    bg = _bg_color(pixels, width, height)
    bg_mask = _flood_background_mask(pixels, width, height, bg, TOLERANCE)

    for y in range(height):
        for x in range(width):
            r, g, b, _ = pixels[x, y]
            dist = _color_dist((r, g, b), bg)
            if bg_mask[y][x]:
                pixels[x, y] = (r, g, b, 0)
            elif dist <= TOLERANCE + FEATHER:
                fade = (dist - TOLERANCE) / FEATHER
                pixels[x, y] = (r, g, b, int(255 * fade))

    img.save(dest, "PNG", optimize=True)
    print(f"Wrote {dest} ({SIZE}x{SIZE})")


def main() -> None:
    DEST_DIR.mkdir(parents=True, exist_ok=True)
    for name in NAMES:
        src = ALT_SRC / name
        if not src.exists():
            raise FileNotFoundError(src)
        process_icon(src, DEST_DIR / name)


if __name__ == "__main__":
    main()
