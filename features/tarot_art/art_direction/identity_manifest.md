# ORACLY Tarot — Identity Manifest

## Deck Name
**ORACLY Tarot** (internal codename: `oracly_tarot_v1`)

## Recognition Test
A card passes identity if an viewer unfamiliar with other tarot decks can answer:
- "This looks expensive and mystical"
- "This belongs to the same app as the purple/gold OR orb"
- "This is NOT a classic tarot reprint"

## Visual DNA (ordered by priority)

**Illustration master style:** [`MASTER_STYLE.md`](MASTER_STYLE.md) — permanent artistic DNA for all 78 cards.

1. **Void + Purple Atmosphere**
2. **Ceremonial Gold Frame**
3. **Cinematic Single-Source Light**
4. **Crystalline OR Energy**
5. **Sacred Geometry (subtle)**
6. **Element Accent (suit-specific)**
7. **Restrained Particle Field**

## Visual DNA (OR-1330 Frame Lock)

| Signature | Description |
|-----------|-------------|
| **Vesica Compass** | Top center navigation sigil — replaces oval gem |
| **Obsidian Name Plaque** | Slim engraved crystal title plate (empty in lock) |
| **OR Lattice** | Seven proprietary primitives — see `ORACLY_VISUAL_DNA.md` |
| **Oracle Veil Ring** | 4–7% inner energy membrane |
| **Harmonic Meridian Grid** | Corner-unifying golden threads |

## Forbidden Elements

- Rider-Waite composition clones
- Pamela Colman Smith / Waite-Smith iconography
- Marseille pattern copies
- Thoth / Crowley symbolism
- Stock photo compositing
- Flat vector tarot style
- Daylight outdoor stock lighting
- Comic/anime line art
- Text inside illustration area (except diegetic runes at ≤3% opacity)
- Watermarks, signatures visible in production crop

## Original Symbol Ownership

All sigils, frames, and emblems are **ORACLY IP**. Document new symbols in card brief before production.

## App Alignment

Pipeline palette syncs with Flutter tokens in `lib/core/theme/app_colors.dart`. Card art may exceed UI saturation inside illustration zone only; frame must match palette exactly.
