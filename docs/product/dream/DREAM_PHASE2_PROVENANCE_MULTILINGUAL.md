# Dream Phase 2 — Truthful Provenance + Multilingual AI Contract

| | |
|---|---|
| START HEAD | `b549453d5106ac869bc8ea35ee52449ca33dedcc` (Dream Phase 1) |
| END HEAD | the single Phase 2 commit whose parent is START HEAD |
| Branch | `fix/final-product-remediation-20260922` |
| Real provider calls | 0 (all tests use stubs / fixtures) |
| Safety | **Not frozen.** Phase 3 still required. |

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
| closingTakeaway | `conclusion` (polished, or its first question) | local ask beat |

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

- **Capture point:** `DreamExperienceService._run` captures `AppLocale.normalize(OraclyL10n.code)` once, before understanding and before the request.
- **Where it flows:**
  - `DreamAnalysisFacts.language` drives the guard's quality context, the local beats and the section titles.
  - `DreamAiContext.language` feeds the `OpenAiPaidRequests.dream` payload.
- **Locale race:** changing the locale mid-flight does not change the request, the guard or the titles (see the test).
- **Fingerprint and idempotency:** unchanged. Language is not part of the fingerprint.
- **Dev path:** the dev-only direct `DreamPromptBuilder` path is unchanged.

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
| Question | the conclusion contains 1–2 question marks |
| Language | ru needs at least 50% Cyrillic letters; tr/en allow at most 20% Cyrillic; function-word dominance is checked between tr and en |
| Genericity | two or more boilerplate tropes (new beginning / good news / change is coming …, TR/EN/RU) |
| Symbol invention | every output symbol shares a stem with the narrative or the supplied symbols |
| Grounding | the interpretation, plus at least one of summary, daily reflection or conclusion, shares a stem with the evidence |

**When symbol and grounding checks apply:** only when the narrative is written in the requested language. If the narrative language is unknown, they apply unless the request is Russian. A cross-language narrative is left to the client guard.

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
- `backend/tests/dream-phase2-fixtures.ts` holds the synthetic fixtures.
- `backend/tests/ai.test.ts` has updated key expectations. The shared `dreamJson` fixture is now substantive and keeps the legacy Turkish keys.

**Flutter**
- `test/features/dream/dream_phase2_provenance_test.dart` covers:
  - `fromAi` cases A–E: all AI, mixed, all rejected, dev local, and legacy `fromAi=true`.
  - Source round trips through JSON, record persistence, reopen, version payload append and selection, and legacy version decode.
- `test/features/dream/dream_phase2_multilingual_test.dart` covers:
  - TR/EN/RU grounding and the whole-word catalogue check.
  - The Cyrillic `ё` tokenizer.
  - The locale race, request language and unchanged fingerprint.
  - The localized footnote, and OR context without enum names.

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
  - `dream_analysis_facts.dart` is about 175 lines.
  - `dream_copy.dart` is about 140 lines.
  - The oversized controller and screen were not grown.

## Remaining Phase 3 blockers

- Safety classification and routing for the categories above, on both client and backend.
- Russian symbol catalogue coverage, if Russian symbol-level guarding is wanted.
