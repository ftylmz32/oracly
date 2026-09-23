# Narrative Evidence Engine — Implementation Specification

**Phase:** 3D.0 (design / contract only)  
**Start SHA:** `e90a5109bbb75ce2c1247be686c9a149aa554846`  
**Status:** **READY FOR IMPLEMENTATION** (OPEN DECISIONS = 0)  
**Production code modified in 3D.0:** **NO**  
**Evidence Engine implemented:** **NO**  

Authority: `NARRATIVE_TAROT_SPEC.md` · `NARRATIVE_TAROT_DATA_CONTRACT.md` · `TAROT_KEYWORD_ONTOLOGY_FINAL_AUDIT.md` (3C.5F safeguards)

---

## 0 — Pipeline lock

```
ReadingSession FACTS
  → NarrativeEvidenceBuilder   (THIS SPEC — deterministic)
  → TarotNarrativeRequest
  → later NarrativeAiSynthesizer     (Phase 6 — NOT NOW)
  → later NarrativeQualityValidator  (Phase 6 — NOT NOW)
  → later TarotNarrativeResult
```

Builder does **not** write Tarot prose. It builds a closed, traceable evidence universe.

---

## 1 — Current implementation inventory

| Concept | Classification | Exact path / type |
|---|---|---|
| `NarrativeCardProfile` | EXISTS-REUSE | `lib/features/tarot/narrative/domain/narrative_card_profile.dart` |
| `NarrativeOrientationProfile` | EXISTS-REUSE | `…/narrative_orientation_profile.dart` |
| `NarrativeKeywordIds` | EXISTS-REUSE | `…/narrative_keyword_ids.dart` (rev 1, 128 ids) |
| `NarrativeSymbolTags` | EXISTS-REUSE | `…/narrative_symbol_tags.dart` |
| `ReversedTransformKind` | EXISTS-REUSE | `…/reversed_transform_kind.dart` |
| `NarrativeTarotProfileCatalog` | EXISTS-REUSE | `…/data/narrative_tarot_profile_catalog.dart` |
| `OraclyTarotDeck` / `OraclyTarotCard` | EXISTS-REUSE | `lib/features/tarot/deck/` |
| `OraclyTarotRelations` | EXISTS-ADAPT | `…/oracly_tarot_relations.dart` — `relatedIds` + note only (no kind/strength) |
| `OraclyTarotBridge` | EXISTS-REUSE | ritual int ↔ canonical id |
| `TarotContentCatalogue` / `DeckService` | EXISTS-REUSE | ritual deck content |
| `TarotSpreadType` + positions | EXISTS-ADAPT | `domain/models/tarot_spread.dart`, `tarot_spread_positions.dart` |
| `ReadingAsk` / `ReadingAskKind` | EXISTS-ADAPT | `reading/reading_ask.dart` — map → `QuestionKind` |
| `ReadingQuestion` | EXISTS-REUSE | sanitize / `real` / max 280 |
| `TarotIntention` | EXISTS-REUSE | text + optional topic |
| `ReadingContext` | EXISTS-ADAPT | interim input shape; map into builder input |
| `JourneyPersonalizationHints` | DEFERRED-LATER-PHASE | **must not** become recurrence facts in 3D.1 |
| `TarotInterpretationService` / Engine / Executors | EXISTS-REUSE (untouched) | user path stays on current stack |
| `SensitiveTopicGate` | EXISTS-REUSE | pre-AI short-circuit — do not weaken |
| `ReadingRelations` / Story / Beat… | EXISTS-REUSE (legacy local narrative) | **not** Evidence Engine; do not merge |
| `NarrativeEvidenceBuilder` | MISSING-CREATE | Phase 3D.1 |
| `TarotNarrativeRequest` + evidence types | MISSING-CREATE | from data contract |
| `RelationshipKind` | MISSING-CREATE | from data contract |
| `QuestionGrounding` / `QuestionKind` | MISSING-CREATE | map from `ReadingAskKind` + topic |
| `SpreadSemanticDefinition` / position edges | MISSING-CREATE | catalog over existing position keys |
| `RequestBounds` | MISSING-CREATE | contract defaults |
| Memory / recurring evidence | DEFERRED-LATER-PHASE | Phase 4 — empty shells only |
| Signature spreads | DEFERRED-LATER-PHASE | Phase 5 |
| AI synthesizer / quality validator | DEFERRED-LATER-PHASE | Phase 6 |
| Visual system | DEFERRED-LATER-PHASE | Phase 7 |

**Counts:** REUSE **18** · ADAPT **5** · CREATE **12** · DEFER **6** (approx; see module plan).

---

## 2 — Phase 3D.1 scope boundary

### IN SCOPE

- Current draw facts (canonical card ids, orientation, positions, spread id, question)
- Profile attach via `NarrativeTarotProfileCatalog`
- Structured signals: `keywordIds`, `symbolTags`, `ReversedTransformKind`
- Question grounding
- Classical spread semantics + position relation edges
- Deterministic relationship candidate scoring / ranking
- Closed request-scoped `evidenceId`s
- Empty memory / empty recurrence placeholders
- Pure function: no network, no AI, no storage

### OUT OF SCOPE

- Memory / recurring cards / recurring themes implementation
- Signature Spreads
- AI narrative synthesis / result prose / quality validator
- Persistence migration / UI / visual / billing / user-path switch

---

## 3 — Phase 4 placeholders (mandatory empty)

Phase 3D.1 `TarotNarrativeRequest` **must** include:

```dart
memory: TarotNarrativeMemoryEvidence(
  entries: const [],
  priorReadingCount: 0,
  recentCardNames: const [],      // MUST remain empty — never copy JourneyPersonalizationHints
  recurringThemeLabels: const [], // MUST remain empty
  included: false,
  omitReason: 'empty',            // or 'none' only when Phase 4 fills
),
recurringCards: const [],
recurringThemes: const [],
```

**Forbidden:** fabricating familiarity from hints, history, or journal.

Only Phase 4 dedicated providers may authorize “appeared again” / “N times” / “keeps returning”.

---

## 4 — Fact / inference / narrative boundary

| Layer | Producer | AI may |
|---|---|---|
| **FACTS** | Session | never rewrite |
| **INFERENCES** | Builder | select / phrase later; not invent |
| **NARRATIVE** | Phase 6 | prose only |

**Facts:** card ids, ritual ids, orientation, position keys/indexes, spread id, question raw/kind, canonical metadata.

**Inferences:** relationship kind, strength, provenance, optional note key, profile field emphasis, current-spread theme echo.

---

## 5 — No deterministic prose parsing

Builder **MUST NOT** NLP/parse:

`coreMeaning`, `light`, `shadow`, `tension`, `desire`, `fear`, `relationshipDynamic`, `decisionDynamic`, `actionDirection`, orientation `expression`, or any localized prose

for scoring.

Scoring uses only: `keywordIds`, `symbolTags`, transforms, `OraclyTarotRelations.relatedIds`, spread position edges, orientation, question kind, stable metadata (suit/rank as attenuation only).

Prose is attached as content for later synthesis, not scored.

---

## 6 — Closed request universe

### Evidence id format (LOCKED)

- Pattern: `rel_` + zero-padded 2-digit index: `rel_01` … `rel_12`
- Assigned **after** final ranked selection, in final output order
- Deterministic for identical builder inputs (excluding external session/reading uuid fields which are passthrough)
- Opaque, request-scoped, non-private (no card ids / memory in the id string)

### Closed-universe rules

- AI may reference only supplied `evidenceId`s
- Unknown id ⇒ hard fail at quality stage (Phase 6)
- Builder must never emit duplicate `evidenceId`s

---

## 7 — RelationshipKind contract

Keep contract enum values. **Semantic lock for `themeRepetition`:** means **current-spread theme echo only** — NOT historical recurrence.

**Recommended rename before AI phase (docs/code in 3D.1):** keep wire value `themeRepetition` for contract compatibility **or** introduce alias `themeEcho` with deprecated synonym. **Decision for 3D.1A:** implement enum as in contract (`themeRepetition`) with dartdoc: *“Current-spread theme echo only. Never historical.”* Rename PR optional later — **not blocking**.

| Kind | Definition | Min evidence | Does NOT qualify | Position | Orientation | Safe implication | Forbidden |
|---|---|---|---|---|---|---|---|
| `support` | Cards cooperatively aid the same workable stance | ≥2 independent families **or** canonical relatedIds + ≥1 semantic | Shared HF keyword alone; Page set identity alone | Affinity edges help | Same polarity preferred | “these lean together” | destiny / guaranteed help |
| `reinforcement` | Cards amplify the **same** semantic atom | ≥2 families including specific (non-HF-only) overlap | Broad HF-only overlap | Neutral | Same polarity | “same theme intensifies” | “you always…” |
| `contrast` | Structured opposite / productive tension | Explicit contrast-pair hit **or** position opposition + semantic | Synonym restatement | Opposition edges boost | Upright↔reversed may contribute | “these pull differently” | moral judgment |
| `conflict` | Active friction / opposition beyond mild contrast | Contrast + challenge/obstacle position **or** conflict-leaning keywords | Mere difference | challenge/obstacle edges | Often reversed involved | “friction is present” | enemy/accusation |
| `causeEffect` | Temporal or positional “leads into” | Position temporal edge required + ≥1 semantic | Keyword overlap alone | past→present→future etc. | Any | “A informs B’s condition” | prediction certainty |
| `blockage` | One card stalls / obstructs another’s movement | obstacle/challenge/hidden edge **or** delay/resistance/block keywords + other signal | Generic delay HF alone | obstacle edges | Reversed often | “something impedes” | permanent curse |
| `resolution` | Softening/integrating toward workable close | strength/direction/outcome affinity + supportive semantics | Wishful reading | direction/outcome/helps | Prefer constructive | “a way through appears” | guaranteed fix |
| `escalation` | Intensity / haste / excess climbing | excess/haste/anger-like overlap + position pressure | Single HF haste | challenge+near_future etc. | Reversed excess | “intensity rises” | panic prophecy |
| `softening` | Cooling / restraint / compassion easing heat | restraint/compassion/pause overlap + supportive edge | Random calm keyword | strength/helps | Often upright | “heat can cool” | toxic positivity |
| `themeRepetition` | ≥2 **current** cards share a material theme | See §29 | Historical recurrence language | Any | Any | “this theme appears in more than one place in **this** spread” | “again / keeps returning” |

---

## 8 — Signal channels (independent families)

| ID | Family | Source | Alone can admit? | Dedupe | Contradiction |
|---|---|---|---|---|---|
| A | Keyword semantic overlap | orientation `keywordIds` (channel-normalized) | **NO** | with C | vs B / polarity |
| B | Keyword semantic contrast | explicit contrast map (§14) | **NO** (needs second family or position) | — | overrides soft A |
| C | SymbolTag overlap | `symbolTags` after FR-F04 merge | **NO** | merged into A channel | — |
| D | Transform interaction | `ReversedTransformKind` lists | **NO** | dual-name with keyword | weak only |
| E | Canonical relations | `OraclyTarotRelations.relatedIds` membership | **YES** as *strong seed* **only if** + ≥1 other family (A/B/C/D/F/G/H) | — | outranks soft A |
| F | Spread-position edge | semantic catalog edges | **YES** for `causeEffect`/`blockage` kinds when edge type matches **and** ≥1 semantic family | — | shapes kind |
| G | Orientation pair pattern | upright/reversed pairing | **NO** | — | supports contrast |
| H | Question-kind relevance | `QuestionKind` boost/penalty | **NO** | — | reweights, never invents |
| I | Suit/rank context | metadata | **NO** — attenuate/veto/tie-break only | — | FR-F01/F02 |

**Independent family count:** A and C count as **one** family after dedupe (SemanticChannel). D is independent of SemanticChannel. E, F, G, H are independent.

---

## 9 — Keyword / symbolTag dedupe (FR-F04) — LOCKED

Per card orientation:

```
semanticChannelIds = unique( keywordIds ∪ { t ∈ symbolTags | t ∈ NarrativeKeywordIds.all } )
```

Tags **not** in the keyword ontology remain tag-only extras (separate weak TagOnly set) and **do not** double a keyword.

**Overlap scoring** between two cards uses `semanticChannelIds` intersection only once per id.

Same id on keyword + tag on the **same** card ⇒ **one** contribution.

---

## 10 — High-frequency keyword discrimination — LOCKED formula

Let:

- `N = 156` (orientations in ontology revision 1)
- `df(id)` = number of orientations containing `id` (frozen table derived from production catalog at ontologyRevision 1; ship as const map in `narrative_keyword_discrimination.dart`)
- Weight:

\[
w(id) = \ln\frac{N+1}{df(id)+1} + 1
\]

Clamp: `w' = clamp(w, 1.0, 6.0)`.

**Overlap mass** between cards A,B:

\[
S_{overlap} = \sum_{id \in Chan(A)\cap Chan(B)} w'(id)
\]

**Rule:** a single shared id with `df ≥ 8` (scatter, haste, withdrawal, escape, isolation, control, delay, display, fear, …) **cannot** alone admit a relationship — even if `S_overlap` is nonzero.

Ship frozen `df` map keyed by ontology revision; rebuild only when ontologyRevision bumps.

---

## 11 — Multi-signal admission — LOCKED

A pair **admits** iff **any** of:

1. **Standard:** `independentFamilyCount ≥ 2` **AND** `S_total ≥ 1.25`  
2. **Canonical seed:** E true (mutual or one-way `relatedIds` contains the other) **AND** `independentFamilyCount ≥ 2` (E counts as one) **AND** `S_total ≥ 1.0`  
3. **Position-strong:** F edge present with kind affinity **AND** ≥1 of {A/B/C/D} **AND** `S_total ≥ 1.0`

Where `S_total` = weighted sum of channel contributions (overlap, contrast, transform, canonical bonus, position bonus, question bonus) after contradiction penalties (§24).

**Never admit** on: one shared keyword only; FR-F01/F02 identical sets alone; HF-only single id.

---

## 12 — FR-F01 Page safeguard — LOCKED

If both cards are Pages (`rank == page` / id suffix `_11`) **and** `Chan(A) == Chan(B)` as sets **and** suits differ:

- Cap `S_overlap` contribution at **0.35**
- Force `independentFamilyCount` from SemanticChannel alone to count as **at most 1**
- Require **another** family (E, F, D, B, or H with structured support) before admission
- Max emitable strength for such pairs: **0.45** (weak)

Applies to known case: `wands_11` upright ↔ `pentacles_11` upright.

---

## 13 — FR-F02 Swords Page/Knight safeguard — LOCKED

If same suit **and** ranks are {page, knight} **and** `Chan(A) == Chan(B)`:

- Same caps as FR-F01 (overlap ≤0.35; channel family ≤1; need another family; strength ≤0.45)

Applies to: `swords_11` reversed ↔ `swords_12` reversed.

---

## 14 — Contrast / polarity map — LOCKED (explicit table)

Hardcoded reviewed pairs only — **no** string antonym inference.

| Left | Right | Class |
|---|---|---|
| balance | imbalance | HARD CONTRAST |
| stability | instability | HARD CONTRAST |
| belonging | isolation | HARD CONTRAST |
| abundance | scarcity | HARD CONTRAST |
| clarity | confusion | HARD CONTRAST |
| truth | denial | HARD CONTRAST |
| union | isolation | HARD CONTRAST |
| momentum | haste | CONTEXTUAL CONTRAST (productive vs premature motion) |
| nurture | rescue | CONTEXTUAL CONTRAST (care vs over-saving) |
| pause | delay | CONTEXTUAL CONTRAST |
| boundary | coldness | CONTEXTUAL CONTRAST |
| opening | closing | HARD CONTRAST |
| joy | despair | HARD CONTRAST |
| hope | despair | HARD CONTRAST |
| listening | notListening | HARD CONTRAST |

**DO NOT TREAT AS CONTRAST:** momentum↔direction, haste↔scatter (related difficulties, not opposites), control↔rigidity (adjacent), delay↔pause without context pair hit.

HARD CONTRAST hit ⇒ family B fires; soft overlap of unrelated ids does not cancel B.

---

## 15 — Transform signal contract — LOCKED

Transforms contribute family D:

- Shared transform set size ≥1 ⇒ weak bonus `+0.15` each unique shared kind, cap `+0.30`
- Alone: **never** admits
- Dual-name (`delay` keyword + `delay` transform): count transform bonus **or** keyword channel once for that name — **not both** (prefer keyword in SemanticChannel; suppress transform self-name double-count)
- Different transforms do not auto-contrast without B or position

---

## 16 — Canonical relations (`OraclyTarotRelations`) — LOCKED consume rules

**What exists:** undirected `List<String> relatedIds` + localized `note` on `OraclyTarotCard`. No kind, no strength, not directional.

**Consume:**

- If `cardA.relationshipWithOtherCards.relatedIds` contains `cardB.id` **or** reverse ⇒ family E true
- Canonical bonus `+0.55` once
- **Do not** parse `note` prose for scoring
- **Do not** fabricate missing relations
- E outranks incidental keyword overlap in kind resolution toward `support`/`reinforcement` when semantics agree; if B contrast also fires, prefer `contrast`/`conflict` over support

---

## 17 — Position semantics — classical spreads in 3D.1

### Spreads REQUIRED in 3D.1 semantic catalog

Reuse keys from `tarot_spread_positions.dart`:

| Spread id (`TarotSpreadType.name`) | Count | Position keys (order = interpretationOrder) |
|---|---:|---|
| `single` | 1 | `sign` |
| `threeCard` | 3 | `past`, `present`, `future` |
| `fiveCard` | 5 | `situation`, `hidden_influence`, `challenge`, `strength`, `direction` |
| `sevenCard` | 7 | `question`, `current_energy`, `obstacle`, `hidden_factor`, `what_helps`, `what_to_avoid`, `direction` |
| `celticCross` | 10 | `present`, `challenge`, `distant_past`, `recent_past`, `crown`, `near_future`, `self`, `environment`, `hopes`, `outcome` |

**Note:** Primary UI offers single/3/5 (+7 behind flag). Celtic is domain-complete; include in catalog so builder accepts all `TarotSpreadType` values without fake Signature spreads.

### Position relation edges (deterministic catalog)

Define undirected/directed edges with types: `temporal`, `opposition`, `supportive`, `pressure`, `mirror`.

**threeCard (examples):** past→present `temporal`; present→future `temporal`; past↔future weak `temporal`.

**fiveCard:** challenge↔situation `opposition`; strength↔challenge `supportive`; hidden_influence↔situation `pressure`; direction←situation `temporal`.

**sevenCard:** obstacle↔current_energy `opposition`; what_helps↔obstacle `supportive`; what_to_avoid↔direction `pressure`; question↔current_energy `mirror`.

**celticCross:** present↔challenge `opposition`; distant_past/recent_past→present `temporal`; near_future←present `temporal`; self↔environment `mirror`; hopes↔outcome `pressure`; challenge↔outcome `pressure`.

**single:** no pair edges (0 relationships unless impossible).

Exact edge table must be coded as data in `narrative_spread_semantics.dart` matching this spec (full enumerated list in implementation file; 3D.0 locks the model).

**Signature Spreads:** architecture-ready later; **no** production catalog entries in 3D.1.

---

## 18 — Position weighting — LOCKED

- Position edge presence contributes family F with bonus by type: opposition `+0.40`, temporal `+0.35`, supportive `+0.30`, pressure `+0.35`, mirror `+0.25`
- Kind resolution uses edge type (§7 / §21)
- Interpretation order distance used in tie-break only: `abs(indexA-indexB)` ascending preferred for equal scores
- Conflicting edges: opposition + supportive on same pair ⇒ prefer contrast/conflict over support unless canonical E strongly agrees with support **and** no HARD CONTRAST

---

## 19 — Question grounding — LOCKED

Map existing `ReadingAsk.kind(raw)`:

| `ReadingAskKind` | `QuestionKind` (new) |
|---|---|
| `decision` | `decision` |
| `relationship` | `relationship` |
| `guidance` | `guidance` |
| `other` | `open` |

Optional `topic` from `TarotIntention.topic` / Epic031 (`love|career|daily|general|money|custom`) stored on `QuestionGrounding.topic` — **does not** invent card facts.

`hasRealQuestion = ReadingQuestion.real(raw) != null`.

Question may reweight candidates (±0.15 max), never create relations alone.

---

## 20 — Profile field emphasis (slice contract) — LOCKED

Each `TarotNarrativeCardEvidence` carries a **profileSlice** selecting which authored fields travel for later AI:

| QuestionKind | Always include | Emphasize |
|---|---|---|
| `open` / `guidance` | coreMeaning, orientation.expression, keywordIds, symbolTags, transforms | tension, light, shadow |
| `relationship` | same always | relationshipDynamic, desire, fear |
| `decision` | same always | decisionDynamic, actionDirection, tension |

Always include: `canonicalCardId`, orientation bool, positionKey/index, displayName, imageAsset ref, safety-safe metadata.

Do **not** omit orientation expression. Do **not** score prose.

---

## 21 — Relationship candidate generation — LOCKED

- Max cards: **10** (celticCross)
- Internal pairs: all unordered pairs `C(n,2) ≤ 45`
- Score each pair → kind resolve → filter by admission → rank → take top **`maxRelationships = 12`**
- Assign `rel_01…` in final order

### Score components (deterministic)

```
S_total =
  S_overlap_weighted          // §10 on Chan∩
+ S_contrast                  // HARD +0.70 / CONTEXTUAL +0.45 if pair hits map
+ S_transform                 // §15
+ S_canonical                 // +0.55 if E
+ S_position                  // §18
+ S_question                  // −0.15…+0.15
− S_penalty_fr                // FR-F01/F02 caps already applied in overlap
− S_contradiction             // if HARD CONTRAST and soft support lobbied: −0.60 to support pathway
```

Clamp `S_total` to `[0, 3.5]` then map to strength:

`strength = clamp(S_total / 3.5, 0.0, 1.0)`

### Kind resolution precedence

1. If HARD CONTRAST or (CONTEXTUAL CONTRAST + opposition edge) ⇒ `contrast` or `conflict` (conflict if challenge/obstacle/pressure edge)
2. Else if temporal edge + semantic ⇒ `causeEffect`
3. Else if blockage semantics (delay/resistance/obstacle) ⇒ `blockage`
4. Else if softening semantics ⇒ `softening`
5. Else if escalation semantics ⇒ `escalation`
6. Else if resolution semantics + supportive edge ⇒ `resolution`
7. Else if theme-echo rule (§29) ⇒ `themeRepetition`
8. Else if E or strong overlap ⇒ `support` / `reinforcement` (reinforcement if ≥2 specific shared ids with mean w' ≥ 4.0)
9. Else drop

---

## 22 — Deterministic ordering — LOCKED

Sort admitted candidates by:

1. `strength` descending  
2. `abs(positionIndexA - positionIndexB)` ascending  
3. `min(positionIndexA, positionIndexB)` ascending  
4. `leftCanonicalId` lexicographic ascending  
5. `rightCanonicalId` lexicographic ascending  

For each pair, normalize left/right so `left` is the lower `positionIndex`; if equal index (impossible), lower `canonicalCardId`.

No hash-map iteration order dependence: materialize pairs from cards sorted by `positionIndex` then `canonicalCardId`.

---

## 23 — Relationship strength — LOCKED

- Range: `0.0 … 1.0`  
- Bands: weak `<0.40` · moderate `0.40–0.69` · strong `≥0.70`  
- Admission uses §11 (`S_total`), not band alone  
- **Never** present as probability / “80% likely”

---

## 24 — Contradiction overrides overlap — LOCKED precedence

1. HARD CONTRAST (B)  
2. Explicit position opposition (F)  
3. CONTEXTUAL CONTRAST  
4. Canonical E agreeing with contrast reading  
5. Specific keyword overlap (high w')  
6. Generic / HF overlap  
7. Transform-only similarity  

If (1) or (2) fire, do **not** emit `support`/`reinforcement` for that pair.

---

## 25 — Suit / rank role — LOCKED

- **Never** “both Cups ⇒ support” / “both Queens ⇒ same theme”
- Suit mismatch attenuates FR-F01 as in §12
- Rank adjacency FR-F02 as in §13
- Suit/rank may appear in tie-break only after §22 keys (optional 6th key: suit name) — **Decision:** do **not** add suit to tie-break (keep §22 as final)

---

## 26 — Card evidence slice

See §20. Minimum fields per card evidence follow data contract `TarotNarrativeCardEvidence`.

---

## 27 — Provenance tokens — LOCKED

Machine-readable, pipe-joined sorted unique tokens, e.g. `canonicalRelation|keywordOverlap|positionEdge`.

Approved set:

`keywordOverlap` · `keywordContrast` · `symbolTag` · `transform` · `canonicalRelation` · `positionEdge` · `orientationPair` · `questionRelevance` · `themeEcho` · `pageSuitGuard` · `courtRankGuard`

No user text inside provenance.

---

## 28 — Note contract — LOCKED

`noteKeyOrText`:

- Prefer `null`
- Else bounded key only: `note.rel.<kind>.<shortCode>` from a closed catalog (≤40 keys)
- **Forbidden:** free-form narrative sentences from builder

---

## 29 — Current-spread theme echo (`themeRepetition`) — LOCKED

Emit at most **one** theme-echo relationship (or a dedicated optional list later — **Decision:** encode as `RelationshipKind.themeRepetition` between the two strongest supporting cards, strength = echo score):

**Admit theme echo iff:**

- ≥2 cards share SemanticChannel id set intersection mass `S_overlap ≥ 2.0` using **non-HF-only** contribution: at least one shared id with `df < 8`
- OR ≥3 cards each pairwise share the same specific id with `df ≤ 6`

HF-only scatter/haste clusters **do not** create themeRepetition.

Copy must never imply historical recurrence.

---

## 30 — Memory / recurrence firewall — LOCKED

Builder pure over:

```
NarrativeEvidenceInput {
  sessionId, readingId, languageCode,
  questionRaw, intentionTopic?,
  spreadType,
  List<{canonicalCardId, ritualCardId?, isReversed, positionKey, positionIndex}>,
}
```

**Tests must prove:** no HistoryService, no JourneyPersonalizationHints read, no SharedPreferences, no recurring computation.

---

## 31 — Safety firewall — LOCKED

Forbidden evidence kinds / provenances / note keys implying:

partnerIsJealous · cheating · criminality · mentalIllness · pregnancy · death · guaranteedOutcome · destinedPartner · mindReadingClaim

Special ids `envy|projection|fear|attachment|control|rescue|bondage` may appear only as semantic channel members — never escalate to accusation kinds.

---

## 32 — SensitiveTopicGate boundary

Keep current placement in `TarotInterpretationService` **before** AI. Phase 3D.1 does not call the gate (deterministic, no prose). Phase 6 synthesizer wiring must still run gate before AI. Builder must not bypass or duplicate crisis prose.

---

## 33 — Performance / bounds

| Bound | Value |
|---|---|
| Network | 0 |
| Pair candidates | ≤45 |
| Emitted relationships | ≤12 |
| Cards | ≤10 |
| Complexity | O(n²) deterministic |

No fragile wall-clock gates; assert structural bounds in tests.

---

## 34 — Error contract — LOCKED typed failures

`NarrativeEvidenceError` sealed codes:

| Code | When |
|---|---|
| `unknownCanonicalCardId` | id not in deck/catalog |
| `profileMissing` | `NarrativeTarotProfileCatalog.lookup` null |
| `duplicatePositionKey` | two cards same positionKey |
| `cardCountMismatch` | cards.length ≠ spread.expectedCount |
| `unknownPositionKey` | key ∉ spread catalog |
| `invalidOrientation` | missing upright/reversed profile slice |
| `spreadMismatch` | unknown `TarotSpreadType` |
| `invalidOntologyId` | keyword/tag not in ontology (should be impossible) |
| `duplicateEvidenceId` | builder invariant broken |

**No silent partial success.** Builder errors do **not** trigger AI provider retries.

---

## 35 — Worked admission examples (≥20)

| # | Pair / case | Expected |
|---|---|---|
| 1 | wands_11↑ ↔ pentacles_11↑ keyword-identical Pages | **NO** strong relation; admit only if other family; strength≤0.45 |
| 2 | swords_11↓ ↔ swords_12↓ identical rev sets | same as 1 |
| 3 | wands_08↑ (momentum…) ↔ wands_08↓ (haste…) | contrast / contextual momentum–haste if co-present across cards |
| 4 | major_11↑ balance ↔ card with imbalance | HARD CONTRAST → contrast/conflict |
| 5 | same card keyword+tag `belonging` | dedupe once |
| 6 | only shared `scatter` | **reject** |
| 7 | only shared `haste` | **reject** |
| 8 | relatedIds hit + shared specific keyword | admit support/reinforcement |
| 9 | threeCard past↔present temporal + semantic | causeEffect candidate |
| 10 | fiveCard challenge↔strength | opposition/supportive → contrast or softening per semantics |
| 11 | sevenCard obstacle↔what_helps | blockage/resolution pathway |
| 12 | celtic present↔challenge | conflict/contrast lean |
| 13 | two cups belonging + position supportive | support |
| 14 | clarity↔confusion pair | contrast |
| 15 | delay keyword + delay transform same card vs other | no double-count |
| 16 | theme echo with rare id across 3 cards | themeRepetition |
| 17 | HF cluster across 3 cards only | **no** themeRepetition |
| 18 | relationship question boosts relationshipDynamic slice | slice only; no fake relation |
| 19 | single-card spread | 0 relationships |
| 20 | unknown card id | hard fail |
| 21 | stability↔instability | HARD CONTRAST |
| 22 | nurture↔rescue contextual | contrast only with second signal |
| 23 | canonical E + HARD CONTRAST | prefer contrast over support |
| 24 | empty question open kind | valid; no invention |

(Implement as fixture scenarios; expand to ≥40 in corpus §38.)

---

## 36 — Test architecture (paths)

```
test/features/tarot/narrative_evidence/
  narrative_evidence_builder_test.dart
  narrative_question_grounding_test.dart
  narrative_spread_semantics_test.dart
  narrative_keyword_discrimination_test.dart
  narrative_keyword_contrasts_test.dart
  narrative_relationship_scorer_test.dart
  narrative_evidence_bounds_test.dart
  narrative_evidence_errors_test.dart
  narrative_evidence_corpus_test.dart
test/features/tarot/narrative_evidence/red_team/
  narrative_evidence_fr_f01_f02_f04_test.dart
  narrative_evidence_safety_firewall_test.dart
  narrative_evidence_determinism_test.dart
  narrative_evidence_no_memory_test.dart
```

---

## 37 — Red-team regressions (required)

FR-F01 · FR-F02 · FR-F04 · one-keyword reject · HF-alone reject · contradiction>overlap · byte-stable structure (excluding session/reading ids) · unknown card/position fail · no recurrence · no memory query · no unsafe accusation evidence

---

## 38 — Fixed evidence corpus

**Path:** `test/fixtures/tarot_narrative_evidence_v1.json`  

**Minimum scenarios:** **40** covering single/3/5/7/10, question kinds, all RelationshipKinds Phase 3D.1 can emit, no-relation, FR-F01/F02/F04, safety, polarity, position contradictions.

Do **not** modify Phase 2 `narrative_tarot_v2_corpus.json`.

---

## 39 — Implementation module plan (CREATE later — do not create in 3D.0)

Under `lib/features/tarot/narrative/evidence/`:

| File | Responsibility |
|---|---|
| `narrative_evidence_builder.dart` | Public API `build(input) → TarotNarrativeRequest` |
| `narrative_evidence_models.dart` | Request/evidence/bounds/errors (or split if >150 lines) |
| `narrative_relationship_candidate.dart` | Internal candidate struct |
| `narrative_relationship_scorer.dart` | Score + kind resolve + admission |
| `narrative_keyword_discrimination.dart` | Frozen df map + w(id) |
| `narrative_keyword_contrasts.dart` | Contrast table |
| `narrative_spread_semantics.dart` | Spreads, edges, interpretation order |
| `narrative_question_grounding.dart` | ReadingAsk → QuestionGrounding |
| `narrative_semantic_channel.dart` | FR-F04 merge |

Reuse deck/profile/catalog imports; no UI.

Honor **≤150 lines/file** rule via splits.

---

## 40 — Implementation subphases

| Subphase | Scope |
|---|---|
| **3D.1A** | Models + QuestionGrounding + SpreadSemantics + empty memory/recurrence + errors |
| **3D.1B** | Semantic channel + discrimination + contrasts + transforms |
| **3D.1C** | Pair scoring, kind resolution, admission, ranking, evidence ids |
| **3D.1D** | Full `NarrativeEvidenceBuilder` + 40-scenario corpus |
| **3D.1E** | Independent red-team / readiness audit (read-only) |

One writer at a time. **No user-path wiring.**

---

## 41 — Definition of Done (Evidence Engine)

All §40 items green; 3C.5F twelve safeguards enforced; FR-F01/F02/F04 tests green; safety green; no memory/recurrence fabrication; bounds enforced; corpus green; profile/Phase2/R2 regressions green; full Flutter green; independent audit PASS; **user path unchanged**.

---

## 42 — No live AI / economy effect

3D.1 implementation: **0** AI calls · **0** gem charges · **0** billing · **0** persistence · **0** journal/history writes · **0** shadow providers.

---

## 43 — Spec decision table (OPEN = 0)

| Decision | Chosen answer | Rationale | Impl | Test |
|---|---|---|---|---|
| Prose parsing | Forbidden | Audit + architecture | no NLP | static review |
| maxRelationships | 12 | Data contract | RequestBounds | bounds test |
| Pair ceiling | C(n,2)≤45 | 10-card max | scorer | complexity |
| Evidence id | `rel_##` | Contract example | assign post-rank | determinism |
| themeRepetition meaning | Current-spread echo only | 3C.5F / Phase4 firewall | dartdoc + tests | no “again” |
| Enum rename | Keep `themeRepetition` + dartdoc | Avoid contract churn | comment | — |
| Admission | §11 exact | Multi-signal lock | scorer | red-team |
| IDF formula | §10 | Stable, testable | discrimination | unit |
| Tag dedupe | §9 | FR-F04 | channel | red-team |
| Contrast | Explicit table §14 | No string antonyms | contrasts | polarity |
| Canonical relations | relatedIds membership only | Actual API | E flag | unit |
| Spreads in 3D.1 | All 5 TarotSpreadType | Domain complete | semantics | lookup |
| Signature spreads | Defer Phase 5 | Scope | none | — |
| Question kinds | Map ReadingAskKind | Exists | grounding | unit |
| Strength range | 0–1 | Contract | map S_total | — |
| Tie-break | §22 | Determinism | sort | golden |
| Memory in 3D.1 | Empty omitReason empty | Phase4 | builder | no_memory |
| Hints as recurrence | Forbidden | Audit | — | red-team |
| Note policy | null or key catalog | No second narrator | — | — |
| Suit in tie-break | No | Simplicity | — | — |
| Celtic included | Yes in catalog | Engine-ready | semantics | — |
| User path | Unchanged | Charter | no wiring | — |
| SensitiveTopicGate | Unchanged pre-AI | Safety | Phase6 note | — |
| Dual delay count | Prefer keyword; suppress transform self-name | 3C.5F | scorer | unit |
| FR-F01/F02 caps | §12–13 | Audit minors | scorer | red-team |
| Theme HF | No HF-only themeRepetition | Audit | §29 | red-team |
| Builder errors | Typed; no AI retry | Fail-closed | errors | unit |
| Corpus size | ≥40 | Coverage | fixture | corpus |
| File location | `narrative/evidence/` | Feature boundary | create 3D.1 | — |
| Subphases | 3D.1A–E | Reviewability | prompts | — |
| Score→strength | S_total/3.5 | Bounded | scorer | — |
| Independent families | §8 after dedupe | Multi-signal | — | — |
| Position edge model | Typed edges catalog | Needed; positions exist, edges don't | CREATE | — |
| Journey hints | Not read | Firewall | — | no_memory |

**OPEN IMPLEMENTATION DECISIONS: 0**  
**SPEC READY FOR IMPLEMENTATION: YES**

---

## 44 — Acceptance contract for Phase 3D.1A (do not execute now)

### Scope

Create **models + question grounding + spread semantics + empty memory/recurrence shells + typed errors** only. No scoring yet.

### Allowed files (create)

- `lib/features/tarot/narrative/evidence/**` (models, grounding, spread semantics, errors)
- matching tests under `test/features/tarot/narrative_evidence/`
- docs pointer updates only if needed

### Forbidden

- Any change to user reading path / InterpretationEngine / AI executors / payments / profiles keywordIds / ontology constants content / Phase 2 corpus
- Scoring / builder full pipeline / AI / memory providers
- `release/ios-1.0`

### Gates

- `flutter analyze` clean on new surface  
- Unit tests for grounding + spread lookup + empty placeholders + errors  
- `git diff` shows no unrelated production  
- Full Flutter if any shared type touched  

### Stop

When 3D.1A tests green — **STOP**; do not start 3D.1B without review.

---

## Appendix A — Classical spreads summary

`single` · `threeCard` · `fiveCard` · `sevenCard` · `celticCross`  
(keys exactly as `tarot_spread_positions.dart`)

## Appendix B — Question kinds summary

`decision` · `relationship` · `guidance` · `open`  
(from `ReadingAskKind`)

## Appendix C — Relationship kinds summary

`support` · `reinforcement` · `contrast` · `conflict` · `causeEffect` · `blockage` · `resolution` · `escalation` · `softening` · `themeRepetition` (current-spread echo only)
