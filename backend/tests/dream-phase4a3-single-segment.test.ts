import { beforeEach, describe, expect, it } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { dreamHistoryClaimViolation } from '../src/ai/dream-history-quality.js';
import type { DreamHistoryItem } from '../src/ai/dream-history.js';
import type { DreamData } from '../src/ai/parse-provider.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import type { OpenAiFetch } from '../src/types.js';
import { enGood, enNarrative, ruGood, trGood, trNarrative } from './dream-phase2-fixtures.js';
import { authHeader, jsonResponse, testApp, testConfig } from './helpers.js';

/** Dream Phase 4A.3 — one evidence source carries a history claim; sources are never combined. */
const item = (key: string, label: string): DreamHistoryItem => ({ kind: 'symbol', key, label, level: 'recurring', priorCount: 2 });
const sea = item('symbol:sea', 'sea');
const door = item('symbol:door', 'door');
const kapi = item('symbol:door', 'Kapı');

const data: Record<AppLanguage, DreamData> = { en: enGood, tr: trGood, ru: ruGood };
type Case = readonly [label: string, narrative: string, sentence: string, history: DreamHistoryItem[], expected: string | null];

function check(language: AppLanguage, narrative: string, sentence: string, history: DreamHistoryItem[] = []) {
  return dreamHistoryClaimViolation({ ...data[language], dailyLifeReflection: sentence }, { narrative, history, language });
}

const run = (language: AppLanguage, cases: Case[]) =>
  it.each(cases)('%s', (_label, narrative, sentence, history, expected) => {
    expect(check(language, narrative, sentence, history)).toBe(expected);
  });

const U = 'history_unsupported';
const redDoorSea = 'I keep dreaming of a red door. The sea keeps returning.';
const blueSkyDoor = 'I keep dreaming of a blue sky. The door keeps returning.';
const blackCatSea = 'A black cat keeps appearing. The sea keeps returning.';

describe('Dream Phase 4A.3 — EN cross-sentence composition', () => {
  run('en', [
    ['1 red door segment alone', redDoorSea, 'The red door keeps returning.', [], null],
    ['2 sea segment alone', redDoorSea, 'The sea keeps returning.', [], null],
    ['3 red + sea → red sea', redDoorSea, 'The red sea keeps returning.', [], U],
    ['sea + door → sea door', redDoorSea, 'The sea door keeps returning.', [], U],
    ['4 blue sky + door → blue door', blueSkyDoor, 'The blue door keeps returning.', [], U],
    ['blue sky segment alone', blueSkyDoor, 'The blue sky keeps returning.', [], null],
    ['door segment alone', blueSkyDoor, 'The door keeps returning.', [], null],
    ['5 black cat + sea → black sea', blackCatSea, 'The black sea keeps appearing.', [], U],
    ['black cat segment alone', blackCatSea, 'The black cat keeps appearing.', [], null],
    ['single segment, strict inflection', 'I keep dreaming of the red door again and again.', 'The doors keep returning.', [], null],
    ['single segment, doorway collision', 'I keep dreaming of the red door again and again.', 'The red doorway keeps returning.', [], U],
    ['generic echo', 'I keep having this dream again and again.', 'This seems to be a recurring dream.', [], null],
    ['negated recurrence is not evidence', 'The red door was there. This red door does not keep recurring.', 'The red door keeps recurring.', [], U],
    ['unrelated narrative noun', 'I saw a rainbow over the sea. This dream keeps recurring.', 'The rainbow keeps recurring.', [], U],
  ]);
});

describe('Dream Phase 4A.3 — saved history never shares a subject with another source', () => {
  const redRoom = 'I keep dreaming of a red room.';
  run('en', [
    ['saved history alone', redDoorSea, 'The sea has appeared in your earlier dreams too.', [sea], null],
    ['user modifier + saved subject', redDoorSea, 'The red sea has appeared before.', [sea], U],
    ['user modifier + saved subject, recent dreams', redDoorSea, 'The red sea has appeared in 2 of your recent dreams.', [sea], U],
    ['saved subject, recent dreams', redDoorSea, 'The sea has appeared in 2 of your recent dreams.', [sea], null],
    ['hybrid red room + door → red door', redRoom, 'The red door keeps returning.', [door], U],
    ['hybrid control: door via saved history', redRoom, 'The door has appeared in earlier dreams.', [door], null],
    ['hybrid control: red room via dreamer echo', redRoom, 'The red room keeps returning.', [door], null],
    ['two supplied items → one composed subject', 'I walked by the shore.', 'The sea door has appeared in your earlier dreams.', [sea, door], U],
  ]);
});

describe('Dream Phase 4A.3 — source truth', () => {
  run('en', [
    ['saved dreams, no history', redDoorSea, 'Your saved dreams show the red door returning.', [], U],
    ['ORACLY saw, no history', redDoorSea, 'ORACLY saw the red door in your earlier dreams.', [], U],
    ['"you said" echo', redDoorSea, 'You said the red door keeps returning.', [], null],
    ['saved dreams do not record the user modifier', 'I often dream of the red door.', 'The red door appears in your saved dreams too.', [door], U],
    ['saved dreams naming the supplied item', 'I often dream of the red door.', 'The door appears in your saved dreams too.', [door], null],
  ]);
  run('tr', [['kayıtlı rüyalar, no history', 'Kırmızı kapıyı tekrar tekrar görüyorum.', 'Kırmızı kapı kayıtlı rüyalarında da vardı.', [], U]]);
  run('ru', [['сохранённые сны, no history', 'Мне снова снится красная дверь.', 'Красная дверь есть в твоих сохранённых снах.', [], U]]);
});

describe('Dream Phase 4A.3 — TR', () => {
  const kirmizi = 'Kırmızı kapıyı tekrar tekrar görüyorum. Deniz de rüyalarıma tekrar geliyor.';
  const siyah = 'Siyah kedi rüyalarıma tekrar geliyor. Kapı da tekrar ediyor.';
  run('tr', [
    ['kırmızı kapı + deniz → kırmızı deniz', kirmizi, 'Kırmızı deniz rüyalarımda tekrar ediyor.', [], U],
    ['kırmızı kapı alone', kirmizi, 'Kırmızı kapı rüyalarında tekrar ediyor.', [], null],
    ['deniz alone', kirmizi, 'Deniz rüyalarında tekrar ediyor.', [], null],
    ['siyah kedi + kapı → siyah kapı', siyah, 'Siyah kapı tekrar ediyor.', [], U],
    ['siyah kedi alone', siyah, 'Siyah kedi rüyalarında tekrar ediyor.', [], null],
    ['kapı alone', siyah, 'Kapı tekrar ediyor.', [], null],
    ['hybrid kırmızı oda + saved kapı', 'Kırmızı odayı tekrar tekrar görüyorum.', 'Kırmızı kapı rüyalarında tekrar ediyor.', [kapi], U],
    ['hybrid control: saved kapı', 'Kırmızı odayı tekrar tekrar görüyorum.', 'Kapı önceki rüyalarında da vardı.', [kapi], null],
  ]);
});

describe('Dream Phase 4A.3 — RU', () => {
  const krasnaya = 'Мне снова снится красная дверь. Море тоже повторяется в моих снах.';
  const chernaya = 'Чёрная кошка снова и снова снится мне. Дверь тоже повторяется.';
  run('ru', [
    ['красная дверь + море → красное море', krasnaya, 'Красное море повторяется в твоих снах.', [], U],
    ['красная дверь alone', krasnaya, 'Красная дверь повторяется в твоих снах.', [], null],
    ['море alone', krasnaya, 'Море повторяется в твоих снах.', [], null],
    ['чёрная кошка + дверь → чёрная дверь', chernaya, 'Чёрная дверь повторяется в твоих снах.', [], U],
    ['чёрная кошка alone', chernaya, 'Чёрная кошка повторяется в твоих снах.', [], null],
    ['дверь alone', chernaya, 'Дверь повторяется в твоих снах.', [], null],
  ]);
});

describe('Dream Phase 4A.3 — count / absolute gates still hold', () => {
  run('en', [
    ['absolute', redDoorSea, 'The red door always returns in your dreams.', [], 'history_absolute'],
    ['invented count', redDoorSea, 'The sea has appeared in 5 earlier dreams.', [], 'history_count'],
  ]);
});

describe('Dream Phase 4A.3 — route red team', () => {
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

  const narratives = {
    en: `${enNarrative} I keep dreaming of a red door. The sea keeps returning.`,
    tr: `${trNarrative} Kırmızı kapıyı tekrar tekrar görüyorum. Deniz de rüyalarıma tekrar geliyor.`,
  };

  it.each([
    ['en', enGood, 'The red sea keeps returning in your dreams.', 'The red door keeps returning in your dreams.'],
    ['tr', trGood, 'Kırmızı deniz rüyalarında tekrar ediyor.', 'Kırmızı kapı rüyalarında tekrar ediyor.'],
  ] as const)('%s: composed subject rejected once; single-sentence echo served', async (lang, good, composed, echo) => {
    const payload = { narrative: narratives[lang], symbols: [], emotions: [], language: lang };
    const bad = await serve({ ...good, dailyLifeReflection: composed }, payload, `or-dream-4a3-${lang}-bad`);
    expect(bad.json).toEqual({ success: false, error: { code: 'invalid_response' } });
    expect(bad.calls).toBe(1);

    const ok = await serve({ ...good, dailyLifeReflection: echo }, payload, `or-dream-4a3-${lang}-ok`);
    expect(ok.json.success).toBe(true);
    expect(ok.json.data.dailyLifeReflection).toBe(echo);
    expect(ok.calls).toBe(1);
  });
});
