# NARRATIVE TAROT DATA CONTRACT

**Program:** ORACLY Narrative Tarot V2
**Document kind:** IMPLEMENTATION DATA CONTRACT (pseudocode / tables — no Dart files yet)
**Schema version:** `narrativeTarotVersion = 2`
**Status:** Phase 1 / 1.1 hardened — **NOT IMPLEMENTED**

Companion: `NARRATIVE_TAROT_SPEC.md`, `NARRATIVE_TAROT_MIGRATION_PLAN.md`

---

## 0. Versioning

```text
narrativeTarotVersion: 2
```

- V2 results are distinguishable from legacy `InterpretationResult` / `AiReadingContent`.
- Old saved readings remain readable via v1 loaders / adapters.
- Forward writers must stamp version on every new narrative result.

---

## 1. NarrativeCardProfile

Keyed by **canonical Oracly card id** (`major_00` … suit ranks). Does **not** replace `OraclyTarotCard`.

```dart
class NarrativeCardProfile {
  final String cardId;                    // canonical
  final L10nTriple coreMeaning;
  final L10nTriple light;
  final L10nTriple shadow;
  final L10nTriple tension;
  final L10nTriple desire;
  final L10nTriple fear;
  final L10nTriple relationshipDynamic;
  final L10nTriple decisionDynamic;
  final L10nTriple actionDirection;
  final NarrativeOrientationProfile upright;
  final NarrativeOrientationProfile reversed;
  final List<String> symbolTags;          // sparse, language-agnostic ids
  final int profileRevision;
}
```

**Derivation:** adapters may seed from existing meanings during Phase 3 / shadow only.

**Production V2 gate:** all 78 cards × release locales must pass deterministic completeness — missing profile is **not** a production success condition (see Spec §4).

---

## 2. NarrativeOrientationProfile

```dart
class NarrativeOrientationProfile {
  final L10nTriple expression;
  final List<ReversedTransformKind> transforms;
  final List<String> keywordIds;
}

enum ReversedTransformKind {
  internalization, delay, excess, deficiency, avoidance,
  distortion, blockedExpression, misdirection, release, privateInternal,
}
```

---

## 3. SpreadSemanticDefinition

```dart
class SpreadSemanticDefinition {
  final String spreadId;                  // classical.* | signature.the_mirror | signature.between_us
  final String? legacyTypeName;           // TarotSpreadType.name when classical
  final int cardCount;
  final String purposeKey;                // machine token in 3D.1 (e.g. purpose.classical.threeCard)
  final List<SpreadPositionSemantic> positions;
  final List<int> interpretationOrder;
  final NarrativeGeometryHook geometryHook; // carried metadata; Phase 7 owns visuals
  final NarrativeLengthBand lengthBand;     // Phase 6 prose policy; not scored in 3D.1
}

enum NarrativeGeometryHook { singlePoint, linearRow, celticCross }

enum NarrativeLengthBand { short, medium, full, long }
```

**Canonical signature ids (immutable once persisted):**

- `signature.the_mirror`
- `signature.between_us`

Underscore forms (`signature_the_mirror`) are **not** valid persisted ids.

**Classical catalog (Phase 3D.1):** see `NARRATIVE_EVIDENCE_ENGINE_IMPLEMENTATION_SPEC.md` §17 — complete; not examples.

---

## 4. SpreadPositionSemantic

```dart
enum TemporalOrientation { past, present, future, atemporal }

/// Structural slot role. In 3D.1 classical spreads, narrativeFunction MUST equal role.
enum PositionRole {
  signal, context, root, state, challenge, hiddenInfluence, support,
  direction, self, environment, hopeFear, outcome, question, avoid,
}

class SpreadPositionSemantic {
  final String positionKey;                 // runtime key; do not rename
  final int index;
  final PositionRole role;
  final String guidingQuestionKey;          // machine token in 3D.1 (gq.classical.*)
  final TemporalOrientation temporal;
  PositionRole get narrativeFunction => role; // 3D.1A identity lock (getter)
  final List<PositionRelationEdge> relationToOtherSlots; // projected from §17.4
  final double weight;                      // 3D.1 classical: always 1.0
  final String displayLabelKey;             // tarot.pos.<positionKey>
}

enum PositionEdgeKind { temporal, opposition, supportive, pressure, mirror }

class PositionRelationEdge {
  final String otherPositionKey;
  final PositionEdgeKind edgeKind;          // typed — never free-form strings
  final bool directed;
  // Directed A→B: only A receives the projected entry (directed:true).
  // Undirected A↔B: both A and B receive projected entries (directed:false).
  // 29 authoritative rows → 45 projected relation entries (13 directed + 16×2).
}
```

Authoritative edge list: Evidence Engine Implementation Spec §17.4 (29 edges). No implementer-invented edges.

---

## 5. TarotNarrativeCardEvidence (FACT)

```dart
class TarotNarrativeCardEvidence {
  final String canonicalCardId;
  final int ritualCardId;
  final bool isReversed;
  final String positionKey;
  final int positionIndex;
  final String displayName;
  final TarotNarrativeProfileSlice profileSlice;
  final String imageAsset;
}
```

Facts: card, orientation, position — AI must not rewrite.

### 5.1 TarotNarrativeProfileSlice (request-side; Phase 3D.0.1)

**Not** a substitute for authored `NarrativeCardProfile`. Derived by the Evidence Builder from the catalog profile for the current draw + question kind.

```dart
class TarotNarrativeProfileSlice {
  // REQUIRED base
  final L10nTriple coreMeaning;
  final L10nTriple orientationExpression; // exact drawn orientation only
  final List<String> keywordIds;            // exact drawn orientation only
  final List<String> symbolTags;            // card-level
  final List<ReversedTransformKind> transforms; // upright=[]; reversed=actual

  // OPTIONAL / question-emphasis (null when not selected)
  final L10nTriple? light;
  final L10nTriple? shadow;
  final L10nTriple? tension;
  final L10nTriple? desire;
  final L10nTriple? fear;
  final L10nTriple? relationshipDynamic;
  final L10nTriple? decisionDynamic;
  final L10nTriple? actionDirection;
}
```

| QuestionKind | Optional fields present (others null) |
|---|---|
| `open` | light, shadow, tension |
| `guidance` | light, shadow, tension, actionDirection |
| `relationship` | relationshipDynamic, desire, fear, tension |
| `decision` | decisionDynamic, actionDirection, tension, fear |

Domain models retain `L10nTriple`. Phase 6 owns locale flattening for AI transport.
---

## 6. TarotNarrativeRelationshipEvidence

```dart
class TarotNarrativeRelationshipEvidence {
  final String evidenceId;                // REQUIRED — request-scoped opaque id
  final String leftCardId;
  final String rightCardId;
  final String leftPositionKey;
  final String rightPositionKey;
  final RelationshipKind kind;
  final String provenance;
  final double strength;
  final String? noteKeyOrText;
}

enum RelationshipKind {
  support, reinforcement, contrast, conflict, causeEffect,
  blockage, resolution, escalation, softening, themeRepetition,
}
```

### Evidence id contract

| Rule | Requirement |
|---|---|
| Presence | Every relationship evidence row has a unique `evidenceId` within the request |
| Scope | Request-scoped / opaque (e.g. `rel_01`) — deterministic within builder for a given request |
| AI | May reference **only** ids supplied in `TarotNarrativeRequest.relationships` |
| AI | May **never invent** an evidence id |
| Validator | Unknown `relationshipEvidenceIds` on beats ⇒ **HARD FAIL** |

---

## 7. TarotRecurringCardEvidence

```dart
class TarotRecurringCardEvidence {
  final String evidenceId;                // REQUIRED — request-scoped
  final String canonicalCardId;
  final int occurrenceCount;              // exact deterministic count
  final List<RecurringOccurrence> occurrences;
  final bool contextsOverlap;
  final String? overlapSummaryKey;
}

class RecurringOccurrence {
  final String readingId;
  final DateTime at;
  final String spreadId;
  final String positionKey;
  final bool isReversed;
  final String? intentionSummary;
}
```

**Authority:** Sole source for explicit card-recurrence claims/counts.

---

## 8. TarotRecurringThemeEvidence

```dart
class TarotRecurringThemeEvidence {
  final String evidenceId;                // REQUIRED — request-scoped
  final String themeIdOrLabel;
  final int supportCount;
  final List<String> supportingReadingIds;
  final List<String> relatedCardIds;
  final double relevanceToCurrentAsk;
}
```

**Authority:** Sole source for explicit theme-recurrence claims. Omit when relevance below threshold.

---

## 9. TarotNarrativeMemoryEvidence

```dart
class TarotNarrativeMemoryEvidence {
  final List<MemoryEvidenceEntry> entries;
  final int priorReadingCount;
  final List<String> recentCardNames;      // MIGRATION HINT ONLY
  final List<String> recurringThemeLabels; // MIGRATION HINT ONLY
  final bool included;
  final String omitReason;                 // none|empty|irrelevant|privacy
}

class MemoryEvidenceEntry {
  final String evidenceRef;                // REQUIRED opaque request-scoped ref (e.g. mem_01)
  final MemoryEvidenceKind kind;           // memorySummary|revisitExcerpt|revisitInstruction
  final String contentForModel;            // bounded; never encoded into ids
}

enum MemoryEvidenceKind { memorySummary, revisitExcerpt, revisitInstruction }
```

### Recurrence vs memory hints

`recentCardNames` / `recurringThemeLabels` **must not** authorize “appeared N times” or “theme keeps returning”.
Dedicated recurrence evidence only.

### Privacy of memory refs

- Refs are opaque; no raw private memory inside ids.
- User-facing result does not expose evidence identifiers.
- Share/export strips quality/evidence metadata.
- Analytics/logging must not dump `contentForModel`.
- Prefer **not** persisting raw memory evidence with the reading (see §15).
- R1: deleting history/memory removes future influence.

---

## 10. TarotNarrativeRequest

```dart
class TarotNarrativeRequest {
  final int narrativeTarotVersion;
  final String languageCode;
  final String sessionId;
  final String readingId;
  final QuestionGrounding question;
  final SpreadSemanticDefinition spread;
  final List<TarotNarrativeCardEvidence> cards;
  final List<TarotNarrativeRelationshipEvidence> relationships;
  final TarotNarrativeMemoryEvidence memory;
  final List<TarotRecurringCardEvidence> recurringCards;
  final List<TarotRecurringThemeEvidence> recurringThemes;
  final RequestBounds bounds;
}

class QuestionGrounding {
  final String? rawText;
  final String? topic;
  final QuestionKind kind;
  final bool hasRealQuestion;
}

class RequestBounds {
  final int maxPriorReadingsScanned;            // default 20
  final int maxRecurringOccurrencesListed;      // default 5
  final int maxRelationships;                   // default 12
  final int maxMemoryChars;                     // default 800
  final int maxThemeLabels;                     // default 4
}
```

**RequestBounds has exactly these 5 fields.** The **90-day recurrence lookback is not a RequestBounds field** — it is Phase 4 recurrence-provider policy only.

The request is the **closed universe** of referenceable card ids, position keys, and evidence ids/refs for this synthesis.

### Bound defaults

| Bound | Default |
|---|---|
| Prior readings scanned | 20 |
| Relationships sent to AI | top 12 by strength |
| Memory summary chars | 800 |
| Theme labels | 4 |
| Recurring occurrence samples | 5 most recent |

**Provider policy (not RequestBounds):** recurrence lookback days = 90 (Phase 4).

**No unbounded prompt growth.**

---

## 11. Evidence layers (FACT vs INFERENCE vs NARRATIVE)

| Layer | Who produces | Mutable by AI? |
|---|---|---|
| **FACTS** | Session / store | **NO** |
| **INFERENCES** | Deterministic evidence builder | AI may **select**; must not contradict facts |
| **AI NARRATIVE** | Model synthesis | YES — prose only |

AI must never rewrite a fact (wrong card, false count, invented reading id, invented evidence id).

---

## 12. TarotNarrativeResult

```dart
class TarotNarrativeResult {
  final int narrativeTarotVersion;
  final String languageCode;
  final String sessionId;
  final String readingId;
  final String? headline;
  final String opening;
  final String coreTension;
  final String movement;
  final String turningPoint;
  final String meaningForUser;
  final String actionDirection;
  final String closing;
  final List<TarotNarrativeBeat> beats;
  final List<TarotCardDetailResult> cardDetails;
  final String? recurringInsight;         // only if dedicated recurrence evidence exists
  final TarotNarrativeQualityMetadata quality;
  final DateTime generatedAt;
  final InterpretationSource source;
}
```

Love/Career/Money are **not** required primary fields. Legacy adapter may project for interim UI.

---

## 13. TarotNarrativeBeat

```dart
class TarotNarrativeBeat {
  final String beatId;
  final String kind;
  final String text;
  final List<String> cardIds;                    // must ⊆ request cards
  final List<String> positionKeys;               // must ⊆ request positions
  final List<String> relationshipEvidenceIds;    // must ⊆ request relationship evidenceIds
  final List<String> memoryEvidenceRefs;         // must ⊆ request memory evidenceRefs
  final List<String> recurringEvidenceIds;       // optional; must ⊆ card/theme recurrence evidenceIds
}
```

Traceability is **required** for quality/debug. **Not** shown to user. Share/export strips these ids.

---

## 14. TarotCardDetailResult

```dart
class TarotCardDetailResult {
  final String canonicalCardId;
  final String positionKey;
  final bool isReversed;
  final String title;
  final String orientationNote;
  final String positionNote;
  final String detailBody;
  final String imageAsset;
}
```

Together with beats, supports **`allCardsAccountedFor`** without forcing equal narrative paragraphs.

---

## 15. TarotNarrativeQualityMetadata

```dart
class TarotNarrativeQualityMetadata {
  final bool questionGrounded;
  final bool allCardsAccountedFor;        // preferred name (Phase 1.1)
  final bool positionSemanticsUsed;
  final bool relationshipEvidenceUsed;
  final bool unsupportedCertaintyDetected;
  final bool memoryEvidenceUsed;
  final bool recurrenceEvidenceUsed;
  final bool legacySectionDependence;
  final bool referentialIntegrityOk;
  final double? genericityScore;
  final List<String> failureTags;
}
```

### Persistence / privacy boundary (Phase 1.1)

| Field class | Runtime | Persist with reading | Debug-only | Safe analytics | Share/export |
|---|---|---|---|---|---|
| Booleans / failure tags / genericityScore | YES | **MAY** persist (useful reopen/audit) | — | YES if aggregated | Strip if any risk |
| Opaque evidence ids/refs | YES | **Prefer NOT** persist | YES | NO | **MUST strip** |
| Raw memory `contentForModel` | YES (request only) | **MUST NOT** persist on result | ephemeral | NO | NO |
| Beat texts / narrative prose | YES | YES (user content) | — | careful | YES (user-facing) |

**Preferred architecture:** persist narrative prose + version + minimal quality booleans/tags; recompute or drop detailed evidence graphs; never persist unnecessary raw memory evidence.

Quality metadata must **not** become a container for private memory content.

---

## 16. NarrativeQualityValidator — HARD FAILURES (Phase 1.1)

AI output **must fail** validation if any of:

| Failure | Meaning |
|---|---|
| Unknown / undrawn card id on beat or detail | not in request cards |
| Unknown position key | not in request spread |
| Unknown relationship `evidenceId` | not in request.relationships |
| Unknown memory `evidenceRef` | not in request.memory.entries |
| Unknown recurring `evidenceId` | not in request recurrence lists |
| Recurrence claim count ≠ deterministic evidence | rewritten count |
| Recurring card claim without supplied recurrence evidence | invented recurrence |
| Rewritten orientation vs request facts | |
| Rewritten spread facts (card set / positions) | |

These are **HARD FAILURES**.

Production behavior remains **R2 / R2.1**:

typed failure → bounded retry → fail-closed

**Never** silently repair fabricated facts into a successful reading.

Referential integrity: beat → evidence refs must resolve inside the request universe.

---

## 17. Localization strategy (Decision H)

| Asset | Strategy |
|---|---|
| Profiles, positions, spread purpose | Authored l10n / `L10nTriple` |
| AI narrative body | Request `languageCode` |
| Mixed/wrong language body | Quality fail |
| Recurrence templates | Localized names + numeric facts |

---

## 18. Domain vs UI (Decision F)

- `TarotNarrativeResult` is domain-layer.
- Widgets map beats; no business logic in widgets.
- Internal evidence ids never render in UI / share.

---

## 19. Pipeline data flow

```text
ReadingSession (facts)
  → NarrativeEvidenceBuilder (deterministic)
       profiles · positions · relationships(+evidenceId)
       recurrence(+evidenceId) · memory entries(+evidenceRef)
  → TarotNarrativeRequest
  → NarrativeAiSynthesizer (AI)
  → NarrativeQualityValidator (HARD referential + quality gates)
  → TarotNarrativeResult (v2)
  → Persistence (versioned; minimal metadata; no raw memory dump)
  → UI mapper / legacy adapter (strip internal refs on export)
```
