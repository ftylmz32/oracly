import { beforeEach, describe, expect, it } from 'vitest';
import { responseLanguageDirective, type AppLanguage } from '../src/ai/app-language.js';
import { DREAM_JSON_KEYS } from '../src/ai/dream-prompts.js';
import {
  evaluateDreamQuality,
  languageMatches,
  narrativeLanguage,
  sameStem,
} from '../src/ai/dream-quality.js';
import { parseDreamData } from '../src/ai/parse-provider.js';
import { dreamMessages } from '../src/ai/prompts.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import type { OpenAiFetch } from '../src/types.js';
import {
  enGood,
  enNarrative,
  enUnrelated,
  ruGood,
  ruNarrative,
  ruUnrelated,
  trGood,
  trNarrative,
  trUnrelated,
} from './dream-phase2-fixtures.js';
import { authHeader, jsonResponse, testApp, testConfig } from './helpers.js';

const LANGS: AppLanguage[] = ['tr', 'en', 'ru'];
const input = (narrative: string, language: AppLanguage, symbols: string[] = []) => ({
  narrative,
  symbols,
  emotions: [],
  language,
});

describe('Dream Phase 2 — prompt contract', () => {
  it.each(LANGS)('%s: one authoritative language directive, no forced Turkish', (lang) => {
    const [system, user] = dreamMessages({ narrative: 'Quiet door, blue sea.' }, lang);
    const sys = String(system?.content);
    const directive = responseLanguageDirective(lang);
    expect(sys.split(directive).length - 1).toBe(1);
    expect(sys.endsWith(directive)).toBe(true);
    const turkish = (sys.match(/Türkçe yaz/g) ?? []).length;
    expect(turkish).toBe(lang === 'tr' ? 1 : 0);
    if (lang !== 'tr') expect(`${sys} ${user?.content}`).not.toMatch(/[ğışİ]/);
  });

  it.each(LANGS)('%s: stable canonical JSON keys, no Turkish-only keys', (lang) => {
    const user = String(dreamMessages({ narrative: 'Quiet door.' }, lang)[1]?.content);
    for (const key of DREAM_JSON_KEYS) expect(user).toContain(`${key} (`);
    for (const legacy of ['ozet (', 'semboller (', 'duygusalTema (', 'yorum (', 'gunlukYansi (', 'sonuc (']) {
      expect(user).not.toContain(legacy);
    }
  });

  it('parser accepts canonical keys and legacy Turkish aliases alike', () => {
    expect(parseDreamData(JSON.stringify(enGood))).toEqual(enGood);
    const legacy = {
      ozet: trGood.summary,
      semboller: trGood.symbols,
      duygusalTema: trGood.emotionalTheme,
      yorum: trGood.interpretation,
      gunlukYansi: trGood.dailyLifeReflection,
      sonuc: trGood.conclusion,
    };
    expect(parseDreamData(JSON.stringify(legacy))).toEqual(trGood);
  });
});

describe('Dream Phase 2 — backend quality gate', () => {
  it('accepts grounded TR / EN / RU output', () => {
    expect(evaluateDreamQuality(trGood, input(trNarrative, 'tr', ['yilan']))).toBeNull();
    expect(evaluateDreamQuality(enGood, input(enNarrative, 'en'))).toBeNull();
    expect(evaluateDreamQuality(ruGood, input(ruNarrative, 'ru'))).toBeNull();
  });

  it('rejects unrelated prose in every language', () => {
    expect(evaluateDreamQuality(trUnrelated, input(trNarrative, 'tr'))).toBe('ungrounded');
    expect(evaluateDreamQuality(enUnrelated, input(enNarrative, 'en'))).toBe('ungrounded');
    expect(evaluateDreamQuality(ruUnrelated, input(ruNarrative, 'ru'))).toBe('ungrounded');
  });

  it('rejects invented symbols', () => {
    expect(evaluateDreamQuality({ ...enGood, symbols: ['snake'] }, input(enNarrative, 'en'))).toBe(
      'invented_symbol',
    );
    expect(evaluateDreamQuality({ ...ruGood, symbols: ['змея'] }, input(ruNarrative, 'ru'))).toBe(
      'invented_symbol',
    );
  });

  it('rejects thin, duplicated, generic and dictionary output', () => {
    const tr = input(trNarrative, 'tr');
    expect(evaluateDreamQuality({ ...trGood, summary: 'kisa' }, tr)).toBe('thin_section');
    expect(
      evaluateDreamQuality({ ...trGood, dailyLifeReflection: trGood.interpretation }, tr),
    ).toBe('duplicate_sections');
    expect(
      evaluateDreamQuality(
        {
          ...trGood,
          interpretation: `${trGood.interpretation} Yeni bir başlangıç yakında; güzel haberler de yolda.`,
        },
        tr,
      ),
    ).toBe('generic_boilerplate');
    expect(
      evaluateDreamQuality({ ...trGood, interpretation: `Yilan = donusum. ${trGood.interpretation}` }, tr),
    ).toBe('dictionary_style');
    expect(
      evaluateDreamQuality({ ...enGood, interpretation: `Meaning: ${enGood.interpretation}` }, input(enNarrative, 'en')),
    ).toBe('dictionary_style');
  });

  it('requires the conclusion to be an open question', () => {
    const closed = { ...trGood, conclusion: 'Bu ruya bir uyari degil, bir davettir.' };
    expect(evaluateDreamQuality(closed, input(trNarrative, 'tr'))).toBe('conclusion_not_question');
  });

  it('rejects output that ignores the requested language', () => {
    expect(evaluateDreamQuality(enGood, input(ruNarrative, 'ru'))).toBe('language_mismatch');
    expect(evaluateDreamQuality(trGood, input(enNarrative, 'en'))).toBe('language_mismatch');
    expect(evaluateDreamQuality(enGood, input(trNarrative, 'tr'))).toBe('language_mismatch');
    expect(evaluateDreamQuality(ruGood, input(trNarrative, 'tr'))).toBe('language_mismatch');
  });

  it('skips lexical grounding only for a cross-language narrative', () => {
    expect(narrativeLanguage(trNarrative)).toBe('tr');
    expect(narrativeLanguage(enNarrative)).toBe('en');
    expect(narrativeLanguage(ruNarrative)).toBe('ru');
    expect(evaluateDreamQuality(enUnrelated, input(trNarrative, 'en'))).toBeNull();
  });

  it('tokenizes Cyrillic (including ё) with inflection-tolerant stems', () => {
    expect(sameStem('окно', 'окну')).toBe(true);
    expect(sameStem('лес', 'лесу')).toBe(true);
    expect(sameStem('маяк', 'окно')).toBe(false);
    expect(languageMatches('Тёплый свет в окне старого дома.', 'ru')).toBe(true);
    expect(languageMatches('Warm light in the window.', 'ru')).toBe(false);
  });
});

describe('Dream Phase 2 — app route', () => {
  beforeEach(() => readingStageStore.clear());

  function counting(content: unknown): { fetch: OpenAiFetch; calls: () => number; bodies: string[] } {
    let calls = 0;
    const bodies: string[] = [];
    const fetch: OpenAiFetch = async (_url, init) => {
      calls++;
      bodies.push(String(init?.body ?? ''));
      return jsonResponse({ choices: [{ message: { content: JSON.stringify(content) } }] });
    };
    return { fetch, calls: () => calls, bodies };
  }

  const post = (payload: Record<string, unknown>) => ({
    method: 'POST' as const,
    url: '/v1/ai/complete',
    headers: authHeader(),
    payload: { operation: 'dream_analysis', payload },
  });

  it('fails a low-quality Dream as invalid_response with exactly one provider call', async () => {
    const stub = counting({ ...trGood, conclusion: 'Bu bir davettir.' });
    const app = await testApp(testConfig(), stub.fetch);
    const res = await app.inject(post({ narrative: trNarrative, symbols: ['yilan'], emotions: [] }));
    expect(res.json()).toEqual({ success: false, error: { code: 'invalid_response' } });
    expect(stub.calls()).toBe(1);
    await app.close();
  });

  it('serves an English Dream in English end to end', async () => {
    const stub = counting(enGood);
    const app = await testApp(testConfig(), stub.fetch);
    const res = await app.inject(post({ narrative: enNarrative, symbols: [], emotions: [], language: 'en' }));
    expect(res.json().success).toBe(true);
    expect(res.json().data.conclusion).toBe(enGood.conclusion);
    expect(stub.calls()).toBe(1);
    expect(stub.bodies[0]).toContain('Respond entirely in English');
    expect(stub.bodies[0]).not.toContain('Türkçe');
    await app.close();
  });

  it('serves a Russian Dream in Russian end to end', async () => {
    const stub = counting(ruGood);
    const app = await testApp(testConfig(), stub.fetch);
    const res = await app.inject(post({ narrative: ruNarrative, symbols: [], emotions: [], language: 'ru' }));
    expect(res.json().success).toBe(true);
    expect(stub.calls()).toBe(1);
    await app.close();
  });
});
