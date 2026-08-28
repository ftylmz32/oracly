# ORACLY visual implementation guide

Acceptance targets for **Coffee Fortune**, **Astrology**, and **Yıldızname**.

These PNGs are **not** production UI. They are composition, atmosphere, and hierarchy to match later. Runtime screens replace every sample sentence with real provider data, real personalization, and `OraclyL10n`.

Location: `design/reference/`

| File | Role | Pixel size |
|------|------|------------|
| `coffee_target.png` | Kahve Falı target | 1024 × 1536 |
| `astrology_target.png` | Astroloji target | 1024 × 1536 |
| `yildizname_target.png` | Yıldızname target | 1024 × 1536 |
| `all_three_reference.png` | Side-by-side identity check | 1536 × 1024 |

Compare Flutter screenshots against the **same three phones** in `all_three_reference.png`. OCR on generated labels may be imperfect — match **layout, light, and hierarchy**, not letterforms.

Do **not** treat decorative cup symbols as detected coffee marks. Do **not** invent Moon / Rising / houses / aspects or numeric scores.

---

## Shared universe

All three screens are one place. Same chrome, same gold, same night.

### Color tokens (`lib/core/design_system/app_colors.dart`, `OraclyChrome`)

| Role | Token | Hex |
|------|--------|-----|
| Near black | `AppColors.background` | `#04030A` |
| Midnight navy | `AppColors.backgroundSecondary` | `#0A0914` |
| Surface | `AppColors.surface` | `#14101F` |
| Elevated glass | `AppColors.surfaceElevated` | `#1C1730` |
| Deep violet | `AppColors.primaryPurple` | `#4A36B0` |
| Soft violet | `AppColors.secondaryPurple` | `#7B64D4` |
| Antique gold | `AppColors.gold` | `#E7C56D` |
| Gold light | `AppColors.goldLight` | `#F5D98A` |
| Gold deep | `AppColors.goldDeep` | `#C9A84E` |
| Warm cream | `OraclyChrome.cream` | `#F0E6D8` |
| Gold glow | `AppColors.glowGold` | `#52E7C56D` |
| Violet glow | `AppColors.glowPurple` | `#334A36B0` |

### Spacing (`AppSpacing` / `OraclyChrome`)

Use **8 · 12 · 16 · 20 · 24 · 32** only.

| Use | Token | px |
|-----|--------|----|
| Screen side | `OraclyChrome.screenSide` | 20 |
| Screen top (inside SafeArea) | `OraclyChrome.screenTop` | 12 |
| Tight chamber gap | `AppSpacing.s8` | 8 |
| Section breath | `AppSpacing.s12` | 12 |
| CTA stack gap | `AppSpacing.s8` | 8 |

### Chrome metrics

| Element | Token | Value |
|---------|--------|-------|
| Header row | `OraclyChrome.headerHeight` | 48 |
| Primary CTA height | `OraclyChrome.buttonHeight` | 44 |
| Touch minimum | — | 44 |
| Hero corner | `OraclyChrome.heroRadius` (`AppRadius.s24`) | 24 |
| Glass card corner | `OraclyChrome.cardRadius` (`AppRadius.s20`) | 20 |
| Pill / nav / CTA | `OraclyChrome.pillRadius` (`AppRadius.s28`) | 28 |
| Hairline gold | `OraclyChrome.borderHairline` | 0.22 alpha |
| Default gold edge | `OraclyChrome.borderDefault` | 0.32 alpha |

### Background layers (every screen)

Paint back-to-front. One ambient atmosphere — no second visual language.

1. Fill `#04030A`
2. Soft vertical haze: deeper navy at top, violet-black at mid (opacity 0.18–0.32)
3. Restrained star field (tiny cream dots, density low, never animated loop)
4. Optional gold geometry (thin rings / arcs, opacity ≤ 0.22)
5. Content
6. Bottom nav floating above the haze

Do **not** add giant purple orbs, neon rims, or stacked identical glass cards.

### Typography hierarchy

| Level | Recipe | Size | Tracking | Color |
|-------|--------|------|----------|-------|
| Screen title | `OraclyChrome.engravedTitle` | 13–15 | ~2.8 | gold 0.94 |
| Lead / subtitle | `ReadingTypography.opening` | ~13.5 | default | cream 0.72–0.84 |
| Hero caption | `ReadingTypography.sectionLabel` | 11 | 2.2 | gold light 0.90 |
| Reading body | `ReadingTypography.body` / `bodyCore` | 15.5–18 | 0.14 | cream 0.88–0.94 |
| Chapter label | `ReadingTypography.sectionLabel` | 11 | 2.2 | gold light 0.90 |
| CTA | `AppTypography` button | 15 | slight | on gold: near-black; ghost: gold |
| Nav label | `OraclyChrome.navLabel` | 10 | — | selected gold; else cream 0.45 |

Long reading copy uses `CraftsmanshipRhythm.paragraphGap` and line-height **1.76**. Never condense with ellipsis on the reading itself.

### Header (all three)

Row height 48, inset 20.

| Left | Center | Right |
|------|--------|-------|
| Back (40×40, gold chevron, semantics) | Engraved title | Live gem capsule (same as Home) |

Titles:

- Coffee → `KAHVE FALI`
- Astrology → `ASTROLOJİ`
- Yıldızname → `YILDIZNAME`

### Bottom navigation relationship

Same floating bar as `OraclyBottomBar`:

- Height 58 + 8 bottom margin + home-indicator inset
- Horizontal margin 16
- Five destinations: Ana Sayfa · Kahve Falı · Astroloji · Yıldızname · Profil
- Selected tab: gold icon + gold label
- Unselected: cream ~0.45
- Chamber content must end above `AppLayout.scrollBottomInset` so nothing sits under the bar

Selected tab in the three targets:

| Screen | Selected index |
|--------|----------------|
| Coffee | Kahve Falı (1) |
| Astrology | Astroloji (2) |
| Yıldızname | Yıldızname (3) |

### Surfaces

Prefer **no card** for the reading. Hierarchy comes from type, space, and a 1–2 px gold rail (`ChamberReadingLane`). If a surface is required (photo well only):

- Fill `surface` @ ~0.55–0.72
- Hairline gold border
- No heavy glow (glow ≤ `OraclyChrome.glowSoft`)
- Never icon + gold title + divider + truncated body tile repeated 4–9 times

Runtime widgets to compose toward these targets later:

- `ChamberSubjectPhoto` / `CoffeeResultPhoto` — subject as hero
- `ChamberNarrativeBlock` — continuous story
- `ChamberReadingLane` — gold-rail chapters
- `ChamberHeaderLead` — one quiet sentence under the hero

---

## 1. Coffee Fortune — `coffee_target.png`

### Identity

Warm · ceremonial · mystical · Turkish coffee ritual.

The **cup is the screen**. Controls stay small.

### Runtime compare frame

Logical phone **390 × 844**. PNG is **1024 × 1536** (2:3). Scale regions by **content height %** below.

### Vertical regions (% of area above nav)

| Region | % | px @ 844 logical (~ nav 66 + header) | Content |
|--------|---|--------------------------------------|---------|
| Header | 0–7 | 48 | `KAHVE FALI` |
| Subtitle | 7–14 | ~56 | *Fincanındaki izleri birlikte okuyalım.* |
| Hero | 14–68 | **~380–420** (~48–55% of full phone) | Cup, table, steam, candlelight |
| Spacer | 68–74 | 32–48 | Negative space |
| Primary CTA | 74–80 | 44 | `FOTOĞRAF ÇEK` |
| Secondary CTA | 80–86 | 44 | `GALERİDEN SEÇ` |
| Nav reserve | 86–100 | `scrollBottomInset` | Bottom bar |

Hero height token to approach: `CoffeeReferenceTokens.artHeightFor` currently clamps ~168–280. The **target** is larger — cup should occupy **about half the viewport**. Do not enlarge in this task; record the gap.

### Hero

- Photoreal (or photo of the user’s cup later) Turkish cup, three-quarter or top
- Dark table, warm candle key light, soft steam
- Deep purple fill in shadows — not a purple blob behind the cup
- Optional faint gold-line ornaments (bird, heart, eye, road, mountain, key) as **environment only**
- They are **not** vision detections

Photo well: radius 8–24, full bleed inside the hero slot, no gold postcard frame.

### Typography on this screen

1. `KAHVE FALI` — engraved title
2. Subtitle — `ReadingTypography.opening`, centered, max 2 lines
3. Primary CTA — gold pill, 44 tall, full width minus 20+20
4. Secondary — ghost / text button, same width, gold hairline or no fill

### Buttons

| | Label | Treatment | Placement |
|--|-------|-----------|-----------|
| Primary | `FOTOĞRAF ÇEK` | Gold fill, cream/near-black label, radius 28, height 44 | Centered, above secondary |
| Secondary | `GALERİDEN SEÇ` | Ghost, gold label | 8 px under primary |

Upload UI must **not** compete with the cup.

### Result hierarchy (later; not fake data)

Visual order only:

1. Cup photo (still the hero if a path exists)
2. `FİNCANIN SANA ANLATTIĞI` — one `ChamberNarrativeBlock` (hero body)
3. Optional gold-rail asides, **not** tiles: AŞK · İŞ & PARA · YAKIN GELECEK · DİKKATİMİ ÇEKEN — only when real copy exists; omit empty lanes

Production must never show invented fortunes to fill this map.

### Background layers (Coffee)

1. `#04030A`
2. Warm candle spill (~gold 0.12) only around the cup, not the whole page
3. Violet shadow in corners
4. Sparse stars, low

---

## 2. Astrology — `astrology_target.png`

### Identity

Celestial · luminous · premium · personal.

**One hero + one narrative.** Supporting chapters are rails, not a dashboard.

### Vertical regions (% above nav)

| Region | % | Notes |
|--------|---|--------|
| Header | 0–7 | `ASTROLOJİ` |
| Subtitle | 7–16 | Two lines: *Bugün gökyüzüne değil, / kendi hikâyene bak.* |
| Hero | 16–52 | Zodiac / sun-sign artwork ~ **208–280 px** logical (`AstrologyReferenceTokens.signCardHeight` → target toward **viewport 0.42–0.46**) |
| Focus heading | 52–58 | `BUGÜN SANA NE SÖYLÜYOR?` section label |
| Narrative | 58–78 | One cream body; no 8-line ellipsis |
| Rails | 78–90 | AŞK · İŞ & YÖN · İÇSEL TEMA — gold rail + short real copy only |
| Nav | 90–100 | Astroloji selected |

Zodiac **strip of signs** (if present) sits **below** the CTA in the current runtime; the target keeps the **hero sign large** and the rest of the wheel as a quiet row or omitted from first viewport. Prefer **one large sign**, not 12 equal chips competing with the story.

### Hero

- Full-width celestial plate, height ~208–280
- Starfield + thin gold rings
- Central sign art (catalogue `AstrologyReferenceSignArt` later)
- Violet atmospheric glow **behind** the sign, opacity ≤ 0.28
- Sign name + date range sit **on** the art, cream, not in a second card

### Typography

1. `ASTROLOJİ` — engraved
2. Lead — opening, 2 lines, cream 0.72
3. `BUGÜN SANA NE SÖYLÜYOR?` — section label (this is the verbal focus; the art is the visual focus)
4. Body — `ChamberNarrativeBlock` hero, 18 / 1.58
5. AŞK / İŞ & YÖN / İÇSEL TEMA — `ChamberReadingLane` titles; bodies only if catalogue/personalization text is real

### Forbidden on this target

- Fake % bars
- Aşk / kariyer **scores**
- Moon, Rising, houses, aspects as invented fields
- Four identical gold tiles

### Buttons

Primary follow-up (`Devam et` / current `AstrologyPresentationCopy.detailCta`) sits **after** the narrative, 44 px gold pill, full content width. It must not sit on top of the hero.

Honesty footnote (`AstrologyReferenceKindNote`) is caption type, cream 0.72, **not** a card.

---

## 3. Yıldızname — `yildizname_target.png`

### Identity

Deep · mysterious · personal · celestial archive.

**Hero + chapters.** Not a menu of result cards.

### Vertical regions (% above nav)

| Region | % | Notes |
|--------|---|--------|
| Header | 0–7 | `YILDIZNAME` |
| Subtitle | 7–16 | *Yıldızlarında gördüğümüz / sembolik izleri keşfet.* (archive voice; hub lead in product is `StarMapPolishCopy.leadLine`) |
| Hero | 16–58 | Circular celestial artwork / wheel **dominates** |
| Heading | 58–64 | `BUGÜN SANA ANLATILANLAR` (maps to archive chapter flow) |
| Chapters | 64–90 | Four typographic chapters, gold rails, **no glass stack** |
| Nav | 90–100 | Yıldızname selected |

Hero diameter: `StarMapReferenceTokens.chartDiameterFor` — target **~0.46–0.55 of content width**, max 312. The PNG makes the wheel/portrait the largest object; runtime should keep that ratio.

### Hero

- Round or rounded-square celestial portrait inside a zodiac wheel
- 12 small gold marks on the ring (symbolic, not tappable house tiles)
- Thin gold geometry, violet nebula **inside** the circle
- Tiny stars; no shooting-star spectacle
- Center artwork must read as a **being / archive face / sky**, not a pie chart

### Chapter map (presentation)

Order on the target vs live archive chapters:

| Target label | Live chapter (do not flatten) |
|--------------|-------------------------------|
| GÜNEŞ BURCUNUN TEMASI | maps to BUGÜNÜN İZİ / sun thread |
| İÇSEL TEMA | İÇİNDEKİ DÜĞÜM |
| BUGÜNKÜ YANSIMA | first narrative block |
| SON DÖNEMDE SENİN HİKÂYEN | SON DÖNEMİN HİKÂYESİ |

Use `ChamberNarrativeBlock` (first) + `ChamberReadingLane` (rest). **No** `StarMapHubInsightCard` revival. CTA under chapters: birth / `Yorumu aç` as the single gold pill if needed.

### Surfaces

Chapters = gold rail + label + body. Not 52 px menu rows stacked as a database.

---

## 4. Triptych — `all_three_reference.png`

Use this file to check **family resemblance** in one glance.

| Check | Pass if |
|-------|---------|
| Night | Same near-black, not three different purples |
| Gold | Same antique champagne, not yellow-neon |
| Hero | Each phone has **one** dominant image |
| Type | Engraved gold title + cream reading |
| Nav | Same 5-tab language |
| Cards | No wallpaper of equal glass tiles |

When implementing, screenshot the three runtime routes at 390×844 and place them in the same order: Coffee · Astrology · Yıldızname.

---

## Comparison workflow (later; not this task)

1. Capture Flutter screens at 390×844 logical.
2. Overlay or side-by-side with the matching `*_target.png`.
3. Score: hero %, gold restraint, cream type, nav, **absence** of dashboard tiles.
4. Swap placeholder sentences for live data only.

---

## Out of scope for implementers of these files

Do not change Home, OR, SoulMate, Premium, auth, or proxy to “match” these PNGs.

Do not ship the sample paragraphs from the PNGs as product copy.

Do not add purchase/gem theatre onto these three chambers to mimic extra chrome in a generated image unless that chrome already exists in `OraclyBottomBar` / gem capsule.
