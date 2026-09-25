# YILDIZNAME Phase 1 — Product Constitution & Astronomical Honesty Specification

**START HEAD:** `29543f270254dafe9b215cb887ac2fb3135aa153`  
**Branch:** `fix/final-product-remediation-20260922`  
**REAL PROVIDER CALLS:** 0  
**Production / test / golden / backend modified:** 0  

Companion matrix: [`YILDIZNAME_PHASE1_TRUTH_MATRIX.md`](./YILDIZNAME_PHASE1_TRUTH_MATRIX.md)

---

## Verdict

| Gate | Status |
|------|--------|
| YILDIZNAME PHASE 1 | **PASS / FROZEN** |
| PHASE 2 READY | **YES** |

Tarot Phase 0–10 remains **COMPLETE / FROZEN**.  
Yıldızname Phase 0 remains **PASS / FROZEN**.

---

## 1. Product jobs (canonical)

### Yıldızname

| | |
|--|--|
| **Internal definition** | The user’s personal **birth-sky identity** and **long-term symbolic life archive**. |
| **User promise** | “ORACLY used my verified birth evidence and my real journey — not a generic horoscope paragraph.” |
| **Time horizon** | **BIRTH / NATAL IDENTITY / ARCHIVE** (and optional secondary “today’s reflection” clearly labeled as non-natal). |
| **Owns** | Natal baseline facts (when calculated), personal archive artifacts, birth evidence completeness, reduced-or-full natal interpretation. |
| **Excludes** | Present-sky transits, “what’s happening today in the sky,” daily newspaper horoscope as primary job, invented Ascendant/houses/Moon when evidence incomplete. |

### Astrology

| | |
|--|--|
| **Internal definition** | The **current / present sky** and **time-oriented** interpretation surface. |
| **User promise** | “What the sky is doing now / this period — timing and transit context.” |
| **Time horizon** | **NOW / TODAY / PERIOD / TRANSITS**. |
| **Owns** | Current ephemeris (future), daily/period readings, transit-to-natal overlays **consuming** Yıldızname natal baseline. |
| **Excludes** | Owning natal calculation as primary product; replacing birth archive; claiming natal identity. |

### Birth Chart

| | |
|--|--|
| **Internal definition** | Yıldızname’s **evidence acquisition + astronomical calculation sub-journey** — not a third competing consumer product. |
| **User promise** | “Enter birth evidence; receive a structured natal layer at the honesty level your evidence supports.” |
| **Time horizon** | Input moment → calculation → structured natal evidence → feeds Yıldızname. |
| **Owns** | Birth profile UX, completeness states, calculator port invocation. |
| **Excludes** | Parallel marketing as a separate “same sun-sign prose” app; silent full-natal claims without ephemeris. |

**Shared data (legitimate):** tropical/full natal sun & placements (once calculated), birth profile, PersonalDiscovery themes for **narrative emphasis only**.

**Current nested route** (`StarMapReferenceScreen` → `BirthChartScreen`) aligns with this constitution. Do not market Birth Chart as a separate Home peer of Yıldızname.

---

## 2. Non-negotiable honesty pipeline

```
USER EVIDENCE
→ EVIDENCE VALIDATION
→ DETERMINISTIC CALCULATION
→ STRUCTURED ASTRONOMICAL FACTS
→ INTERPRETATION
→ QUALITY GATE
→ NARRATIVE
```

**Forbidden:** birth details → LLM → invented natal chart.  
**Forbidden:** asking an LLM for Rising / Moon / houses / aspects.  
LLM (if used later) may receive only **already-calculated** structured facts.

**Deterministic calculation owns:** longitudes, signs, houses, aspects, Ascendant, MC, retrogrades, balances.  
**Interpretation owns:** meaning, themes, archive voice, PersonalDiscovery emphasis.  
**PersonalDiscovery must never alter astronomical facts.**

---

## 3. Evidence states (E0–E4)

| State | Known | Unknown | Allowed | Forbidden |
|-------|-------|---------|---------|-----------|
| **E0** | — | everything | onboarding / explanation only | any personal natal claim |
| **E1** | birth date | time, place/TZ | reduced symbolic / legacy date-based sun identity (explicit fidelity) | Ascendant, MC, houses, exact angles, fake precision |
| **E2** | date + place (+ coords; TZ resolvable) | exact time | interval-safe facts only | Ascendant, houses, MC; picking one Moon if sign changes in interval |
| **E3** | date + clock time text | place / TZ | **not** full natal; ask place once | treating device TZ as birth TZ; assuming Türkiye; UTC = local |
| **E4** | date + time + place (+ resolved TZ/UTC) | — | full natal **iff** verified ephemeris | prose-computed sky; silent noon chart |

### Completeness enum (conceptual)

`BirthEvidenceCompleteness`:

- `missingDate` → E0  
- `dateOnly` → E1  
- `dateAndPlaceNoTime` → E2  
- `dateAndTimeNoPlace` → E3  
- `full` → E4  

---

## 4. Unknown time — first-class state

- **Never** default to 12:00, 00:00, sunrise, random, or device now as a factual birth instant.  
- **Noon-chart invention forbidden.**  
- With date+place and unknown time: evaluate facts over the **valid local birth-day interval**; expose only **interval-stable** facts; mark others `ambiguous` / `unavailable`.  
- **No midpoint-guess.**  
- User confirms “I don’t know my birth time” → store conceptual `timeUnknownConfirmed`; **ask once**; allow later profile edit.  
- **Reduced scope is a success state**, not a fatal error.  
  Semantic UI truth: *“Bu yorum doğum saatin bilinmediği için saat bağımlı katmanları içermez.”*

---

## 5. Location / timezone contract (future)

Birth-place evidence must include conceptually:

| Field | Role |
|-------|------|
| `displayName` | User-facing place |
| `latitude` / `longitude` | Geographic |
| `timezoneId` | IANA (or equivalent) |
| `timezoneResolutionStatus` | resolved / missing / failed |

**Critical:** historical UTC offset ≠ today’s offset. Future calc must use a timezone DB with historically correct conversion.  
**Never:** birth local time → current device UTC offset.  
**Never:** assume current device timezone equals birth timezone.

---

## 6. Fact certainty

| Certainty | Meaning |
|-----------|---------|
| `exact` | Derived from a verified exact UTC instant |
| `intervalStable` | Same value across unknown-time interval |
| `ambiguous` | Changes within interval — do not pick |
| `unavailable` | Evidence/engine insufficient |
| `unsupported` | Engine does not implement this body/system |

Facts are not boolean presence alone — certainty travels with the fact.

---

## 7. Provenance & fidelity

Every future structured astronomical fact carries conceptually:

- calculation engine / version  
- input evidence fingerprint  
- calculation timestamp  
- fidelity  
- certainty  
- (optional) ephemeris dataset / version  

### Fidelity model (reuse + extend later)

Current enum (`ChartCalculationFidelity`):

| Value | Status |
|-------|--------|
| `tropicalSunSign` | **Live legacy** — date-based sun; not ephemeris |
| `fullNatalEphemeris` | Reserved — real engine |

**Future (do not change enum in Phase 1):** introduce conceptual `reducedNatal` (interval-safe / incomplete evidence) between legacy and full. Phase 4 may add enum value or equivalent metadata without pretending legacy was full.

**Legacy placeholders:** `sun.degree = 0`, `sun.house = 0` = **INTERNAL ONLY** — never user-visible astronomical claims. Phase 4 must eliminate or structurally harden.

---

## 8. Structured natal evidence (conceptual)

`NatalChartEvidence` may include placements for:

Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto; Ascendant; MC; houses; aspects; element/modality balances.

### Placement

`body`, `longitude`, `sign`, `degreeWithinSign`, `house?`, `retrograde?`, `certainty`, `provenance`

### Aspect

`bodyA`, `bodyB`, `aspectType`, `orb`, applying/separating **only if engine supplies**, `certainty`, `provenance`

### Houses

`houseSystem` **must be explicit** (e.g. Placidus, Whole Sign).  
**Phase 4 decision:** choose and freeze one primary system — do not mix silently. No prior product decision → mark for Phase 4 selection.

---

## 9. Allowed fact matrix (summary)

See Truth Matrix for full Evidence × Layer table.

| Layer | E0 | E1 | E2 | E3 | E4+ephemeris |
|-------|----|----|----|----|--------------|
| Sun identity (legacy/date) | ✗ | ✓* | ✓* | ✓* | ✓ exact |
| Moon | ✗ | ✗ | interval only | ✗ until place | ✓ |
| Personal/outer planets | ✗ | ✗ | interval only | ✗ | ✓ |
| Ascendant / MC / houses | ✗ | ✗ | ✗ | ✗ | ✓ |
| Aspects | ✗ | ✗ | rare interval-stable only | ✗ | ✓ |
| Element/modality from sun | ✗ | ✓* | ✓* | ✓* | ✓ from placements |
| Natal themes | ✗ | reduced* | reduced* | reduced* | full |
| Archive / discovery themes | narrative only — never rewrite sky | | | | |

\* = legacy/reduced fidelity, labeled honestly — not fake precision.

---

## 10. Evidence Acquisition Loop policy

Ask only for evidence that **unlocks** valid new layers:

| Gap | Ask |
|-----|-----|
| No date | birth date |
| Date only | optional place/time for deeper chart |
| Time unknown | “Do you know your birth time?” once |
| Time known, place missing | place once |

Never endless completeness loop.  
Missing time → successful reduced Yıldızname.

---

## 11. Forbidden behaviors (no fake precision)

Fake Moon / Rising / houses / aspects / exact degrees / retrogrades / timezone / coordinates / cusp mysticism / “dominant planet” without deterministic support.

**Cusp policy:** if exact longitude places Sun in a sign → that sign. If evidence cannot resolve a boundary → `ambiguous` / `unavailable`. No newspaper cusp marketing. Current `ZodiacSignId.fromDate` = **legacy** until calc upgrade.

---

## 12. Interpretation & LLM

- Interpretation receives **structured facts only** + verified discovery + verified artifacts + allowed user context.  
- Does **not** receive raw incomplete birth input to invent sky.  
- LLM for Yıldızname is **optional later**; if used = narration only.  
- LOCAL catalogue narrative remains valid for reduced/legacy layers.

---

## 13. Memory

| Memory | May affect | Must not affect |
|--------|------------|-----------------|
| PersonalDiscovery themes | narrative emphasis | planet/sign/house/aspect/Ascendant |
| Yıldızname-specific memory | emphasis from **real persisted artifacts** | fabricated “you often…” without artifacts; treating current reading as past |

---

## 14. Historical artifact constitution

A saved Yıldızname reading is an **IMMUTABLE ARTIFACT**.

Reopen must **not** rebuild from: today’s date, current locale, feature flags, new interpretation model, or updated PersonalDiscovery.

Artifact preserves conceptually: `artifactId`, `owner`, `createdAt`, evidence snapshot/ref, fidelity, calc version, structured fingerprint, narrative, result locale, source, schema version.

**LIVE TODAY VIEW** may evolve on a new calendar day.  
**SAVED HISTORY** must not.

### Stable IDs

Forbidden for durable identity: `Object.hash`, localized visible strings alone, locale, `DateTime.now` alone.  
Require explicit artifact id or deterministic durable content identity (algorithm in later phase).

### Owner isolation

Birth evidence, charts, artifacts, memory: **owner-scoped** when authenticated. A ↛ B. Anonymous/local mode needs explicit local-owner semantics.

---

## 15. Privacy

Birth data is sensitive.

| Surface | Default |
|---------|---------|
| Share | insight text only; no raw timestamp/coords/JSON/owner/machine ids |
| OR handoff | artifact id, verified placements, fidelity, narrative highlights — **not** raw lat/lon, storage keys, hidden uncertainty dumps, unrelated history |
| Analytics | no raw coordinates / exact birth timestamp by default |

Minimum necessary context only.

---

## 16. Safety & “karmic” language

**Forbidden certainty:** death date, lifespan, medical diagnosis, pregnancy certainty, legal/financial guarantees, crime prediction, guaranteed spouse identity, exact future event/date, fixed unavoidable fate.

**“Karmic”:** reflective metaphor only — never past-life fact, cosmic punishment, or objective destiny evidence. Prefer user-facing: themes, journey, threshold, İçindeki tema (per Phase 0 honesty direction).

---

## 17. Astrology distinction matrix

| Dimension | Yıldızname | Astrology |
|-----------|------------|-----------|
| Primary evidence | Birth evidence + natal calc | Present sky / period |
| Time horizon | Birth + archive | Now / today / period |
| Calculation | Natal baseline | Current + transits |
| User intent | Who I am / my sky archive | What’s happening now |
| Artifact | Immutable natal/archive readings | Daily/period may refresh by design |
| Daily behavior | Optional secondary “today’s reflection” | Primary daily job |
| Transits | Consumed later as overlay input | **Owns** transit computation |
| Natal facts | **Owns** | Reads from Yıldızname |
| Memory | Natal + archive artifacts | Period context; may reference natal |
| UI promise | Personal birth-sky archive | Present-sky timing |

**Interop:** Astrology may consume Yıldızname natal structured evidence (e.g. transit Saturn to natal Venus). Ownership stays as above.

---

## 18. Day-based archive role

Current `StarMapReadingService` day catalogue is **KEEP** as a **secondary** Yıldızname layer.

Conceptual sections (not implementing UI):

1. **Doğum Göğün** — natal / birth-sky (evidence-scoped)  
2. **Arşivindeki İzler** — PersonalDiscovery + saved artifacts  
3. **Bugünün Yansıması** — day seed; clearly non-natal  

`StarMapCopy` / `StarMapArchiveBeats` = **symbolic narrative assets**, never astronomical evidence.

---

## 19. Quality dimensions (future)

groundedness · evidence completeness · astronomical consistency · scope honesty · personal relevance · memory truth · claim safety · non-repetition · natural language · answer usefulness

---

## 20. Acceptance failure conditions (Phase 2+)

Harness must fail if: Moon/Rising/house/aspect invented; unknown time silently defaulted; place silently assumed; fact contradicts structured evidence; saved artifact regenerates; owner leakage; history fabricated; Astrology/Yıldızname identities collapse; unsafe fatalism; generic narrative ignores available evidence; device TZ used as birth TZ; `Object.hash` used as durable artifact id.

---

## 21. Ephemeris requirements (Phase 4 — no library yet)

Deterministic · offline/testable · historical dates · Sun/Moon/planets · Ascendant/MC when E4 · houses · aspects · timezone-correct instant · version/provenance · known astronomical fixtures.

### Fixture categories

normal chart · near sign boundary · Moon transition day · DST/historical TZ · high-latitude house edge · unknown-time interval · invalid evidence

---

## 22. UI truth states (semantic)

| State | Meaning |
|-------|---------|
| FULL | Calculated from birth time + place |
| REDUCED | Time-dependent layers omitted because time unknown / incomplete |
| SYMBOLIC / LEGACY | Date-based symbolic / `tropicalSunSign` fidelity |

Final marketing copy deferred; semantics frozen.

---

## 23. Monetization principle

Current: free. Phase 1: no monetization change.  
Users must never pay for “full natal” when only reduced/legacy scope is available without clear disclosure.

---

## 24. Migration

Preserve `birth_chart_latest` and favorites.  
Do not delete birth data.  
Do not reinterpret placeholders as full natal.  
Do not claim legacy charts were ephemeris-calculated.  
Legacy records keep explicit `tropicalSunSign` (or equivalent) fidelity.

### Versioning

Independent: `calculationVersion`, `interpretationVersion`, `artifactSchemaVersion`.

---

## 25. Phase 2 acceptance harness blueprint

| Family | Focus |
|--------|--------|
| A | Evidence completeness matrix |
| B | Fact certainty matrix |
| C | No-invention firewall |
| D | Owner isolation |
| E | Legacy record compatibility |
| F | Historical artifact immutability |
| G | Astrology / Yıldızname distinction |
| H | Safety claims |
| I | Locale invariance of **facts** |
| J | Deterministic calculation fixtures |
| K | Reduced-scope success |
| L | Memory truth |

---

## 26. Phase plan (frozen)

| Phase | Focus |
|-------|--------|
| **0** | Existing-system forensic audit — **COMPLETE** |
| **1** | Product constitution + astronomical honesty — **THIS** |
| **2** | Acceptance harness / truth fixtures |
| **3** | Birth Evidence + Evidence Acquisition Loop |
| **4** | Deterministic astronomical calculation / ephemeris |
| **5** | Structured evidence interpretation + quality gate |
| **6** | Frozen artifacts + owner-safe memory/history |
| **7** | Result architecture + visual craftsmanship |
| **8** | Complete E2E ritual |
| **9** | Destructive red-team |
| **10** | Full-app regression / YILDIZNAME COMPLETE |

Phase 0 suggested no plan rename; sequence retained.

---

## 27. Spec consistency invariants

1. Unknown time ⇒ Ascendant/houses/MC unavailable.  
2. No place/TZ ⇒ no exact natal instant ⇒ no full houses/Ascendant.  
3. Historical artifact immutable ⇒ reopen must not recompute from “today”.  
4. Yıldızname ≠ daily transit owner; Astrology owns present sky.  
5. PersonalDiscovery ≠ astronomical mutation.  
6. LLM ≠ sky calculator.  
7. Reduced scope = success, not failure.  
8. Legacy `degree=0`/`house=0` ≠ visible exact placement.  
9. `Object.hash` ≠ durable artifact identity.  
10. Device timezone ≠ birth timezone.

**Contradictions found in this spec:** none.

---

## 28. Baseline reconfirmation (Phase 1)

| Suite | Pass | Fail |
|-------|------|------|
| `test/features/star_map/` | 26 | 0 |
| `test/features/birth_chart/` | 30 | 0 |
| `test/yildizname_honesty_p0_test.dart` | 4 | 0 |
| Combined | 60 | 0 |

| `flutter analyze` | |
|-------------------|--|
| Errors | 0 |
| Warnings | 0 |
| Infos | 202 |

Matches Phase 0 baseline. No fixes applied.

---

## PHASE 1 — PASS / FROZEN

Next: Phase 2 — Acceptance harness / truth fixtures (no production engine yet).

STOP.
