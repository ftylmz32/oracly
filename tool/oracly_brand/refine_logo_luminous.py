from pathlib import Path
from PIL import Image, ImageEnhance, ImageFilter, ImageChops, ImageDraw

MASTER = Path("assets/brand/oracly_launcher_source.png")
RUNTIME = Path("lib/assets/brand/oracly_logo.png")
BACKUP = Path("art_masters/brand/oracly_launcher_source_pre_luminous.png")

BACKUP.parent.mkdir(parents=True, exist_ok=True)
src = Image.open(MASTER).convert("RGBA")
if not BACKUP.exists():
    src.save(BACKUP)
    print("backed up to", BACKUP)

w, h = src.size
r, g, b, a = src.split()
rgb = Image.merge("RGB", (r, g, b))

# 1) Lift midtones / gold without crushing blacks
lifted = ImageEnhance.Brightness(rgb).enhance(1.42)
lifted = ImageEnhance.Contrast(lifted).enhance(1.20)
lifted = ImageEnhance.Color(lifted).enhance(1.28)
lifted = ImageEnhance.Sharpness(lifted).enhance(1.15)

# 2) Soft gold ambient bloom from bright regions (readability at 48px)
gray = lifted.convert("L")
# Keep only brighter gold-ish pixels for bloom
bloom_mask = gray.point(lambda p: 255 if p > 28 else 0)
bloom = ImageChops.multiply(lifted, Image.merge("RGB", (bloom_mask, bloom_mask, bloom_mask)))
bloom = bloom.filter(ImageFilter.GaussianBlur(radius=18))
bloom = ImageEnhance.Brightness(bloom).enhance(1.55)
composed = ImageChops.screen(lifted, bloom)

# 3) Subtle violet ambient behind emblem (center radial)
overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
draw = ImageDraw.Draw(overlay)
cx, cy = w // 2, h // 2
# Draw concentric soft violet discs
for i, (rad, alpha) in enumerate([(0.42, 55), (0.28, 40), (0.16, 28)]):
    rad_px = int(min(w, h) * rad)
    color = (72, 36, 140, alpha)
    draw.ellipse(
        (cx - rad_px, cy - rad_px, cx + rad_px, cy + rad_px),
        fill=color,
    )
overlay = overlay.filter(ImageFilter.GaussianBlur(radius=42))
# Composite violet under the logo content
base = Image.new("RGBA", (w, h), (5, 2, 8, 255))
base = Image.alpha_composite(base, overlay)
logo = Image.merge("RGBA", (*composed.split(), a))
final = Image.alpha_composite(base, logo)

# 4) Final micro-contrast for small-size silhouette
fr, fg, fb, fa = final.split()
frgb = Image.merge("RGB", (fr, fg, fb))
frgb = ImageEnhance.Contrast(frgb).enhance(1.08)
frgb = ImageEnhance.Brightness(frgb).enhance(1.06)
final = Image.merge("RGBA", (*frgb.split(), fa))

final.save(MASTER, optimize=True)
final.save(RUNTIME, optimize=True)

# luminance report
px = list(final.getdata())
vis = [0.2126 * r + 0.7152 * g + 0.0722 * b for r, g, b, a in px if a > 30]
vis.sort()
n = len(vis)
print(
    "saved",
    MASTER,
    "mean",
    round(sum(vis) / n, 2),
    "p50",
    round(vis[n // 2], 2),
    "p90",
    round(vis[int(n * 0.9)], 2),
    "p99",
    round(vis[int(n * 0.99)], 2),
)
final.resize((192, 192), Image.Resampling.LANCZOS).save("_inspect/_brand_logo_192_luminous.png")
final.resize((48, 48), Image.Resampling.LANCZOS).save("_inspect/_brand_logo_48_luminous.png")
print("previews written")
