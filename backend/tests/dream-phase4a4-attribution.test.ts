import { beforeEach, describe, expect, it } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { dreamHistoryClaimViolation } from '../src/ai/dream-history-quality.js';
import type { DreamHistoryItem } from '../src/ai/dream-history.js';
import type { DreamData } from '../src/ai/parse-provider.js';
import { dreamMessages } from '../src/ai/prompts.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import type { OpenAiFetch } from '../src/types.js';
import { enGood, enNarrative, ruGood, ruNarrative, trGood, trNarrative } from './dream-phase2-fixtures.js';
import { authHeader, jsonResponse, testApp, testConfig } from './helpers.js';

/** Dream Phase 4A.4 — a history item attests exactly its own words, nothing added around them. */
const item = (key: string, label: string): DreamHistoryItem => ({ kind: 'symbol', key, label, level: 'recurring', priorCount: 2 });
const door = item('symbol:door', 'door');
const sea = item('symbol:sea', 'sea');
const cat = item('symbol:cat', 'cat');
const red = item('symbol:red', 'red');
const station = item('symbol:train station', 'train station');
const kapi = item('symbol:door', 'Kapı');
const deniz = item('symbol:sea', 'Deniz');
const okno = item('symbol:окно', 'окно');

const data: Record<AppLanguage, DreamData> = { en: enGood, tr: trGood, ru: ruGood };
const stories: Record<AppLanguage, string> = { en: enNarrative, tr: trNarrative, ru: ruNarrative };
type Case = readonly [label: string, sentence: string, history: DreamHistoryItem[], expected: string | null, narrative?: string];

function check(language: AppLanguage, sentence: string, history: DreamHistoryItem[], narrative = stories[language]) {
  return dreamHistoryClaimViolation({ ...data[language], dailyLifeReflection: sentence }, { narrative, history, language });
}

const run = (language: AppLanguage, cases: Case[]) =>
  it.each(cases)('%s', (_label, sentence, history, expected, narrative) => {
    expect(check(language, sentence, history, narrative)).toBe(expected);
  });

const U = 'history_unsupported';

describe('Dream Phase 4A.4 — EN exact attribution', () => {
  run('en', [
    ['door: noun', 'The door has appeared in earlier dreams.', [door], null],
    ['door: plural', 'Doors have appeared before.', [door], null],
    ['door: keeps returning', 'The door keeps returning.', [door], null],
    ['door: hedged', 'The door seems to have appeared before.', [door], null],
    ['door: supplied count', 'The door has appeared in two of your earlier dreams.', [door], null],
    ['door → red door', 'The red door has appeared before.', [door], U],
    ['door → wooden door', 'The wooden door keeps returning.', [door], U],
    ['door → locked door', 'The locked door appeared in earlier dreams.', [door], U],
    ['door → waiting at the door', 'Waiting at the door happened in previous dreams.', [door], U],
    ['door → door at the station', 'The door at the station appeared before.', [door], U],
    ['door → two doors', 'Two doors have appeared before.', [door], U],
    ['door → red door via supplied count', 'The red door has appeared 3 times.', [door], U],
    ['sea: noun', 'The sea has appeared before.', [sea], null],
    ['sea → dark sea', 'The dark sea has appeared before.', [sea], U],
    ['sea → sound of the sea', 'The sound of the sea appeared before.', [sea], U],
    ['sea → stormy sea', 'The stormy sea keeps returning.', [sea], U],
    ['cat: noun', 'The cat appeared in earlier dreams.', [cat], null],
    ['cat → black cat', 'The black cat appeared in earlier dreams.', [cat], U],
    ['multiword item', 'The train station appeared before.', [station], null],
    ['multiword item + attribute', 'The dark train station appeared before.', [station], U],
    ['two items never compose', 'The red door appeared before.', [door, red], U],
  ]);
});

describe('Dream Phase 4A.4 — the current dream never rewrites history', () => {
  run('en', [
    ['current red + history door', 'The red door has appeared in earlier dreams.', [door], U, 'I saw a red door.'],
    ['history noun alone', 'The door has appeared in earlier dreams.', [door], null, 'I saw a red door.'],
    ['history and current kept apart', 'The door has appeared before; in this dream it is red.', [door], null, 'I saw a red door.'],
    ['dreamer echo, no history', 'The red door keeps returning.', [], null, 'I keep dreaming of a red door.'],
    ['dreamer echo, history door', 'The red door keeps returning.', [door], null, 'I keep dreaming of a red door.'],
    ['hybrid red room + history door', 'The red door keeps returning.', [door], U, 'I keep dreaming of a red room.'],
  ]);
  run('tr', [
    ['current kırmızı + history Kapı', 'Kırmızı kapı önceki rüyalarında da vardı.', [kapi], U, 'Kırmızı bir kapı gördüm.'],
    ['history Kapı alone', 'Kapı önceki rüyalarında da vardı.', [kapi], null, 'Kırmızı bir kapı gördüm.'],
  ]);
  run('ru', [
    ['current красное + history окно', 'Красное окно уже встречалось в прошлых снах.', [okno], U, 'Я видел красное окно.'],
    ['history окно alone', 'Окно уже встречалось в прошлых снах.', [okno], null, 'Я видел красное окно.'],
  ]);

  it('no cross-field bootstrap: an attribute stated in one field is not history in another', () => {
    const reply = { ...enGood, summary: 'The door in this dream is red.', dailyLifeReflection: 'The red door has appeared in earlier dreams.' };
    expect(dreamHistoryClaimViolation(reply, { narrative: 'I saw a red door.', history: [door], language: 'en' })).toBe(U);
  });
});

describe('Dream Phase 4A.4 — TR exact attribution', () => {
  run('tr', [
    ['Kapı: noun', 'Kapı önceki rüyalarında da vardı.', [kapi], null],
    ['Kapı: hedged commentary', 'Kapının daha önce de görünmüş olması dikkat çekici olabilir.', [kapi], null],
    ['Kapı: accusative', 'Kapıyı önceki rüyalarında da görmüştün.', [kapi], null],
    ['Kapı → kırmızı kapı', 'Kırmızı kapı önceki rüyalarında da vardı.', [kapi], U],
    ['Kapı → kapıda beklemek', 'Kapıda beklemek önceki rüyalarında da vardı.', [kapi], U],
    ['Kapı → ahşap kapı', 'Ahşap kapı tekrar ediyor.', [kapi], U],
    ['Deniz: noun', 'Deniz önceki rüyalarında da vardı.', [deniz], null],
    ['Deniz: accusative', 'Denizi önceki rüyalarında da görmüştün.', [deniz], null],
    ['Deniz → karanlık deniz', 'Karanlık deniz önceki rüyalarında da vardı.', [deniz], U],
    ['Deniz → denizin sesi', 'Denizin sesi önceki rüyalarında da vardı.', [deniz], U],
  ]);
});

describe('Dream Phase 4A.4 — RU exact attribution', () => {
  run('ru', [
    ['окно: noun', 'Окно уже встречалось в прошлых снах.', [okno], null],
    ['окно: plural', 'Окна уже встречались в прошлых снах.', [okno], null],
    ['окно: accusative with reporting verb', 'Ты уже видел окно в прошлых снах.', [okno], null],
    ['окно → красное окно', 'Красное окно уже встречалось.', [okno], U],
    ['окно → свет в окне', 'Свет в окне уже встречался в прошлых снах.', [okno], U],
  ]);
});

describe('Dream Phase 4A.4 — count / date / fate / absolute still first', () => {
  run('en', [
    ['absolute', 'The door always returns in your dreams.', [door], 'history_absolute'],
    ['invented count', 'The door has appeared in 5 earlier dreams.', [door], 'history_count'],
    ['fate', 'The recurring door is your destiny.', [door], 'history_fate'],
    ['date', 'The door first appeared on 12 March.', [door], 'history_date'],
  ]);
});

describe('Dream Phase 4A.4 — prompt rule', () => {
  it.each([
    ['tr', 'zenginleştirilmiş hâlin daha önce görüldüğünü ima etme'],
    ['en', 'imply that richer combination appeared before'],
    ['ru', 'намекая, что именно такое сочетание уже встречалось'],
  ] as const)('%s: exact-attribution rule is always present', (lang, rule) => {
    const [system] = dreamMessages({ narrative: 'Quiet door.', history: [door] }, lang);
    expect(String(system?.content)).toContain(rule);
    const [bare] = dreamMessages({ narrative: 'Quiet door.' }, lang);
    expect(String(bare?.content)).toBe(String(system?.content));
  });
});

describe('Dream Phase 4A.4 — route red team', () => {
  beforeEach(() => readingStageStore.clear());

  async function serve(reply: DreamData, payload: Record<string, unknown>, key: string) {
    let calls = 0;
    const fetch: OpenAiFetch = async () => {
      calls++;
      return jsonResponse({ choices: [{ message: { content: JSON.stringify(reply) } }] });
    };
    const app = await testApp(testConfig(), fetch);
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(), 'idempotency-key': key },
      payload: { operation: 'dream_analysis', payload },
    });
    await app.close();
    return { json: res.json(), calls };
  }

  const payloads = {
    en: { narrative: `${enNarrative} I saw a red door.`, history: [door] },
    tr: { narrative: `${trNarrative} Kırmızı bir kapı gördüm.`, history: [kapi] },
  };

  it.each([
    ['en', enGood, 'The red door has appeared in earlier dreams.', 'The door has appeared in earlier dreams.'],
    ['tr', trGood, 'Kırmızı kapı önceki rüyalarında da vardı.', 'Kapı önceki rüyalarında da vardı.'],
  ] as const)('%s: retroactive attribute rejected once; exact history served', async (lang, good, retro, exact) => {
    const payload = { ...payloads[lang], symbols: [], emotions: [], language: lang };
    const bad = await serve({ ...good, dailyLifeReflection: retro }, payload, `or-dream-4a4-${lang}-bad`);
    expect(bad.json).toEqual({ success: false, error: { code: 'invalid_response' } });
    expect(bad.calls).toBe(1);

    const ok = await serve({ ...good, dailyLifeReflection: exact }, payload, `or-dream-4a4-${lang}-ok`);
    expect(ok.json.success).toBe(true);
    expect(ok.json.data.dailyLifeReflection).toBe(exact);
    expect(ok.calls).toBe(1);
  });
});
