import { readFileSync } from 'node:fs';
import { beforeEach, describe, expect, it } from 'vitest';
import type { DreamData } from '../src/ai/parse-provider.js';
import { responseLanguageDirective, type AppLanguage } from '../src/ai/app-language.js';
import { dreamMessages } from '../src/ai/dream-prompts.js';
import {
  classifyDreamSafety,
  dreamOutputViolation,
  isSensitiveDreamMemory,
} from '../src/ai/dream-safety.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import { AiProxyService } from '../src/ai/service.js';
import { validateAiBody } from '../src/ai/validate-request.js';
import { ProxyError, successEnvelope } from '../src/errors.js';
import type { ResponseReplayRepository } from '../src/middleware/response-replay-repository.js';
import type { OpenAiFetch } from '../src/types.js';
import { enGood, enNarrative, ruGood, ruNarrative, trGood, trNarrative } from './dream-phase2-fixtures.js';
import { authHeader, jsonResponse, testApp, testConfig } from './helpers.js';

type InputRow = { language: AppLanguage; text: string; expected: 'allow' | 'block'; concern: string | null };
type OutputRow = { language: AppLanguage; text: string; expected: 'reject' | 'pass'; check: string | null };

const rows = <T>(name: string): T[] =>
  JSON.parse(readFileSync(`./tests/fixtures/dream_safety/${name}.json`, 'utf8')).rows as T[];
const inputRows = rows<InputRow>('input_corpus');
const outputRows = rows<OutputRow>('output_corpus');

const good: Record<AppLanguage, { narrative: string; reply: DreamData }> = {
  tr: { narrative: trNarrative, reply: trGood },
  en: { narrative: enNarrative, reply: enGood },
  ru: { narrative: ruNarrative, reply: ruGood },
};

function provider(reply: DreamData) {
  const state = { calls: 0, bodies: [] as string[] };
  const fetch: OpenAiFetch = async (_url, init) => {
    state.calls++;
    state.bodies.push(String(init?.body ?? ''));
    return jsonResponse({ choices: [{ message: { content: JSON.stringify(reply) } }] });
  };
  return { fetch, state };
}

const body = (payload: Record<string, unknown>) => ({ operation: 'dream_analysis', payload });
const post = (payload: Record<string, unknown>, key = 'or-dream-K') => ({
  method: 'POST' as const,
  url: '/v1/ai/complete',
  headers: { ...authHeader(), 'idempotency-key': key },
  payload: body(payload),
});
const roomy = () => testConfig({ AI_RATE_LIMIT_MAX: '500' });

beforeEach(() => readingStageStore.clear());

describe('Dream Phase 3 — shared corpus parity', () => {
  it.each(inputRows.map((r) => [r.language, r.expected, r.text, r.concern] as const))(
    'input %s %s: %s',
    (_lang, _expected, text, concern) => {
      expect(classifyDreamSafety([text])).toBe(concern);
    },
  );

  it.each(outputRows.map((r) => [r.language, r.expected, r.text, r.check] as const))(
    'output %s %s: %s',
    (_lang, _expected, text, check) => {
      expect(dreamOutputViolation([text])).toBe(check);
    },
  );
});

describe('Dream Phase 3 — backend input preflight', () => {
  it('every blocked corpus row returns the typed safety code with zero provider calls', async () => {
    const p = provider(enGood);
    const app = await testApp(roomy(), p.fetch);
    for (const row of inputRows.filter((r) => r.expected === 'block')) {
      const res = await app.inject(post({ narrative: row.text, language: row.language }, `or-dream-${row.concern}`));
      expect(res.json()).toEqual({ success: false, error: { code: 'dream_safety_blocked' } });
    }
    expect(p.state.calls).toBe(0);
    await app.close();
  });

  it('a guided answer line in the enriched narrative is gated too', async () => {
    const p = provider(enGood);
    const app = await testApp(roomy(), p.fetch);
    const narrative = `${enNarrative}\n\n[Context]\n- How did you feel on waking?: I want to kill myself`;
    const res = await app.inject(post({ narrative, language: 'en' }));
    expect(res.json().error.code).toBe('dream_safety_blocked');
    expect(p.state.calls).toBe(0);
    await app.close();
  });

  it('direct AiProxyService call fails closed before transport', async () => {
    const p = provider(enGood);
    const service = new AiProxyService(testConfig(), p.fetch);
    const request = validateAiBody(body({ narrative: 'I want to kill myself now.', language: 'en' }));
    await expect(service.handle(request, undefined)).rejects.toMatchObject({
      code: 'dream_safety_blocked',
    } satisfies Partial<ProxyError>);
    expect(p.state.calls).toBe(0);
  });
});

describe('Dream Phase 3 — safety wins over replay', () => {
  it('K replays a safe exact retry; a sensitive request under K never gets the cached reading', async () => {
    const p = provider(enGood);
    const app = await testApp(roomy(), p.fetch);
    const safe = { narrative: enNarrative, language: 'en' };
    expect((await app.inject(post(safe))).json().data.summary).toBe(enGood.summary);
    expect((await app.inject(post(safe))).json().data.summary).toBe(enGood.summary);
    expect(p.state.calls).toBe(1);
    const sensitive = await app.inject(post({ ...safe, narrative: `${enNarrative} Now I want to kill myself.` }));
    expect(sensitive.json()).toEqual({ success: false, error: { code: 'dream_safety_blocked' } });
    expect(sensitive.body).not.toContain(enGood.summary);
    expect(p.state.calls).toBe(1);
    await app.close();
  });

  it('the replay store is never consulted for a sensitive request, even when it holds an entry for K', async () => {
    const p = provider(enGood);
    let claims = 0;
    const poisoned: ResponseReplayRepository = {
      async claim() {
        claims++;
        return {
          kind: 'completed',
          entry: {
            status: 200,
            body: successEnvelope(enGood),
            contentType: 'application/json',
            expiresAtMs: Date.now() + 60_000,
          },
        };
      },
      async complete() {},
    };
    const app = await testApp(roomy(), p.fetch, { responseReplayRepository: poisoned });
    const res = await app.inject(post({ narrative: 'Uyandım ve şimdi kendimi öldürmek istiyorum.', language: 'tr' }));
    expect(res.json().error.code).toBe('dream_safety_blocked');
    expect(res.body).not.toContain(enGood.summary);
    expect(claims).toBe(0);
    const safe = await app.inject(post({ narrative: enNarrative, language: 'en' }));
    expect(safe.json().data.summary).toBe(enGood.summary);
    expect(claims).toBe(1);
    expect(p.state.calls).toBe(0);
    await app.close();
  });
});

describe('Dream Phase 3 — memory, prompt and output', () => {
  it('a sensitive memorySummary is left out of the prompt; a safe one is kept', async () => {
    const p = provider(enGood);
    const app = await testApp(roomy(), p.fetch);
    const sensitive = 'Earlier the dreamer wrote about suicide after a hard night.';
    const safe = 'Earlier dream: a quiet red door by the sea.';
    expect(isSensitiveDreamMemory(sensitive)).toBe(true);
    expect(isSensitiveDreamMemory(safe)).toBe(false);
    const a = await app.inject(post({ narrative: enNarrative, language: 'en', memorySummary: sensitive }, 'or-dream-m1'));
    expect(a.json().success).toBe(true);
    const b = await app.inject(post({ narrative: enNarrative, language: 'en', memorySummary: safe }, 'or-dream-m2'));
    expect(b.json().success).toBe(true);
    expect(p.state.calls).toBe(2);
    expect(p.state.bodies[0]).not.toContain('suicide');
    expect(p.state.bodies[1]).toContain('quiet red door by the sea');
    await app.close();
  });

  it.each([
    ['tr', ['kanıtı değildir', 'Teşhis koyma', 'Anlatılmayan bir travmayı', 'kader, karma ya da ders', 'Kendine zarar vermeyi asla', 'ilacı bırakmayı', 'ölüm imgesi bir kehanet değildir', 'temkinli']],
    ['en', ['not evidence of an external threat', 'Do not diagnose', 'Do not infer trauma', 'destiny, karma or a lesson', 'Never encourage self-harm', 'stopping medication', 'not a prediction', 'tentative']],
    ['ru', ['не является доказательством внешней угрозы', 'Не ставь диагнозов', 'Не додумывай травму', 'судьбу, карму или урок', 'не поощряй самоповреждение', 'бросать лекарства', 'не предсказание', 'осторожными']],
  ] as const)('%s prompt carries every safety clause and keeps the single directive', (lang, clauses) => {
    const system = String(dreamMessages({ narrative: good[lang].narrative }, lang)[0]?.content);
    for (const clause of clauses) expect(system).toContain(clause);
    expect(system.endsWith(responseLanguageDirective(lang))).toBe(true);
  });

  const unsafe: Record<AppLanguage, string> = {
    tr: 'Bu rüya şizofren olduğunu gösteriyor.',
    en: 'This dream shows you have PTSD.',
    ru: 'Этот сон значит, что у тебя шизофрения.',
  };
  const negation: Record<AppLanguage, string> = {
    tr: 'Rüyada ölüm görmek gerçek hayatta öleceğin anlamına gelmez.',
    en: 'A dream cannot diagnose PTSD.',
    ru: 'Сон не может поставить диагноз.',
  };

  it.each(['tr', 'en', 'ru'] as const)('%s unsafe provider prose fails closed after exactly one call', async (lang) => {
    const reply = { ...good[lang].reply, dailyLifeReflection: `${good[lang].reply.dailyLifeReflection} ${unsafe[lang]}` };
    const p = provider(reply);
    const app = await testApp(roomy(), p.fetch);
    const res = await app.inject(post({ narrative: good[lang].narrative, language: lang }));
    expect(res.json()).toEqual({ success: false, error: { code: 'invalid_response' } });
    expect(p.state.calls).toBe(1);
    await app.close();
  });

  it.each(['tr', 'en', 'ru'] as const)('%s safe negation passes and normal Dream succeeds with one call', async (lang) => {
    const reply = { ...good[lang].reply, dailyLifeReflection: `${good[lang].reply.dailyLifeReflection} ${negation[lang]}` };
    const p = provider(reply);
    const app = await testApp(roomy(), p.fetch);
    const res = await app.inject(post({ narrative: good[lang].narrative, language: lang }));
    expect(res.json().success).toBe(true);
    expect(res.json().data.dailyLifeReflection).toContain(negation[lang]);
    expect(p.state.calls).toBe(1);
    await app.close();
  });
});
