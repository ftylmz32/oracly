# ORACLY Tarot — Official Production Manual
**Document:** OR-1310  
**Version:** 1.0  
**Audience:** Art Director, Illustrators, QA, Engineering (asset integration)

---

## 1. Purpose

This manual defines the **complete production workflow** for the ORACLY Tarot deck (78 cards + 1 card back). Every card must appear painted by a single hand, obeying OR-1300 Art Direction without deviation.

**This pipeline produces specifications and metadata — not images.** Illustration happens in external tools; acceptance happens through this validator system.

---

## 2. Roles & Responsibilities

| Role | Delivers | Approves |
|------|----------|----------|
| **Art Director** | Briefs, thumbnails, final sign-off | All stages |
| **Illustrator** | Line, color, paint, FX within template | — |
| **Compositor** | Frame lock, numeral, nameplate, finish layer | Frame QA |
| **QA Reviewer** | Checklist execution | Pass/Fail report |
| **Engineering** | Asset import, WebP delivery, app paths | Format compliance |

---

## 3. Production Workflow (8 Stages)

### Stage 0 — Registry Lookup
- Open `card_registry.yaml`
- Locate card by `id`, confirm `arcana`, `suit`, `element`, `numeral`
- Status must be `planned` before work begins

### Stage 1 — Brief
- Copy `validators/card_brief_schema.json` → `briefs/{card_id}.json`
- Fill all required fields (mood, character, environment, symbols, etc.)
- Art Director signs brief (`approved_by`, `approved_at`)

### Stage 2 — Thumbnail (3-up)
- Three value sketches, grayscale, composition only
- Must show: focal subject, light direction, depth planes
- AD selects one direction → `briefs/{card_id}/thumb_selected.png` (stored outside repo until approved)

### Stage 3 — Prompt Assembly
- Load `prompt_library/master_prompt.template.md`
- Inject variables from brief + matching `style_rules/{category}.yaml`
- Append `prompt_library/negative_prompt.txt` block
- Save composed prompt → `briefs/{card_id}/prompt.md`

### Stage 4 — Illustration
- Paint **only inside** `card_templates/master_template.yaml` → `illustration_safe_zone`
- Do **not** paint frame, numerals, or nameplate (composited in Stage 5)
- Master canvas: 1024 × 1792 px @ 2× (see `exports/export_spec.yaml`)

### Stage 5 — Composite
- Stack layers per `card_templates/layer_stack.json`:
  1. Background plate (optional separate)
  2. Illustration
  3. FX group (fog, glow, particles)
  4. Vignette
  5. **Locked frame template** (from `card_templates/frame_locked/`)
  6. Roman numeral cartouche
  7. Nameplate + title text
  8. Element + arcana symbols
  9. Card finish layer (matte/gloss pass)

### Stage 6 — Validation
- Execute every item in `validators/acceptance_checklist.yaml`
- Score must be **100% pass** on blocking items
- Non-blocking recommendations logged separately
- Output: `briefs/{card_id}/qa_report.yaml`

### Stage 7 — Export
- Follow `exports/export_spec.yaml` exactly
- Deliver to `exports/delivery/` folder structure (see `exports/folder_structure.md`)
- Update `card_registry.yaml` status → `approved`

### Stage 8 — Integration Handoff
- Engineering receives manifest: `exports/delivery/{card_id}/manifest.json`
- App asset path: `lib/assets/images/cards/tarot/oracly/` (per naming convention)

---

## 4. One-Artist Consistency Rules

To guarantee a unified deck:

1. **Single frame source** — never redraw borders per card  
2. **Single light vector** — key upper-left 45° on every card  
3. **Single gold material recipe** — see `art_direction/palette.json` → `gold_material`  
4. **Single fog preset** — purple undertone, 12–18% opacity mid-ground  
5. **Category rules override** — suit palette only modifies accents, never void ground  
6. **AD spot-check every 5th card** — drift correction before batch continues  

---

## 5. Card Back (Special Case)

- **One artwork** for entire deck: OR Seal (OR-1300 §15)
- Produced once, validated once, never varied per suit
- Registry entry: `card_id: oracly_tarot_back`
- Same export pipeline, no illustration brief variables except global style

---

## 6. Batch Production Order (Recommended)

| Batch | Cards | Rationale |
|-------|-------|-----------|
| 1 | Card back + 3 Majors (Fool, Magician, High Priestess) | Establish gold standard |
| 2 | Remaining Majors (0–21) | Archetype range locked |
| 3 | All Aces + Kings | Suit identity extremes |
| 4 | Queens + Knights + Pages | Court consistency |
| 5 | Pips 2–10 per suit (Cups → Wands → Swords → Pentacles) | Pip narrative patterns |

---

## 7. Version Control

```
features/tarot_art/
  briefs/              ← gitignored (artist working files)
  card_registry.yaml   ← tracked (status only)
  exports/delivery/    ← gitignored until approved batch
```

Tracked in repo: templates, rules, validators, specs, registry metadata.  
Not tracked: WIP PNG/PSD, rejected iterations.

---

## 8. Escalation

| Issue | Escalate To |
|-------|-------------|
| Frame/template change request | Art Director + OR-1300 amendment |
| New symbol introduction | Art Director |
| Export spec change | Engineering + Art Director |
| Failed QA twice | Art Director review brief |

---

## 9. Reference Documents

- OR-1300 Art Direction (full) — summarized in `art_direction/OR-1300_SUMMARY.md`
- App color tokens — `art_direction/palette.json` (synced with `lib/core/theme/app_colors.dart`)
- Tarot aspect ratio — 2:3.5 (`cardAspectRatio` ≈ 0.571 in app; art uses 512:896 = 0.571)

---

## 10. Sign-Off

A card is **production complete** when:

- [ ] Registry status = `approved`
- [ ] QA report = all blocking passes
- [ ] Export manifest validated
- [ ] Engineering confirms in-app display

---

**OR-1310 Production Manual — End**
