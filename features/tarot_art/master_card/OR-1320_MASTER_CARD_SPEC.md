# ORACLY Tarot — Master Card Design Specification
**Document ID:** OR-1320  
**Version:** 1.1 (frame amended by OR-1330)  
**Status:** Approved Production DNA  
**Frame Lock:** [`OR-1330_FRAME_LOCK_REVISION.md`](OR-1330_FRAME_LOCK_REVISION.md)  
**Visual DNA:** [`../art_direction/ORACLY_VISUAL_DNA.md`](../art_direction/ORACLY_VISUAL_DNA.md)  
**Authority:** Supersedes all informal card layout notes; subordinate only to OR-1300 Art Direction  
**Pipeline:** OR-1310  
**Scope:** Single immutable blueprint — all 78 cards + card back derive from this document  

---

## 0. Purpose

This specification defines the **visual DNA of one master ORACLY Tarot card**. Every card in the deck is a variation of this blueprint: same frame, same zones, same lighting physics, same ornament grammar, same finish — only the central illustration and swappable metadata (numeral, title, sigils) change.

**Goal:** A collector holding any two cards instantly sees they belong to the same luxury deck, painted by one hand, in one universe.

**Constraints:** No Rider-Waite references. No third-party tarot artwork. No AI placeholder images in repo. This is a production specification only.

---

## 1. Master Card Identity

### 1.1 The Blueprint Concept

The ORACLY Master Card is a **Sacred Artifact Frame** containing a **Living Oracle Window**:

- **Frame** = dark mystical metal + ancient gold + crystal inlays (locked, identical on every card)
- **Window** = original digital painting (unique per card)
- **Seal** = typography + sigils (swappable within fixed positions)

### 1.2 Recognition DNA (Instant ID)

| Priority | Signature |
|----------|-----------|
| 1 | Deep cosmic void ground — never flat |
| 2 | Ceremonial gold double-border with hex geometry |
| 3 | Upper-left cinematic key light + gold rim |
| 4 | OR purple volumetric magic (`#9B6DFF`) |
| 5 | Faceted crystal highlights |
| 6 | Symmetric filigree — restrained, never baroque clutter |
| 7 | **Vesica Compass** centerpiece + **OR Lattice** (OR-1330) |

### 1.3 Frame-Only Recognition (OR-1330)

Empty locked frame must be instantly ORACLY. See [`OR-1330_FRAME_LOCK_REVISION.md`](OR-1330_FRAME_LOCK_REVISION.md) and [`ORACLY_VISUAL_DNA.md`](../art_direction/ORACLY_VISUAL_DNA.md).

---

## 2. Card Dimensions

### 2.1 Canvas Sizes

| Tier | Width | Height | DPI | Use |
|------|-------|--------|-----|-----|
| **Master** | 1024 px | 1792 px | 144 | Archive, recomposite, print future |
| **Production** | 512 px | 896 px | 72 | App runtime (authoritative) |
| **Thumbnail** | 256 px | 448 px | 72 | History, grids |

### 2.2 Aspect Ratio

| Property | Value |
|----------|-------|
| **Ratio** | **512 : 896** (simplified: **32 : 56** or **4 : 7**) |
| **Decimal** | **0.5714285714** |
| **Standard name** | Tarot portrait (2 × 3.5 proportion) |

All exports must maintain exact ratio. No crop-to-fit. No letterboxing in final delivery.

### 2.3 Corner Radius

| Scale | Outer radius | Inner illustration clip |
|-------|--------------|---------------------------|
| Production (512×896) | **12 px** | **10 px** (inside velvet inset) |
| Master (1024×1792) | **24 px** | **20 px** |

Corner arcs are circular — no superellipse deviation.

### 2.4 Frame Thickness (Total Border System)

Total frame occupies **12% of card width** (61 px per side @ production).

| Layer | Production px | Master px | % of width |
|-------|---------------|-----------|------------|
| Outer bevel (gold) | 2 | 4 | 0.4% |
| Dark gutter | 4 | 8 | 0.8% |
| Filigree band | 8 | 16 | 1.6% |
| Velvet inset | 3 | 6 | 0.6% |
| Side rail (combined) | 61 | 122 | 12.0% |

**Frame thickness (visual mass):** 17 px from outer edge to illustration bleed (production).

### 2.5 Border Width (Gold Line Weights)

| Element | Stroke (production) | Color |
|---------|---------------------|-------|
| Outer bevel highlight | 2 px gradient | `#F0D77A` → `#D4AF37` |
| Outer bevel shadow | 1 px | `#9A7420` |
| Inner filigree primary | 1.0 px | `#D4AF37` |
| Inner filigree secondary | 0.5 px | `#9A7420` |
| Nameplate top rule | 1 px | `#D4AF37` |
| Hex cartouche double line | 1 px + 1 px gap | `#D4AF37` |

### 2.6 Safe Area

**Outer safe (full card):** 512 × 896 — nothing clipped at display.

**Illustration safe zone (paintable):**

| Edge | Production inset | Master inset |
|------|------------------|--------------|
| Top | 72 px (below numeral zone) | 144 px |
| Bottom | 215 px (above bottom zone) | 430 px |
| Left | 31 px | 62 px |
| Right | 31 px | 62 px |
| **Paintable area** | **450 × 609 px** | **900 × 1218 px** |

**Critical detail safe (inner):** Additional 12 px padding inside paintable area — no faces, hands, or focal symbols in this margin.

### 2.7 Decoration Zones (Normalized)

```
┌─────────────────────────────────────────────────────────────┐
│ ZONE A — ROMAN NUMERAL          (y: 0.000 – 0.080)          │
│   Height: 72 px @ production                                │
├─────────────────────────────────────────────────────────────┤
│ ZONE B — TOP TRANSITION         (y: 0.080 – 0.100)          │
│   Filigree bridge, 10 px                                      │
├──────────┬──────────────────────────────────────┬───────────┤
│ ZONE C   │ ZONE D — ILLUSTRATION                │ ZONE C    │
│ SIDE     │ (x: 0.061 – 0.939, y: 0.100 – 0.680) │ SIDE      │
│ RAIL     │ Height: 521 px, Width: 450 px          │ RAIL      │
│ 6% w     │                                      │ 6% w      │
├──────────┴──────────────────────────────────────┴───────────┤
│ ZONE E — BOTTOM ORNAMENT        (y: 0.680 – 0.720)          │
│   Height: 36 px                                               │
├─────────────────────────────────────────────────────────────┤
│ ZONE F — NAMEPLATE + TITLE      (y: 0.720 – 0.920)          │
│   Height: 179 px                                              │
├─────────────────────────────────────────────────────────────┤
│ ZONE G — BOTTOM EDGE + SIGILS    (y: 0.920 – 1.000)          │
│   Element symbols, 36 px                                      │
└─────────────────────────────────────────────────────────────┘
```

| Zone | ID | Locked | Swappable content |
|------|-----|--------|-------------------|
| A | `roman_numeral_area` | Cartouche yes | Numeral text |
| B | `top_transition` | Yes | — |
| C | `side_rails` | Yes | Arcana markers |
| D | `illustration_area` | Clip yes | **Unique art** |
| E | `bottom_ornament_area` | Yes | — |
| F | `title_area` | Nameplate yes | Title text |
| G | `element_sigil_area` | Position yes | Suit sigil |

---

## 3. Frame Design — Premium Luxury Frame

### 3.1 Design Intent

The frame must feel like **dark mystical metal** forged in the OR Realm, inlaid with **ancient gold** and **faceted crystal** — a museum relic, not costume jewelry. **Elegant symmetry. Nothing excessive.**

### 3.2 Material Stack (Outside → Inside)

#### Layer 1 — Outer Bevel (Dark Mystical Metal)
- Base: `#0A0812` with subtle cool purple undertone
- Micro-texture: brushed obsidian, 2% noise
- Top-left catch: `#4A4560` at 8% opacity (metal glint)
- Bottom-right recess: `#030106`

#### Layer 2 — Dark Gutter
- Solid: `#060410`
- Width: 4 px (production)
- Purpose: visual separation — frame floats above illustration

#### Layer 3 — Golden Ornament Band (Ancient Gold)
- Primary filigree: flowing Art Nouveau curves terminating in **crystal nodes**
- Gold material: brushed ceremonial (see §3.3)
- Engraving: micro-dot pattern, 0.5 px spacing, `#9A7420` in grooves
- **Sacred geometry:** hex lattice at 3% opacity beneath filigree

#### Layer 4 — Crystal Inlay Strip
- 1 px row of faceted crystal reflections at filigree inner edge
- Colors: `#B794FF`, `#F0D77A`, `#FFFFFF` — each facet ≤1 px
- Reflection angle consistent with upper-left key light

#### Layer 5 — Velvet Inset
- Color: `#12071F`
- Width: 3 px
- Matte — absorbs light, creates jewel-box effect for illustration

### 3.3 Gold Material Recipe (Frame Only)

| Property | Value |
|----------|-------|
| Highlight | `#F0D77A` — specular streak, 35% opacity |
| Mid | `#D4AF37` |
| Shadow | `#9A7420` |
| Patina in grooves | 5% darker than mid |
| Finish | Brushed ceremonial — NOT mirror chrome |
| Reflection source | Upper-left 45° |

### 3.4 Corner Design

Each corner contains:
1. **Quarter-arc filigree** — 90° sweep, 18 px radius (production)
2. **Diamond node** — 4 px rotated square at corner apex
3. **Celestial micro-engraving** — 3 tiny star points (0.5 px) radiating from node

Corners are **perfect mirror** — top-left reflects to top-right, etc.

### 3.5 Sacred Geometry (Frame-Embedded)

- **Hex cartouche** at top center (numeral housing)
- **Vesica piscis** faint watermark behind side-rail arcana markers (2% opacity)
- **Concentric circles** at corner nodes (1 px stroke, `#D4AF37` at 20%)

Geometry never competes with illustration — frame geometry ≤4% total visual weight.

### 3.6 Symmetry Rules

- Vertical axis: perfect mirror for frame elements
- Illustration: asymmetric allowed
- Ornament density: max 1 focal corner accent per side — no competing clusters

### 3.7 Premium Finish on Frame

- +15% gloss pass on gold only (Layer L20)
- Crystal inlays: +25% specular vs gold
- Dark metal: matte-satin (no gloss)

---

## 4. Background Design (Illustration Interior)

### 4.1 Absolute Rule

**The background must never be flat.** Even the darkest card contains depth, atmosphere, and light history.

### 4.2 Mandatory Background Layers (Minimum 4)

| Layer | Content | Opacity range |
|-------|---------|---------------|
| 1 — Deep base | Radial gradient `#030106` center → `#12071F` edge | 100% |
| 2 — Cosmic wash | Nebula blob, suit/element tinted | 8–18% |
| 3 — Volumetric fog | Purple-grey fog pocket mid-ground | 10–20% |
| 4 — Celestial | Stars (3–12 points) OR distant nebula grain | 15–35% per star |
| 5 — Ancient light | Single faint god-ray or horizon glow | 5–12% |

### 4.3 Gradient Specification

```
Type: radial + linear composite
Radial center: (0.45, 0.35) — offset toward key light
Radial colors: #030106 (0%) → #0B0615 (55%) → #12071F (100%)
Linear overlay: #1A0B2E at 6% from bottom — grounds composition
```

### 4.4 Volumetric Fog

- Color: `#6B4BC4` at 12% + element accent at 4%
- Soft gaussian falloff — no hard fog edges
- Always between subject and deepest background

### 4.5 Stars & Nebula

| Element | Spec |
|---------|------|
| Star size | 0.5–1.5 px (production) |
| Star count | 3–12 per card |
| Twinkle | Optional 2–3 stars at 2 brightness levels |
| Nebula | Soft blob, blurred 40+ px equivalent, never sharp |

### 4.6 Ancient Light

- One directional warmth source matching key light
- Suggests age, temple light, or cosmic dawn
- Never full daylight — always twilight or interior cosmic

### 4.7 Crystal Reflections (Background)

- 0–3 floating micro-shards in deep background (blurred)
- Internal glow: element or OR purple
- Scale: 2–8 px — never compete with subject crystals

### 4.8 Forbidden Backgrounds

- Pure `#000000` field >2% canvas
- Flat single-color fill
- White or grey studio backdrop
- Photographic sky stock

---

## 5. Lighting System

All cards share **one lighting rig**. Category rules modify intensity, not direction.

### 5.1 Primary Light (Key)

| Property | Value |
|----------|-------|
| Direction | **Upper-left, 45°** |
| Color | Warm gold-white `#FFF4E0` |
| Temperature | 3200K |
| Character | Soft sun through temple window |
| Purpose | Define form, cast primary shadows |

### 5.2 Secondary Light (Fill)

| Property | Value |
|----------|-------|
| Direction | **Lower-right, 15° above horizon** |
| Color | Cool purple `#6B4BC4` |
| Temperature | 8000K |
| Intensity | **15% of key** |
| Purpose | Lift shadows — never eliminate them |

### 5.3 Rim Light

| Property | Value |
|----------|-------|
| Direction | Behind subject, offset key 30° |
| Color | `#F0D77A` gold |
| Width | 1–3 px edge (production scale) |
| Opacity | 40–70% on subject silhouette |
| Purpose | Separate subject from background — **mandatory on all figurative cards** |

### 5.4 Magic Glow

| Property | Value |
|----------|-------|
| Source | Subject artifact, hands, or OR crystal |
| Core color | Element accent OR `#9B6DFF` |
| Falloff | Inverse square, soft — volumetric |
| Bloom radius | 8–24 px (production) |
| Opacity core | 25–45% |
| Opacity edge | 0% |

### 5.5 Shadow Balance

| Zone | Value |
|------|-------|
| Deepest shadow | `#030106` with `#12071F` undertone — **never pure black** |
| Mid shadow | 40% brightness of local color |
| Shadow saturation | +8% purple in shadows globally |
| Contrast ratio (subject) | 1:4 to 1:6 — cinematic, not HDR flat |

### 5.6 Gold Reflection

- Gold surfaces (costume, objects) pick up key light streak
- Specular: `#F0D77A` narrow band
- Reflective bounce from frame onto near-edge illustration pixels: 3% max at illustration border

### 5.7 Lighting Diagram (Canonical)

```
                    KEY (45° gold)
                         ↘
              ┌──────────────────┐
              │    ╭────────╮    │
              │    │ SUBJECT│←── RIM (gold edge)
              │    ╰────────╯    │
              │         ↑ MAGIC  │
              │       (element)  │
              └──────────────────┘
                         ↗
                    FILL (purple 15%)
```

---

## 6. Character Rules

When a card contains a figure, these rules are **non-negotiable**.

### 6.1 Rendering Style

| Attribute | Rule |
|-----------|------|
| Style | **Semi-realistic premium fantasy digital painting** |
| Proportions | Elegant elongation — 8 to 8.5 heads tall |
| Anatomy | Correct — no distortion except stylized grace |
| Skin | Moonlit, slightly desaturated — never orange daylight tan |
| Eyes | May hold subtle OR purple glow — never anime shine bursts |

### 6.2 Forbidden Styles

- Anime / manga
- Cartoon / chibi
- Hyper-realism / photographic composite
- 3D render look without paint-over
- Comic book ink outlines

### 6.3 Costume & Adornment

- **Luxury fantasy** — layered fabrics, crystal jewelry, geometric embroidery
- Materials: silk, velvet, aged metal, faceted gems
- Gold trim on costume: same material recipe as frame gold
- No direct copies of historical religious vestments
- Silhouette readable at thumbnail size

### 6.4 Pose & Expression

- Poses: graceful, intentional — never action-manga dynamic
- Expressions: serene, knowing, contemplative, regal — extremes only when card meaning demands
- Hands: fully rendered — QA rejects extra/missing fingers

### 6.5 Character Scale in Frame

- Figure occupies **40–55%** of illustration safe zone height
- Head below top 15% of illustration zone (breathing room)
- Feet above bottom 20% unless intentionally cropped at mid-thigh for bust compositions

---

## 7. Magic Effects — Standardized Library

All magic in the deck draws from this library. **Mix 2–4 types per card maximum.**

### 7.1 Particles (Magic Dust)

| Spec | Value |
|------|-------|
| Size | 0.5–2 px |
| Count | 8–16 visible (20 max Major) |
| Colors | 40% gold, 35% purple/white, 25% element |
| Motion implied | Slow drift — upward default |
| Opacity | 8–25% |
| Distribution | Avoid face obstruction |

### 7.2 Energy Lines

| Spec | Value |
|------|-------|
| Width | 1–3 px tapering |
| Color | Element core → `#9B6DFF` fade |
| Style | Flowing curves — never straight laser beams |
| Glow | 4 px outer bloom at 20% |
| Max per card | 3 distinct streams |

### 7.3 Floating Crystals

| Spec | Value |
|------|-------|
| Count | 0–5 |
| Size | 2–12 px (production) |
| Facets | 3–7 visible per shard |
| Internal glow | Element color at 40% |
| Edge highlight | `#F0D77A` 1 px |
| Placement | Foreground blur or mid-ground sharp |

### 7.4 Aura

| Spec | Value |
|------|-------|
| Shape | Contour-following envelope, 4–12 px from body |
| Color | Element at 12% → transparent |
| Pulse | Static in art; UI may animate |
| Never | Solid outline stroke |

### 7.5 Glow (General)

| Spec | Value |
|------|-------|
| Type | Radial bloom from magic source |
| Max radius | 15% of illustration width |
| Composite | Screen or soft light blend |

### 7.6 Smoke / Mist

| Spec | Value |
|------|-------|
| Color | `#6B4BC4` at 8–15% + element tint |
| Edge | Fully soft — zero hard boundary |
| Use | Mid-ground depth, mystery |
| Max coverage | 25% of illustration area |

### 7.7 Effect Budget

Total visual noise from all magic effects ≤ **30% of illustration area**. Luxury = restraint.

---

## 8. Title — Typography Specification

### 8.1 Typeface

| Property | Value |
|----------|-------|
| Category | Refined display serif OR elegant transitional serif |
| Weight | SemiBold (600) |
| License | Must be cleared for mobile app embedding |
| Fallback reference | Cormorant Garamond / Cinzel Decorative class — final font TBD by AD |

### 8.2 Title Text

| Property | Value |
|----------|-------|
| Case | **Title Case** (Turkish locale supported: İ, Ğ, Ş, Ö, Ç, Ü) |
| Color | `#F0D77A` (Celestial Gold) |
| Max width | 80% of card width (410 px @ production) |
| Overflow | Scale down to min 78% before ellipsis |
| Anti-aliasing | Subpixel, light-on-dark optimized |

### 8.3 Spacing & Letter Spacing

| Property | Value |
|----------|-------|
| Letter spacing (tracking) | **+0.08em** |
| Word spacing | Default + 0.02em |
| Line height | 1.15 (single line preferred) |
| Padding above title | 12 px from bottom ornament |
| Padding below title | 8 px to element sigil row |

### 8.4 Hierarchy

```
ROMAN NUMERAL     — smaller, `#D4AF37`, cartouche enclosed
CARD TITLE        — primary, `#F0D77A`, nameplate ground
(no subtitle on card face — subtitle is app UI only)
```

### 8.5 Position

| Property | Value |
|----------|-------|
| Horizontal | Center-aligned |
| Vertical center | y = 0.820 (737 px from top @ production) |
| Nameplate | `#23153C` at 85% opacity, full width minus 48 px side margin |
| Nameplate top rule | 1 px `#D4AF37` |

---

## 9. Roman Numeral Area

| Property | Value |
|----------|-------|
| Zone | A (y: 0.000–0.080) |
| Cartouche | Hexagon, 56 × 48 px (production) |
| Position | Center x, y center = 36 px from top |
| Numeral color | `#D4AF37` |
| Numeral size | 28 px cap height (production) |
| Major | Roman: 0, I, II … XXI |
| Minor pip | Arabic: 1–10 |
| Minor court | P, Kn, Q, K — centered, 22 px |

---

## 10. Ornament Language — Reusable Vocabulary

### 10.1 Design Grammar

All ornaments built from **5 primitives**:

1. **Arc** — quarter or half circle filigree
2. **Vine** — single-weight curve with 2px leaf terminal
3. **Node** — diamond or hex crystal junction
4. **Dot** — micro-engraved point (0.5 px)
5. **Ray** — 3-line celestial burst (corner only)

### 10.2 Top Ornaments

| Element | Description |
|---------|-------------|
| Hex cartouche | Central numeral housing — double gold border |
| Flanking curls | Symmetric vine arcs left/right of hex, 24 px span |
| Micro stars | 3 dots above hex at 8 px spacing |

### 10.3 Side Ornaments

| Element | Description |
|---------|-------------|
| Vertical filigree | Continuous 1 px gold line at x = 18 px and x = 494 px |
| Arcana markers | Suit/Major sigil at 25%, 50%, 75% height — 16 px size |
| Rail texture | `#12071F` matte, 61 px width |

**Major Arcana side marker:** OR Eye (16 px)  
**Minor side marker:** Suit sigil repeated ×3

### 10.4 Bottom Ornaments

| Element | Description |
|---------|-------------|
| Ornament band | ZONE E — 36 px height |
| Central motif | Symmetric vine + hex crystal, 80 px span |
| Side terminals | Curl inward toward title — guides eye down |

### 10.5 Element Ornaments (Sigils)

| Element | Sigil name | Placement |
|---------|------------|-------------|
| Fire | Eternal Flame Spire | Bottom-left + bottom-right (mirror) |
| Water | Chalice of Tides | Bottom-left + bottom-right |
| Air | Blade of Clarity | Bottom-left + bottom-right |
| Earth | Seal of Manifestation | Bottom-left + bottom-right |
| Universal | OR Prism Hex | Majors without suit element |

Size: 24 × 24 px zone, 20 px sigil, embossed gold.

### 10.6 Arcana Ornaments

| Arcana | Ornament |
|--------|----------|
| Major | OR Eye in Prism Hex — top cartouche flanking + side rails |
| Minor | Suit sigil only — side rails + element corners |

---

## 11. Illustration Area — Content Rules

### 11.1 Unique Content

Only ZONE D varies per card. Artist paints:
- Subject(s), environment, magic, background layers
- Does NOT paint: frame, text, sigils, nameplate

### 11.2 Edge Behavior

- Soft vignette at illustration boundary — 2% inset darkening
- No hard rectangular crop visible
- Subject may bleed toward edges; critical detail stays in critical safe (§2.6)

### 11.3 Focal Point

- Single primary focal point — eye travels: numeral → subject → title
- Secondary elements support, never compete

---

## 12. Premium Finish — Collector Card Feel

### 12.1 Finish Intent

The completed card must feel like a **luxury printed collector card** from a limited dark-fantasy edition:

- Heavy stock sensation (visual weight through border depth)
- Spot gloss on gold and crystal
- Matte illustration surface
- Subtle edge highlight suggesting physical card thickness

### 12.2 Finish Layer Recipe (L20)

| Surface | Treatment |
|---------|-----------|
| Dark metal frame | Matte-satin, no gloss |
| Gold filigree | +15% gloss, narrow specular streak upper-left |
| Crystal inlays | +25% gloss, prismatic edge |
| Illustration | Matte — zero gloss pass |
| Nameplate | Soft satin (`#23153C`) |
| Card edge (3D reveal) | Top-left 0.5 px `#F0D77A`, bottom-right 0.5 px `#030106` |

### 12.3 Optional Legendary Tier (UI Channel)

- Separate `_shimmer.webp` — gold frame only, alpha channel
- Holographic shift: 3% rainbow on gold, angle-dependent in app
- Illustration unchanged

### 12.4 Print Simulation Checklist

- [ ] Gold reads as metal, not yellow paint
- [ ] Frame casts subtle inner shadow on illustration (1 px, 20% black)
- [ ] Card feels "heavy" — dark borders dominate periphery
- [ ] Title legible at 256 px thumbnail width
- [ ] No moiré on filigree at production resolution

---

## 13. Master Blueprint — Single-Page Summary

```
┌─────────────────────────────────────────┐  512 × 896 px
│  ╔═╗     XVII (hex gold)     ╔═╗       │  ZONE A: 72px
│  ───────────────────────────────        │  ZONE B: 10px
│ ┃ ★ ┃                         ┃ ★ ┃    │  ZONE C: rails
│ ┃   ┃   ┌─────────────────┐   ┃   ┃    │
│ ┃   ┃   │                 │   ┃   ┃    │  ZONE D: 450×521
│ ┃   ┃   │  ILLUSTRATION   │   ┃   ┃    │  (unique art)
│ ┃   ┃   │  (never flat)   │   ┃   ┃    │
│ ┃   ┃   └─────────────────┘   ┃   ┃    │
│ ┃ ★ ┃                         ┃ ★ ┃    │
│  ──✦── ORNAMENT BAND ──✦──              │  ZONE E: 36px
│  ┌─────────────────────────────┐      │
│  │        The Star             │      │  ZONE F: 179px
│  └─────────────────────────────┘      │
│  ♦ element              element ♦     │  ZONE G: 36px
└─────────────────────────────────────────┘

Frame: 17px visual mass │ Radius: 12px │ Ratio: 512:896
Light: Key UL 45° gold │ Fill LR purple 15% │ Rim gold
Finish: Matte art │ Gloss gold+crystal │ Collector weight
```

---

## 14. Consistency Enforcement

| Mechanism | Document |
|-----------|----------|
| Template lock | `card_templates/master_template.yaml` |
| Prompt assembly | `prompt_library/master_prompt.template.md` |
| Category accents | `style_rules/*.yaml` |
| QA gate | `validators/acceptance_checklist.yaml` |
| Export | `exports/export_spec.yaml` |
| **This DNA** | **OR-1320 (this document)** |

Any proposed deviation requires Art Director amendment to OR-1320 with version increment.

---

## 15. Document Governance

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-08-05 | Initial Master Card DNA |

**Approved by:** Creative Director, ORACLY  
**Supersedes:** Informal layout notes  
**Referenced by:** OR-1300, OR-1310, all card briefs  

---

**OR-1320 COMPLETE**
