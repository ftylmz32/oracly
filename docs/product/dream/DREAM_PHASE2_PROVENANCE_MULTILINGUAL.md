# Dream Phase 2 — Truthful Provenance + Multilingual AI Contract

| | |
|---|---|
| START HEAD | `b549453d5106ac869bc8ea35ee52449ca33dedcc` (Dream Phase 1) |
| END HEAD | the single Phase 2 commit whose parent is START HEAD |
| Branch | `fix/final-product-remediation-20260922` |
| Real provider calls | 0 (all tests use stubs / fixtures) |
| Safety | **Not frozen.** Phase 3 still required. |
| Final audit | Remediation on top of `a64c8962`: semantic request identity, narrative-language contract, localized local scaffolding, exactly one closing question (sections below marked **Final audit**). |
| Phase 2.1 | On top of `52602375`: provider-facing evidence in the operation language; TR local-copy nits closed (section **Phase 2.1**). |

## The defect

- `Dream.fromAi` was set to `true` whenever the provider call succeeded. That included readings where every provider section had failed the client guard and been replaced by on-device text. The footnote then told the user "written with AI" about prose the model never wrote.
- The request sent the app locale, but the backend Dream prompt also said "Türkçe yaz", so the output language contradicted the directive.
- The client grounding tokenizer only understood Latin letters, so English and Russian readings could not be grounded honestly.
- Catalogue tokens were matched as substrings. For example, "appeared" contains "red", so the guard flagged an invented image that was never there.

## Provenance model

`DreamInsightSource` (`lib/features/dream/models/dream_insight.dart`) has three values:

| Value | Meaning |
|---|---|
| `ai` | Provider text that survived `DreamAnalysisGuard` |
| `local` | Composed on device from the user's own told facts |
| `legacyUnknown` | Persisted before sections carried a source |

- **JSON:** each insight serializes `"source": "<name>"`.
- **Decoding:** a missing or unknown value decodes as `legacyUnknown`, and never as `ai`.
- **Legacy records:** they are not migrated or rewritten on read.

### Composer

`DreamAnalysisComposer` labels every section with its true source:

| Section | AI candidate | If the candidate is rejected |
|---|---|---|
| summary | `summary`, then `emotionalTheme` | local feeling beat |
| symbols | AI symbol list (joined) | told images / places, or the detail beat |
| emotionalMeaning | `emotionalTheme` | local feeling beat |
| mainInterpretation | `interpretation` | **omitted**, never replaced |
| personalConnection | `dailyLifeReflection` | local "you" beat |
| themes | — | always local |
| closingTakeaway | `conclusion` with exactly one question mark | local ask beat |

When no AI section is accepted, every section is `local`, and there is no interpretation section.

### `fromAi` meaning

`Dream.fromAi` is kept for compatibility. It means **at least one accepted AI section**, and it is computed by `DreamReadingProvenance.hasAcceptedAi`.

- It is false for the dev local fallback.
- It is false when every provider section is rejected.
- The UI never reads it to make a claim.

### Provenance summary

`DreamReadingProvenance.of(dream)` is a pure function that returns a `DreamProvenance`. It classifies only the sections the result view displays: meaning (the interpretation, or the summary when there is no interpretation), symbols, emotion and reflection. The always-local themes section is excluded, so it cannot turn an otherwise fully AI reading into "mixed".

| Displayed sources | Provenance | Footnote lead (TR / EN / RU) |
|---|---|---|
| all `ai` | `aiOnly` | `dream.source_ai` |
| `ai` and `local` | `mixed` | `dream.source_mixed` |
| all `local` | `localOnly` | `dream.source_local` |
| empty, or any `legacyUnknown` | `legacyUnknown` | `dream.source_saved` (neutral, no AI claim) |

- **Disclosure:** there is one result-level footnote and no per-section badges.
- **OR context:** the Dream context and favorite payloads use neutral labels ("Yorum", "Rüya yorumu"). They never contain provenance enum names or an AI claim about local text.

## Language snapshot

- **Capture point:** `DreamExperienceService._run` captures one operation language, before understanding and before the request: `DreamNarrativeLanguage.forOperation(narrative, OraclyL10n.code)`.
- **Where it flows:**
  - `DreamAnalysisFacts.language` drives the guard's quality context, the local beats and the section titles.
  - `DreamAiContext.language` feeds the `OpenAiPaidRequests.dream` payload.
- **Locale race:** changing the locale mid-flight does not change the request, the guard or the titles (see the test).
- **Dev path:** the dev-only direct `DreamPromptBuilder` path is unchanged.

### Cross-language contract (Final audit)

**The reading follows the narrative's language; the app language is only the fallback.** Grounding on both sides is lexical, so a reading can only be proven grounded when it shares words with what the dreamer wrote. Writing it in the narrative's language is the one contract that is truthful and fail-closed without translation.

`DreamNarrativeLanguage.detect` (`lib/features/dream/services/dream_narrative_language.dart`) is deterministic and has no network or model:

- Cyrillic letters are at least half of all letters → `ru`.
- Otherwise Latin text is scored: TR = Turkish function words + words containing a Turkish-only letter; EN = English function words.
- A language wins only with more than twice the other's score. A tie, a close call or no letters is "unknown" → the app language.

| Narrative | App | Operation / prompt / titles |
|---|---|---|
| TR | EN | `tr` |
| EN | TR | `en` |
| RU | EN | `ru` |
| unknown (names, numbers, mixed) | any | app language |

- The backend gate grounds **every** request lexically (the old cross-language skip is removed). Unrelated prose in any language is `invalid_response`; an invented symbol is still rejected.
- **Unknown-language edge:** when detection falls back to the app language and the narrative is in another language, grounding can fail closed (`invalid_response` / local sections). It never passes ungrounded prose.

## Request identity (Final audit)

Before this audit the client coalesced every Dream on the constant key `'dream'`, the provider idempotency key ignored language, and the backend replayed any response stored under the same raw Idempotency-Key. So a TR reading could be returned for an EN request under one paid operation.

**Client** — `DreamRequestIdentity` (`lib/features/ai/production/dream_request_identity.dart`):

- Fingerprint `dream:v1:<sha256>` of: language (normalized like the payload), narrative (sanitized like the payload), symbols, emotions, memory summary. Tags are folded into the narrative by `DreamContextEnricher`, so tag edits change it too.
- Normalization: trim, lowercase, collapse whitespace runs; symbols and emotions are de-duplicated and sorted (they are sets in the prompt). Only casing / whitespace / set-order edits are an exact retry.
- The fingerprint is the `AiRequestGuard` coalesce key **and** its duplicate fingerprint. Abuse limits (duplicate window, burst cap) are unchanged.
- Provider idempotency key: `dream-<32 hex>`; inside a paid operation `<billing op id>:ds-<32 hex>`. The billing operation id itself is untouched, so paid settlement identity is unchanged.

**Backend** — `backend/src/ai/dream-request-identity.ts`:

- `dreamRequestFingerprint` (`dream:v2:<sha256>`) canonicalizes the same fields the prompt uses; it drives the duplicate guard.
- `/v1/ai/complete` binds the replay record to `<Idempotency-Key>|dream-sem:<digest>`. The same raw key with a different language, emotion or symbol set is a new execution; an exact retry replays with no provider call.

## Provider evidence language (Phase 2.1)

Before 2.1 the request could carry Turkish or app-language ORACLY-owned values in an EN/RU operation: emotion chips as `labelTr` ("Korkulu"), catalogue symbols as their Turkish label ("Kapı" for a dreamer who wrote "door"), and entry chips / guided-question labels / `[Context]` in the app language.

`DreamProviderEvidence` (`lib/features/dream/services/dream_provider_evidence.dart`) is now the single boundary: dream + understanding + operation language → `DreamAiContext`. `DreamInsightBuilder` calls it; `OpenAiPaidRequests` only serializes it; `DreamRequestIdentity`, the backend fingerprint and the replay key all derive from that same context.

| Evidence | TR | EN | RU |
|---|---|---|---|
| Emotion chip (from `DreamEmotionId`) | `labelTr` (unchanged) | `dream.read.feeling_word.<id>` ("fearful") | same key ("испуганный") |
| Narrative feeling words | only if written | only if written as a word | only if written |
| Symbols | catalogue label only when the Turkish word was written | English token only when written as a word ("door", "sea") | none — no Russian catalogue is claimed |
| Context heading | `[Bağlam]` | `[Context]` | `[Контекст]` |
| Entry chips / guided labels | `dream.chip_*` / `dream.guided_*` rendered in the operation language | same | same |
| Guided answers, narrative, memory | verbatim (existing trim / control-char sanitizer only) | verbatim | verbatim |

- **Structured entry context:** `DreamEntrySelection` (chip ids + raw guided answers) travels next to the display tags from the entry screen through `DreamPaidSubmit` → controller → `DreamExperienceService`. It is persisted additively as `entryContext` in the Dream JSON payload, so reinterpret rebuilds the same provider context. Display tags and the entry UI are unchanged; localized display text is never parsed back into ids.
- **Legacy records** (no `entryContext`): their stored tags are sent as historical text under the localized heading, like memory — not translated, not parsed.
- **Backend:** no production change. `dreamMessages` already prints the client's evidence under TR/EN/RU headings; `backend/tests/dream-phase21-prompt-evidence.test.ts` proves one language per operation for ORACLY-owned text.
- Persisted `DreamEmotion` ids, `DreamEmotionId` and on-device `DreamUnderstanding` are unchanged.

## Exactly one open question (Final audit)

The closing must contain exactly one `?` (`？` accepted). Zero is rejected; two or more is rejected, never trimmed into one. A question mark in another section never affects the closing. Client: `DreamAnalysisGuard.conclusion`. Backend: `isSingleQuestion` in `dream-quality.ts`.

## Local scaffolding (Final audit)

Local replacements keep the dreamer's observed words and localize only the glue (`DreamAnalysisFactParts`, `kL10nDreamReadJoin`):

- EN/RU never carry "içinde", "ve", "bu sahne" or the Turkish-only sentence split; each language has its own lead-in and pause rules.
- EN/RU images use the dreamer's own word, never the Turkish catalogue label; places and relationships come from Turkish-only lexicons and are used only for TR (EN "every" no longer yields "Ev").
- Feeling chips are localized (`dream.read.feeling_word.*`); EN/RU template fills open with a capital letter; RU feeling templates agree with a masculine noun.
- TR output is unchanged, except the two Phase 2.1 fixes below.
- **Phase 2.1:** an observed item filling several local slots is shown once ("Ev · Ev" → "Ev"; only identical normalized items). TR template fills now open with a capital using Turkish rules (i → İ, ı → I, a softened İ's combining dot is not doubled).

## Client grounding (TR / EN / RU)

`DreamGroundingWords` (`lib/features/dream/services/dream_grounding_words.dart`) handles tokenizing and matching.

- **Letters:** Latin plus Turkish letters, plus Cyrillic `а-я ё`.
- **Folding:** lowercase, remove the U+0307 combining dot, map `ı→i` and `ё→е`.
- **Stop words:** bounded, locale-specific sets for tr, en and ru. Dream-domain words ("rüya", "dream", "сон…") are treated as connectors.
- **Stems:** a prefix of `min(5, shorter − 1)` letters, never fewer than 3.
- **Catalogue matching:** tokens must match at the start of a word. English tokens must also end the word, optionally followed by a plural `s`/`es`. So "appeared" no longer flags "red".
- **Russian:** the symbol catalogue exists in TR and EN only. Russian prose is never catalogue-matched and relies on narrative grounding. **Russian catalogue coverage is not claimed.**
- **Strength:** grounding was not weakened. Unrelated prose still fails in all three languages, and the invented-image check is stricter on the told side.

## Backend prompt contract

The Dream prompt lives in `backend/src/ai/dream-prompts.ts`. `prompts.ts` re-exports `dreamMessages`.

- **Forced Turkish removed:** "Türkçe yaz" is gone from the Dream system prompt.
- **One language directive:** `responseLanguageDirective(language)` is the single authoritative directive, and it ends the system message.
- **Localized contracts:** full TR, EN and RU behaviour contracts with the same rules. The TR wording is preserved byte for byte apart from the removed phrase.
- **Canonical JSON keys:** `summary`, `symbols`, `emotionalTheme`, `interpretation`, `dailyLifeReflection`, `conclusion` (`DREAM_JSON_KEYS`).
- **Legacy keys:** `parseDreamData` still accepts the old Turkish aliases (`ozet`, `semboller`, `duygusalTema`, `yorum`, `gunlukYansi`, `sonuc`).

## Backend Dream quality gate

`backend/src/ai/dream-quality.ts` `evaluateDreamQuality` runs in `AiProxyService.dream` after `parseDreamData` and before success is returned.

**Inputs:** only the parsed `DreamData`, the sanitized narrative, the observed symbols and emotions, and the request language. It receives no UID, owner, birth data or tokens.

| Check | Rule |
|---|---|
| Required sections | minimum characters: summary 20, emotionalTheme 16, interpretation 60, dailyLifeReflection 30, conclusion 16 |
| Distinctness | no identical sections, and token-set overlap below 0.8 (for sets of 3 or more words) |
| Dictionary | no `X = Y`, "Anlam:", "meaning:", "значение:", "temsil eder", "symbolizes", "сонник", … |
| Question | the conclusion contains exactly one question mark |
| Language | ru needs at least 50% Cyrillic letters; tr/en allow at most 20% Cyrillic; function-word dominance is checked between tr and en |
| Genericity | two or more boilerplate tropes (new beginning / good news / change is coming …, TR/EN/RU) |
| Symbol invention | every output symbol shares a stem with the narrative or the supplied symbols |
| Grounding | the interpretation, plus at least one of summary, daily reflection or conclusion, shares a stem with the evidence |

**When symbol and grounding checks apply:** always (Final audit). Grounding is lexical; the client sends the narrative's own language, so a truthful reading shares words with the narrative. Semantic (translation-level) grounding coverage is **not** claimed.

**On failure:**
- The gate returns the typed `invalid_response`.
- There is no canned text, no local repair, no retry, no second provider call and no model change.
- A test asserts exactly one transport call.

**Client guard:** it can still reject individual fields. Any local replacement is labelled `local`.

## Tests (no real provider)

**Backend**
- `backend/tests/dream-phase2-contract.test.ts` covers:
  - The prompt contract in TR/EN/RU and the canonical and legacy keys.
  - Acceptance of grounded TR/EN/RU fixtures and rejection of unrelated prose.
  - Rejection of invented symbols, thin, duplicated, generic and dictionary output, non-question conclusions and language mismatches.
  - An app-route `invalid_response` with a single call, and EN/RU end-to-end success.
- `backend/tests/dream-phase2-request-identity.test.ts` (Final audit) covers:
  - The fingerprint matrix: exact retry, TR/EN, EN/RU, emotions, symbols, memory, tags, cosmetic casing/whitespace.
  - App-route replay under one base key: TR then EN is a new execution, exact retries replay with zero extra provider calls, a changed emotion or symbol is a new execution.
- `backend/tests/dream-phase21-prompt-evidence.test.ts` (Phase 2.1): `dreamMessages` for TR/EN/RU payloads carries ORACLY-owned evidence and headings in one language.
- `backend/tests/dream-phase2-fixtures.ts` holds the synthetic fixtures.
- `backend/tests/ai.test.ts` has updated key expectations. The shared `dreamJson` fixture is now substantive and keeps the legacy Turkish keys.

**Flutter**
- `test/features/dream/dream_phase2_provenance_test.dart` covers:
  - `fromAi` cases A–E: all AI, mixed, all rejected, dev local, and legacy `fromAi=true`.
  - Source round trips through JSON, record persistence, reopen, version payload append and selection, and legacy version decode.
- `test/features/dream/dream_phase2_multilingual_test.dart` covers:
  - TR/EN/RU grounding and the whole-word catalogue check.
  - The Cyrillic `ё` tokenizer.
  - The locale race, and request language as part of identity.
  - The localized footnote, and OR context without enum names.
- Final audit:
  - `dream_phase2_request_identity_test.dart`: identity matrix A–H, paid binder prefix, semantic guard coalescing.
  - `dream_phase2_cross_language_test.dart`: TR+EN app, EN+TR app, RU+EN app (operation, prompt, titles, provenance), unrelated and invented-image rejection, detection fallback.
  - `dream_phase2_local_language_test.dart`: all-rejected local readings in TR/EN/RU without Turkish scaffolding.
  - `dream_phase2_one_question_test.dart`: 0 / 1 / 2 questions in TR/EN/RU and in the composed closing.
- Phase 2.1 (real service path → `OpenAiPaidRequests.dream`):
  - `dream_phase21_provider_evidence_test.dart`: EN narrative + TR app, RU narrative + EN app, TR narrative + EN app; guided answer byte-faithful; reinterpret from storage; legacy tags.
  - `dream_phase21_identity_test.dart`: identity after the evidence fix (exact, cosmetic, language, emotion, chip, guided answer, symbol evidence), paid binder, unknown-language fail-closed.
  - `dream_phase21_local_copy_test.dart`: "Ev · Ev", Turkish sentence start, `entryContext` round trip.

**Phase 1 regression:** the owner-switch, ABA, stale reinterpret, in-flight, discovery-clear and attempt-privacy tests stay green.

## Safety — explicitly NOT frozen

Phase 2 adds no crisis handling. Dream Phase 3 must still handle:
- Self-harm and suicidal content.
- Crisis and acute distress.
- Trauma disclosure.
- Delusion.
- Medical and psychiatric symptoms.

## Carried residuals

- The residual account-wipe race documented in Phase 1 is unchanged and is not newly reachable.
- The original-version save order is carried as debt.
- File sizes:
  - `dream_analysis_facts.dart` is about 115 lines (language pieces moved to `dream_analysis_fact_parts.dart`).
  - `dream_copy.dart` is about 140 lines.
  - The already-oversized controller, entry screen and experience service grew only by the Phase 2.1 `entry` pass-through (2–5 lines each); no logic was added to them.
- Final audit observations:
  - Turkish emotion labels in the provider payload — closed in Phase 2.1.
  - "Ev · Ev" and the lowercase TR opening — closed in Phase 2.1.
  - The unknown-language edge above can fail closed for short or mixed narratives (accepted contract; tested).
- Phase 2.1 residual: records saved before `entryContext` existed send their stored tags as saved (historical text in the language of that time).
- Dream memory retrieval builds its local query from display labels; it only selects history and never reaches the provider as ORACLY-owned evidence.

## Remaining Phase 3 blockers

- Safety classification and routing for the categories above, on both client and backend.
- Russian symbol catalogue coverage, if Russian symbol-level guarding is wanted.
