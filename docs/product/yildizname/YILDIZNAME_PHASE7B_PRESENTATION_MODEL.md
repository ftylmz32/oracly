# YILDIZNAME Phase 7B — Presentation Model · Truthful Scope Disclosure · Localized Chrome

**Status:** IMPLEMENTED (closes verified debts **B1** and **B2** from Phase 7A)  
**Canonical result owner:** `StarMapReferenceResultScreen` (unchanged — still the only result screen)  
**Artifact adapter:** `YildiznameArtifactPresentation` → typed `YildiznameResultPresentation`  
**Not in this phase:** natal fact visual layer (7C), narrative hierarchy redesign (7D), footer reorder (7E), responsive polish (7F), golden master refresh (7G), live Narrative wiring (Phase 8).

---

## What 7B closes

| Debt | Before | After |
|---|---|---|
| **B1** raw titles leaked | `summary` · enum `.name` (`coreIdentity`) · `reflection` · `closing` shown as result chrome | explicit localized chrome (TR/EN/RU); typed roles; unknown kinds → neutral chapter chrome; `sectionChromeTitle` (the `.name` leak) deleted |
| **B2** no scope truth | stored scope/fidelity/omitted-layers never reached the reader | quiet archive **scope note** derived from stored evidence, fail-closed |

---

## Layering (presentation firewall)

```
artifact / request / result (immutable, stored)
        │
        ▼   YildiznameArtifactPresentation.of(artifact, chromeLocale?)
YildiznameResultPresentation  (typed, display-ready, deterministic)
        │
        ▼
StarMapReferenceResultScreen  →  StarMapScopeNote · section cards · footer
```

Widgets never read payload maps, wire names, fidelity strings, or `omittedLayers`. A static firewall test
(`phase7b_firewall_test.dart`) enforces this, plus: no provider / astronomy / network imports on the presentation
path, no enum `.name` derivation, no hard-coded product label, no second result screen, and no production caller
of the test-only unscoped compatibility path.

### Types (`lib/features/star_map/result/`)

| Type | Meaning |
|---|---|
| `YildiznameResultSource` | `legacyLive` · `legacyArtifact` · `narrativeLive` · `narrativeArtifact` — chosen by the caller, never inferred from copy. `isArtifact` / `isNarrative` helpers. |
| `YildiznameResultScope` | `legacy` · `reduced` · `full` — presentation semantics, never a wire value. Ordered; resolution only moves **down**. |
| `YildiznameSectionRole` | `summary` · `chapter` · `reflection` · `closing` — so 7D can style roles apart without re-parsing titles. |
| `StarMapResultSection` | `title` (display chrome) · `body` (stored prose) · `role`. |
| `YildiznameScopeDisclosure` | resolved evidence + localized `kicker` + `body`. |
| `YildiznameResultPresentation` | source · scope · title · sections · planets (legacy only) · scopeDisclosure · artifactId (internal) · createdAtUtc · chromeLanguage · `isHistoricalArtifact`. Value-equal → deterministic projection is testable. |
| `YildiznameResultChrome` | explicit `switch` mappings to localization keys. Never `.name`, never a wire name. |
| `YildiznameScopeResolver` | fail-closed scope resolution from stored evidence. |

`YildiznameArtifactPresentation.narrativeLive(request, result, …)` projects a live accepted result through the **same**
path as a reopen, so Phase 8 needs no second screen or chrome path. Artifact reopen (`StarMapArtifactReopenScreen`)
now builds the typed presentation and hands it to the canonical screen.

---

## Scope truth — fail-closed resolution

`FULL` does **not** mean every natal layer is present. The resolver inspects, at minimum:

1. `artifact.source` (legacy-local is fixed `legacy`)
2. artifact `scope` and `fidelity`
3. stored `request.scope`, `request.fidelity`, `result.scope`
4. stored `request.omittedLayers`
5. stored structured request arrays (`placements` degrees, `angles`, `houses`, `aspects`, `balances`, `houseSystem`)

Rules (every rule can only **lower** the claim):

- **Every declared marker is a claim; the lightest wins.** A present-but-unrecognized or non-string marker supports no
  claim above `legacy`. Blank markers are absent, not conflicting.
- **Structure must back the claim.** `full` needs exact structure (degrees / angles / houses / aspects / house system);
  `reduced` needs more than a bare Sun or a stored balance. Rich structure never outranks a lighter claim.
- **`omittedLayers` contradicts.** `exactDegrees` caps at `reduced`; `moon` / `personalPlanets` caps at `legacy`.
- **Missing request or no markers** → cannot prove anything → `legacy`-level disclosure (the lightest, still-true claim).
- **Layer flags** (`hasAscendant/Midheaven/Houses/Aspects`) exist only under `full`, and only when the layer is
  present in the stored request **and** not listed in `omittedLayers`.

No astronomy is recalculated, no provider is called, no artifact is mutated on reopen (tests assert hash, payload
and integrity are unchanged).

### Disclosure copy (`star.result.scope.*`, TR/EN/RU)

| Resolution | Meaning (EN) |
|---|---|
| `legacy` | A symbolic interpretation based on the birth-date and Sun-sign level information available to this reading. It is not a precise sky-chart calculation. |
| `reduced` | A personalized interpretation based on the birth details available. Because the birth time is not certain, time-dependent layers such as the Ascendant and houses are not included. |
| `full` (every layer present) | A natal interpretation based on the birth details that were calculated. |
| `full` (any layer absent) | Same, plus: *Only the layers that could actually be calculated were used.* |

FULL wording never names a layer positively and never promises an exhaustive set. Kicker: *What this reading rests on.*

---

## Localized chrome

- Product title → the app's own `nav.star_map` label (TR `Yıldızname`, EN `Yıldızname`, RU `Йылдызнаме`).
- Roles: summary / reflection / closing (`star.result.role.*`); neutral chapter (`star.result.chapter.neutral`).
- All 10 `YildiznameSectionKind` values map explicitly (`star.result.chapter.*`) — see the chapter table in
  `YILDIZNAME_PHASE7_VISUAL_CONTRACT.md` (plural “Açılar ve evler” used for angles + houses).
- Unknown / future / non-string kinds → neutral chapter title; prose is preserved; the identifier is never shown.
- Stored prose is **never** trimmed, localized, or rewritten. Chrome localizes to the *current* app language
  (`OraclyL10n.depend`); prose keeps its stored result language (TR body under EN/RU chrome is valid).

---

## UI — the scope note

`StarMapScopeNote`: a hairline brass rail beside a quiet two-line note. Not a banner, not a card, not interactive
(so no tap-target obligation), no glow, gold as accent only. Placed **between the app bar and the summary** per the
frozen visual hierarchy (identity → disclosure → facts (7C) → summary). Reading order = visual order; header
semantics on the kicker; readable at the Phase 7A `textScale 1.3` fixture in TR/EN/RU and at 320×568 / 390×844 / 412×915.

No natal fact cards were added (7C).

---

## Test & golden policy (7A baseline handling)

The 7A masters represent **pre-7B** production and are **untouched on disk** (hash-locked by the 7A hash test).

- The 7A pixel masters keep exercising the shared chrome through the **pre-typed `.unscoped` compatibility path**
  (`StarMapReferenceResultScreen.unscoped`, `@visibleForTesting`; no production caller — firewall-enforced). They
  remain byte-identical, which proves the shared chrome (hero, lanes, footer, atmosphere) did not drift.
- `artifact_legacy_reopen_390` was a **production** path; its 7A master now renders the *stored legacy payload*
  through the unscoped path (exact pre-7B reopen output, including the OR context) so the 7A master still passes
  unchanged. The new production reopen is captured in a phase-scoped fixture.
- **Expected-delta fixtures (phase-scoped, not masters):** `test/goldens/yildizname/phase7b/`
  `phase7b_artifact_legacy_reopen_390.png` · `phase7b_artifact_narrative_reduced_390.png` ·
  `phase7b_artifact_narrative_full_390.png`. Delta vs 7A: localized chrome titles + the scope note; prose identical.
- 7A tests that *documented* the B1 defect (`current narrative reduced exposes raw titles`) were flipped to prove
  the defect is closed through the production adapter (`B1 closed — Narrative adapter never exposes raw titles`).
- **7G** owns the comprehensive golden refresh + hash freeze. Nothing here is a final master set.

## Files

Production: `lib/features/star_map/result/*` (types, resolver, chrome, presentation) ·
`artifacts/yildizname_artifact_presentation.dart` (typed projection; `sectionChromeTitle` removed from
`yildizname_narrative_payload.dart`) · `presentation/reference/star_map_reference_result_screen.dart`,
`star_map_artifact_reopen_screen.dart`, `star_map_result_open.dart`, `star_map_result_section.dart`,
`star_map_scope_note.dart` (new) · `lib/core/l10n/tables/table_star_result.dart` (+ `app_string_tables.dart`).

Tests: `test/features/star_map/result/phase7b_{scope_resolver,presentation,screen,firewall}_test.dart` ·
`test/support/yildizname_result_fixtures.dart` · `test/visual/yildizname/yildizname_phase7b_golden_test.dart`
(+ 7A harness adaptations described above).

Backend / astronomy / Tarot / dependencies: **unchanged**.
