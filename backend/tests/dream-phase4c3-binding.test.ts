// Dream Phase 4C.3 — the frozen Astra writer binding: config parsing, the
// locked fail-closed contract (production and staging, zero provider calls)
// and the development behaviour. Fake provider only.
import { describe, expect, it } from 'vitest';
import {
  buildDreamCompleteOptions,
  FROZEN_DREAM_REASONING_EFFORT,
  FROZEN_DREAM_WRITER_MODEL,
} from '../src/ai/dream-writer-model.js';
import { ErrorCode, ProxyError } from '../src/errors.js';
import { ASTRA, configWith, dreamCall, NO_DREAM } from './dream-phase4c3-support.js';

describe('Dream Phase 4C.3 — config', () => {
  it('freezes Astra with medium reasoning', () => {
    expect(FROZEN_DREAM_WRITER_MODEL).toBe('gpt-6-astra');
    expect(FROZEN_DREAM_REASONING_EFFORT).toBe('medium');
  });

  it('keeps the explicit Dream model exactly — no allowlist filter, no gpt-4o substitution', () => {
    const typo = configWith({ OPENAI_DREAM_MODEL: ' gpt-6-astr ' });
    expect(typo.openaiDreamModel).toBe('gpt-6-astr');
    expect(typo.openaiAllowedModels).not.toContain('gpt-6-astr');
    expect(configWith(ASTRA).openaiDreamModel).toBe('gpt-6-astra');
    expect(configWith(NO_DREAM).openaiDreamModel).toBeNull();
  });

  it('parses reasoning to a bounded level; anything else is null (observable)', () => {
    expect(configWith({ OPENAI_DREAM_REASONING_EFFORT: ' MEDIUM ' }).openaiDreamReasoningEffort).toBe('medium');
    expect(configWith({ OPENAI_DREAM_REASONING_EFFORT: 'xhigh' }).openaiDreamReasoningEffort).toBe('xhigh');
    expect(configWith({ OPENAI_DREAM_REASONING_EFFORT: 'turbo' }).openaiDreamReasoningEffort).toBeNull();
    expect(configWith(NO_DREAM).openaiDreamReasoningEffort).toBeNull();
  });
});

const misconfigured: Array<[string, Record<string, string>]> = [
  ['missing OPENAI_DREAM_MODEL', NO_DREAM],
  ['missing reasoning', { ...ASTRA, OPENAI_DREAM_REASONING_EFFORT: '' }],
  ['gpt-4o', { ...ASTRA, OPENAI_DREAM_MODEL: 'gpt-4o' }],
  ['gpt-6-sol', { ...ASTRA, OPENAI_DREAM_MODEL: 'gpt-6-sol' }],
  ['typo gpt-6-astr', { ...ASTRA, OPENAI_DREAM_MODEL: 'gpt-6-astr' }],
  ['Astra + low', { ...ASTRA, OPENAI_DREAM_REASONING_EFFORT: 'low' }],
  ['Astra + high', { ...ASTRA, OPENAI_DREAM_REASONING_EFFORT: 'high' }],
  ['Astra + invalid', { ...ASTRA, OPENAI_DREAM_REASONING_EFFORT: 'turbo' }],
];

describe.each(['production', 'staging'])('Dream Phase 4C.3 — locked %s', (APP_ENV) => {
  it.each(misconfigured)('%s → no_configuration before any provider call', async (_, env) => {
    const config = configWith({ APP_ENV, ...env });
    const run = await dreamCall(config, 'gpt-6-astra');
    expect(run.outcome).toBe(ErrorCode.noConfiguration);
    expect(run.sent).toHaveLength(0);
    let thrown: unknown;
    try {
      buildDreamCompleteOptions(config, []);
    } catch (e) {
      thrown = e;
    }
    expect(thrown).toBeInstanceOf(ProxyError);
    expect((thrown as ProxyError).code).toBe(ErrorCode.noConfiguration);
  });

  it('Astra + medium → exactly one call with the frozen body', async () => {
    const run = await dreamCall(configWith({ APP_ENV, ...ASTRA }), undefined);
    expect(run.outcome).toBe('PASS');
    expect(run.sent).toHaveLength(1);
    expect(run.sent[0].url).toBe('https://api.openai.com/v1/chat/completions');
    expect(run.body).toMatchObject({ model: 'gpt-6-astra', reasoning_effort: 'medium', response_format: { type: 'json_object' } });
    for (const k of ['temperature', 'top_p', 'logprobs', 'top_logprobs', 'tools']) expect(run.body).not.toHaveProperty(k);
  });
});

describe('Dream Phase 4C.3 — locked options', () => {
  it('model gpt-6-astra, messages unchanged, JSON mode, medium, temperature omitted', () => {
    const messages = [{ role: 'user' as const, content: 'JSON please' }];
    const options = buildDreamCompleteOptions(configWith({ APP_ENV: 'production', ...ASTRA }), messages);
    expect(options).toEqual({ model: 'gpt-6-astra', messages, jsonMode: true, reasoningEffort: 'medium' });
    expect(options.messages).toBe(messages);
    expect(options).not.toHaveProperty('temperature');
  });
});

describe('Dream Phase 4C.3 — development', () => {
  it('unset → the generic model with the pre-4C.3 body', async () => {
    const run = await dreamCall(configWith({ APP_ENV: 'development', ...NO_DREAM }), 'gpt-4o-mini');
    expect(run.outcome).toBe('PASS');
    expect(run.body).toMatchObject({ model: 'gpt-4o', temperature: 0.6, response_format: { type: 'json_object' } });
    expect(run.body).not.toHaveProperty('reasoning_effort');
  });

  it('Astra configured → Astra with medium, whatever reasoning is set', async () => {
    for (const effort of ['medium', 'high', '']) {
      const config = configWith({ APP_ENV: 'development', ...ASTRA, OPENAI_DREAM_REASONING_EFFORT: effort });
      const run = await dreamCall(config, 'gpt-4o');
      expect(run.body).toMatchObject({ model: 'gpt-6-astra', reasoning_effort: 'medium' });
      expect(run.body).not.toHaveProperty('temperature');
    }
  });
});
