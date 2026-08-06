# ORACLY Tarot — Master Card Template Specification
**Template ID:** `oracly_card_master_v1`  
**Canvas:** 1024 × 1792 px (master) / 512 × 896 px (production)

---

## Required Components (Every Card)

Every finished card **must** contain all eight mandatory components:

| # | Component | Layer ID | Locked |
|---|-----------|----------|--------|
| 1 | **Roman Numeral** | `L10_numeral` | Cartouche locked; numeral swappable |
| 2 | **Card Title** | `L11_title` | Nameplate locked; text swappable |
| 3 | **Central Illustration Area** | `L03_illustration` | Unique per card |
| 4 | **Element Symbol** | `L12_element_sigil` | Position locked; sigil variant by suit |
| 5 | **Arcana Symbol** | `L13_arcana_sigil` | Major = OR Eye; Minor = suit sigil |
| 6 | **Luxury Border** | `L01_frame_outer` + `L02_frame_inner` | Fully locked |
| 7 | **Bottom Ornament** | `L14_bottom_ornament` | Locked filigree band |
| 8 | **Card Finish Layer** | `L20_finish` | Matte/gloss pass — locked recipe |

---

## Zone Map (Normalized 0–1)

```
┌──────────────────────────────────────────┐  y=0.00
│  TOP ZONE (0.00 – 0.08)                  │
│  ┌────┐  Roman Numeral Cartouche  ┌────┐ │
│  │ ◆  │         HEX PLATE         │ ◆  │  y=0.08
├──────────────────────────────────────────┤
│ ▌ SIDE   ILLUSTRATION SAFE ZONE    ▌   │  x: 0.06–0.94
│ ▌ RAIL   (0.08 – 0.76)             ▌   │  y: 0.08–0.76
│ ▌ 0.06   Central painting only     ▌   │
│ ▌        w×h: 0.88 × 0.68          ▌   │
├──────────────────────────────────────────┤  y=0.76
│  BOTTOM ZONE (0.76 – 1.00)               │
│  ♦ Element   NAMEPLATE + TITLE   Element ♦│
│  ─────── Bottom Ornament Band ───────    │  y=1.00
└──────────────────────────────────────────┘
```

---

## Illustration Safe Zone (Pixels @ 1024×1792)

| Edge | Inset |
|------|-------|
| Left | 61 px (6%) |
| Right | 61 px (6%) |
| Top | 143 px (8%) |
| Bottom | 430 px (24%) — includes bottom zone margin |
| Paintable height | 1219 px |
| Paintable width | 902 px |

**Critical detail** must stay inside paintable area minus 24 px inner padding.

---

## Border Construction (Luxury Border)

Outside → inside:
1. Outer gold bevel gradient stroke — 2 px
2. Dark gutter — 4 px `#060410`
3. Inner filigree band — 8 px (decorative, locked asset)
4. Purple velvet inset — 3 px `#12071F`
5. Soft vignette into illustration — 2% inset gradient

Corner radius: **12 px** (production), **24 px** (master @2×)

---

## Numeral Cartouche (Top)

- Shape: Hexagon with gold double border
- Center: x=512, y=72 (master)
- Font: Classical Roman serif, `#D4AF37`
- Major: Roman numerals (0, I–XXI)
- Minor pip: Arabic 1–10
- Minor court: P / Kn / Q / K

---

## Nameplate (Bottom)

- Background: `#23153C` at 85% opacity over dark plate
- Top edge: 1 px `#D4AF37` highlight line
- Title color: `#F0D77A`
- Title case, tracking +0.08em
- Max width: 80% of card width, scale down before truncate

---

## Element Symbol

- Position: bottom-left inner frame, 48×48 px zone (master)
- Embossed gold, suit sigil per OR-1300
- Mirrored copy bottom-right (optional on pips, mandatory on courts/majors)

---

## Arcana Symbol

- Position: top side rail center OR embedded in hex cartouche flanking
- Major: OR Eye in prism hex
- Minor: repeating suit sigil at 25/50/75% rail height

---

## Bottom Ornament

- Horizontal filigree band above nameplate
- Height: 24 px (master)
- Symmetric vine + crystal nodes
- Gold `#D4AF37` line art on `#0C0820`

---

## Card Finish Layer

Simulated print finish applied last:
- Frame + sigils: +15% specular gloss pass
- Illustration: matte
- Legendary tier (UI): optional holographic gold shift on frame only (separate export channel)

---

## Template Files (External — Not in Repo)

| File | Description |
|------|-------------|
| `frame_locked.psd` | Immutable border group |
| `numeral_cartouche.psd` | Swappable text layer |
| `nameplate.psd` | Swappable title |
| `finish_pass.psd` | Gloss adjustment layers |

Store in secure art drive. Pipeline references paths in brief only.
