# ORACLY — Photorealistic Image Asset Pipeline

**Status:** Permanent visual infrastructure  
**Art standard:** [GLOBAL_VISUAL_QUALITY_SYSTEM.md](./GLOBAL_VISUAL_QUALITY_SYSTEM.md) → [PHOTOREALISTIC_ART_STANDARD.md](./PHOTOREALISTIC_ART_STANDARD.md)  
**Tooling:** `tool/oracly_image_pipeline/`  
**Masters vault:** `art_masters/` (not shipped in the app bundle)  
**Runtime:** `lib/assets/images/` via `AppAssets`  
**Version:** 1.1

---

## Purpose

One repeatable path from generation → quality gate → mobile-optimized shipping.

Does **not** change business logic, AI providers, or feature routes.

---

## Absolute art bar (pipeline gate 0)

Every major asset must pass [GLOBAL_VISUAL_QUALITY_SYSTEM.md](./GLOBAL_VISUAL_QUALITY_SYSTEM.md) and [PHOTOREALISTIC_ART_STANDARD.md](./PHOTOREALISTIC_ART_STANDARD.md).

| Accept | Reject |
|--------|--------|
| Luxury cinematic photography | AI-generated illustration look |
| Physically believable materials & light | Vector / cartoon / game art |
| No baked UI text | Titles, logos, CTAs, badges in pixels |

**Lighting:** deep black · midnight violet · subtle navy · warm antique gold · controlled amber  
**No:** neon purple · excessive bloom · overexposed gold  

**Lens:** natural DoF · subtle compression · realistic bokeh · soft atmospheric perspective  
**No:** extreme fake blur · over-sharpen · game-render look  

---

## Three-tier asset model

| Tier | Location | Purpose | Shipped? |
|------|----------|---------|----------|
| **Master** | `art_masters/<feature>/…` | Highest-quality source (PNG/TIFF/WebP) for regen & archive | **No** |
| **Runtime** | `lib/assets/images/…` | Optimized WebP for Flutter | **Yes** |
| **Thumb** | `lib/assets/images/**/thumbs/` or `…_thumb.webp` | Lists, strips, previews | **Yes** (only if needed) |

Never ship 4K/8K masters in `pubspec` assets.

---

## Roles & target sizes

| Role | Typical use | Runtime target | WebP quality |
|------|-------------|----------------|--------------|
| `hero_wide` | Home / Profile / wide heroes | long edge ≤ **1600** | 88–92 |
| `hero_tall` | Palm / coffee / portrait heroes | long edge ≤ **1440** | 88–92 |
| `discovery_tile` | Home 3×2 portals | **900×1200** (3:4) | 86–90 |
| `plate_square` | Astrology instrument plate | **1024×1024** | 88–92 |
| `backdrop` | Soft full-bleed atmosphere | long edge ≤ **1600** | 82–88 |
| `banner` | Thin strips | long edge ≤ **1200** | 84–88 |
| `thumb` | Moments / lists | long edge ≤ **384** | 78–84 |

Aspect ratios must match the widget (`AspectRatio` / flex slot). Prefer cover-safe center composition.

---

## Pipeline steps (every new major asset)

1. **Brief** — feature identity + shared ORACLY DNA (light/gold/violet).
2. **Generate / shoot** — photoreal cinematic frame; **no text in image**.
3. **QC human** — pass art standard checklist (below). Reject illustration look.
4. **Save master** — `art_masters/<feature>/<slug>.png` (or lossless).
5. **Optimize** — run:

```bash
python tool/oracly_image_pipeline/optimize_asset.py \
  --in art_masters/<feature>/<slug>.png \
  --out lib/assets/images/<path>/<slug>.webp \
  --role <role> \
  [--thumb lib/assets/images/<path>/thumbs/<slug>.webp]
```

6. **Register** — add constant in `lib/core/constants/app_assets.dart`; ensure `pubspec.yaml` folder is listed.
7. **Wire** — `OraclyAssetImage` / `Image.asset` with `BoxFit.cover`, stable aspect, high `FilterQuality` on heroes.
8. **Audit** — `python tool/oracly_image_pipeline/audit_runtime.py` (flags oversized runtimes).

---

## Quality checklist (print before merge)

- [ ] Photoreal / cinematic / editorial — not illustration
- [ ] Shared light language (no neon purple bloom)
- [ ] Materials show micro-texture
- [ ] Humans: natural anatomy, skin, hair, eyes (if present)
- [ ] Zero baked UI text / logos / badges
- [ ] Feature identity clear without labels
- [ ] Belongs to one ORACLY universe
- [ ] Runtime WebP within role size budget
- [ ] Flutter layout uses fixed aspect / no jump on decode
- [ ] Bottom nav / safe area still clear of content

---

## Feature folders (convention)

```
art_masters/
  home/
  coffee/
  palm/
  astrology/
  yildizname/
  tarot/          # card masters may follow existing tarot pipeline
  soulmate/
  profile/
  or/
  shared/

lib/assets/images/
  home/
  astrology/
  profile/
  …               # + root heroes (palm_ritual_hero.webp, etc.)
```

Tarot 78-card shipping already uses explicit `pubspec` entries + thumbs — do not break that path; new non-tarot majors use this pipeline.

---

## Performance rules

- Prefer **WebP** runtime over PNG for new majors.
- Cap long edge per role table — no unnecessary 8K.
- Use `OraclyAssetImage` / decode cache caps already in the design system.
- Thumbs only when a list/strip would otherwise decode full heroes.
- `audit_runtime.py` may **WARN** on legacy PNG heroes until they are migrated through this pipeline — new assets must not add to that debt.

---

## Consistency

Same universe: lighting discipline · gold accent · dark violet · material realism · depth  
Different subjects: Coffee cup · Palm hand · Observatory · Archive · Deck · SoulMate · Journal · Home entrance · OR presence

---

## Final gate

| Look | Verdict |
|------|---------|
| “AI-generated illustration” | **FAIL** — do not ship |
| “Luxury cinematic photography” | **PASS** — optimize & register |
