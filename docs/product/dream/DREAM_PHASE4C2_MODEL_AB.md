# Dream Phase 4C.2 — Live Model A/B Quality Evaluation

**INDEPENDENT SEMANTIC VERDICT: gpt-6-astra (production candidate) · runner-up gpt-6-sol · gpt-4o not selected** (see §10). The production model is unchanged.

Sections 1–9 are the frozen 4C.2 evidence record as captured. §10 records the independent review, and §11 records the Phase 4C.2a offline gate calibration.

This phase captures evidence only. It compares `gpt-4o`, `gpt-6-sol` and `gpt-6-astra` on the frozen Phase 4C.1 Dream writer (revision `4c1`) and acceptance contract. No prompt, gate, client guard, transport or production model setting changed. Nothing was deployed, and no model was used to score another.

- Artifact: `docs/product/dream/evals/DREAM_PHASE4C2_MODEL_AB_20260928.json`
- Client replay: `docs/product/dream/evals/DREAM_PHASE4C2_CLIENT_REPLAY_20260928.json`
- Harness: `backend/scripts/dream-phase4c2/`
- Payload fixture: `backend/tests/fixtures/dream-phase4c2-payloads.json`

## 1. Compatibility and endpoint

Checked against the official OpenAI documentation on 2026-09-28 (the GPT-6 model guide, the three model pages, Structured Outputs and Prompt Caching). The full list is in `artifact.compatibility`.

- All three models list `POST /v1/chat/completions`. The run uses it for every call; there was no Responses API migration.
- Chat Completions takes `reasoning_effort`.
- GPT-6 Astra has no `none` effort level. `medium` is supported by both Sol and Astra.
- When effort is not `none`, the guide says to drop `temperature`, `top_p` and `top_logprobs`, plus `logprobs` on Chat Completions.
- JSON mode is `response_format: {"type":"json_object"}`. Every Dream prompt language contains "JSON", which JSON mode requires; a test checks this.

Assumptions (recorded in the artifact):

- The docs list JSON mode for gpt-4o and "compatible GPT-5 models". GPT-6 keeps the GPT-5.6 API capabilities, so `json_object` was assumed to be accepted. Every call returned HTTP 200, which bears this out.
- `reasoning_tokens` are billed inside `completion_tokens`.
- Prices are Standard tier. Every response reported `service_tier: default`.
- Every candidate runs under the production transport timeout of 45 s from the deploy script.

## 2. Candidates and parameters

| Candidate | Body sent (besides model/messages) |
|---|---|
| gpt-4o | `temperature: 0.6`, `response_format: json_object`, no `reasoning_effort` (byte-identical to `AiProxyService.dream`) |
| gpt-6-sol | `reasoning_effort: "medium"`, `response_format: json_object`; no temperature / top_p / logprobs / top_logprobs |
| gpt-6-astra | same as gpt-6-sol |

The adapter (`adapter.ts`) runs `AiProxyService.dream` step for step, in this order:

1. The input safety gate.
2. Dropping a sensitive memory.
3. Building the prompt with `dreamMessages`.
4. A call through the production `OpenAiTransport`.
5. `parseDreamData`.
6. Output safety on the raw body.
7. `acceptDreamData`.

Only the model and its reasoning control vary. The production model allowlist is bypassed inside the harness only; production still resolves to `gpt-4o`. Tests prove two things. First, the gpt-4o request body is byte-identical to the production service's. Second, the harness and production reach the same verdict on both a passing and a rejected frozen body.

## 3. Case matrix and budget

There are 9 cases × 3 models = **27 real calls: 27 used, 0 retries, 0 repair calls, 0 judge calls.** All 27 responses were HTTP 200, so there were no infrastructure failures.

The cases run in this order: tr-negated-fear, en-negated-fear, ru-negated-fear, en-mixed-emotion, tr-domain-work, ru-domain-family, ru-memory, en-history, tr-history.

Model order rotates per case:

- case 1: 4o → sol → astra
- case 2: sol → astra → 4o
- case 3: astra → 4o → sol
- then the rotation repeats.

Every payload is the production Flutter client's own request (`dream_phase4c2_payload_test.dart`). Each one is byte-identical to the frozen Phase 4C payload, and each case sent the same prompt to all three models. `ru-memory` came through ordinary retrieval (`memorySource: retriever`). The memory summary sent was:

`Yalnızca şimdiki kanıt desteklerse kullan: [tarot|2026-09-14|qa-4c-memory-ru] Расклад таро о перекрёстке и выборе без спешки.`

## 4. Outcomes

| Case | gpt-4o | gpt-6-sol | gpt-6-astra |
|---|---|---|---|
| tr-negated-fear | REJECT parse_failed | REJECT emotion_contradiction | REJECT emotion_contradiction |
| en-negated-fear | REJECT generic_reflection | PASS / client PASS | PASS / client PASS |
| ru-negated-fear | REJECT dictionary_style | REJECT emotion_contradiction | REJECT emotion_contradiction |
| en-mixed-emotion | REJECT plot_recap | REJECT emotion_contradiction | PASS / client PASS |
| tr-domain-work | REJECT thin_section | PASS / client PASS | REJECT unsupported_personal_fact |
| ru-domain-family | REJECT ungrounded_section | PASS / client PASS | PASS / client PASS |
| ru-memory | REJECT invented_symbol | PASS / client PASS | PASS / client PASS |
| en-history | REJECT history_unsupported | PASS / client PASS | REJECT history_unsupported |
| tr-history | REJECT parse_failed | PASS / client PASS | PASS / client FAIL_DELIVERY |

| Model | Backend PASS | Client PASS | First failures |
|---|---|---|---|
| gpt-4o | 0 / 9 | 0 | parse_failed 2, generic_reflection, dictionary_style, plot_recap, thin_section, ungrounded_section, invented_symbol, history_unsupported |
| gpt-6-sol | 6 / 9 | 6 / 6 | emotion_contradiction 3 |
| gpt-6-astra | 5 / 9 | 4 / 5 | emotion_contradiction 2, unsupported_personal_fact, history_unsupported |

These are gate outcomes, not a quality ranking. Each model has a single sample per case, and repeat variance was not measured.

## 5. Mechanical observations (for the reviewer)

All of these are string facts. Per-attempt detail is in `analysis.perAttempt`, and the five fields side by side are in `analysis.sideBySide`.

**gpt-4o parse failures.** Both are valid JSON. The production parser requires at least 8 characters per field, and each body had a one-word `emotionalTheme`: "merak" (tr-negated-fear) and "Huzur" (tr-history).

**Emotion cases.** All five GPT-6 `emotion_contradiction` rejects are quoted below so the reviewer can judge whether the gate or the model is at fault. Several state an explicitly negated fear:

- tr-negated-fear · sol (emotionalTheme): "Arkandan gelen ayak sesleri seni korkutmuyor; sesin kime ait olduğunu merak ederken sakin kalıyorsun."
- tr-negated-fear · astra (summary flagged; emotionalTheme): "…hiç korkmadığını, sesin kime ait olduğunu merak ettiğini belirtiyorsun…"
- ru-negated-fear · astra (emotionalTheme): "Темнота подвала не вызывает у тебя испуга…"
- ru-negated-fear · sol (summary and emotionalTheme): "Капающая впереди вода вызывает любопытство, а страха во сне нет."
- en-mixed-emotion · sol (emotionalTheme): "Seeing your old friend feels relieving and happy, while the thought of the train leaving without you feels heavy."

**Symbols.** gpt-4o `ru-memory` returned "перекрёсток" (nominative). The narrative says "перекрёстке". The strict symbol match removed the item, and its prose mention then triggered `invented_symbol`. This may be an inflection false positive of the gate, pending review.

**History.** No attempt made a count, date, fate or diagnosis claim (`analysis.history`). Two recurrence sentences were rejected by Phase 4A:

- en-history · astra: "The sea has appeared before, though that alone does not establish a shared meaning."
- en-history · gpt-4o: "The recurring presence of the sea might reflect a consistent source of calm…"

**Memory (ru-memory).** Output words that come only from the memory: gpt-4o "выборе"; sol "спешки"; astra "выборе", "спешки". No output named the source reading as tarot. Whether the memory was used appropriately is for the independent review.

**Personal domain.** tr-domain-work · astra was flagged `relationship` and rejected.

**Questions.** Every parsed reading had exactly one question mark.

**Boilerplate.** No identical sentences repeated across dreams for any model. Astra's English conclusions share a template in 3 of 3 English dreams ("What stands out to you about …"). gpt-4o and sol have no shared openings or templates at the three-dream threshold.

**Duplicate phrases across fields.** en-mixed-emotion · sol: "the train leaving without you". en-mixed-emotion · astra: "the sense that the train".

**Recurrence wording without supplied history.** This is a lexical flag only; the gates passed or rejected these for other reasons. It appears in en-mixed-emotion · sol and astra, and in ru-memory · astra.

## 6. Client parity

All 11 backend PASS bodies were replayed offline through the production client (Mapper → Composer → Guard → DeliveryQuality → Provenance). Each was replayed exactly as the backend returns it, with sanitized symbols.

- **10 / 11** deliver all five required sections from AI (`requiredAiSections: 5`, `fromAi: true`).
- **tr-history · astra**: the backend passed it, but client delivery failed (`FAIL_DELIVERY`). The `interpretation` field was refused by `HumanReader.looksGeneric`, and the client replaced it with the local section. This is a backend/client disagreement to review; nothing was changed.

## 7. Cost and latency (descriptive only)

Cost is computed from the usage each response reported and the documented Standard prices, including GPT-6 cache writes at 1.25× and reads at 0.1× the input rate. Every attempt had computable cost; none was estimated.

| Model | Total | Per attempt | Per backend PASS | Per client PASS | Input / output / reasoning tokens |
|---|---|---|---|---|---|
| gpt-4o | $0.041486 | $0.004610 | — | — | 11,613 / 1,693 / 0 |
| gpt-6-sol | $0.069656 | $0.007740 | $0.011609 | $0.011609 | 11,604 / 5,382 / 3,484 |
| gpt-6-astra | $0.245824 | $0.027314 | $0.049165 | $0.061456 | 11,604 / 3,333 / 915 |

| Model | Median | Mean | p90 | Min | Max |
|---|---|---|---|---|---|
| gpt-4o | 2,977 ms | 3,103 ms | 4,055 ms | 1,954 ms | 4,055 ms |
| gpt-6-sol | 13,624 ms | 12,037 ms | 15,577 ms | 4,905 ms | 15,577 ms |
| gpt-6-astra | 12,067 ms | 12,310 ms | 17,201 ms | 7,650 ms | 17,201 ms |

Latency was measured from a development machine. Prompt caching made later same-case calls cheaper; the rotation spreads this effect across models.

## 8. Limitations

- **Invented concrete scene content (prose-only limit, Phase 4C.1b).** The gates judge prose, so an invented scene item without a catalogue anchor can pass. Every attempt therefore carries `inventedConcreteSceneContent: "PENDING_INDEPENDENT_REVIEW"` with an empty `inventedConcreteSceneItems`, for a human reviewer to fill in.
- One sample per model per case: no repeat variance, no significance.
- Gate verdicts are the frozen 4C.1 contract. The quoted emotion, symbol and client-guard disagreements above may reflect gate behaviour rather than model quality.
- The gate outcomes above do not select a model; the independent review in §10 does. The production model stays `gpt-4o` until a separate binding step.

## 9. Reproduce (no provider call)

```bash
cd backend && npx vitest run tests/dream-phase4c2        # harness, parity, artifact
flutter test test/features/dream/dream_phase4c2_payload_test.dart test/features/dream/dream_phase4c2_client_replay_test.dart
```

The live runner (`PHASE4C2_LIVE=1 … scripts/dream-phase4c2/run-live.ts`) refuses to run while the artifact exists.

## 10. INDEPENDENT SEMANTIC VERDICT

- Review: `docs/product/dream/evals/DREAM_PHASE4C2_INDEPENDENT_REVIEW_20260928.json`
- The observations were supplied by an independent reviewer. No model was called to produce, score or rewrite them.

**Claim, scoped to this corpus only:** On the frozen ORACLY Dream Phase 4C.2 corpus under writer revision 4c1, independent semantic review selects gpt-6-astra as the production candidate. This is not a general claim about the models.

| Role | Model |
|---|---|
| Selected production candidate | gpt-6-astra |
| Runner-up | gpt-6-sol |
| Not selected | gpt-4o |

**Why gpt-6-astra.**

- It gave the strongest nuanced treatment across the nine-case corpus.
- It was particularly strong on EN mixed emotion, RU negated fear, RU choice/memory and EN historical personalization.
- It uses current details relationally rather than as dictionary mappings.
- It preserved uncertainty well.
- It had no clear invented concrete scene content.
- Its use of history in EN history was more valuable than Sol's.

**gpt-6-sol.** Very strong, more concise and cheaper: an excellent fallback or cost-optimized candidate. It sometimes underused optional history and personalization. One live RU summary subtly framed curiosity as stronger than fear, although the dreamer reported no fear. The backend still rejects that summary ("сильнее страха").

**Why not gpt-4o.** Generic and dictionary tendencies, weak reflections and one invented physical action. It gave two one-word `emotionalTheme` responses, and its premium feel is materially weaker.

**Invented concrete scene content (bounded review).**

- `tr-negated-fear::gpt-4o` is **PRESENT**: "ayak seslerini merakla takip ettim" (physical_action). The narrative says the dreamer heard footsteps behind them and walked toward the lantern. It never says they followed the footsteps.
- The other 26 attempts are **NONE**. NONE means no clear unsupported concrete object, person, animal, place, setting, physical action or visual attribute was found in this bounded review. It does not mean every interpretation is perfect.

**Cost and latency.** These are context, not a quality score; the selection is premium-quality-first.

- gpt-6-sol: $0.069656 in total, about 12.0 s mean latency.
- gpt-6-astra: $0.245824 in total, about 12.3 s mean latency.

The selection becomes actionable only after the gate and client false positives found in these live outputs are closed (§11). Binding the production model is a separate, later step.

## 11. Phase 4C.2a — live gate calibration (offline, 0 provider calls)

The 27 live outputs and the 4C.2 client replay are immutable. They were re-run offline through the calibrated gates. The writer prompt (revision `4c1`) and the production model are unchanged.

- Reclassification: `docs/product/dream/evals/DREAM_PHASE4C2A_OFFLINE_RECLASSIFICATION_20260928.json` (`backend/scripts/dream-phase4c2a/`)
- Client replay: `docs/product/dream/evals/DREAM_PHASE4C2A_CLIENT_REPLAY_20260928.json`

| Fix | Closed false positive | Still rejected |
|---|---|---|
| TR fear negation | "korkutmuyor / korkutmadı / korkutmaz / korkutmayan", "korkuya dönüşmediğini" deny fear | "korkutuyor / korkuttu / korkutucu / korkutmaya" |
| RU bounded cause negation | "не вызывает (у тебя) испуга" | "вызывает у тебя испуг"; `не` never negates a later feeling in a long clause |
| EN `without` | "without fear", "without any anxiety" | "without you feels heavy" affirms heaviness |
| History scope | "The sea has appeared before, though that alone does not establish a shared meaning."; "The recurring presence of the sea might reflect…" | "The red sea has appeared before…", "The sea has appeared before, red and stormy.", "The stormy sea, which has appeared before…", "The door keeps returning, red and heavy." |
| RU mobile vowel | перекрёсток ↔ перекрёстке | перекрёстный, цвета ≠ цветок, плато ≠ платок |
| TR "ilişkin" (regarding) | "sunuma ilişkin gerginliğin", "anlatmaya ilişkin kaygın" | "senin ilişkin", "ilişkini", "ilişkinde", sentence-initial "İlişkin…", "sevgilin", "evliliğin" |
| Client source-aware guard | Provider-AI sections are not hard-rejected by `HumanReader.looksGeneric` alone | Medical, certainty, dictionary, `AiOutputQualityGate`, invented catalogue image, Dream grounding, emotion-role grounding, one-question closing. Local text keeps the generic guard. |

The history scope fix adds two narrow English boundaries:

- A final though/although/but/however clause with its own subject and no past or comparative wording ends the claim.
- may/might/could + suggest/reflect/indicate ends the claim, but only after a subject already strictly bound to a supplied history item.

The parser minimum (8 characters) is unchanged, so gpt-4o's one-word themes ("merak", "Huzur") stay rejected.

**Gate outcomes after calibration (per model /9).** These counts are gate outcomes, not the semantic ranking.

| Model | Backend PASS 4C.2 → 4C.2a | Client PASS 4C.2 → 4C.2a |
|---|---|---|
| gpt-6-astra | 5 → 8 | 4 → 8 |
| gpt-6-sol | 6 → 7 | 6 → 7 |
| gpt-4o | 0 → 1 | 0 → 1 |

Rejections that remain:

- tr-negated-fear · astra: "korkudan çok merakla" is comparative wording, not an explicit negation.
- ru-negated-fear · sol: "сильнее страха", which matches the reviewer's criticism.
- en-mixed-emotion · sol: `ungrounded_section` after the `without` fix.
- ru-memory · gpt-4o: `ungrounded_section` after the symbol fix.
- gpt-4o, otherwise: two parse failures (the one-word themes), plus `generic_reflection`, `dictionary_style`, `plot_recap`, `thin_section` and `ungrounded_section` (ru-domain-family).

Frozen-evidence tests still read the frozen files and permit only the drift named above.
