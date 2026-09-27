import { beforeEach, describe, expect, it } from 'vitest';
import type { DreamData } from '../src/ai/parse-provider.js';
import { dreamReplayKey, dreamRequestFingerprint } from '../src/ai/dream-request-identity.js';
import { fingerprintRequest } from '../src/ai/request-fingerprint.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import { validateAiBody } from '../src/ai/validate-request.js';
import type { OpenAiFetch } from '../src/types.js';
import { authHeader, jsonResponse, testApp, testConfig } from './helpers.js';

/** Synthetic narrative sharing names/words across TR and EN on purpose. */
const narrative = 'Mira ile Leo, Mira and Leo: fener lantern, liman harbor.';

const trReply: DreamData = {
  summary: 'Mira ile Leo fenerin yaninda limana bakarken sakin bir bekleyis tasiyor.',
  symbols: ['fener', 'liman'],
  emotionalTheme: 'Sakin bir merak ve Mira ile Leo arasinda yumusak bir yakinlik.',
  interpretation:
    'Fenerin limana isik tutmasi, Mira ile Leo icin tanidik bir yeri yeniden gorunur kiliyor; burada bir uyari degil, birlikte bakilan sakin bir yol var ve bu yol acele istemiyor.',
  dailyLifeReflection: 'Bugun yaninda duran biriyle sakin bir liman aramak iyi gelebilir.',
  conclusion: 'Senin icin fenerin isik tuttugu liman neresi olabilir?',
};

const enReply: DreamData = {
  summary: 'Mira and Leo stand near the lantern while the harbor stays calm and quiet.',
  symbols: ['lantern', 'harbor'],
  emotionalTheme: 'Quiet curiosity and a gentle closeness between Mira and Leo.',
  interpretation:
    'The lantern lighting the harbor makes a familiar place visible again for Mira and Leo; it reads less like a warning and more like a calm path you can look at together, without hurry.',
  dailyLifeReflection: 'Today you might look for a calm harbor with someone who stands beside you.',
  conclusion: 'Which harbor would you want that lantern to light for you?',
};

const body = (payload: Record<string, unknown>) => ({ operation: 'dream_analysis', payload });
const base = { narrative, symbols: ['fener'], emotions: ['Huzurlu'], language: 'tr' };
const fp = (payload: Record<string, unknown>) => fingerprintRequest(validateAiBody(body(payload)));

describe('Dream Phase 2 — backend semantic request identity', () => {
  it('A/H: exact and cosmetic retries share one identity', () => {
    expect(fp(base)).toBe(fp({ ...base }));
    expect(fp(base)).toBe(fp({ ...base, narrative: `  ${narrative.toUpperCase()}  ` }));
    expect(fp({ ...base, symbols: ['a', 'b'] })).toBe(fp({ ...base, symbols: [' B', 'a'] }));
    expect(fp(base)).toMatch(/^dream:v2:[0-9a-f]{64}$/);
    expect(fp(base)).not.toContain('mira');
  });

  it.each([
    ['B: TR vs EN', { language: 'en' }],
    ['C: TR vs RU', { language: 'ru' }],
    ['D: emotions', { emotions: ['Korkulu'] }],
    ['E: symbols', { symbols: ['liman'] }],
    ['F: memory', { memorySummary: 'Onceki ruyada da bir liman vardi.' }],
    ['G: enriched narrative/tags', { narrative: `${narrative}\n\n[Context]\n- Kabus` }],
  ])('%s → a different identity and replay slot', (_label, change) => {
    const changed = fp({ ...base, ...change });
    expect(changed).not.toBe(fp(base));
    expect(dreamReplayKey('K', changed)).not.toBe(dreamReplayKey('K', fp(base)));
  });

  it('EN vs RU are distinct too', () => {
    expect(fp({ ...base, language: 'en' })).not.toBe(fp({ ...base, language: 'ru' }));
    expect(dreamRequestFingerprint({ payload: base, language: 'en' })).toBe(fp({ ...base, language: 'en' }));
  });
});

describe('Dream Phase 2 — /v1/ai/complete response replay is payload-safe', () => {
  beforeEach(() => readingStageStore.clear());

  function languageAwareProvider() {
    const calls = { tr: 0, en: 0 };
    const fetch: OpenAiFetch = async (_url, init) => {
      const english = String(init?.body ?? '').includes('Respond entirely in English');
      calls[english ? 'en' : 'tr']++;
      return jsonResponse({ choices: [{ message: { content: JSON.stringify(english ? enReply : trReply) } }] });
    };
    return { fetch, calls };
  }

  const post = (payload: Record<string, unknown>, key = 'or-dream-K') => ({
    method: 'POST' as const,
    url: '/v1/ai/complete',
    headers: { ...authHeader(), 'idempotency-key': key },
    payload: body(payload),
  });

  it('same base key K: TR then EN never replays TR; exact retries replay', async () => {
    const provider = languageAwareProvider();
    const app = await testApp(testConfig(), provider.fetch);
    const en = { ...base, language: 'en' };

    const tr = await app.inject(post(base));
    expect(tr.json().data.summary).toBe(trReply.summary);

    const first = await app.inject(post(en));
    expect(first.json().success).toBe(true);
    expect(first.json().data.summary).toBe(enReply.summary);
    expect(provider.calls).toEqual({ tr: 1, en: 1 });

    const retry = await app.inject(post(en));
    expect(retry.json().data.summary).toBe(enReply.summary);
    const trRetry = await app.inject(post(base));
    expect(trRetry.json().data.summary).toBe(trReply.summary);
    expect(provider.calls).toEqual({ tr: 1, en: 1 });

    const emotion = await app.inject(post({ ...en, emotions: ['Merakli'] }));
    const symbol = await app.inject(post({ ...en, symbols: ['liman'] }));
    expect(emotion.json().data.summary).toBe(enReply.summary);
    expect(symbol.json().data.summary).toBe(enReply.summary);
    expect(provider.calls).toEqual({ tr: 1, en: 3 });
    await app.close();
  });
});
