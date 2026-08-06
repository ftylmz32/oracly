# ORACLY Master Tarot Frame — Final Luxury Revision (Frame Lock)
**Document ID:** OR-1330  
**Version:** 1.0  
**Status:** **LOCK CANDIDATE** — final refinement before official deck frame freeze  
**Amends:** OR-1320 v1.0 (dimensions unchanged — identity preserved)  
**Companion:** [`ORACLY_VISUAL_DNA.md`](../art_direction/ORACLY_VISUAL_DNA.md)  

---

## 0. Directive

The current ORACLY frame is **excellent**. This document does **not** redesign it. It performs **final luxury refinement** so that:

> **An empty frame — no illustration, no title — is instantly recognizable as ORACLY.**

All changes are refinements within the existing silhouette, zone map, and material family.

---

## 1. Replace Top Center Gem → Vesica Compass

### Retired
- Large oval crystal centerpiece (attracted excessive focal weight)

### Locked Replacement: **Vesica Compass** (OL-7)

See [`ORACLY_VISUAL_DNA.md` §3](../art_direction/ORACLY_VISUAL_DNA.md) for full spec.

**Summary:**
- Cosmic navigation sacred geometry — vesica piscis + upward tri-prism + micro crystal core
- **28 × 24 px** @ production — small, elegant, highly detailed
- Timeless luxury — no logo, no letters, no branding marks
- Ancient magical symbol unique to ORACLY universe

**Numeral cartouche:** Hex cartouche remains; Vesica Compass sits **above** numeral, not overlapping. Numeral stays swappable below compass.

---

## 2. Redesign Title Plate → Obsidian Name Plaque

### Retired
- Heavy flat `#23153C` nameplate bar

### Locked Replacement: **Obsidian Name Plaque**

See [`ORACLY_VISUAL_DNA.md` §4](../art_direction/ORACLY_VISUAL_DNA.md).

**Summary:**
- Deep obsidian crystal, hand-polished gold engraved edge
- Slim lens curves — **22% height reduction** (139 px vs 179 px @ production)
- Collector edition quality — reads as carved crystal, not UI panel
- **Empty in locked master asset** — title composited at production
- Gold engraving border only — interior dark satin with cyan micro-reflection

---

## 3. Side Ornament Density −20%

Apply reduction per [`ORACLY_VISUAL_DNA.md` §5](../art_direction/ORACLY_VISUAL_DNA.md).

**Principle:** Frame supports artwork. Illustration = hero. Side rails = whisper, not speech.

- Remove 20% of non-functional filigree strokes
- Preserve arcana markers (functional, reduced to 14 px)
- Compensate luxury via material pass (§7), not stroke count

---

## 4. Inner Energy Ring → Oracle Veil Ring

**New layer:** `L02b_oracle_veil_ring`

Inside illustration window, outside art content.

| Property | Value |
|----------|-------|
| Appearance | Magical energy membrane — NOT a second frame |
| Opacity | **4–7% max** |
| Colors | Deep purple `#4A2578`, royal violet `#7B4BC4`, warm gold `#9A7420` |
| Edge | 0.5 px soft gradient, 1 px blur |
| Purpose | Visually merge all future illustrations with frame |

Validation: invisible at thumbnail; felt at full view.

---

## 5. Connect Four Corners → Harmonic Meridian Grid

**System:** Harmonic Meridian Grid (OL-6 + OL-1 + OL-3 + OL-5)

See [`ORACLY_VISUAL_DNA.md` §7](../art_direction/ORACLY_VISUAL_DNA.md).

- Thin golden energy lines (0.35 px) along hidden octagon
- Identical Anchor Nodes at each corner apex
- Celestial intersection bursts at edge midpoints
- Constellation fragments between corner pairs

**Result:** Frame reads as **one magical artifact**, not four independent corner ornaments.

---

## 6. ORACLY Visual DNA — OR Lattice

Official decorative language: **OR Lattice** (Oracle Resonance Lattice)

Seven primitives: Anchor Node, Triad Motif, Crossing Line, Shard Whisper, Constellation Fragment, Meridian Thread, Vesica Compass.

Full specification: [`ORACLY_VISUAL_DNA.md`](../art_direction/ORACLY_VISUAL_DNA.md)

**This is the signature language of every future ORACLY card.**

---

## 7. Premium Material Refinement

### Obsidian (deeper)
- 3-stop radial depth `#030106` → `#060410` → `#0A0812`
- Satin polish, no plastic shine

### Gold (hand-polished)
- Micro directional texture, specular streaks on curves
- Groove shadow `#9A7420` always paired with `#F0D77A` highlight

### Crystals (believable refraction)
- Faceted 3–5 faces
- **Soft cyan reflection** `#A8E8FF` at 8–15% on single facet
- Internal glow — never flat gradient fill

---

## 8. Micro Details Layer

**New layer:** `L01c_micro_engraving`

- Ancient celestial symbols (non-alphabetic)
- Invisible magical runes (original OR script, decorative)
- Hidden sacred geometry hex grid at 2%
- Reward curiosity at 150–300% zoom
- **Does not increase** macro ornament density

---

## 9. Final Quality Target & Master Asset Export

### 9.1 Feel Target

| Must feel like | Must NOT feel like |
|----------------|-------------------|
| Luxury collector artifact | Game UI border |
| Sacred relic | Stock frame overlay |
| Museum-quality magical object | Plastic tarot template |
| Handcrafted one-of-a-kind | Mass-produced print |

### 9.2 Master Frame Asset (Locked PNG)

For official deck production — **frame only, no illustration, no text:**

| Property | Value |
|----------|-------|
| Format | **Transparent PNG** |
| Resolution | **8192 × 14336 px** (8K portrait master) |
| Aspect ratio | 512:896 (exact) |
| Color space | sRGB, 16-bit recommended |
| Symmetry | **Perfect vertical mirror** — QA flip test |
| Content | Empty illustration window, empty name plaque |
| Includes | Vesica Compass, Obsidian Plaque, Oracle Veil Ring, Meridian Grid, OR Lattice |
| Filename | `oracly_tarot_frame_locked_v1.1.png` |
| Location (post-approval) | External art vault + `exports/frame/` staging |

### 9.3 Downstream Derivatives

| Tier | Size | Use |
|------|------|-----|
| 8K master | 8192 × 14336 | Frame lock archive, print |
| 2K composite | 1024 × 1792 | Card compositing |
| Production | 512 × 896 | App runtime |

---

## 10. Updated Layer Stack (Amendment to OR-1320)

```
L01_frame_outer          — dark mystical metal (refined obsidian depth)
L01c_micro_engraving     — NEW: micro runes, celestial symbols
L02_frame_inner          — gold filigree (−20% side density)
L02b_oracle_veil_ring    — NEW: inner energy membrane
L03_illustration         — (empty in frame master)
L08_side_rails           — reduced density, OR Lattice markers
L09_top_cartouche        — numeral zone (below Vesica Compass)
L07_vesica_compass       — NEW: top centerpiece OL-7
L14_bottom_ornament      — meridian-connected corners
L15_obsidian_plaque      — RENAMED/REDESIGNED from nameplate
L16_meridian_grid        — NEW: corner connection system
L20_finish               — premium gloss pass
```

---

## 11. What Does NOT Change

- Card dimensions (512 × 896 production)
- Aspect ratio 512:896
- Corner radius 12 px
- Zone map proportions (A–G)
- Gold + purple + void palette family
- Symmetric filigree identity
- Eight mandatory component categories
- Illustration safe zone (paintable area unchanged)
- No Rider-Waite, no third-party art

---

## 12. Approval & Lock Procedure

1. Artist delivers `oracly_tarot_frame_locked_v1.1.png` @ 8K transparent
2. QA runs [`frame_lock_checklist.yaml`](../validators/frame_lock_checklist.yaml)
3. Art Director blind recognition test (3/3 ORACLY ID)
4. Update `card_templates/master_template.yaml` → `frame_version: 1.1`
5. Status: **FRAME LOCKED** — no frame changes without OR-1330 amendment

---

## 13. Revision History

| Version | Change |
|---------|--------|
| OR-1320 v1.0 | Initial master frame DNA |
| **OR-1330 v1.0** | Vesica Compass, Obsidian Plaque, −20% side density, Oracle Veil Ring, Meridian Grid, OR Lattice, material + micro pass, 8K PNG spec |

---

**OR-1330 FRAME LOCK REVISION — COMPLETE**
