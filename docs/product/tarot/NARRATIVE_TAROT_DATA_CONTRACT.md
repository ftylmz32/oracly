# NARRATIVE TAROT DATA CONTRACT

**Program:** ORACLY Narrative Tarot V2  
**Document kind:** IMPLEMENTATION DATA CONTRACT (pseudocode / tables — no Dart files yet)  
**Schema version:** `narrativeTarotVersion = 2`  
**Status:** Phase 1 — **NOT IMPLEMENTED**

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

**Derivation:** adapters may seed from existing `symbolicMeaning` → core, `challengeMeaning` → shadow, etc., until authored profiles are complete.

---

## 2. NarrativeOrientationProfile

```dart
class NarrativeOrientationProfile {
  final L10nTriple expression;            // how this orientation speaks
  final List<ReversedTransformKind> transforms; // upright: usually empty/default
  final List<String> keywordIds;          // optional bridge to existing keywords
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
  final String spreadId;                  // e.g. classical.threeCard | signature.the_mirror
  final String? legacyTypeName;           // TarotSpreadType.name when classical
  final int cardCount;
  final String purposeKey;                // l10n key for spread purpose
  final List<SpreadPositionSemantic> positions;
  final List<int> interpretationOrder;
  final NarrativeGeometryHook geometryHook; // for Visual System
  final NarrativeLengthBand lengthBand;   // short|medium|full|deep
}

enum NarrativeGeometryHook {
  singleFocus, linearThree, classicalFive, classicalSeven,
  celticCross, mirrorAxis, betweenUsBridge, other,
}
```

---

## 4. SpreadPositionSemantic

```dart
class SpreadPositionSemantic {
  final String positionKey;
  final int index;
  final String role;                      // stable role id
  final String guidingQuestionKey;        // l10n
  final TemporalOrientation temporal;     // past|present|future|none
  final String narrativeFunction;         // setup|conflict|aid|outcome|...
  final List<PositionRelationEdge> relationToOtherSlots;
  final double weight;                    // 0..1
  final String displayLabelKey;           // l10n
}

class PositionRelationEdge {
  final String otherPositionKey;
  final String edgeKind;                  // opposes|supports|explains|...
}
```

---

## 5. TarotNarrativeCardEvidence (FACT)

```dart
class TarotNarrativeCardEvidence {
  final String canonicalCardId;
  final int ritualCardId;                 // 0..77 bridge id when applicable
  final bool isReversed;
  final String positionKey;
  final int positionIndex;
  final String displayName;               // locale-resolved at request build
  final NarrativeCardProfile profileSlice;// or profile id + resolved locale strings
  final String imageAsset;
}
```

Facts: card, orientation, position — AI must not rewrite.

---

## 6. TarotNarrativeRelationshipEvidence (DERIVED FACT / INFERENCE BAND)

```dart
class TarotNarrativeRelationshipEvidence {
  final String leftCardId;
  final String rightCardId;
  final String leftPositionKey;
  final String rightPositionKey;
  final RelationshipKind kind;
  final String provenance;                // relatedIds|suitAffinity|positionRoles|traitOverlap|adjacency
  final double strength;                  // 0..1
  final String? noteKeyOrText;            // optional localized seed from OraclyTarotRelations
}

enum RelationshipKind {
  support, reinforcement, contrast, conflict, causeEffect,
  blockage, resolution, escalation, softening, themeRepetition,
}
```

Deterministic builder emits these. AI may narrate among them; must not invent undrawn cards.

---

## 7. TarotRecurringCardEvidence

```dart
class TarotRecurringCardEvidence {
  final String canonicalCardId;
  final int occurrenceCount;              // exact
  final List<RecurringOccurrence> occurrences;
  final bool contextsOverlap;             // computed relevance
  final String? overlapSummaryKey;        // only if overlap true
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

---

## 8. TarotRecurringThemeEvidence

```dart
class TarotRecurringThemeEvidence {
  final String themeIdOrLabel;            // from verified insights / intention clusters
  final int supportCount;
  final List<String> supportingReadingIds;
  final List<String> relatedCardIds;      // optional
  final double relevanceToCurrentAsk;     // 0..1 vs current question/spread
}
```

Separate from card recurrence. Omit when `relevanceToCurrentAsk` below threshold.

---

## 9. TarotNarrativeMemoryEvidence

```dart
class TarotNarrativeMemoryEvidence {
  final String? memorySummary;            // verified OraclyMemory excerpt
  final String? revisitPriorExcerpt;
  final String? revisitInstruction;
  final int priorReadingCount;
  final List<String> recentCardNames;     // bounded
  final List<String> recurringThemeLabels;// bounded
  final bool included;                    // false ⇒ omit from prompt
  final String omitReason;                // none|empty|irrelevant|privacy
}
```

Hierarchy: current spread > current context > relevant recent history > longer memory.

---

## 10. TarotNarrativeRequest

Authoritative package for synthesis. Prefer **stable IDs** over bare ambiguous strings.

```dart
class TarotNarrativeRequest {
  final int narrativeTarotVersion;        // 2
  final String languageCode;              // tr|en|ru
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
  final String? topic;                    // love|career|daily|general|...
  final QuestionKind kind;                // explicit|topicOnly|open|relationship|decision|...
  final bool hasRealQuestion;
}

class RequestBounds {
  final int maxPriorReadingsScanned;      // e.g. 20
  final int maxRecurringOccurrencesListed;// e.g. 5
  final int maxRelationships;             // e.g. 12
  final int maxMemoryChars;               // e.g. 800
  final int maxThemeLabels;               // e.g. 4
}
```

### Bound defaults (contract)

| Bound | Default |
|---|---|
| Prior readings scanned | 20 |
| Recurrence lookback days | 90 |
| Relationships sent to AI | top 12 by strength |
| Memory summary chars | 800 |
| Theme labels | 4 |
| Recurring occurrence samples | 5 most recent |

**No unbounded prompt growth.**

---

## 11. Evidence layers (FACT vs INFERENCE vs NARRATIVE)

| Layer | Who produces | Mutable by AI? |
|---|---|---|
| **FACTS** | Session / store (cards, orientation, positions, question, saved recurrence) | **NO** |
| **INFERENCES** | Deterministic evidence builder (relationships, relevance scores, counts) | AI may **select**; must not invent contradiction of facts |
| **AI NARRATIVE** | Model synthesis | YES — prose only |

AI must never rewrite a fact (wrong card, false count, invented reading id).

---

## 12. TarotNarrativeResult

Primary product schema. Love/Career/Money are **not** required primary fields.

```dart
class TarotNarrativeResult {
  final int narrativeTarotVersion;        // 2
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
  final String? recurringInsight;         // optional user-facing; only if evidence
  final TarotNarrativeQualityMetadata quality;
  final DateTime generatedAt;
  final InterpretationSource source;      // ai|local (local only when policy allows)
}
```

### Legacy adapter (migration only)

May project into old `InterpretationResult` / `AiReadingContent` for temporary UI:

| Legacy field | Projection rule |
|---|---|
| summary | opening + meaningForUser (clipped) |
| advice | actionDirection |
| closingMessage | closing |
| fullInterpretation | concatenated narrative beats |
| love/career/money/… | empty or topic-conditional secondary only |

---

## 13. TarotNarrativeBeat

```dart
class TarotNarrativeBeat {
  final String beatId;
  final String kind;                      // opening|tension|movement|turn|meaning|action|closing|custom
  final String text;
  final List<String> cardIds;
  final List<String> positionKeys;
  final List<String> relationshipEvidenceIds;
  final List<String> memoryEvidenceRefs;  // opaque refs, not raw PII dump
}
```

Traceability is **required** for quality/debug. Not necessarily shown to user.

---

## 14. TarotCardDetailResult

Secondary layer (card sheet / expand).

```dart
class TarotCardDetailResult {
  final String canonicalCardId;
  final String positionKey;
  final bool isReversed;
  final String title;
  final String orientationNote;
  final String positionNote;
  final String detailBody;                // concise; not a second full reading
  final String imageAsset;
}
```

---

## 15. TarotNarrativeQualityMetadata

Machine-checkable flags for Phase 2 harness (define fields now; scoring later).

```dart
class TarotNarrativeQualityMetadata {
  final bool questionGrounded;
  final bool allCardsRepresented;
  final bool positionSemanticsUsed;
  final bool relationshipEvidenceUsed;
  final bool unsupportedCertaintyDetected;
  final bool memoryEvidenceUsed;
  final bool recurrenceEvidenceUsed;
  final bool legacySectionDependence;
  final double? genericityScore;          // optional future
  final List<String> failureTags;         // empty if pass
}
```

Production fail-closed (R2/R2.1): quality failure ⇒ typed error / retry — **not** fake success.

---

## 16. Localization strategy (Decision H)

| Asset | Strategy |
|---|---|
| Card names, profile fields, position labels, spread purpose | Authored `L10nTriple` / l10n keys (tr/en/ru) |
| AI narrative body | Generated in `languageCode` of request |
| Quality / mixed-language | Reject or fail quality if body language mismatches request |
| Recurrence user strings | Template + localized card names; counts are numeric facts |

---

## 17. Domain vs UI (Decision F)

- `TarotNarrativeResult` lives in **domain / interpretation** layer.
- Widgets map beats → Narrative Result UI (Phase 6/7).
- No widget imports inside evidence builders or quality validators.
- Visual System consumes `geometryHook` + card assets only — not AI prose structure.

---

## 18. Pipeline data flow (contract view)

```text
ReadingSession (facts)
  → NarrativeEvidenceBuilder (deterministic)
       profiles · positions · relationships · recurrence · memory filter
  → TarotNarrativeRequest
  → NarrativeAiSynthesizer (AI)
  → NarrativeQualityValidator
  → TarotNarrativeResult (v2)
  → Persistence (versioned)
  → UI mapper / legacy adapter
```
