# YILDIZNAME Phase 7 — Visual Contract

**Status:** FROZEN (Phase 7A baseline)  
**Feature identity:** Ancient celestial archive — birth · identity · personal history  
**Not:** Astrology observatory · transit dashboard · neon horoscope app

---

## Global DNA

near-black · midnight navy · deep violet · antique gold · warm ivory · cinematic darkness · real materials · controlled contrast · editorial typography

~70% calm dark · ~20% violet/navy · ~10% antique gold accent.

## Chamber materials

dark stone/ink · brass · warm paper/ivory · candle amber · deep violet atmospheric depth

Gold = **accent only** (never gold walls).

## Hub hero

`StarMapReferenceChart` — archive seal / brass medallion.  
**Recommendation (7A):** hub-only. Do not duplicate the giant hub hero above every result (damages reading hierarchy). Result may later use a **small** archive motif if needed — never a zodiac-wheel dashboard.

## Canonical result owner

`StarMapReferenceResultScreen`

One architecture for: legacy · reduced · full · live · artifact reopen.  
No parallel Narrative / Artifact / FullNatal result screens.

Scroll owner: single `OraclyAdaptiveScrollView` under one app bar.  
No nested Scaffold / nested primary scroll.

## Result hierarchy (frozen)

1. App bar / Yıldızname identity  
2. Reading identity / historical state  
3. Scope + fidelity disclosure (human copy)  
4. Natal signature / compact verified facts  
5. **Main narrative summary — dominant**  
6. Meaningful interpretation chapters  
7. Verified archive recurrence — only when present  
8. Reflection prompt (quiet question)  
9. Closing message (epilogue weight)  
10. OR / share / favorite / continuation  
11. Symbolic / scope footnote  

Facts support interpretation; they never bury it.

## Scope disclosure semantics

| State | Human intent (conceptual) | Must NOT imply |
|-------|---------------------------|----------------|
| LEGACY | “Doğum tarihine göre sembolik yorum” | full natal / precise sky |
| REDUCED | “Doğum saati bilinmediği için saat bağımlı katmanlar dahil değil.” | broken / half-loaded |
| FULL | “Doğum tarihi, saati ve yerine göre hesaplandı.” | engine / TZ DB / calcVersion |

Never show wire enums: `tropicalSunSign` · `reducedNatal` · `fullNatalEphemeris`.

## Live vs artifact

| | Live | Artifact |
|--|------|----------|
| Meaning | current/new reading | saved historical reading |
| Visual | subtle status/metadata | “Kayıtlı yorum” + original date |
| Prose | current accepted body | **immutable** stored body |
| Chrome | localizes | may localize labels/buttons |

Same screen design; difference is metadata, not a second universe.

Sources: `legacyLive` · `legacyArtifact` · `narrativeLive` · `narrativeArtifact`.

## Fact priority (FULL)

PRIMARY: Sun · Moon · Ascendant (optional MC)  
SECONDARY: Mercury · Venus · Mars  
DEEPER (lower / “Doğum Göğün”): Jupiter–Pluto · houses · aspects  

REDUCED: interval-safe body+sign only — **no** exact degrees, no fake Asc/MC/house slots.  
LEGACY: visibly lighter — no full chart chrome.

Degrees: FULL factual UI may show degrees from **structured facts only**. Never parse narrative prose. Never invent `0°` / `—°`.

## Chapter mapping (chrome labels — implement in 7B+)

| Wire kind | TR (concept) | EN (concept) | RU (concept) |
|-----------|--------------|--------------|--------------|
| core_identity | Kimlik | Identity | Идентичность |
| emotional_world | Duygusal dünya | Emotional world | Эмоциональный мир |
| mind_and_expression | Zihin ve ifade | Mind & expression | Ум и выражение |
| relationships_and_values | İlişkiler ve değerler | Relationships & values | Отношения и ценности |
| drive_and_growth | İtici güç ve büyüme | Drive & growth | Движение и рост |
| angles_and_houses | Açı ve evler | Angles & houses | Углы и дома |
| patterns_and_tensions | Örüntüler | Patterns & tensions | Паттерны и напряжения |
| strengths_and_resources | Güçler | Strengths & resources | Сильные стороны |
| archive_echo | Arşiv yankısı | Archive echo | Эхо архива |
| practical_reflection | Pratik yansıma | Practical reflection | Практическое отражение |

Never show raw wire names or enum `.name` in UI.

## Memory

Only when verified recurrence exists.  
Looks like historical echo / archive connection — not AI badge, feed, or achievement.  
No empty memory section.

## Footer hierarchy (target)

1. OR follow-up  
2. Share  
3. Favorite/save (disabled honestly if no artifact id)  
4. Continue / new journey  
5. Quality feedback  

Avoid five equal giant CTAs. Current production order differs (documented in 7A baseline) — remediate in 7E.

## Responsive matrix

| Role | Size |
|------|------|
| CANONICAL | 390×844 |
| COMPACT | 320×568 |
| STANDARD | 360×800 · 375×812 · 393×852 |
| TALL | 412×915 · 430×932 |
| A11Y | 360×800 @ textScale 1.3 |
| Later | textScale 2.0 destructive |

Narrative measure: respect `AppLayout.maxContentWidth` (560); prefer readable column — not 600px stretched prose.

## Accessibility

≥44×44 targets · body contrast AA · semantics on major actions · textScale 1.3 baseline · reading order = visual order · scope readable without color alone.

## Motion / performance

≤1 ambient loop on result.  
Settle calmly; no forever-animating planet cards / rotating wheel / particle storm.  
Reduced motion: meaning remains.  
Target 60 FPS mid-tier. No blur-per-paragraph. No per-row expensive shaders.

## Forbidden visual patterns

- neon astrology dashboard / cyan HUD  
- rainbow zodiac wheel  
- 10 equal planet cards before narrative  
- 12 equal house cards  
- glass card around every paragraph  
- raw enum/wire names  
- engine/version metadata as hero  
- fake unavailable slots (Asc/house for reduced)  
- purple orb / game constellation UI  
- analytics dashboard look  
- over-glowing gold surfaces  

## Golden inventory (Phase 7A baseline)

Root: `test/visual/yildizname/` · masters: `test/goldens/yildizname/`  
See `YILDIZNAME_PHASE7A_VISUAL_FORENSIC_BASELINE.md` for hash table.

## Premium / gems

Yıldızname remains free. No premium badge / gem cost / purchase CTA on feature surfaces.

---

## Update — Phase 7B.1 (LEGACY disclosure wording)

The conceptual LEGACY row above (“Doğum tarihine göre sembolik yorum”) named a birth-date basis the legacy runtime cannot always prove.
Phase 7B.1 supersedes it with generic, evidence-safe copy that names no birth date, Sun sign, birth time, birth place or natal precision.
See `YILDIZNAME_PHASE7B_PRESENTATION_MODEL.md` (Phase 7B.1). Every other row is unchanged.
