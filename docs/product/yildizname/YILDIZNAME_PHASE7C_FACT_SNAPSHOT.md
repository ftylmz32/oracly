# YILDIZNAME Phase 7C — Truthful Natal Fact Snapshot

**Status:** IMPLEMENTED  
**Canonical result owner:** `StarMapReferenceResultScreen` (unchanged — still the only result screen)  
**Fact source:** the STORED structured request of the accepted reading — nothing else  
**Not in this phase:** narrative hierarchy redesign (7D), footer/action parity (7E), responsive polish (7F),
golden master refresh + hash freeze (7G), live Narrative wiring (Phase 8).

---

## The rule

> **No stored fact → no displayed fact. The resolved scope is the ceiling. Every rule below can only REMOVE a fact.**

A displayed fact must be provably present in the exact request that belongs to that reading. Nothing is derived from
prose, section text, summary/reflection/closing, theme labels, result `factRefs`, titles, the current
`BirthProfile`, the birth-chart repository, or a recalculation. Reopen never touches astronomy.

## Layering

```
stored request (immutable)      resolved scope (7B resolver)
        │                              │
        └────────────┬─────────────────┘
                     ▼
        YildiznameFactProjector.project(resolved, request, languageCode)
                     ▼
        YildiznameFactSnapshot   (typed, localized, display-ready)
                     ▼
        YildiznameResultPresentation.factSnapshot
                     ▼
        StarMapReferenceResultScreen → StarMapFactSnapshotPlate
```

The widget receives finished strings. It never sees a request map, a wire value, a `factRef`, a certainty word, a
fidelity, an `omittedLayers` entry or an artifact id. `YildiznameArtifactPresentation._narrative` is the **only**
production caller of the projector, so `narrativeLive(request, result)` (Phase 8 readiness) and an artifact reopen
project through the identical path and yield value-equal snapshots (tested).

### Types (`lib/features/star_map/result/`)

| Type | Meaning |
|---|---|
| `YildiznameFactSubject` | typed body / angle (Sun … Pluto, Ascendant, Midheaven) — never a wire string |
| `YildiznameFactGroup` | `primary` · `secondary` · `outer` |
| `YildiznameDisplayFact` | subject · group · localized `label` · localized sign `value` · optional `detail` (degree · house · retrograde) · `semanticsLabel` |
| `YildiznameDisplayAspect` | localized first / second body + localized aspect name (orb is validated, never displayed) |
| `YildiznameDisplayBalance` | localized label + localized dominant element / quality |
| `YildiznameFactSnapshot` | `primary` · `secondary` · `outer` · `aspects` · `balances` + localized chrome; `empty`, `isEmpty`, `hasDeeper`, value equality |
| `YildiznameFactChrome` | closed wire→typed maps (unknown ⇒ `null` ⇒ fact dropped) and localized labels. No `.name`, no `birth_chart` import |
| `YildiznameFactProjector` | the pure projector (no clock, no randomness, no IO) |
| `StarMapFactSnapshotPlate` | the one widget |

`YildiznameResultPresentation.factSnapshot` defaults to `YildiznameFactSnapshot.empty`; it participates in value
equality / hash. `withoutFactSnapshot()` returns the exact Phase 7B shape (used to keep the 7B baselines honest).

---

## What each scope may show

| | LEGACY | REDUCED | FULL |
|---|---|---|---|
| Snapshot | **empty** (never built from the planet catalogue) | signs only | signs + precision |
| Placements | — | only `intervalStable` signs actually stored | `exact` (degree, house, retrograde) and `intervalStable` (sign only) |
| Exact degree | — | **never** | only finite `0 ≤ v < 30` from an `exact` fact |
| Ascendant / MC | — | **never** | only stored, `exact`, not omitted, kind/`factRef` agree |
| House number | — | **never** | only when the resolver says houses are present and the number is an integer 1–12 |
| Aspects | — | **never** | only when the resolver says aspects are present, both bodies are displayed facts |
| Balances | — | **never** | dominant element / quality only when the stored dominant is the **unique** maximum |
| Retrograde | — | **never** | `retrograde == true` on an `exact` fact of a planet that can be retrograde (not Sun / Moon) |

### The ceiling

The projector receives the `YildiznameResolvedScope` computed by the 7B `YildiznameScopeResolver` (lightest claim
wins, structure-backed, `omittedLayers` caps). Finding richer fields in the request never upgrades anything:

- rich FULL request + `reducedNatal` fidelity / `reduced` artifact scope / conflicting scope markers ⇒ REDUCED
  behaviour;
- FULL request with `omittedLayers ∋ exactDegrees` ⇒ resolver caps to REDUCED ⇒ no degree;
- `omittedLayers ∋ ascendant | midheaven | houses | aspects` ⇒ the resolver clears that layer flag ⇒ not shown
  even though the object is physically present (contradiction never resolves toward the richer display).

**Decision — `exact` under a REDUCED ceiling is not trusted.** A downgrade means the evidence that the birth time
was known is contradicted; an `exact` Moon computed from a possibly guessed time can sit in the wrong sign. Only
`intervalStable` signs (which hold across the whole time uncertainty) survive a REDUCED ceiling. A downgraded rich
FULL request therefore projects to an empty or interval-stable-only snapshot — truthful, never richer.

**Note — a bare Sun cannot prove REDUCED.** The frozen 7B resolver resolves “reduced + Sun only” to the LEGACY
level; that resolution is respected, so it yields no snapshot.

### Fail-closed rules (every fact)

Dropped when: the body / sign / aspect / kind is unknown or not a `String`; certainty is missing, unknown,
`ambiguous`, `unavailable` or `unsupported`; a body is stated twice (contradictory); a placement `factRef` is
missing, non-string, or is not **exactly** `placement.<body>`; an angle is missing `kind` or `factRef`, or they
disagree / are unknown (both sides are required — never inferred); an aspect `factRef` is missing, non-string, or
is not **exactly** `aspect.<bodyA>.<bodyB>.<type>` for the stored raw fields; an aspect names an undisplayed body,
the same body twice, or an invalid orb (NaN / negative / non-number); a balance is stated twice, has malformed
counts, an unknown dominant, a non-maximum dominant, or a **tied** maximum (the request builder breaks ties
silently and “dominant” over a tie would be a false claim).

### Duplicate aspects (Phase 7C.1)

Aspects are grouped by a **canonical** key after identity validation:

`rank(bodyA′) | rank(bodyB′) | type` where bodies are ordered by fixed subject rank.

| Case | Policy |
|------|--------|
| Identical copies (same canonical bodies, type, finite orb; each row has its own matching raw factRef) | Collapse to **one** deterministic candidate |
| Conflicting evidence for the same key (e.g. different orbs) | **Drop the entire canonical aspect** — do not choose first / last / min / max orb |

False understatement is preferred over invented certainty. Request-array order never decides which orb wins or which aspects enter the top-5 cap.

Malformed containers (a non-list array, non-map entries, missing arrays) project to nothing and never throw.

---

## Precision decisions (documented, deterministic)

| Topic | Decision |
|---|---|
| Degree format | **Whole degrees, truncated** (`22.4 → 22°`, `29.99 → 29°`). Truncation follows astrological convention, can never round across a sign boundary (`29.99°` never becomes `30°`), and shows no sub-degree precision the stored value does not warrant. No arc-minutes. |
| Real `0.0°` | A genuine stored `0.0` renders `0°`. Only an absent / invalid degree renders nothing — the value `0°` is never synthesised. |
| Invalid degree | NaN, ±∞, negative, `≥ 30`, non-number ⇒ degree omitted (the sign still shows). |
| Locale | Degrees are locale-independent (`11°` in TR/EN/RU). |
| Retrograde | Shown as a localized word after degree/house, exact facts only, never for Sun/Moon. |
| Orb | Validated and used **only** to choose/order aspects; **not displayed** (avoids false precision in a compact layer). |
| House system | The `houseSystem` wire value is **never** displayed. House numbers are shown only as per-placement detail. |
| House list | The 12 stored house signs are **not** rendered as a chart/table (documented subset — a fake wheel would violate the design brief). The typed snapshot can grow to carry them. |

---

## Ordering (deterministic — never request-array order)

PRIMARY: Sun · Moon · Ascendant · Midheaven  
SECONDARY: Mercury · Venus · Mars  
OUTER: Jupiter · Saturn · Uranus · Neptune · Pluto  
ASPECTS: ascending orb, then body order, then aspect order, capped at **5** (tightest first)  
BALANCES: element, then quality

Shuffling or rotating the request arrays, or inserting unknown facts, never changes the snapshot.

---

## UI treatment — one quiet plate, not a dashboard

`StarMapFactSnapshotPlate` sits **after the scope note and before the summary** (app bar → scope note → **facts** →
summary → chapters → footer) and is absent when the snapshot is empty. It is one hairline-bordered block (gold =
accent only, no glass card per planet, no zodiac wheel, no chart, no rainbow, no game stats):

1. Title: *Doğum göğün / Your birth sky / Твоё небо рождения*.
2. **Primary** (Sun · Moon · Ascendant · Midheaven): a compact 1–2 column tile grid chosen from the *real* width and
   text scale (no fixed heights).
3. **Secondary** (Mercury · Venus · Mars): one wrapping line of “Body Sign detail”.
4. **Deeper layer, folded by default** behind one full-width ≥44px toggle (only when it has content): outer planets,
   the closest aspects, dominant element / quality. Restrained by design — the summary, not the data, stays the hero.

REDUCED renders as complete-within-scope: sign lines, no toggle (no deeper content exists), no placeholder for
missing time-dependent layers. The only interactive element is the toggle (button semantics, expanded state);
non-interactive content creates no buttons.

Accessibility: each fact is one calm semantics node (`Güneş, Aslan, 22° · 10. ev`) in reading order = visual order;
the title is a header. Verified at 320×568, 390×844, 412×915, 360×800 @ 1.3× and 320×568 @ 1.3× in TR/EN/RU (no
overflow, nothing clipped, everything inside the plate).

## Localization

Reuses the existing tables — `planet.*` (bodies), `zodiac.*` (signs), `aspect.*`, `birth.element.*` — so there is one
translation of each name in the app. New chrome only in `table_star_facts.dart` (TR/EN/RU): title, more-toggle, outer
planets, aspects heading, Midheaven, retrograde, house, dominant element / quality, cardinal / fixed / mutable.
(EN keeps the existing product term “Rising” for the Ascendant.)

---

## Red-team matrix → tests

`test/features/star_map/result/phase7c_fact_projector_test.dart` (matrix A–X + balance / immutability groups):
A legacy absent · B bare Sun · C reduced stable planets · D reduced with stray degree · E FULL complete · F no Moon ·
G no Ascendant · H no houses · I no aspects · J omitted Asc/MC · K omitted houses · L downgrade ceiling ·
M ambiguous/unavailable/unsupported/unknown certainty · N unknown body · O unknown sign · P unknown aspect ·
Q real 0.0 · R invalid degree · S no request · T profile non-enrichment · U live/artifact parity · V TR/EN/RU ·
W identifier scan · X determinism.
`phase7c_fact_screen_test.dart`: position, legacy absence, folding, tap target, semantics, responsiveness, rendered
identifier scan, profile non-enrichment through the real reopen screen, immutability through the screen.
`phase7c_firewall_test.dart`: static firewall (no provider / astronomy / profile / network / clock on the fact path,
one production projector caller, widget reads no request, single result screen, visual order, l10n keys).
The projector guards were mutation-tested (ceiling, omitted layers, degree range, rounding, certainty, house gate,
aspect gate, tie rule, ordering): every mutant is killed.

## Golden policy

- **7A masters:** untouched (SHA-256 verified before / after).
- **7B fixtures:** untouched. The 7B golden pumps now render `presentation.withoutFactSnapshot()` — the exact 7B
  contract — because 7C changes production for those artifacts; they are *not* rewritten as if 7C changed nothing.
- **7C expected-delta fixtures** (`test/goldens/yildizname/phase7c/`, phase-scoped, not masters):
  `phase7c_narrative_reduced_facts_390` · `phase7c_narrative_full_complete_390` ·
  `phase7c_narrative_full_complete_expanded_390` · `phase7c_narrative_full_partial_390` (no Ascendant / houses /
  aspects) · `phase7c_legacy_reopen_fact_layer_absent_390` · `phase7c_narrative_full_complete_{320x568,412x915,360x800_ts13}`.
- **7G** owns the master consolidation + hash freeze.

## Files

Production: `lib/features/star_map/result/yildizname_fact_{snapshot,chrome,projector}.dart` ·
`yildizname_result_presentation.dart` (+`factSnapshot`, `withoutFactSnapshot`) ·
`artifacts/yildizname_artifact_presentation.dart` (projector call) ·
`presentation/reference/star_map_fact_snapshot_plate.dart` (new) · `star_map_reference_result_screen.dart`
(integration) · `lib/core/l10n/tables/table_star_facts.dart` (+ `app_string_tables.dart`).

One 7B helper hardened: `YildiznameScopeResolver._maps` now skips (instead of throwing on) a non-string-keyed
entry — found by the 7C red-team; behaviour for every valid input is identical and unreachable from persisted JSON.

Tests: `test/features/star_map/result/phase7c_*_test.dart` · `test/support/yildizname_result_fixtures.dart`
(`rich`) · `test/visual/yildizname/yildizname_phase7c_golden_test.dart` (+ 7B golden pump / one 7B screen assertion
adapted, harness path helpers).

Backend / astronomy / provider contract / artifact schema & storage / Phase 6 memory / Tarot / footer order /
Phase 8 wiring: **unchanged**.
