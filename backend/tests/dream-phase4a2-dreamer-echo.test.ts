import { beforeEach, describe, expect, it } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { dreamHistoryClaimViolation } from '../src/ai/dream-history-quality.js';
import type { DreamHistoryItem } from '../src/ai/dream-history.js';
import type { DreamData } from '../src/ai/parse-provider.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import type { OpenAiFetch } from '../src/types.js';
import { enGood, enNarrative, ruGood, trGood, trNarrative } from './dream-phase2-fixtures.js';
import { authHeader, jsonResponse, testApp, testConfig } from './helpers.js';

/** Dream Phase 4A.2 — a dreamer's recurrence statement is evidence only for its own words. */
const item = (key: string, label: string): DreamHistoryItem => ({ kind: 'symbol', key, label, level: 'recurring', priorCount: 2 });
const rain = item('symbol:rain', 'rain');
const door = item('symbol:door', 'door');
const kapi = item('symbol:door', 'Kapı');
const okno = item('symbol:окно', 'окно');

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
const enGeneric = 'I keep having this dream again and again.';
const enSpecific = 'I keep dreaming of the red door again and again.';

describe('Dream Phase 4A.2 — EN', () => {
  run('en', [
    ['1 generic user → invented subject', 'I keep dreaming of it again and again.', 'The rainbow keeps coming back in your dreams.', [rain], U],
    ['2 generic user → generic echo', enGeneric, 'This seems to be a recurring dream.', [], null],
    ['3 specific user → same subject', enSpecific, 'The red door keeps returning in your dreams.', [], null],
    ['4 specific user → different subject', enSpecific, 'The rainbow keeps returning in your dreams.', [], U],
    ['5 strict collision door → doorway', 'I keep dreaming of the door.', 'The doorway keeps recurring.', [], U],
    ['6 saved history grounds the subject', 'This dream keeps recurring.', 'The door has appeared in your earlier dreams too.', [door], null],
    ['6b saved history does not ground another subject', 'This dream keeps recurring.', 'Rainbow has appeared before.', [door], U],
    ['7 unrelated narrative noun', 'I saw a rainbow over the sea. This dream keeps recurring.', 'The rainbow keeps recurring.', [], U],
    ['generic user → "keeps appearing" subject', enGeneric, 'The rainbow keeps appearing in your dreams.', [], U],
    ['specific cautious echo', enSpecific, 'The red door appears to be recurring in what you describe.', [], null],
    ['strict inflection doors → door', 'I keep dreaming of doors.', 'The door keeps returning.', [], null],
    ['no user claim, no history', 'I walked by a red door.', 'The red door keeps returning in your dreams.', [], U],
  ]);
});

describe('Dream Phase 4A.2 — EN source truth', () => {
  const told = 'I often dream of the red door.';
  run('en', [
    ['user-reported echo', told, 'You say the red door often returns in your dreams.', [], null],
    ['"you said" is not stored history', told, 'You said this dream repeats.', [], null],
    ['saved dreams without history', told, 'The red door appeared in your earlier saved dreams.', [], U],
    ['ORACLY has seen', told, 'ORACLY has seen this door in your previous dreams.', [], U],
    ['we have seen', told, 'We have seen this in your previous dreams.', [], U],
    ['saved dreams naming supplied history', told, 'The door appears in your saved dreams too.', [door], null],
  ]);
});

describe('Dream Phase 4A.2 — TR', () => {
  const generic = 'Bu rüyayı tekrar tekrar görüyorum.';
  const specific = 'Kapıyı rüyalarımda tekrar tekrar görüyorum.';
  run('tr', [
    ['generic → generic echo', generic, 'Bu rüyanın tekrar ettiği anlaşılıyor.', [], null],
    ['generic → invented subject', generic, 'Kapı rüyalarında tekrar ediyor.', [], U],
    ['generic → absolute invented subject', generic, 'Kapı sürekli rüyalarına geliyor.', [], 'history_absolute'],
    ['specific → same subject (inflected)', specific, 'Kapı rüyalarında tekrar eden bir öğe.', [], null],
    ['specific → different subject', specific, 'Deniz rüyalarında tekrar ediyor.', [], U],
    ['specific → derivation kapıcı', specific, 'Kapıcı rüyalarında tekrar ediyor.', [], U],
    ['saved history → grounded subject', 'Bu rüya tekrar ediyor.', 'Kapı önceki rüyalarında da vardı.', [kapi], null],
    ['unrelated narrative noun', 'Rüyamda denizde bir gökkuşağı gördüm. Bu rüya tekrar ediyor.', 'Gökkuşağı tekrar ediyor.', [], U],
    ['stored-record wording without history', 'Kapıyı sık sık rüyamda görüyorum.', 'Kapı kayıtlı rüyalarında da vardı.', [], U],
  ]);
});

describe('Dream Phase 4A.2 — RU', () => {
  const generic = 'Мне снова и снова снится этот сон.';
  const specific = 'Мне снова и снова снится красная дверь.';
  run('ru', [
    ['generic → generic echo', generic, 'Похоже, этот сон повторяется.', [], null],
    ['generic → invented subject', generic, 'Радуга снова и снова возвращается в твоих снах.', [], U],
    ['specific → same subject', specific, 'Красная дверь повторяется в твоих снах.', [], null],
    ['specific → same subject (inflected)', specific, 'Красные двери повторяются в твоих снах.', [], null],
    ['specific → different subject', specific, 'Радуга повторяется в твоих снах.', [], U],
    ['saved history → grounded subject', 'Этот сон повторяется.', 'Окно уже встречалось в прошлых снах.', [okno], null],
    ['unrelated narrative noun', 'Я видела радугу над морем. Этот сон повторяется.', 'Радуга повторяется.', [], U],
    ['stored-record wording without history', 'Мне часто снится красная дверь.', 'Красная дверь есть в твоих сохранённых снах.', [], U],
  ]);
});

describe('Dream Phase 4A.2 — count / date / fate rules still hold for echoes', () => {
  run('en', [
    ['absolute', enSpecific, 'The red door always returns in your dreams.', [], 'history_absolute'],
    ['fate', enSpecific, 'The recurring red door is your destiny.', [], 'history_fate'],
    ['invented count', enSpecific, 'The red door has appeared in 5 earlier dreams.', [], 'history_count'],
    ['invented date', enSpecific, 'The red door first came back on 12 March.', [], 'history_date'],
  ]);
});

describe('Dream Phase 4A.2 — route red team', () => {
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
    en: { narrative: `${enNarrative} Soft rain was falling. I keep dreaming of it again and again.`, language: 'en', history: [rain] },
    tr: { narrative: `${trNarrative} Evin kapısı açıktı. Bu rüyayı tekrar tekrar görüyorum.`, language: 'tr', history: [kapi] },
  };

  // Phase 4B: a served reflection must also belong to this Dream, so the EN
  // echo carries one Dream-grounded sentence; the history property is unchanged.
  it.each([
    ['en', enGood, 'Rainbow keeps coming back in your dreams.', 'Soft rain may be worth noticing today. This seems to be a recurring dream.'],
    ['tr', trGood, 'Kapıcı rüyalarında tekrar ediyor.', 'Bu rüyanın tekrar ettiği anlaşılıyor.'],
  ] as const)('%s: invented subject rejected once; generic echo served', async (lang, good, invented, generic) => {
    const payload = { ...payloads[lang], symbols: [], emotions: [] };
    const bad = await serve({ ...good, dailyLifeReflection: invented }, payload, `or-dream-4a2-${lang}-bad`);
    expect(bad.json).toEqual({ success: false, error: { code: 'invalid_response' } });
    expect(bad.calls).toBe(1);

    const ok = await serve({ ...good, dailyLifeReflection: generic }, payload, `or-dream-4a2-${lang}-ok`);
    expect(ok.json.success).toBe(true);
    expect(ok.json.data.dailyLifeReflection).toBe(generic);
    expect(ok.calls).toBe(1);
  });
});
