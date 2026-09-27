import { beforeEach, describe, expect, it } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { dreamHistoryClaimViolation } from '../src/ai/dream-history-quality.js';
import type { DreamHistoryItem } from '../src/ai/dream-history.js';
import type { DreamData } from '../src/ai/parse-provider.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import type { OpenAiFetch } from '../src/types.js';
import { enGood, enNarrative, ruGood, ruNarrative, trGood, trNarrative } from './dream-phase2-fixtures.js';
import { authHeader, jsonResponse, testApp, testConfig } from './helpers.js';

/** Dream Phase 4A.1 — a history claim must name a supplied item strictly. */
const item = (key: string, label: string, priorCount = 2): DreamHistoryItem => ({
  kind: 'symbol',
  key,
  label,
  level: priorCount >= 2 ? 'recurring' : 'seen_before',
  priorCount,
});

const rain = item('symbol:rain', 'rain');
const water = item('symbol:water', 'water');
const door = item('symbol:door', 'door');
const fear = item('symbol:fear', 'fear');
const kapi = item('symbol:door', 'Kapı');
const deniz = item('symbol:sea', 'Deniz');
const okno = item('symbol:окно', 'окно');
const les = item('symbol:лес', 'лес');

const trStory = 'Rüyamda denizin kıyısında eski bir kapı vardı ve rüzgâr esiyordu.';
const base: Record<AppLanguage, [DreamData, string]> = {
  en: [enGood, enNarrative],
  tr: [trGood, trStory],
  ru: [ruGood, ruNarrative],
};

function check(language: AppLanguage, sentence: string, history: DreamHistoryItem[]) {
  const [data, narrative] = base[language];
  return dreamHistoryClaimViolation({ ...data, dailyLifeReflection: sentence }, { narrative, history, language });
}

describe('Dream Phase 4A.1 — prefix collisions never bind history', () => {
  it.each([
    ['rain → rainbow', 'en', 'The rainbow keeps coming back in your dreams.', rain],
    ['water → waterfall', 'en', 'The waterfall appeared in your previous dreams.', water],
    ['door → doorway', 'en', 'A doorway keeps recurring.', door],
    ['fear → fearless', 'en', 'Fearless moments have appeared in earlier dreams.', fear],
    ['kapı → kapıcı', 'tr', 'Kapıcı önceki rüyalarında da vardı.', kapi],
    ['deniz → denizci', 'tr', 'Denizci rüyalarında tekrar ediyor.', deniz],
    ['лес → лесник', 'ru', 'Лесник уже снился тебе в прошлых снах.', les],
  ] as const)('%s → history_unsupported', (_label, language, sentence, history) => {
    expect(check(language, sentence, [history])).toBe('history_unsupported');
  });

  it('an unbound claim is unsupported even when history exists', () => {
    expect(check('en', 'This image has appeared in your earlier dreams too.', [door])).toBe('history_unsupported');
  });
});

describe('Dream Phase 4A.1 — real inflections still bind', () => {
  it.each([
    ['en', 'Rain has appeared in earlier dreams too.', rain],
    ['en', 'Rains have appeared in your earlier dreams too.', rain],
    ['en', 'Waters have appeared in your previous dreams.', water],
    ['en', 'The door has appeared in your earlier dreams too.', door],
    ['en', 'Doors have appeared before.', door],
    ['en', 'Fears have appeared in earlier dreams.', fear],
    ['tr', 'Kapı önceki rüyalarında da vardı.', kapi],
    ['tr', 'Kapıda beklemek önceki rüyalarında da vardı.', kapi],
    ['tr', 'Kapıyı önceki rüyalarında da görmüştün.', kapi],
    ['tr', 'Kapının tekrar etmesi dikkat çekici olabilir.', kapi],
    ['tr', 'Deniz önceki rüyalarında da vardı.', deniz],
    ['tr', 'Denizde yürümek önceki rüyalarında da vardı.', deniz],
    ['tr', 'Denize bakmak önceki rüyalarında da vardı.', deniz],
    ['tr', 'Denizin sesi önceki rüyalarında da vardı.', deniz],
    ['ru', 'Окно уже встречалось в прошлых снах.', okno],
    ['ru', 'Окна уже встречались в прошлых снах.', okno],
    ['ru', 'Свет в окне уже встречался в прошлых снах.', okno],
  ] as const)('%s: "%s" passes', (language, sentence, history) => {
    expect(check(language, sentence, [history])).toBeNull();
  });

  it('a generic dreamer recurrence statement never authorizes an invented subject (4A.2)', () => {
    const told = `${enNarrative} I keep dreaming of it again and again.`;
    const data = { ...enGood, dailyLifeReflection: 'The rainbow keeps coming back in your dreams.' };
    expect(dreamHistoryClaimViolation(data, { narrative: told, history: [rain], language: 'en' })).toBe(
      'history_unsupported',
    );
  });
});

describe('Dream Phase 4A.1 — route: collision rejected once, grounded claim served', () => {
  beforeEach(() => readingStageStore.clear());

  async function run(reply: DreamData, payload: Record<string, unknown>, key: string) {
    let calls = 0;
    const fetch: OpenAiFetch = async () => {
      calls++;
      return jsonResponse({ choices: [{ message: { content: JSON.stringify(reply) } }] });
    };
    const app = await testApp(testConfig(), fetch);
    const post = () =>
      app.inject({
        method: 'POST',
        url: '/v1/ai/complete',
        headers: { ...authHeader(), 'idempotency-key': key },
        payload: { operation: 'dream_analysis', payload },
      });
    const first = (await post()).json();
    const firstCalls = calls;
    const again = (await post()).json();
    await app.close();
    return { first, firstCalls, again };
  }

  const enPayload = {
    narrative: `${enNarrative} Soft rain was falling.`,
    symbols: [],
    emotions: [],
    language: 'en',
    history: [rain],
  };
  const trPayload = {
    narrative: `${trNarrative} Evin kapısı açıktı.`,
    symbols: [],
    emotions: [],
    language: 'tr',
    history: [kapi],
  };

  it.each([
    ['en', enPayload, enGood, 'Rainbow keeps coming back in your dreams.', 'Rain has appeared in earlier dreams too.'],
    ['tr', trPayload, trGood, 'Kapıcı önceki rüyalarında da vardı.', 'Kapı önceki rüyalarında da vardı.'],
  ] as const)('%s', async (lang, payload, good, collision, grounded) => {
    const bad = await run({ ...good, dailyLifeReflection: collision }, payload, `or-dream-${lang}-bad`);
    expect(bad.first).toEqual({ success: false, error: { code: 'invalid_response' } });
    expect(bad.firstCalls).toBe(1);
    expect(bad.again.success).not.toBe(true);

    const ok = await run({ ...good, dailyLifeReflection: grounded }, payload, `or-dream-${lang}-ok`);
    expect(ok.first.success).toBe(true);
    expect(ok.first.data.dailyLifeReflection).toBe(grounded);
    expect(ok.firstCalls).toBe(1);
  });
});
