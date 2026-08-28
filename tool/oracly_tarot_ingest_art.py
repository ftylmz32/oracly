"""Collect 78 generated illustrations and compose locked ORACLY faces."""
from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GEN_DIRS = [
    Path(r"C:\Users\FATİH TAHA\.cursor\projects\c-Dev-oracly-new\assets"),
    ROOT / "assets",
]
ILL = ROOT / "design" / "tarot" / "source" / "illustrations"
RUNTIME = ROOT / "assets" / "tarot" / "cards"

PREFIX = {
    "major_": "major",
    "wands_": "wands",
    "cups_": "cups",
    "swords_": "swords",
    "pentacles_": "pentacles",
}


def collect() -> list[Path]:
    found: dict[str, Path] = {}
    for folder in GEN_DIRS:
        if not folder.exists():
            continue
        for path in folder.glob("*.png"):
            name = path.name
            for prefix, group in PREFIX.items():
                if name.startswith(prefix):
                    stem = name[len(prefix) : -4]
                    dest = ILL / group / f"{stem}.png"
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(path, dest)
                    found[f"{group}/{stem}"] = dest
                    break
    return sorted(found)


def compose_all() -> None:
    for group in ("major", "wands", "cups", "swords", "pentacles"):
        out = RUNTIME / group
        if out.exists():
            for stale in out.glob("*"):
                stale.unlink()
        cmd = [
            sys.executable,
            str(ROOT / "tool" / "oracly_tarot_compose_cards.py"),
            "--ill",
            str(ILL / group),
            "--out",
            str(RUNTIME / group),
        ]
        subprocess.check_call(cmd)


def report() -> None:
    files = sorted(RUNTIME.glob("*/*.webp"))
    files = [p for p in files if "_thumb" not in p.name]
    hashes = [hashlib.sha256(p.read_bytes()).hexdigest() for p in files]
    manifest = {
        "card_art": len(files),
        "unique": len(set(hashes)),
        "missing": 78 - len(files),
        "duplicates": len(files) - len(set(hashes)),
        "files": [str(p.relative_to(ROOT)).replace("\\", "/") for p in files],
    }
    (RUNTIME / "MANIFEST.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )
    print(json.dumps({k: manifest[k] for k in ("card_art", "unique", "missing", "duplicates")}, indent=2))


def main() -> None:
    keys = collect()
    print("illustrations", len(keys))
    if len(keys) != 78:
        raise SystemExit(f"expected 78 illustrations, got {len(keys)}: {keys}")
    compose_all()
    report()


if __name__ == "__main__":
    main()
