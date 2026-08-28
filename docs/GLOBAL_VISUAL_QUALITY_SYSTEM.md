# ORACLY — Global Visual Quality System

**Status:** Permanent · Production-grade visual governance  
**Version:** 1.0  
**Apex parents:** [Master Directive](./MASTER_DIRECTIVE.md) · [Development Charter](./DEVELOPMENT_CHARTER.md) · [vision.md](./vision.md) · [PRINCIPLE-001](./PRINCIPLE-001.md)  
**Art enforcement:** [PHOTOREALISTIC_ART_STANDARD.md](./PHOTOREALISTIC_ART_STANDARD.md)  
**Pipeline:** [PHOTOREALISTIC_IMAGE_ASSET_PIPELINE.md](./PHOTOREALISTIC_IMAGE_ASSET_PIPELINE.md)  
**UI chrome tokens:** `lib/core/design_system/oracly_art_direction.dart` · `OraclyChrome`  
**Brand mark:** [BRAND_MARK.md](./BRAND_MARK.md)

---

## Purpose

One global visual rule system for the entire application.

Every major screen must feel like it belongs to **ORACLY**.  
Each feature must keep its **own visual identity**.

This document does **not** invent a second style language. It locks the DNA already implied by chrome, photoreal pipeline, and chamber craftsmanship.

**Do not** add random visual styles, competing palettes, or one-off hero treatments.

---

## Global ORACLY DNA (shared)

| Token | Role |
|-------|------|
| Near-black | Deep calm base |
| Midnight navy | Secondary depth |
| Deep violet | Atmosphere (never neon purple) |
| Antique gold | Accent only — metal, candle, rim |
| Warm ivory | Reading / cream body text |
| Cinematic darkness | Low-key frames, controlled shadow |
| Realistic lighting | Warm primary + soft fill + deep falloff |
| Real materials | Ceramic, velvet, paper, brass, wood, skin, glass |
| Controlled contrast | Readable on mobile; no blowouts |
| Editorial typography | Flutter owns hierarchy — engraved titles, calm body |

**Mix discipline (UI):** ~70% dark calm · ~20% violet/navy · ~10% antique gold  
See `OraclyArtDirection` — do not exceed gold fill / glow caps without cause.

**Motion:** invisible weight (`OraclySignatureMotion`) — never spectacle for its own sake.

**One universe:** one glass family, one press language, one chamber darkness — feature identity changes **subject and warmth**, not chrome grammar.

---

## One universe, distinct chambers

| Rule | Meaning |
|------|---------|
| Shared DNA | Palette, light, materials, type, gold restraint |
| Distinct identity | Subject, ritual warmth, hero metaphor |
| No second language | No competing Material skins, neon themes, or flat illustration packs |

If removing a chamber’s hero image would leave a screen that could belong to another product → identity is too weak.  
If a chamber invents a new chrome grammar → consistency has broken.

---

## Realistic image rule (major assets)

Major image assets **MUST** be photorealistic.

### Reject immediately

- Illustration · vector · cartoon · anime  
- Flat fantasy · generic 3D render · mobile-game art  
- Plastic human faces · fake anatomy · AI-looking hands  
- Neon magic overlays as decoration · baked UI chrome in pixels  

### Accept

- Photoreal / cinematic / editorial frames  
- Physically believable materials and light  
- Feature-clear subject **without** on-image titles  

**Exception:** small functional UI icons may stay simple line art under `lib/assets/icons/`.  
**Exception:** Tarot deck IP briefs live under `features/tarot_art/` — they still obey Global DNA (materials, light, no baked UI text) and must feel like the same sanctuary.

---

## Feature visual identities

| Feature | Must feel like |
|---------|----------------|
| **Home** | Cinematic entrance into ORACLY |
| **Coffee** | Warm Turkish coffee ritual — real cup, steam, candlelight |
| **Palm** | Real human hand — dark velvet, warm directional light |
| **Astrology** | Luxury astronomical observatory — real celestial instrument, realistic stars |
| **Yıldızname** | Ancient celestial archive — real brass / stone / wood, deep mystical atmosphere |
| **Tarot** | Real physical premium deck — real paper, velvet, candlelight |
| **SoulMate** | Cinematic real portrait — natural anatomy, romantic but sophisticated |
| **OR** | Minimal living intelligence — **not** a giant orb, **not** a mascot |
| **Profile** | Private cinematic journal |
| **Premium** | Luxury private chamber / premium artifact |

Chamber tints (coffee warmth, palm velvet, observatory cool) are **multipliers on shared darkness** — never a new brand.

---

## Image text rule

Never bake into major images:

- Title · logo · CTA · body text · feature name · badges · watermarks  

**Flutter renders all text** — including empty/error/loading copy and CTAs.

---

## Layout & readability (visual, not feature)

- Stable hero slots: `AspectRatio` / fixed height + `BoxFit.cover`  
- Bottom navigation and safe areas must **never** cover CTAs or last list rows  
- No distorted stretch; faces/hands cropped with editorial intent  
- Awkward empty voids without atmospheric plate or calm copy → fail empty/error gates  

---

## Quality gate (every major asset)

Must pass **all**:

1. **Photorealism** — photographed / film still, not AI illustration  
2. **Material realism** — believable surfaces and contact  
3. **Lighting** — ORACLY DNA (antique gold + midnight/violet darkness)  
4. **Composition** — clear hero; readable at phone width  
5. **Brand consistency** — same sanctuary as Home  
6. **Feature distinction** — identity clear without baked text  

If it looks like an AI illustration mockup → **REJECT**.

### Cinema test

Could this be a frame from a premium cinematic film?  
**No** → regenerate. Do not ship “good enough.”

---

## Engineering coupling

1. QC against this system + [PHOTOREALISTIC_ART_STANDARD.md](./PHOTOREALISTIC_ART_STANDARD.md)  
2. Master → `art_masters/<feature>/` (not shipped)  
3. `python tool/oracly_image_pipeline/optimize_asset.py …`  
4. Register in `AppAssets` + `pubspec`  
5. Wire with stable layout; Flutter owns copy  
6. Optional: `python tool/oracly_image_pipeline/audit_runtime.py`  

Roles: `hero_wide` · `hero_tall` · `discovery_tile` · `plate_square` · `backdrop` · `banner` · `thumb`

---

## Governance

| Layer | Owns |
|-------|------|
| **This doc** | Global DNA, feature identities, reject rules, gates |
| Photoreal Art Standard | Detailed forbidden list, people/anatomy, data honesty |
| Image Asset Pipeline | Master → runtime path, roles, audits |
| `OraclyArtDirection` / `OraclyChrome` | Runtime color/glow/radius discipline |
| Feature UI | Composition within DNA — no new visual language |

Previous systems remain intact: empty atmospheres, cinematic errors, loading cinema, brand mark, chamber transitions — they must **obey** this DNA, not invent another.

---

## Final scorecard (system)

| Gate | Criterion |
|------|-----------|
| GLOBAL ART DNA | Shared palette, light, materials, type locked |
| PHOTOREALISM | Major assets must be photoreal; illustration rejected |
| FEATURE DISTINCTION | Each chamber has a clear subject identity |
| CONSISTENCY | One chrome/universe; no random styles |

Live screenshots must still be audited against these gates before shipping art changes.
