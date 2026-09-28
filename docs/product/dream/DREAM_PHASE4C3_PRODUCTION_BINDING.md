# Dream Phase 4C.3 — Frozen Production Writer Binding (GPT-6 Astra)

Status: **bound in code and deploy script; not deployed.** No provider call was made in this phase.

## 1. Selected writer

| | Value |
|---|---|
| Dream writer model | `gpt-6-astra` (`FROZEN_DREAM_WRITER_MODEL`) |
| Reasoning effort | `medium` (`FROZEN_DREAM_REASONING_EFFORT`) |
| Endpoint | Chat Completions (`/chat/completions`), JSON mode (`response_format: json_object`) |
| Temperature / top_p / logprobs / top_logprobs | never sent |
| Tools / Responses API | none (unchanged) |
| Timeout | 45 s (unchanged) |
| Writer prompt | unchanged — the 4C.1 prompt evaluated in 4C.2/4C.2a |

Evidence: Phase 4C.2 model A/B plus the 4C.2a calibrated live gates (`DREAM_PHASE4C2_MODEL_AB.md` §10–11). Astra delivered 8/9 on both the backend and the client, versus 7/9 for Sol and 1/9 for gpt-4o.

## 2. Why `OPENAI_MODEL` was not changed

`OPENAI_MODEL` (`gpt-4o`) is the generic default for Chat, Oracle, legacy Tarot and the generic fallback of other features. Pointing it at Astra would silently move every feature onto an unvalidated writer. The generic allowlist (`OPENAI_ALLOWED_MODELS=gpt-4o,gpt-4o-mini`) is also unchanged. Astra is **not** client-selectable for any feature: `resolveModel(config, 'gpt-6-astra')` resolves to `gpt-4o`.

## 3. Server-owned isolation

- `backend/src/ai/dream-writer-model.ts` owns the binding.
- `AppConfig.openaiDreamModel` and `AppConfig.openaiDreamReasoningEffort` are parsed from `OPENAI_DREAM_MODEL` and `OPENAI_DREAM_REASONING_EFFORT`.
- The model string is kept exactly as configured. It is never allowlist-filtered or replaced with `gpt-4o`, so a typo stays observable and fails closed.
- The reasoning effort is bounded to a known level; anything else parses to `null`.
- `AiProxyService.handle` dispatches `dream_analysis` as `this.dream(request)`. The client model hint is not passed through, and the request is built only by `buildDreamCompleteOptions(config, dreamMessages(...))`.
- Only `config.ts` and `dream-writer-model.ts` read the Dream fields. The Dream env changes exactly those two config fields, so Chat, Oracle, Coffee, Palm, Soulmate, Tarot and Yıldızname are byte-identical with or without it.
- Development: if `OPENAI_DREAM_MODEL` is unset, Dream uses the generic `OPENAI_MODEL` and sends the pre-4C.3 body (JSON mode, default temperature). If Astra is configured, Dream uses Astra with medium reasoning.

## 4. Exact parity with the 4C.2 Astra request

For every 4C.2 case:

```text
buildChatCompletionBody(buildDreamCompleteOptions(productionConfig, messages))
  === buildChatCompletionBody(completeOptions(candidate('gpt-6-astra'), messages))
```

Both calls use the same messages and must match byte for byte. The body contains `model`, `messages`, `reasoning_effort: "medium"` and `response_format: {type: "json_object"}`, and has no temperature, sampling, logprob, tool or token-limit fields. The `AiProxyService` wire body also equals the 4C.2 adapter wire body for every case. The 4C.2 adapter's gpt-4o candidate still equals the pre-4C.3 generic body (development, no Dream model).

## 5. Locked fail-closed behaviour

In production and staging, `assertFrozenDreamWriter` requires exactly `gpt-6-astra` + `medium`. Any of the following throws `no_configuration` before any provider call (0 provider calls):

- a missing model;
- a missing reasoning effort;
- `gpt-4o`, `gpt-6-sol` or a typo;
- Astra with `low`, `high` or an invalid effort.

There is no fallback to `gpt-4o`, Sol, the client hint or `OPENAI_MODEL`. `backend/scripts/deploy-cloud-run.sh` sets `OPENAI_DREAM_MODEL: gpt-6-astra` and `OPENAI_DREAM_REASONING_EFFORT: medium` next to the unchanged `OPENAI_MODEL: gpt-4o`. The QA reader (`scripts/dream-phase4c/production-config.ts`) reports the configured generic model, the configured and resolved Dream model, the reasoning, temperature `null` and the endpoint. It never reports the key.

## 6. Replay revision

`DREAM_WRITER_REVISION` moves from `'4c1'` to `'4c3-astra'`. A response stored in a pre-4C.3 `4c1` slot is never replayed. An exact retry under `4c3-astra` replays without a second provider call, whatever client model hint the retry sends. The 4C.2 A/B harness keeps recording `'4c1'` (`PHASE4C2_WRITER_REVISION`), which is the prompt revision it compared across models.

## 7. Billing identity unchanged

The `dream:v2` semantic fingerprint (the duplicate and billing identity) is untouched and pinned in tests. It does not depend on the writer or on the client model hint. The client Gem operation stays bound to the stable attempt Idempotency-Key, and an exact retry replays the stored success. There is no second provider call and no second charge.

## 8. Deployment

**Not deployed.** Nothing was run with `gcloud`: no traffic change, no candidate revision and no live env var change. The deploy script is ready. Deploying the backend requires the two Dream variables (the script sets them); without them, locked Dream fails closed honestly instead of falling back.

## 9. Rollback contract

- There is no silent runtime fallback from Astra to gpt-4o or Sol, no hidden second provider call and no automatic model fallback.
- An Astra failure (provider error, timeout, gate reject) fails honestly through the existing Dream error path.
- A rollback is an explicit config/code release that binds a separately validated writer. It requires a new frozen constant, parity tests and a writer revision bump. Changing the env alone fails closed.

## 10. Client

No Flutter production change. The client still sends its model hint, which the server ignores for Dream. Response shape, gates and the Gem flow are unchanged.
