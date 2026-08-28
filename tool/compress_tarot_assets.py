# Compress ritual tarot PNGs to WebP. Same artwork. No redraw.
from pathlib import Path
from PIL import Image

ROOT = Path("lib/assets/images/tarot")
THUMBS = ROOT / "thumbs"
PUBSPEC = Path("pubspec.yaml")
BEGIN = "    # TAROT_RUNTIME_ASSETS_BEGIN"
END = "    # TAROT_RUNTIME_ASSETS_END"


def _webp_pubspec_block() -> str:
    lines = [BEGIN, "    # Source PNG beside these files is not listed, so not bundled."]
    for path in sorted(p.as_posix() for p in ROOT.rglob("*.webp")):
        lines.append(f"    - {path}")
    lines.append(END)
    return "\n".join(lines)


def write_pubspec_runtime_assets() -> None:
    text = PUBSPEC.read_text(encoding="utf-8")
    block = _webp_pubspec_block()
    if BEGIN in text and END in text:
        start = text.index(BEGIN)
        stop = text.index(END) + len(END)
        PUBSPEC.write_text(text[:start] + block + text[stop:], encoding="utf-8")
        return
    raise SystemExit("pubspec.yaml is missing TAROT_RUNTIME_ASSETS markers")


def main() -> None:
    count = 0
    full_bytes = 0
    thumb_bytes = 0
    for src in sorted(ROOT.rglob("*.png")):
        if "thumbs" in src.parts:
            continue
        rel = src.relative_to(ROOT)
        image = Image.open(src).convert("RGB")
        full = src.with_suffix(".webp")
        image.save(full, "WEBP", quality=86, method=4)
        full_bytes += full.stat().st_size
        dest_dir = THUMBS / rel.parent
        dest_dir.mkdir(parents=True, exist_ok=True)
        thumb = dest_dir / f"{src.stem}.webp"
        image.resize((320, 480), Image.Resampling.LANCZOS).save(
            thumb,
            "WEBP",
            quality=80,
            method=4,
        )
        thumb_bytes += thumb.stat().st_size
        count += 1
        print(f"{count:02d} {rel} {full.stat().st_size // 1024}k / {thumb.stat().st_size // 1024}k")
    write_pubspec_runtime_assets()
    print(f"DONE {count} full_mb={full_bytes / 1e6:.2f} thumb_mb={thumb_bytes / 1e6:.2f}")


if __name__ == "__main__":
    main()
