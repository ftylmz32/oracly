import { beforeEach, describe, expect, it } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { dreamReplayKey } from '../src/ai/dream-request-identity.js';
import { dreamHistoryClaimViolation } from '../src/ai/dream-history-quality.js';
import type { DreamHistoryItem } from '../src/ai/dream-history.js';
import type { DreamData } from '../src/ai/parse-provider.js';
import { dreamMessages } from '../src/ai/prompts.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import { fingerprintRequest } from '../src/ai/request-fingerprint.js';
import { validateAiBody } from '../src/ai/validate-request.js';
import { ProxyError } from '../src/errors.js';
import type { OpenAiFetch } from '../src/types.js';
import { enGood, enNarrative, ruGood, ruNarrative, trGood, trNarrative } from './dream-phase2-fixtures.js';
import { authHeader, jsonResponse, testApp, testConfig } from './helpers.js';

const door: DreamHistoryItem = { kind: 'symbol', key: 'symbol:door', label: 'red door', level: 'recurring', priorCount: 2 };
const calm: DreamHistoryItem = { kind: 'emotion', key: 'emotion:peaceful', label: 'Peaceful', level: 'seen_before', priorCount: 1 };
const base = { narrative: enNarrative, symbols: [], emotions: [], language: 'en' };
const body = (payload: Record<string, unknown>) => ({ operation: 'dream_analysis', payload });
const parsed = (history: unknown) => validateAiBody(body({ ...base, history })).payload.history;
const fp = (payload: Record<string, unknown>) => fingerprintRequest(validateAiBody(body(payload)));

function codeOf(run: () => unknown): string | undefined {
  try {
    run();
  } catch (error) {
    return error instanceof ProxyError ? error.code : 'unexpected';
  }
  return undefined;
}

describe('Dream Phase 4A — strict history validator', () => {
  it('accepts bounded structured evidence; absent / null / [] mean none', () => {
    expect(parsed([door, calm])).toEqual([door, calm]);
    for (const none of [undefined, null, []]) expect(parsed(none)).toBeUndefined();
  });

  it.each([
    ['not a list', 'door'],
    ['six items', Array.from({ length: 6 }, (_, i) => ({ ...door, key: `symbol:d${i}` }))],
    ['extra field', [{ ...door, narrative: 'I dreamt of a door last week' }]],
    ['prior id', [{ ...door, priorIds: ['p1'] }]],
    ['missing field', [{ kind: 'symbol', key: 'symbol:door', label: 'door', level: 'recurring' }]],
    ['unknown kind', [{ ...door, kind: 'theme', key: 'theme:door' }]],
    ['key/kind mismatch', [{ ...door, key: 'location:door' }]],
    ['uppercase key', [{ ...door, key: 'symbol:Door' }]],
    ['unknown emotion id', [{ ...calm, key: 'emotion:despair' }]],
    ['unknown entry id', [{ kind: 'entry', key: 'entry:prophecy', label: 'x', level: 'seen_before', priorCount: 1 }]],
    ['prose label', [{ ...door, label: 'Door. You always dream of it' }]],
    ['oversized label', [{ ...door, label: 'a'.repeat(49) }]],
    ['zero count', [{ ...door, priorCount: 0, level: 'seen_before' }]],
    ['count over scan window', [{ ...door, priorCount: 41 }]],
    ['fractional count', [{ ...door, priorCount: 1.5 }]],
    ['string count', [{ ...door, priorCount: '2' }]],
    ['level inflated', [{ ...calm, level: 'recurring' }]],
    ['level deflated', [{ ...door, level: 'seen_before' }]],
    ['duplicate key', [door, { ...door, label: 'door' }]],
  ])('rejects %s as invalid_request', (_label, history) => {
    expect(codeOf(() => parsed(history))).toBe('invalid_request');
  });
});

describe('Dream Phase 4A — request identity and replay', () => {
  it('no history keeps the old identity; retries are stable', () => {
    expect(fp({ ...base, history: [] })).toBe(fp(base));
    expect(fp({ ...base, history: null })).toBe(fp(base));
    expect(fp({ ...base, history: [door] })).toBe(fp({ ...base, history: [{ ...door, label: 'Red Door' }] }));
  });

  it.each([
    ['history added', [door]],
    ['count changed', [{ ...door, priorCount: 3 }]],
    ['level changed', [{ ...door, priorCount: 1, level: 'seen_before' }]],
    ['item added', [door, calm]],
  ])('%s → a new identity and replay slot', (_label, history) => {
    const before = fp({ ...base, history: _label === 'history added' ? [] : [door] });
    const after = fp({ ...base, history });
    expect(after).not.toBe(before);
    expect(dreamReplayKey('K', after)).not.toBe(dreamReplayKey('K', before));
  });

  it('same idempotency key: history change calls the provider, exact retry replays', async () => {
    readingStageStore.clear();
    let calls = 0;
    const fetch: OpenAiFetch = async () => {
      calls++;
      return jsonResponse({ choices: [{ message: { content: JSON.stringify(enGood) } }] });
    };
    const app = await testApp(testConfig(), fetch);
    const post = (payload: Record<string, unknown>) =>
      app.inject({ method: 'POST', url: '/v1/ai/complete', headers: { ...authHeader(), 'idempotency-key': 'or-dream-K' }, payload: body(payload) });
    expect((await post(base)).json().success).toBe(true);
    expect((await post({ ...base, history: [door] })).json().success).toBe(true);
    expect(calls).toBe(2);
    await post({ ...base, history: [door] });
    await post(base);
    expect(calls).toBe(2);
    await app.close();
  });
});

describe('Dream Phase 4A — prompt contract', () => {
  const cases: [AppLanguage, string, string[]][] = [
    ['tr', 'Önceki rüya örüntüleri', ['kehanet değildir', 'sebep uydurma', 'teşhise ya da kadere', 'gerçek bir olayın', 'en fazla bir ya da iki', 'her zaman']],
    ['en', 'Prior dream patterns', ['not predictive', 'never invent a reason', 'diagnosis or fate', 'real-life event', 'at most one or two', 'always']],
    ['ru', 'Повторяющиеся элементы прошлых снов', ['не предсказательно', 'не придумывай', 'диагноз или судьбу', 'реальное событие', 'одной-двух', 'всегда']],
  ];

  it.each(cases)('%s: separated section, rules always present, no prior prose', (lang, heading, rules) => {
    const [system, user] = dreamMessages({ narrative: 'Quiet door.', history: [door, calm] }, lang);
    const sys = String(system?.content);
    for (const rule of rules) expect(sys).toContain(rule);
    const text = String(user?.content);
    expect(text).toContain(`\n\n${heading}`);
    expect(text).toContain('- red door (');
    expect(text).toContain('- Peaceful (');
    const [bareSystem, bare] = dreamMessages({ narrative: 'Quiet door.' }, lang);
    expect(String(bareSystem?.content)).toBe(sys);
    expect(String(bare?.content)).not.toContain(`\n\n${heading}`);
  });
});

const check = (data: DreamData, narrative: string, language: AppLanguage, history?: DreamHistoryItem[]) =>
  dreamHistoryClaimViolation(data, { narrative, history, language });
const en = (reflection: string) => ({ ...enGood, dailyLifeReflection: reflection });

describe('Dream Phase 4A — provider history claims (synthetic fixtures)', () => {
  it('frozen Phase 2 replies stay clean with and without history', () => {
    expect(check(trGood, trNarrative, 'tr')).toBeNull();
    expect(check(enGood, enNarrative, 'en')).toBeNull();
    expect(check(ruGood, ruNarrative, 'ru')).toBeNull();
    expect(check(enGood, enNarrative, 'en', [door])).toBeNull();
  });

  it.each([
    ['recurrence with no history', en('The red door is a recurring image from your previous dreams.'), undefined, 'history_unsupported'],
    ['symbol absent from history', en('The beach keeps coming back in your dreams.'), [door], 'history_unsupported'],
    ['two priors inflated to always', en('The red door always returns in your dreams.'), [door], 'history_absolute'],
    ['all your dreams', en('A door waits in all your dreams.'), undefined, 'history_absolute'],
    ['recurrence as fate', en('The recurring red door is your destiny.'), [door], 'history_fate'],
    ['recurrence as trauma', en('The red door recurs because of an unresolved trauma.'), [door], 'history_fate'],
    ['invented count', en('The red door has appeared in 5 earlier dreams.'), [door], 'history_count'],
    ['invented total', en('The red door has appeared in 5 of your recent dreams.'), [door], 'history_count'],
    ['many dreams', en('You have seen the red door in many dreams.'), [door], 'history_count'],
    ['invented date', en('You last saw the red door on 12 March.'), [door], 'history_date'],
    ['invented iso date', en('The red door first came on 2021-03-02.'), [door], 'history_date'],
  ])('rejects %s', (_label, data, history, code) => {
    expect(check(data, enNarrative, 'en', history)).toBe(code);
  });

  it.each([
    ['cautious recurring link', en('The red door has appeared in your earlier dreams too; it may be worth a gentle look.'), [door]],
    ['exact supplied total', en('The red door has appeared in 3 of your recent dreams.'), [door]],
    ['seen-before link', en('The red door showed up before, in one earlier dream.'), [{ ...door, priorCount: 1, level: 'seen_before' as const }]],
    ['negated claim', en('The red door is not recurring here; it simply stands in the sand.'), undefined],
    ['non-dream many times', en('Today you might try many times to find a quiet place.'), undefined],
  ])('accepts %s', (_label, data, history) => {
    expect(check(data, enNarrative, 'en', history)).toBeNull();
  });

  it('echoes the dreamer: their own recurrence and counts are not invented', () => {
    const told = `${enNarrative} I keep dreaming of the red door again and again; I knocked three times.`;
    expect(check(en('The red door seems to be recurring.'), told, 'en')).toBeNull();
    expect(check(en('You knocked on the red door three times.'), told, 'en', [door])).toBeNull();
  });

  const yilan: DreamHistoryItem = { kind: 'symbol', key: 'symbol:yilan', label: 'yilan', level: 'recurring', priorCount: 2 };
  const tr = (reflection: string) => ({ ...trGood, dailyLifeReflection: reflection });
  it('TR equivalents', () => {
    expect(check(tr('Yilan önceki rüyalarında da vardı.'), trNarrative, 'tr')).toBe('history_unsupported');
    expect(check(tr('Yilan önceki rüyalarında da vardı.'), trNarrative, 'tr', [yilan])).toBeNull();
    expect(check(tr('Yilan hep rüyalarına geliyor.'), trNarrative, 'tr', [yilan])).toBe('history_absolute');
    expect(check(tr('Yilanın tekrar etmesi senin kaderin.'), trNarrative, 'tr', [yilan])).toBe('history_fate');
    expect(check(tr('Yilan 5 rüyanda göründü.'), trNarrative, 'tr', [yilan])).toBe('history_count');
  });

  const okno: DreamHistoryItem = { kind: 'symbol', key: 'symbol:окно', label: 'окно', level: 'recurring', priorCount: 2 };
  const ru = (reflection: string) => ({ ...ruGood, dailyLifeReflection: reflection });
  it('RU equivalents', () => {
    expect(check(ru('Окно уже встречалось в прошлых снах.'), ruNarrative, 'ru')).toBe('history_unsupported');
    expect(check(ru('Окно уже встречалось в прошлых снах.'), ruNarrative, 'ru', [okno])).toBeNull();
    expect(check(ru('Окно всегда повторяется.'), ruNarrative, 'ru', [okno])).toBe('history_absolute');
    expect(check(ru('Повторяющееся окно — это твоя судьба.'), ruNarrative, 'ru', [okno])).toBe('history_fate');
  });
});

describe('Dream Phase 4A — route gate', () => {
  beforeEach(() => readingStageStore.clear());

  async function run(reply: DreamData, history?: DreamHistoryItem[]) {
    let calls = 0;
    const fetch: OpenAiFetch = async () => {
      calls++;
      return jsonResponse({ choices: [{ message: { content: JSON.stringify(reply) } }] });
    };
    const app = await testApp(testConfig(), fetch);
    const res = await app.inject({ method: 'POST', url: '/v1/ai/complete', headers: authHeader(), payload: body({ ...base, history }) });
    await app.close();
    return { json: res.json(), calls };
  }

  it('grounded history reply passes; false recurrence fails with one provider call', async () => {
    expect((await run(en('The red door has appeared in your earlier dreams too.'), [door])).json.success).toBe(true);
    const unsupported = await run(en('The red door is a recurring image from your previous dreams.'));
    expect(unsupported.json).toEqual({ success: false, error: { code: 'invalid_response' } });
    expect(unsupported.calls).toBe(1);
    const absolute = await run(en('The red door always returns in your dreams.'), [door]);
    expect(absolute.json.error.code).toBe('invalid_response');
    expect(absolute.calls).toBe(1);
  });
});
