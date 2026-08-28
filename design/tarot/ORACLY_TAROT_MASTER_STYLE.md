# ORACLY Tarot — Master Style Guide

**Status:** Canonical visual DNA · v1.0  
**Feeling to protect:** a private midnight tarot ritual  
**Screen implementation:** not in this task  

Spine: **Draw → Pause → Reflect → Return**

This document is the visual foundation for the entire Tarot product. Cards, card back, icons, atmosphere, and later UI all obey it. It extends the existing ORACLY universe — it does not invent a second one.

Canonical code tokens:

- Color / mix: `OraclyArtDirection`, `AppColors`, `OraclyChrome`
- Type: `AppTypography` (Cormorant Garamond + Inter), `ReadingTypography`
- Motion: `OraclySignatureMotion`
- Illustration pipeline: `features/tarot_art/` (subordinate to this file)

---

## 1. North star

ORACLY Tarot must feel:

| Must | Because |
|------|---------|
| Ancient | The object feels older than the phone |
| Mysterious | Meaning is invited, never shouted |
| Premium | Materials look handmade, not themed |
| Cinematic | Light has a direction and a temperature |
| Intimate | One person, one table, midnight |
| Intelligent | Symbols are quiet and considered |
| Modern | Editorial, not costume medieval |

It must **not** feel:

| Forbidden | Why it fails |
|-----------|----------------|
| Cheap fortune app | Plastic gold, fake gems, countdown energy |
| Rider-Waite clone | Instantly dated; not ours |
| Neon occult game | Bright saturation, HUD, spectacle |
| Horror UI | Fear is not ORACLY |
| Cartoon tarot | Breaks sanctuary |
| Stock illustration | Generic, forgettable |

Recognition test (2 seconds, no logo):

> This is a quiet room at midnight. Someone laid down a card. The gold is old. I want to stay.

If the answer is “beautiful app” or “cool occult game,” the frame is too loud.

Disappearance test: if removing a glow, particle, or ornament does not make the ritual worse, remove it.

---

## 2. Color

Mix (locked with product chrome): **70% near-black · 20% violet/navy · 10% antique gold.**

### Primary

| Name | Hex | Role |
|------|-----|------|
| Near-black | `#04030A` | Chamber fill. Always first paint. |
| Obsidian | `#030106` | Card field, plaque, deepest shadow |
| Midnight navy | `#0A0914` | Upper haze, distance |
| Deep violet | `#4A36B0` | Atmosphere only, never a fill block |
| Antique gold | `#E7C56D` | Engraving, titles, selected edge |
| Warm cream | `#F0E6D8` | Reading body, star motes |

### Gold family (never flat yellow)

| Name | Hex | Role |
|------|-----|------|
| Gold light | `#F5D98A` | Specular streak, upper-left bevel |
| Gold | `#E7C56D` | Mid metal |
| Gold deep | `#C9A84E` | Recessed edge |
| Gold groove | `#9A7420` | Engraved shadow (illustration / frame only) |

### Secondary accents (whisper only)

| Name | Hex | Max use |
|------|-----|---------|
| Muted burgundy | `#5C2A38` | Cloth lining, dried petal, Cups warmth |
| Deep indigo | `#1A1630` | Cool shadow, Swords night |
| Subtle amber | `#C48A3A` | Candle core, never a button fill |
| Moon silver | `#C8C2D4` | Cool rim, moon metal — ≤ 4% of a card |
| Crystal whisper | `#A8E8FF` | One facet of a crystal only, 8–15% |

### Forbidden color

- Neon pink, electric cyan, lime, pure `#FFD700`
- Saturated purple fills (`#9B6DFF` as atmosphere — too game-like)
- Pure black `#000000` as a large field
- Stark white `#FFFFFF` as body text on midnight (use cream)

Gold fill on UI ≤ 10% of the screen. Gold glow α ≤ 0.22. Violet glow α ≤ 0.16.

---

## 3. Material language

The product is an **object in a dark room**, not a UI skin.

| Material | How it looks | How it fails |
|----------|--------------|--------------|
| Velvet void | Soft, light-absorbing, slight pile at edges | Plastic matte, poster black |
| Antique gold | Aged, engraved, highlight + groove together | Flat yellow stroke, emoji gold |
| Paper / fiber | Barely visible laid texture, 2–4% | Obvious parchment overlay, tea-stain |
| Candlelight | Warm, small, directional | Studio HDR, lens-flare sun |
| Cosmic dust | Few cream/gold motes, almost still | Particle fountain, snow, sparkles |
| Deep shadow | Indigo-violet, readable silhouette | Crushed black, horror vignette |

Gold treatment (mandatory):

1. Highlight `#F5D98A` on the light side  
2. Mid `#E7C56D`  
3. Groove `#9A7420` in the cut  
4. Optional 1% directional micro-scratch, upper-left  
5. Never a single flat gold hex

Crystal: 3–5 facets, one cool whisper, satin — not jewelry-store neon.

---

## 4. Line weight

| Kind | Weight | Opacity | Use |
|------|--------|---------|-----|
| Construction | 0.35 px | 8–12% | Hidden octagon, meridians |
| Hairline | 0.50 px | 0.22 | Frame inner edge, veil ring |
| UI gold edge | 1.0 logical px | 0.32 default / 0.48 emphasis | Cards, buttons, plaques |
| Engraved motif | 1.0–1.25 px | 0.40–0.70 | Keys, moons, vesica |
| Forbidden | ≥ 3 px gold bar | — | Cheap fortune chrome |

Corners of frames are filigree, not rounded-rect stickers. Side rails stay quiet: illustration is the hero; ornament ≤ ~18% of attention.

---

## 5. Typography

Locked families (already in `AppTypography`):

| Role | Family | Feeling |
|------|--------|---------|
| Headings, card names, ceremonial labels | **Cormorant Garamond** | Editorial serif, intimate, old paper |
| Body, UI, interpretation | **Inter** | Calm, modern, high readability |

| Use | Recipe | Size | Tracking | Color |
|-----|--------|------|----------|-------|
| Chamber title | `OraclyChrome.engravedTitle` | 13–15 | ~2.8 | gold 0.94 |
| Card name | Serif, title case | 20–24 | **1.2–1.6** | cream or gold light |
| Section label | `ReadingTypography.sectionLabel` | 11–12 | **2.2** | gold light 0.86–0.90 |
| Reading body | `ReadingTypography.body` | 15.5–18 | 0.14 | cream 0.88–0.94 |
| Reflection | `ReadingTypography.reflection` | body | italic | cream muted |
| Closing | `ReadingTypography.closing` | body | italic | muted |
| Numerals on cards | Small serif or engraved | discreet | wide | gold 0.70 |

Card names: ceremonial, spaced, **confident Title Case**.  
Example: `The High Threshold` — not `THE HIGH THRESHOLD`, not `the high threshold`.

Avoid ALL CAPS except short engraved labels (≤ 14 letters), already used for chamber titles.

Line-height for long reading: **1.76**. Paragraph gap: `CraftsmanshipRhythm.paragraphGap`. No ellipsis on the reading itself.

---

## 6. Lighting

Illustration and UI share one candle.

| Light | Spec |
|-------|------|
| Key | Upper-left ~40°, **2900K**, champagne gold, never a spotlight cone |
| Fill | Lower-right, cool indigo/violet, **≤ 16%** |
| Rim | Thin gold or moon-silver on the hero silhouette |
| Bloom | ≤ 8% — felt in the eye, not a glow layer |
| God-rays | Optional, ≤ 6%, almost absent. Prefer still air. |
| Shadows | Deep indigo, not pure black; faces stay readable |

No overexposure. No horror under-lighting. No RGB neon rims.

UI: no extra light engines. Chamber atmosphere uses existing universe multipliers (moon, ritual time) — opacity and warmth only.

---

## 7. Background treatment

Paint back-to-front. One ambient. No second sky.

1. Fill `#04030A`  
2. Soft vertical haze: navy above, violet-black mid (α 0.18–0.32)  
3. Restrained star field — tiny cream dots, low density, **not a looping animation**  
4. Optional gold geometry (vesica, meridian ticks) α ≤ 0.22  
5. Optional fiber grain 2–4%  
6. Content  
7. Existing floating chrome (header, nav)

Do not add giant purple orbs, stacked identical glass, or a second particle system.

Illustration backgrounds (on the card, inside the frame):

- Dreamlike depth, 4 planes minimum  
- 15% negative space  
- Ancient quiet architecture or open night — not a video-game vista  
- Nebula only as distant color, never as the subject  

---

## 8. Card illustration rules

Full motif list: [`MOTIFS.md`](MOTIFS.md). Fence: [`ORIGINALITY.md`](ORIGINALITY.md).

### What a card is

A **single cinematic still** of a figure or emblem in the ORACLY night. It is not a poster, not a comic panel, not a reprint of any published deck.

### Hard rules

- Original compositions only. No tracing, no “in the style of Rider-Waite.”  
- Paint **illustration window only**. No title, numeral, logo, or frame inside the painting. Frame is composited.  
- One hero. Strong silhouette. Centered with breath.  
- Same artist, same realm, same light vector for all 78.  
- Faces: calm intelligence. No scream, no wink, no pin-up.  
- Hands: anatomically honest. Gesture of offering, pause, or holding a motif — never claw or devil-horn.  
- Clothing: velvet, linen, embroidered gold thread. No latex, no armor-fantasy overload.  
- Magic: dust and quiet geometry. Never lightning, fireballs, or HUD runes.  
- Text in image: none, except diegetic engraving at ≤ 3% opacity.

### Suit climate (accent only, mix still 70/20/10)

| Suit | Whisper |
|------|---------|
| Major | Universal — vesica, moon, key |
| Wands | Subtle amber ember in cloth or dust |
| Cups | Muted burgundy lining, still water |
| Swords | Cooler indigo air, moon silver edge |
| Pentacles | Warm earth gold in objects, never green neon |

### Quality

Collector still, not 8K spectacle checklist. Prefer fewer perfect materials over “every hair strand.” If detail fights intimacy, reduce detail.

---

## 9. Icon rules

Icons in Tarot UI are **engraved marks**, not emoji and not Material occult.

- Stroke 1.25 px, antique gold or cream 0.70  
- Optical size 18–20 px in a 36–44 px well  
- Motifs only from [`MOTIFS.md`](MOTIFS.md)  
- No filled neon glyphs, no 3D crystal icons, no skulls  
- Selected state: gold 0.94, unselected: cream 0.45 — same as product nav  
- One motif per icon. Do not stack moon + eye + key.

---

## 10. Animation rules

Reuse `OraclySignatureMotion`. Do not invent a Tarot motion language.

| Token | Value |
|-------|-------|
| Press scale | 0.982 |
| Press opacity | 0.96 |
| Press | 220 ms |
| Release | 280 ms |
| Reveal pause | ~420 ms weighted stillness before meaning |

Rules:

- Users remember the pause, not the flip.  
- One ambient atmosphere per screen. Star field is wall-clock, not a perpetual loop.  
- Shuffle: slight desync / micro-imperfection (EPIC-008). Never metronome.  
- Particles: illustration ≤ 14; UI overlay ≤ 8.  
- No bounce, no sparkle-on-tap, no streak counters, no game XP flashes.  
- 60 FPS. Ambient isolated from reading rebuilds (RC-001).

---

## 11. UI atmosphere

When the Tarot chamber is implemented later, it is **the same sanctuary** as Home, Coffee, Astrology.

| Do | Don’t |
|----|-------|
| Existing header (back, engraved title, gem) | A new tarot HUD |
| `OraclyGoldButton`, crystal frames, glass cards | Second button style |
| Reading hierarchy: identity → core → depth → reflection → close | Walls of mystic jargon |
| Transparency footnote | Fortune-telling certainty |
| Chamber tint via universe multipliers only | Redesign Home or navigation |

Emotional sequence (RC-001): Presence → Wonder → Understanding → Peace.

Copy tone: observational, warm, never predictive (EPIC-013).

---

## 12. Card-back design principles

Full spec: [`CARD_BACK.md`](CARD_BACK.md).

The back is the object the user trusts before meaning. It must look like **one artifact**, identical in a spread, original, and quiet.

- Same gold frame language as the face (Vesica Compass, obsidian field, OR Lattice primitives)  
- Center: **Midnight Vesica** + **Threshold Key** or **Celestial Circle** — never a face illustration  
- Velvet field, fiber 3%, constellation fragment α ≤ 0.12  
- Symmetric at arm’s length; 2% micro-imperfection up close  
- No logo wordmark, no inverted scene, no zodiac wheel copy  

---

## 13. Originality

We do not copy Rider-Waite-Smith, Thoth, Marseille, or any commercial deck.  
See [`ORIGINALITY.md`](ORIGINALITY.md) for the full fence and the original motif set.

---

## 14. Implementation later (not now)

Do **not** build the Tarot screen from this document in this task.

When implementation is explicitly requested:

1. Reuse chrome, type, motion, glass  
2. Composite locked frames with original illustrations  
3. Keep files small; screens orchestrate, widgets render  
4. `flutter analyze` clean  

---

## 15. Acceptance

MASTER STYLE passes if:

- [x] Colors, type, line, gold, light, background, illustration, icons, motion, UI, card back are specified  
- [x] Mix 70/20/10 matches `OraclyArtDirection`  
- [x] Feeling is midnight ritual, not neon occult  
- [x] Originality fence is explicit  
- [x] No Tarot screen was implemented in this pass  

**MASTER STYLE: PASS**
