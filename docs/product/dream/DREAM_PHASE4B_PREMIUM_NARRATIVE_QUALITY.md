# Dream Phase 4B — Premium Narrative Quality / Red-Team Firewall

Status: Phase 4B. Builds on Phase 1 (owner/privacy), Phase 2 (provenance,
multilingual identity, evidence), Phase 3 (safety firewall) and Phase 4A
(grounded history) without changing their contracts.

A Dream reading is accepted only when each section does its own job, stays
faithful to what the dreamer said, and invents nothing about their life. The
checks are deterministic and lexical. They make no extra provider call and
use no network or NLP library.

**Limits.** Every example in this phase is synthetic. Passing these tests does
not show that a live model writes premium Dream readings. Phase 4C evaluates
real provider output.

## Audit before 4B

- The backend accepted any reply that passed Phase 2 and the 4A history gate.
  That included plot retellings, a "deep fear" when the dreamer said "I was
  not afraid", generic wellness lines, and invented "your job / your family".
- `?` outside the conclusion passed the backend. Only the client closing
  counted questions.
- The client silently completed missing or rejected required sections with
  local text and still labelled the reading `fromAi` / "mixed". The summary
  could stand in for the emotional theme.
- Backend and client grounding disagreed. The client rejected five of nine
  backend-acceptable goldens, for two reasons:
  - Catalogue "fear" was treated as an invented image even when the dreamer
    said "not afraid".
  - The client requires every section to touch a told word of 4 or more
    letters.

## Backend acceptance order

`dreamAcceptanceFailure` (`backend/src/ai/dream-acceptance.ts`) runs after
parse and output safety. The first failure wins:

1. Phase 2 `evaluateDreamQuality` (unchanged)
2. Phase 4A `dreamHistoryClaimViolation` (unchanged)
3. Phase 4B `evaluateDreamPremiumQuality`

Any failure becomes `invalid_response` after exactly one provider call, with no
retry, repair or rewrite. The reason is never exposed or logged. Safety and
quality stay separate systems.

## Phase 4B failures (in order)

| Code | Rule |
|---|---|
| `thin_section` | A prose section shorter than 24 characters. This is the client guard floor. |
| `extra_question` | `?` in summary, theme, interpretation or reflection. The only question lives in the conclusion; Phase 2 already requires it to hold exactly one. |
| `symbol_list` | More than 8 symbols, or duplicates after fold, trim and whitespace collapse. |
| `plot_recap` | At least 60% of summary tokens sit inside trigrams copied from the narrative. Pronouns are mapped from first to second person, and summaries under 6 tokens are exempt. Reusing an image ("red door") passes. |
| `emotion_contradiction` | Theme or summary, each checked on its own, affirms a feeling the narrative only negated, or negates one the narrative only affirmed. Covers fear, anxiety, calm, joy, sadness and curiosity in TR/EN/RU. |
| `invented_image` | Mirrors the client catalogue rule: a catalogue image (11 TR/EN entries) that the dreamer never told. RU is exempt, as on the client. Fear is exempt when the dreamer spoke of fear, stated or denied. |
| `ungrounded_section` | Mirrors the client: summary, theme and interpretation must each reach a told word of 4 or more letters (directional TR inflection). |
| `weak_interpretation` | In a rich narrative, the interpretation reaches fewer than 2 distinct anchor clusters. |
| `generic_reflection` | The reflection reaches neither the Dream nor the filtered `payload.memorySummary`, or it contains 2 or more wellness clichés. |
| `unsupported_personal_fact` | A sentence addressed to the reader names a life domain (work, relationship, family, money, school, health or childhood) that neither the narrative, symbols, emotions nor safe memory supports. |
| `weak_conclusion` | A leading yes/no question, a question with no wh-word, or a question not grounded in the Dream. |

### Thresholds

- **Rich narrative:** at least 5 distinct anchor words spread over at least 3
  clusters.
  - Anchors are words of 3 or more letters, excluding stop words and dream
    words.
  - A cluster is a run of adjacent anchors inside one clause; clauses break
    at punctuation.
- **Interpretation of a rich narrative:** must reach at least 2 clusters. A
  sparse dream is never failed for staying with one image.
- **Cluster granularity:** clusters are deliberately coarse, so "the lamp at
  the top was dark" counts as two ("lamp" and "dark"). The rule only fails an
  interpretation that clearly stays with a single detail.

### Emotion negation

The check works per clause; clauses split at punctuation and at
but/ama/но-style contrast words. Negation is recognized in four ways:

- **Word-level:** fearless, korkmadım, kaygısız, бесстрашно.
- **Before the feeling (within 3 words):** not, without, no, never, any
  "n't" form, не, без, никакого.
- **After the feeling:**
  - EN "absent/missing" within 3 words, or a copula followed by "not".
  - TR yok/değil/hissetmedim, optionally after hiç/da/bile.
  - RU нет/отсутствует, or "не было".
- **Unknown feelings are ignored.**

## Client delivery contract

- `DreamPremiumDeliveryQuality` requires five sections to be present,
  non-empty and accepted as AI prose after the guard: summary,
  emotionalMeaning, mainInterpretation, personalConnection and
  closingTakeaway. `themes` and `recurringPattern` stay local by design.
- In configured AI mode, any gap throws `AiRequestException(invalidResponse)`
  before commit. Nothing is persisted: no record, memory or version, and there
  is no second call. The summary-to-theme substitution was removed.
- Dev local fallback (unconfigured AI that allows local) is unchanged.

### Parity decisions (aligned, never weakened)

- **Backend mirrors the client:** per-section grounding (words of 4 or more
  letters) and the catalogue invention rule.
- **Client stated-feeling exception:** `DreamStatedFeeling`. "Calm curiosity,
  with fear absent." passes when the dreamer spoke of fear. Otherwise "fear"
  is still an invented image.
- **Memory-grounded reflection:** the client reflection alone may lean on the
  safe memory (`DreamAnalysisFacts.withContext`), matching "Dream or safe
  memory" on the backend.
- **Catalogue sync test:** a test asserts that the backend catalogue mirror
  equals `DreamSymbolCatalogue`.

### Residual gaps (for Phase 4C)

- **Client-only guard rules:** these are not mirrored on the backend.
  - `HumanReader.looksGeneric`
  - FortuneVoice robotic/certainty scrubbing
  - `AiOutputQualityGate`

  A backend-accepted live reply can still be rejected on the client. The
  client then fails closed with `invalidResponse` and never falls back
  locally.
- **Question count:** the backend is stricter here. It enforces the single
  `?` across all prose.
- **Memory length:** the backend truncates the safe memory at 220 characters.
- **Lexical detection:** the checks are lexical, so paraphrased contradictions
  or invented facts that avoid the listed words can pass. Phase 4C measures
  this on real output.

## Writer revision

`DREAM_WRITER_REVISION = '4b'` salts only the Dream replay key:
`<idem>|dream-sem:4b:<digest>`.

- A response stored by the pre-4B writer (`<idem>|dream-sem:<digest>`) is
  never replayed.
- An exact 4B retry replays the same body.
- The semantic fingerprint (`dream:v2:…`, used for duplicate and billing
  identity) is unchanged.

## Prompt

`DREAM_FIELD_ROLES` (TR/EN/RU) is appended after the unchanged Phase 3 safety
and Phase 4A history clauses, before the language directive. It gives each
field its own job:

- A summary that compresses rather than retells.
- An emotional theme that is faithful to stated and negated feelings.
- A relational bridge between at least two details.
- A dream-specific reflection with no wellness advice.
- No "your work…" unless the dream or context supports it.
- A single open, grounded, non-yes/no conclusion.

The JSON schema is unchanged.

## Fixture adjustments (intentional)

- **Phase 2 `trGood` / `helpers.dreamJson` theme:** now grounded
  ("Yilanin sessizce gidisinde belirsizlik ile sakinlik…"). The old theme
  touched no told word and is rejected by both client and backend.
- **Phase 2 question test:** `?` in the summary still passes Phase 2 alone,
  but the combined acceptance now returns `extra_question`.
- **Phase 4A.2 EN generic echo:** now grounded in the narrative.
- **Client stubs and contract tests:** tests that expected a "mixed" reading
  with a locally replaced required section now expect `invalidResponse` with
  nothing stored.

## Evidence

- **Goldens:** 9 synthetic goldens (3 per language) in
  `backend/tests/fixtures/dream-premium-golden.json`. Each passes the backend
  and the client parser, mapper, composer, guard and provenance as a complete
  AI reading, persisted once.
- **Corpus:**

  | Language | GOOD | BAD |
  |---|---|---|
  | EN | 16 | 34 |
  | TR | 16 | 33 |
  | RU | 16 | 32 |

  Cases vary per language rather than being translated. They include the
  false-positive controls: work at work, partner present, stated fear, "fear
  absent", a summary reusing "red door", a sparse one-anchor interpretation,
  and "What was behind the door?".
- **Routes:**
  - A: a premium EN reply succeeds after 1 call.
  - B–F (contradiction, generic reflection, invented work, extra question,
    shallow rich interpretation), plus TR and RU equivalents, each return
    `invalid_response` with 1 call and no reason.
- **Client flow:**
  - A premium reply shows all required sections as AI and is persisted once
    with one version.
  - An unacceptable reply is `invalidResponse` after 1 call, with stored state
    byte-for-byte unchanged.
  - An unacceptable reinterpretation adds no version.
- **Performance:** 3,000 full acceptance evaluations take about 0.6 ms each
  (local run).
- **Mutations** (all restored): each weakened rule fails targeted tests.

  | Mutation | Failing tests |
  |---|---|
  | M1: emotion check off | 15 |
  | M2: questions allowed outside the conclusion | 17 |
  | M3: one-anchor interpretation allowed | 13 |
  | M4: personal-fact check off | 22 |
  | M5: client completeness check off | 13 |
  | M6: revision removed from the replay key | 2 |
