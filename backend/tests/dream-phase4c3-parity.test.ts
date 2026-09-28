// Dream Phase 4C.3 — the production Dream request is exactly the 4C.2
// winning Astra request, and the deploy-config QA reader reports the binding.
import { describe, expect, it } from 'vitest';
import { buildDreamCompleteOptions } from '../src/ai/dream-writer-model.js';
import { buildChatCompletionBody } from '../src/ai/openai-transport.js';
import { dreamMessages } from '../src/ai/prompts.js';
import { describeDreamConfig, phase4cConfig } from '../scripts/dream-phase4c/production-config.js';
import { runPhase4c2, validated } from '../scripts/dream-phase4c2/harness.js';
import { candidate, completeOptions } from '../scripts/dream-phase4c2/candidates.js';
import { completion, fakeFetch } from './dream-phase4c2-support.js';
import { astraAttempts, dreamCall, FAKE_KEY, passRaw } from './dream-phase4c3-support.js';

const production = () => phase4cConfig(FAKE_KEY);
const ABSENT = ['temperature', 'top_p', 'logprobs', 'top_logprobs', 'tools', 'max_tokens', 'max_completion_tokens'];

describe('Dream Phase 4C.3 — exact 4C.2 Astra parity', () => {
  it('covers every 4C.2 case once', () => {
    expect(astraAttempts.length).toBeGreaterThanOrEqual(9);
    expect(new Set(astraAttempts.map((a) => a.caseId)).size).toBe(astraAttempts.length);
  });

  it.each(astraAttempts.map((a) => [a.caseId, a]))('%s: options → body equal the 4C.2 candidate', (_, a) => {
    const request = validated(a);
    const messages = dreamMessages(request.payload, request.language);
    const prod = buildChatCompletionBody(buildDreamCompleteOptions(production(), messages));
    const winner = buildChatCompletionBody(completeOptions(candidate('gpt-6-astra'), messages));
    expect(prod).toEqual(winner);
    expect(JSON.stringify(prod)).toBe(JSON.stringify(winner));
    expect(prod).toMatchObject({ model: 'gpt-6-astra', reasoning_effort: 'medium', response_format: { type: 'json_object' } });
    expect(prod.messages).toEqual(messages);
    for (const k of ABSENT) expect(prod).not.toHaveProperty(k);
  });

  it.each(astraAttempts.map((a) => [a.caseId, a]))('%s: AiProxyService sends the 4C.2 adapter bytes', async (_, a) => {
    const prod = await dreamCall(production(), 'gpt-4o', a);
    const fake = fakeFetch((body) => completion(String(body.model), passRaw));
    await runPhase4c2({ attempts: [{ ...a, order: 1 }], config: production(), fetch: fake.fetch });
    expect(prod.sent).toHaveLength(1);
    expect(prod.sent[0].url).toBe(fake.sent[0].url);
    expect(JSON.stringify(prod.body)).toBe(JSON.stringify(fake.sent[0].body));
  });
});

describe('Dream Phase 4C.3 — production config QA reader', () => {
  it('describes the server-owned Dream request, never the key', () => {
    const d = describeDreamConfig(production());
    expect(d).toMatchObject({
      appEnv: 'production',
      endpoint: 'https://api.openai.com/v1/chat/completions',
      configuredGenericModel: 'gpt-4o',
      configuredDreamModel: 'gpt-6-astra',
      configuredDreamReasoningEffort: 'medium',
      allowedModels: ['gpt-4o', 'gpt-4o-mini', 'gpt-5.6-sol'],
      resolvedModel: 'gpt-6-astra',
      reasoningEffort: 'medium',
      temperature: null,
      responseFormat: { type: 'json_object' },
      timeoutMs: 45_000,
      transportRetries: 0,
      locked: true,
    });
    expect(d.deployedEnv).toMatchObject({ OPENAI_DREAM_MODEL: 'gpt-6-astra', OPENAI_DREAM_REASONING_EFFORT: 'medium' });
    expect(JSON.stringify(d)).not.toContain(FAKE_KEY);
    expect(JSON.stringify(d)).not.toMatch(/api[_-]?key|bearer/i);
  });
});
