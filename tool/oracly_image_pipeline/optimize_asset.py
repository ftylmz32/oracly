"""ORACLY image pipeline — master → optimized WebP runtime (+ optional thumb).

Does not touch Flutter business logic. Art bar: docs/PHOTOREALISTIC_ART_STANDARD.md
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

# Role → (mode, param, quality)
# mode "box" = exact (w, h); mode "long" = max long edge
ROLES: dict[str, tuple[str, tuple[int, ...] | int, int]] = {
    "hero_wide": ("long", 1600, 90),
    "hero_tall": ("long", 1440, 90),
    "discovery_tile": ("box", (900, 1200), 88),
    "plate_square": ("box", (1024, 1024), 90),
    "backdrop": ("long", 1600, 86),
    "banner": ("long", 1200, 86),
    "thumb": ("long", 384, 82),
}


def _fit_long_edge(im: Image.Image, max_long: int) -> Image.Image:
    w, h = im.size
    long = max(w, h)
    if long <= max_long:
        return im
    scale = max_long / float(long)
    nw = max(1, int(round(w * scale)))
    nh = max(1, int(round(h * scale)))
    return im.resize((nw, nh), Image.Resampling.LANCZOS)


def _fit_box(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    """Cover-fit into exact size (center crop) — stable layout slots."""
    tw, th = size
    w, h = im.size
    scale = max(tw / w, th / h)
    nw = max(1, int(round(w * scale)))
    nh = max(1, int(round(h * scale)))
    resized = im.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - tw) // 2
    top = (nh - th) // 2
    return resized.crop((left, top, left + tw, top + th))


def optimize(
    src: Path,
    dest: Path,
    role: str,
    *,
    dry_run: bool = False,
) -> tuple[int, int, int]:
    if role not in ROLES:
        raise SystemExit(f"Unknown role {role!r}. Choose: {', '.join(ROLES)}")
    mode, param, quality = ROLES[role]
    im = Image.open(src).convert("RGB")
    if mode == "long":
        out = _fit_long_edge(im, int(param))
    else:
        out = _fit_box(im, param)  # type: ignore[arg-type]
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dry_run:
        out.save(dest, "WEBP", quality=quality, method=6)
    size = dest.stat().st_size if dest.exists() and not dry_run else 0
    return out.size[0], out.size[1], size


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        description="ORACLY photorealistic asset optimizer (master → runtime WebP)",
    )
    p.add_argument("--in", dest="src", required=True, type=Path)
    p.add_argument("--out", dest="dest", required=True, type=Path)
    p.add_argument("--role", required=True, choices=sorted(ROLES.keys()))
    p.add_argument("--thumb", type=Path, default=None)
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args(argv)

    if not args.src.is_file():
        print(f"Missing input: {args.src}", file=sys.stderr)
        return 2

    w, h, nbytes = optimize(args.src, args.dest, args.role, dry_run=args.dry_run)
    print(f"runtime {args.role}: {w}x{h} -> {args.dest} ({nbytes} bytes)")

    if args.thumb is not None:
        tw, th, tn = optimize(
            args.src, args.thumb, "thumb", dry_run=args.dry_run
        )
        print(f"thumb: {tw}x{th} -> {args.thumb} ({tn} bytes)")

    print("QC reminder: no text in image | photoreal cinematic | register AppAssets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
