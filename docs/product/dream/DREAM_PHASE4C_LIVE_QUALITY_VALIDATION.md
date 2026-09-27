# Dream Phase 4C — Live Provider Quality Validation

**Status:** live dataset captured · semantic verdict **PENDING INDEPENDENT REVIEW**
**Start HEAD:** `9fcd2b006d9aae740f897ed477de1ac84393d521` (backend `src/` content-identical to HEAD during the run)
**Captured:** 2026-09-27T23:23Z · **Real Dream writer calls:** 36 / 36 · retries 0 · judge-model calls 0

Phase 4C is observational. No prompt, gate, client guard, FortuneVoice rule or
writer revision was changed. Every finding below is recorded for review, not
fixed.

---

## 1. Model and configuration (audited, not chosen)

| Setting | Value | Source |
|---|---|---|
| Provider endpoint | `https://api.openai.com/v1/chat/completions` | deploy env `OPENAI_BASE_URL` |
| Configured / resolved model | `gpt-4o` | deploy env `OPENAI_MODEL`, allowlist `gpt-4o,gpt-4o-mini`; client hint `AiRuntimeConfig.defaultModel` = production dart-define `ORACLY_AI_MODEL` |
| Provider snapshot returned | `gpt-4o-2024-08-06` (all 36) | response `model` |
| Temperature | 0.6 | `buildChatCompletionBody` default (Dream passes neither temperature nor reasoning effort) |
| Reasoning effort | none | — |
| JSON mode | `response_format: json_object` | `jsonMode: true` in `AiProxyService.dream` |
| Max output tokens | not set | — |
| Timeout | 45 s | deploy env `OPENAI_TIMEOUT_SECONDS` |
| Transport retries | 0 | `OpenAiTransport.complete` is a single fetch |
| Writer revision | `4b` | `DREAM_WRITER_REVISION` |

The harness reads the `OPENAI_*` values from the non-secret env block of
`backend/scripts/deploy-cloud-run.sh` and resolves them through the production
`loadConfig` / `resolveModel`. No model is hardcoded in the harness. The API key
came from the developer backend env file via a BOM-tolerant reader inside the
harness process; it was never printed, logged or stored (the artifact is scanned
for key and header patterns by test).

## 2. Methodology

- **One production path.** For each run: `validateAiBody` → `AiProxyService.handle`
  → real `OpenAiTransport` → `dreamMessages` → `parseDreamData` →
  `dreamOutputViolation` → `dreamAcceptanceFailure` (Phase 2 → 4A → 4B). There is
  no second writer path.
- **Capture.** A wrapper around the transport's `fetch` counts calls and refuses
  any call past 36 before it reaches the network. It clones the response to
  capture the message content, provider model, usage and finish reason, plus the
  non-message request parameters (model, temperature, response format, prompt
  SHA-256 and length). It never reads or stores headers.
- **Stages.** The captured raw text is re-classified with the same production
  functions in production order (`production`: stops at the first failure,
  identical to the route). Each stage is also evaluated independently
  (`diagnostic`, analysis only). The two verdicts agree with the live route
  result on all 36 runs (`stageAgreement`).
- **Client offline replay.** Every backend-PASS body goes through the production
  client step by step, as `DreamInsightBuilder.build` runs it:
  `DreamAnalysisParser` → `DreamOutputSafety` → `DreamAiInsightMapper` /
  `DreamAnalysisComposer` / `DreamAnalysisGuard` → `DreamPremiumDeliveryQuality`
  → `DreamReadingProvenance`. A refused field is attributed to the first layer
  that refuses it. The layers are length, dictionary, `FortuneVoice.claimsMedical`,
  `FortuneVoice.claimsCertainty`, `HumanReader.looksGeneric`,
  `AiOutputQualityGate`, and the guard's private image/grounding check.
- **Fake transport first.** Before any real call, `dream-phase4c-harness.test.ts`
  proved the 36 cap, no retries, raw capture, no secret capture, per-stage
  codes, repeat grouping, schema validation and a Phase 3 provider-zero control.
  The Flutter replay was proven on the nine backend premium goldens.

## 3. Corpus design

24 unique synthetic cases (8 per language, written natively rather than
translated) plus 12 repeats, for 36 runs:

| # | Category | TR | EN | RU |
|---|---|---|---|---|
| 1 | Rich / negated fear | forest, lantern, "hiç korkmadım" | dark lake, "wasn't scared" | cellar, "совсем не было страшно" |
| 2 | Rich / mixed emotion | childhood kitchen | station goodbye | old school |
| 3 | Sparse single image | rusty key | red balloon | white feather |
| 4 | Surreal / absurd | melting clocks, singing whale | upside-down house, fish | flying teapots, cat in a hat |
| 5 | Supported life domain | work (presentation) | partner (moving in) | family (sister) |
| 6 | No domain / hallucination temptation | nameless ringing phone | empty letter | empty platform |
| 7 | Safe connected memory | synthetic tarot memory | synthetic tarot memory | synthetic tarot memory |
| 8 | Prior Dream history | `symbol:sea` ×2 | `symbol:sea` ×2 | `emotion:peaceful` ×2 |

Repeats (a second attempt with an identical payload and a different attempt key)
cover negated fear, mixed emotion, no-domain and history in each language. The
school domain appears only incidentally (RU mixed emotion).

**Client-derived payloads.** The provider payloads are not hand-written.
`dream_phase4c_payload_test.dart` runs each case through the real
`DreamExperienceService` with a context-capturing AI, then
`OpenAiPaidRequests.dream`. The client itself computes language, symbols,
emotions, connected memory (`OraclyMemoryRetriever` over a synthetic memory
store) and Phase 4A history (`DreamHistoryBuilder` over seeded synthetic prior
Dreams). The payloads are committed in
`backend/tests/fixtures/dream-phase4c-payloads.json`.

**Finding (client, automated fact):** `OraclyMemoryRetriever` tokenizes with a
Latin/Turkish-only character class, so a Russian dream never matches a memory
and no `memorySummary` is sent. For `ru-memory` the payload uses the same
retriever's own recall path to format the identical memory row
(`memorySource: retriever_recall_fallback`). TR and EN memory come from the
normal retriever path.

## 4. Budget and artifacts

- `docs/product/dream/evals/DREAM_PHASE4C_LIVE_RUN_20260928.json` — the 36 runs:
  inputs, provider metadata, raw text, parsed data, stage verdicts, client join,
  and `observations`.
- `docs/product/dream/evals/DREAM_PHASE4C_CLIENT_REPLAY_20260928.json` — the
  client replay of backend-PASS bodies, plus a diagnostic replay of backend
  rejects.
- Tokens: 49,674 prompt, 8,715 completion. Latency 1.6–4.2 s (median 2.6 s).
  All 36 finished with `stop`; all 36 parsed; zero output-safety violations.

## 5. Results — AUTOMATED FACT

**Backend final:** PASS 2 / 36 (5.6%): `tr-memory`, `ru-history`. REJECT 34,
TRANSPORT_ERROR 0.

| Language | PASS | REJECT |
|---|---|---|
| TR | 1 | 11 |
| EN | 0 | 12 |
| RU | 1 | 11 |

First production failure: invented_symbol 7 · ungrounded_section 6 ·
history_unsupported 4 · emotion_contradiction 3 · invented_image 3 ·
generic_reflection 3 · ungrounded 2 · dictionary_style 2 · extra_question 2 ·
weak_conclusion 1 · plot_recap 1.

Independent (diagnostic) stage evaluation:
- **Phase 2:** 25 PASS · invented_symbol 7 · ungrounded 2 · dictionary_style 2.
- **Phase 4A:** 32 PASS · history_unsupported 4.
- **Phase 4B:** 2 PASS · ungrounded_section 17 · invented_image 4 ·
  emotion_contradiction 3 · generic_reflection 3 · weak_conclusion 2 ·
  extra_question 2 · plot_recap 1 · unsupported_personal_fact 1 · thin_section 1.

Section grounding (production `touchesTold`) was false for `emotionalTheme` in
21/36 outputs (EN 11/12), `dailyLifeReflection` 16, `conclusion` 9 and
`summary` 5. A typical ungrounded theme is a free-standing feeling label ("Curiosity
mixed with a sense of unease.") that names no image from the dream. All seven
invented_symbol rejections carry symbol lists that add abstractions (darkness,
sessizlik, пустота) or restate narrative images in a different form.

### Client parity

- **Backend PASS → client FAIL:** none. Both backend-accepted readings replay as
  complete AI readings (5/5 required sections, `fromAi: true`).
- **FortuneVoice / HumanReader rewrite audit:** all 10 displayed required fields
  of the two accepted readings are `unchanged`. No format-only, lexical or
  meaningful rewrite occurred. The symbols section fell back to local in both
  (not a required section).
- **Diagnostic replay of the 34 backend rejects** (never user-visible): the client
  would have accepted 6 (`tr-negated-fear`, `tr-negated-fear#r2`, `tr-history`,
  `en-history`, `ru-negated-fear`, `ru-negated-fear#r2`) and refused 28. Client
  refusal layers: the guard's image/grounding check 53 fields, dictionary 2,
  too-short 1. In this sample the backend was never looser than the client.

### Candidate gate false positives — reproducible, NOT fixed

Every item below re-derives offline from the committed artifact
(`observations.gateTriggers`, `observations.perReading`). None reopens a frozen
contract in this phase. They are the concrete, reproducible evidence the
independent review and any Phase 4D decision should start from.

1. **Phase 4A rejects accurate recurrence of the supplied history item (4/4 of
   its rejections).**
   - Trigger sentences:
     - "The sea, a recurring symbol in your dreams, …" (`en-history`)
     - "The sea, a recurring element in your dreams, …" (`en-history#r2`)
     - "Denizin tekrarlayan bir motif olması …" (`tr-history#r2`)
     - "Спокойствие, которое повторяется в снах …" (`ru-history#r2`)
   - Each names the supplied `recurring` item: sea / deniz (`symbol:sea`,
     priorCount 2), or спокойствие against the label "спокойный".
   - None adds a count, date, fate or diagnosis.
2. **Phase 4B `emotion_contradiction` fires on themes that negate fear (3/3).**
   - Trigger themes:
     - "… korku hissedilmiyordu" (`tr-negated-fear`)
     - "Любопытство преобладает над страхом …" (`ru-negated-fear`)
     - "Любопытство и отсутствие страха." (`ru-negated-fear#r2`)
   - Each narrative states the absence of fear.
3. **Phase 4B personal-domain lexicon reads "familiar" as family.** `famil\p{L}*`
   matches "a familiar space/source" in sentences addressed with "your". This
   caused the diagnostic `unsupported_personal_fact`/family on both `en-history`
   runs.
4. **Diagnostic only:** "childhood" is flagged unsupported for `tr-mixed-emotion`,
   although the narrative says "çocukken yaşadığım ev". The evidence lexicon
   matches `çocukluk…` but not `çocukken`.

## 6. Repetition and boilerplate — AUTOMATED FACT

Flags, not failures:
- **Identical sentences across different dreams:** none in any language.
- **5/6-grams shared by 3+ unique dreams:** none. There are no conclusion
  templates.
- **Shared reflection openings:** "Этот сон может …" opens `dailyLifeReflection`
  in 5 RU dreams, and "This dream might …" in 3 EN dreams.
- **Section-role similarity:** no interpretation≈reflection or summary≈theme pair
  reached the 0.4 flag.
- **Within one reading:** duplicate 5-grams across fields in 3 readings; more than
  one question in 2 (`tr-no-domain#r2`, `en-no-domain#r2`); summary recap share
  ≥ 0.6 in 1 (`en-mixed-emotion`, 0.636).
- **Heuristic noise:** the "same word in 3+ sections" heuristic also catches
  hedges such as "olabilir". It is a noisy flag, not evidence of a repeated
  metaphor.

## 7. Repeat consistency — AUTOMATED FACT

| Case | Backend | First failures | Emotions preserved | Invented domain | History (4A) |
|---|---|---|---|---|---|
| tr-negated-fear | both reject | emotion_contradiction / invented_image | no / yes | — | PASS / PASS |
| tr-mixed-emotion | both reject | invented_image / generic_reflection | yes / yes | childhood / — | PASS / PASS |
| tr-no-domain | both reject | generic_reflection / extra_question | yes / yes | — | PASS / PASS |
| tr-history | both reject | weak_conclusion / history_unsupported | yes / yes | — | PASS / fail |
| en-negated-fear | both reject | invented_symbol ×2 | yes / yes | — | not reached |
| en-mixed-emotion | both reject | plot_recap / invented_symbol | yes / yes | relationship ×2 | PASS / not reached |
| en-no-domain | both reject | ungrounded_section / extra_question | yes / yes | — | PASS / PASS |
| en-history | both reject | history_unsupported ×2 | yes / yes | family ×2 ("familiar") | fail / fail |
| ru-negated-fear | both reject | emotion_contradiction ×2 | no / no | — | PASS / PASS |
| ru-mixed-emotion | both reject | generic_reflection / dictionary_style | yes / yes | — | PASS / not reached |
| ru-no-domain | both reject | invented_symbol ×2 | yes / yes | — | not reached |
| ru-history | **mixed** | PASS / history_unsupported | yes / yes | — | PASS / fail |

- **Identical first failure:** 4/12 pairs.
- **Both passed:** 0/12 pairs.
- **Mixed:** 1/12 pairs (`ru-history`).
- **Emotions preserved:** "no" appears only where the gate flagged a negated fear
  (see §5, item 2).

## 8. History and memory — AUTOMATED FACT

- **History cases:**
  - Recurrence wording appears in 4 of 6 history runs, always about the supplied
    item.
  - None states a count, date, cause, fate or diagnosis (regex flags all false).
  - Phase 4A rejected 4 (see §5, item 1).
- **No-history runs:** the recurrence/past regex matched a few sentences (mostly
  the Russian "прошлое", meaning "the past"). Phase 4A passed all of them. These
  are regex hits, not claims.
- **Memory (mechanical term presence only):**
  - `en-memory`: `not_used`.
  - `tr-memory` and `ru-memory`: `memory_terms_present`. The TR hit ("etmeden")
    is a morphological variant of the narrative's own "etmedim".
  - No output names the source reading (tarot).
  - Whether use was cautious or an unsupported expansion is **not** claimed; it
    needs independent review.

## 9. Limitations

- One generation per case at temperature 0.6. Rates on 36 samples are wide
  estimates, not measurements.
- Only two backend-accepted readings exist, so client parity and the FortuneVoice
  audit rest on 10 fields. The 34-body diagnostic replay adds disagreement
  evidence but is not a user path.
- Memory "use" and all semantic quality (warmth, insight, overreach) are outside
  mechanical reach.
- `ru-memory` uses the retriever recall-path fallback (§3). The real client would
  send no memory for that dream.
- The client replay composes insights directly, as `DreamInsightBuilder` does; it
  does not commit to storage.

## 10. AUTOMATED FACT vs INDEPENDENT SEMANTIC REVIEW PENDING

| AUTOMATED FACT (re-derivable by test) | INDEPENDENT SEMANTIC REVIEW PENDING |
|---|---|
| Config, model snapshot, 36 calls, 0 retries, 0 transport errors | Whether any output is premium, warm, insightful |
| Stage verdicts and codes for all 36 (re-derived offline) | Whether each rejection is a writer fault or a gate false positive (§5 candidates first) |
| 2/36 backend PASS; both pass the client unchanged | Whether the two accepted readings are good enough to ship |
| Trigger sentences for 4A and emotion rejections | Whether the recurrence/negation phrasings are acceptable product language |
| Boilerplate, similarity, repeat and domain flags | Whether flagged openings or domains read as templated or invented |
| Memory term presence | Cautious use vs unsupported expansion |

## 11. Reproduction (no provider calls)

```
cd backend
npx vitest run tests/dream-phase4c-harness.test.ts tests/dream-phase4c-artifact.test.ts
npx tsx scripts/dream-phase4c/analyze.ts        # rewrites observations deterministically
cd ..
flutter test test/features/dream/dream_phase4c_payload_test.dart test/features/dream/dream_phase4c_client_replay_test.dart
```

`scripts/dream-phase4c/run-live.ts` refuses to run without `PHASE4C_LIVE=1`, a
key, and a clean backend `src/`. It also refuses to overwrite an existing
artifact, so the committed dataset cannot be spent twice.

---

DREAM PHASE 4C LIVE DATASET CAPTURED: YES
DREAM PHASE 4C SEMANTIC VERDICT: PENDING INDEPENDENT REVIEW
