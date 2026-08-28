# ORACLY — Photorealistic Art Standard

**Status:** Permanent · Applies to every new major image asset without explicit exception  
**Parent:** [Global Visual Quality System](./GLOBAL_VISUAL_QUALITY_SYSTEM.md) · [Master Directive](./MASTER_DIRECTIVE.md) · [Development Charter](./DEVELOPMENT_CHARTER.md) · [PRINCIPLE-001](./PRINCIPLE-001.md) · [AI Agent Guide](./AI_AGENT_GUIDE.md)  
**Code chrome (UI glow/mix):** `lib/core/design_system/oracly_art_direction.dart`  
**Image pipeline (master → runtime → thumb):** [PHOTOREALISTIC_IMAGE_ASSET_PIPELINE.md](./PHOTOREALISTIC_IMAGE_ASSET_PIPELINE.md)  
**Version:** 1.1

---

## North star

ORACLY imagery must feel like a **premium cinematic product** — editorial photography and film stills — never like an AI mobile-app mockup, fortune illustration pack, or game UI.

Defer shared DNA, feature identities, and governance hierarchy to [GLOBAL_VISUAL_QUALITY_SYSTEM.md](./GLOBAL_VISUAL_QUALITY_SYSTEM.md). This file is the **detailed art rejection / acceptance standard**.

**PASS:** luxury campaign / streaming-service key art  
**FAIL:** illustrated, vector, cartoon, plastic CGI, cheap fantasy poster

---

## Required for every major asset

| Requirement | Meaning |
|-------------|---------|
| Photorealistic | Believable as a photograph or film capture |
| Cinematic | Controlled depth, atmosphere, single-scene composition |
| Editorial | High-end restraint — quiet luxury, not spectacle |
| Physically believable | Real materials, light, shadow, contact, haze |
| Real materials | Brass, glass, velvet, ceramic, paper, wood, skin — with micro-variation |
| Real light | Primary warm source + soft fill + deep shadow; no neon blowouts |
| Real depth | Atmospheric perspective; subject hierarchy clear |

**Shared ORACLY DNA (all features):**

- Near-black · midnight navy · deep violet · antique gold · warm ivory
- Lighting discipline (low-key, antique gold rim, controlled highlights)
- Realistic materials + cinematic depth · controlled contrast · editorial type in Flutter

**No text, logos, feature names, or watermarks inside generated images.** Flutter renders all UI copy.

---

## Strictly forbidden

- Illustration · vector · cartoon · anime · flat icon
- Flat fantasy · generic 3D render · mobile-game art · cheap fantasy art
- Plastic-looking people · fake skin · fake hands · unrealistic anatomy
- AI-looking eyes · floating objects · random mystical symbols
- Emoji · medical diagrams · glowing neon palm/zodiac overlays as “decoration”
- Decorative planet placement presented as scientific ephemeris
- Giant OR mascot or cartoon orb as primary chamber hero

---

## Feature identity (shared direction, distinct subject)

| Surface | Must look like |
|---------|----------------|
| **Home** | Cinematic entrance to the ORACLY universe |
| **Coffee** | Warm Turkish coffee ritual — real cup, steam, candlelight |
| **Palm** | Real human hand — dark velvet, warm directional light |
| **Astrology** | Luxury astronomical observatory — real instrument, realistic stars |
| **Yıldızname** | Ancient celestial archive — brass / stone / wood |
| **Tarot** | Real physical premium deck — paper, velvet, candlelight |
| **SoulMate** | Cinematic real portrait — natural anatomy, romantic but sophisticated |
| **OR** | Minimal living intelligence — not a giant orb, not a mascot |
| **Profile** | Private cinematic journal |
| **Premium** | Luxury private chamber / premium artifact |

---

## People & anatomy

When a human is present:

- Natural skin texture, proportions, hair, eyes, clothing
- Photoreal silhouette or portrait as required by the scene
- Celestial / instrument systems stay primary when both appear

Never: plastic CGI perfection, distorted hands, extra fingers, floating hair, invented faces for user avatars (real photo or ORACLY emblem only).

---

## Data honesty (visual)

- Do not invent astronomical positions or fake “scan percentages”
- Symbolic instrument design is allowed; scientific placement is not, unless real data exists
- User photos (palm, coffee, etc.) remain the result hero when captured — do not replace with generic art

---

## Engineering coupling

- Follow [PHOTOREALISTIC_IMAGE_ASSET_PIPELINE.md](./PHOTOREALISTIC_IMAGE_ASSET_PIPELINE.md): master in `art_masters/` → optimized WebP runtime → optional thumb
- Register paths in `AppAssets`; prefer WebP under `lib/assets/images/…`
- Stable layout: `AspectRatio` / fixed slots + `BoxFit.cover` — no jump after decode
- Titles, dates, CTAs, readings: Flutter only
- Bottom nav / safe area must never cover art CTAs or last content
- Run `python tool/oracly_image_pipeline/audit_runtime.py` before shipping large new sets

---

## Quality gate (before shipping art)

1. Would a luxury brand campaign use this frame?
2. Does it look photographed — not illustrated?
3. Does it share ORACLY light/gold/violet discipline with other chambers?
4. Is feature identity still clear without on-image text?
5. Does the Home/feature screenshot feel like a **premium cinematic product**?
6. **Cinema test:** Could this be a frame from a premium cinematic film? **No** → regenerate. Do not accept “good enough.”

Any **no** → regenerate or reject. Do not ship illustration substitutes.

### Zero illustration enforcement

Major visual assets must be **100% photorealistic**. Forbidden for majors: illustration, vector scenes, cartoon, anime, flat graphic, 3D mascot, fantasy game art, generic AI app art, baked UI text.

**Exception:** small UI icons may remain simple vector line art (`lib/assets/icons/`).
