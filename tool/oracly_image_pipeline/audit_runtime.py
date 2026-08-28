"""Audit Flutter runtime images — flag oversized / non-WebP majors.

Usage:
  python tool/oracly_image_pipeline/audit_runtime.py
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
IMAGES = ROOT / "lib" / "assets" / "images"

# Soft budgets for non-tarot majors (tarot cards are intentionally many files).
MAX_BYTES = 450_000
MAX_LONG_EDGE = 1800
WARN_PNG = True


def main() -> int:
    if not IMAGES.is_dir():
        print(f"Missing {IMAGES}", file=sys.stderr)
        return 2

    issues = 0
    rows: list[str] = []
    for path in sorted(IMAGES.rglob("*")):
        if not path.is_file():
            continue
        if path.suffix.lower() not in {".webp", ".png", ".jpg", ".jpeg"}:
            continue
        # Skip tarot deck bulk — separate pipeline.
        if "tarot" in path.parts and "thumbs" not in path.parts:
            if path.name.startswith(("0", "1", "2")) or "minor_arcana" in str(path):
                continue

        try:
            with Image.open(path) as im:
                w, h = im.size
        except OSError as exc:
            rows.append(f"FAIL read {path.relative_to(ROOT)}: {exc}")
            issues += 1
            continue

        nbytes = path.stat().st_size
        rel = path.relative_to(ROOT).as_posix()
        long = max(w, h)
        flags: list[str] = []
        if long > MAX_LONG_EDGE:
            flags.append(f"long_edge>{MAX_LONG_EDGE}")
        if nbytes > MAX_BYTES:
            flags.append(f"bytes>{MAX_BYTES}")
        if WARN_PNG and path.suffix.lower() == ".png" and "tarot" not in path.parts:
            flags.append("prefer_webp")

        status = "WARN" if flags else "OK"
        if flags:
            issues += 1
        rows.append(f"{status:4} {w:4}x{h:<4} {nbytes:8}  {rel}  {', '.join(flags)}")

    print("\n".join(rows))
    print(f"\n{len(rows)} files scanned · {issues} warnings")
    return 0 if issues == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
