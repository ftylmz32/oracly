# Tarot Phase 7 — Visual Contract

**Status:** Locked for Phase 7 implementation · Parent: Global Visual Quality System  
**Date:** 2026-09-25  
**DNA:** near-black · midnight navy · deep violet atmosphere · antique gold restraint · warm ivory reading text

Tarot chamber identity: **real premium deck · velvet/physical table · candle / low-key cinematic light · antique gold detail**.

Not: neon game UI · giant orbs · dashboard tiles · cartoon Tarot · baked text in images.

---

## Global Tarot chrome

| Token | Rule |
|-------|------|
| Background | One live owner: `TarotTableBackground` / chamber darkness — no second galaxy system on live path |
| Content width | Centered reading column; horizontal margins from `TarotTokens` / `OraclyChrome` |
| Top rhythm | SafeArea + consistent top inset |
| Section spacing | `CraftsmanshipRhythm` / reading gaps — no ad-hoc densification |
| Gold | Accent only (~10%); never fill walls |
| Cream text | Body via `ReadingTypography` |
| Glass | Restricted — ritual glass only where already canonical; no new glass cards for every paragraph |
| Radius | One hierarchy — reuse existing tokens |

---

## Card physicality

- Consistent aspect ratio (`TarotTokens` / ritual metrics)
- Real deck feeling (photoreal faces + `tarot_card_back`)
- Face hierarchy > ornamental glow
- Reversed = calm orientation cue, not neon alert
- Tilt limits: subtle only
- Names readable when shown; Flutter owns labels

---

## Motion

| Phase | Behavior |
|-------|----------|
| Entrance | Weighted, short |
| Shuffle / cut / draw / flight / flip | Ritual-owned; one ambient loop max |
| Result arrival | Settled content first; no perpetual particle storm |
| Reduced motion | Skip spectacle; keep state clarity |

Golden captures use **settled** frames only.

---

## Result hierarchy (Narrative V2)

1. Reading identity / spread  
2. User question when real  
3. Drawn cards / spread visual  
4. **Main Narrative** — dominant body  
5. Meaningful chapters / transitions  
6. Optional relationships only when useful  
7. Verified recurrence/memory **only when present**  
8. Closing / direction  
9. OR follow-up / save / share / new reading  

**Avoid:** Card-1/2/3 essays · Love/Career/Money/Spiritual as primary dashboard · ten glass panels for one story.

Preserve: premium shell · question header · art strip pattern · direction · OR CTA · transparency footnote.  
Extend: Narrative-first chapters · Signature geometry on strip · memory/recurrence when evidenced.

---

## History

- Preview shows spread identity honestly (`signature.crossroads` must not become fiveCard in Narrative senses)
- Reopen path to full reading
- History filter alias Crossroads→five icon is UX debt for later (not Narrative fabrication)

---

## Error / loading / safety

- Cinematic but calm  
- No fake successful interpretation visuals on safety/error  
- Retry obvious  
- Safety: reason only — no story/cards  

---

## Viewports

| Role | Size |
|------|------|
| Canonical | 390×844 |
| Compact | 320×568 |
| Tall | 412×915 |
| A11y | 360×800 @ textScale 1.3 |

---

## Accessibility

≥44px targets · contrast · textScale 1.3 · semantics · reduced motion · SafeArea.
