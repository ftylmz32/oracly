// Dream Phase 4C.3 — the Astra writer is Dream-only and server-owned: every
// client model hint resolves Dream to Astra, generic resolution and the
// allowlist never see Astra, and no other feature reads the Dream binding.
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { buildNarrativeTarotCompleteOptions } from '../src/ai/narrative-tarot-model.js';
import { buildYildiznameNarrativeCompleteOptions } from '../src/ai/narrative-yildizname-model.js';
import { AiProxyService } from '../src/ai/service.js';
import { validateAiBody } from '../src/ai/validate-request.js';
import { resolveModel } from '../src/config.js';
import { deployedOpenAiEnv } from '../scripts/dream-phase4c/production-config.js';
import { completion, fakeFetch } from './dream-phase4c2-support.js';
import { ASTRA, configWith, dreamCall, NO_DREAM } from './dream-phase4c3-support.js';
import { palmOracleBody } from './helpers.js';

const HINTS = ['gpt-4o', 'gpt-4o-mini', 'gpt-6-sol', 'gpt-6-astra', 'garbage', null, undefined, 42];

describe.each(['production', 'staging'])('Dream Phase 4C.3 — red team (%s)', (APP_ENV) => {
  it.each(HINTS.map((h) => [String(h), h]))('client hint %s → Dream still writes with Astra', async (_, hint) => {
    const run = await dreamCall(configWith({ APP_ENV, ...ASTRA }), hint);
    expect(run.sent).toHaveLength(1);
    expect(run.body).toMatchObject({ model: 'gpt-6-astra', reasoning_effort: 'medium' });
    expect(run.body).not.toHaveProperty('temperature');
  });
});

describe('Dream Phase 4C.3 — generic resolution stays generic', () => {
  const locked = configWith({ APP_ENV: 'production', ...ASTRA });

  it('deploy keeps OPENAI_MODEL gpt-4o and the gpt-4o / gpt-4o-mini allowlist', () => {
    const env = deployedOpenAiEnv();
    expect(env.OPENAI_MODEL).toBe('gpt-4o');
    expect(env.OPENAI_ALLOWED_MODELS).toBe('gpt-4o,gpt-4o-mini');
    expect(locked.openaiModel).toBe('gpt-4o');
    expect(locked.openaiAllowedModels).toEqual(['gpt-4o', 'gpt-4o-mini']);
  });

  it('Astra is not client-selectable for generic features', () => {
    expect(resolveModel(locked, 'gpt-6-astra')).toBe('gpt-4o');
    expect(resolveModel(locked, 'gpt-4o-mini')).toBe('gpt-4o-mini');
  });

  const generic: Array<[string, unknown]> = [
    ['chat', { operation: 'chat', payload: { userMessage: 'I keep thinking about the move.', priorUser: [] } }],
    ['oracle', palmOracleBody],
  ];
  it.each(generic)('%s with an Astra hint still sends gpt-4o, temperature 0.72', async (_, raw) => {
    const fake = fakeFetch((body) => completion(String(body.model), 'A calm reflection.'));
    await new AiProxyService(locked, fake.fetch).handle(validateAiBody(raw), 'gpt-6-astra');
    expect(fake.sent).toHaveLength(1);
    expect(fake.sent[0].body).toMatchObject({ model: 'gpt-4o', temperature: 0.72 });
    expect(fake.sent[0].body).not.toHaveProperty('reasoning_effort');
  });
});

describe('Dream Phase 4C.3 — no other feature reads the Dream binding', () => {
  it('the Dream env changes exactly the two Dream config fields', () => {
    const { openaiDreamModel: a, openaiDreamReasoningEffort: b, ...without } = configWith(NO_DREAM);
    const { openaiDreamModel: c, openaiDreamReasoningEffort: d, ...withDream } = configWith(ASTRA);
    expect([a, b, c, d]).toEqual([null, null, 'gpt-6-astra', 'medium']);
    expect(withDream).toEqual(without);
  });

  it('only config.ts and dream-writer-model.ts read it; only AiProxyService.dream builds it', () => {
    const src = fileURLToPath(new URL('../src', import.meta.url));
    const files = readdirSync(src, { recursive: true, encoding: 'utf8' }).filter((f) => f.endsWith('.ts'));
    const text = (f: string) => readFileSync(join(src, f), 'utf8');
    const readers = files.filter((f) => /openaiDream(Model|ReasoningEffort)/.test(text(f)));
    expect(readers.map((f) => f.replace(/\\/g, '/')).sort()).toEqual(['ai/dream-writer-model.ts', 'config.ts']);
    const builders = files.filter((f) => text(f).includes('buildDreamCompleteOptions('));
    expect(builders.map((f) => f.replace(/\\/g, '/')).sort()).toEqual(['ai/dream-writer-model.ts', 'ai/service.ts']);
    expect(text('ai/service.ts')).toMatch(/case 'dream_analysis':\s*return this\.dream\(request\);/);
  });

  it('Tarot and Yıldızname frozen writers are identical with or without the Dream env', () => {
    const tarot = { OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-4o-mini,gpt-5.6-sol', OPENAI_TAROT_NARRATIVE_MODEL: 'gpt-5.6-sol' };
    const yn = { ...tarot, OPENAI_YILDIZNAME_NARRATIVE_MODEL: 'gpt-5.6-sol' };
    const messages = [{ role: 'user' as const, content: 'x' }];
    for (const APP_ENV of ['development', 'production']) {
      const base = configWith({ APP_ENV, ...NO_DREAM, ...yn });
      const dream = configWith({ APP_ENV, ...ASTRA, ...yn });
      expect(buildNarrativeTarotCompleteOptions(dream, dream.openaiModel, messages)).toEqual(
        buildNarrativeTarotCompleteOptions(base, base.openaiModel, messages),
      );
      expect(buildYildiznameNarrativeCompleteOptions(dream, dream.openaiModel, messages)).toEqual(
        buildYildiznameNarrativeCompleteOptions(base, base.openaiModel, messages),
      );
    }
  });
});
