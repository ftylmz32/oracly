// Dream Phase 4C.1a — a provider symbol removed from the array is harmless in
// prose only when it is a safe derivation of a told word (complete suffix,
// minimum root), never because it shares an opening. Synthetic provider only.
import { describe, expect, it } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { acceptDreamData } from '../src/ai/dream-acceptance.js';
import { dreamHistoryClaimViolation } from '../src/ai/dream-history-quality.js';
import { evaluateDreamPremiumQuality } from '../src/ai/dream-premium-quality.js';
import { evaluateDreamQuality } from '../src/ai/dream-quality.js';
import { groundDreamSymbols, leakedSymbol } from '../src/ai/dream-symbol-grounding.js';
import type { DreamData } from '../src/ai/parse-provider.js';
import { serveDream } from './dream-phase4b-support.js';

const input = (narrative: string, language: AppLanguage = 'en') => ({ narrative, symbols: [], emotions: [], language });

const door: DreamData = {
  summary: 'A lone door standing open on an empty beach, asking to be noticed.',
  symbols: ['door', 'beach'],
  emotionalTheme: 'A quiet stillness settles around the door on the beach, open and unhurried.',
  interpretation:
    'The door on the beach frames the open shore: something built for passage stands where nothing needs to be entered, so the beach becomes a threshold rather than a place to cross.',
  dailyLifeReflection:
    'Today you might notice a moment that feels like that door on the beach, an opening that stands on its own without asking you to walk through it.',
  conclusion: 'What would you see if you stood beside that door on the beach?',
};
const doorway: DreamData = {
  ...door,
  symbols: ['doorway'],
  interpretation: door.interpretation.replace('The door on the beach', 'The doorway on the beach'),
};
const lake: DreamData = {
  summary: 'A still moment at the edge of a dark lake, held and unhurried.',
  symbols: ['darkness', 'lake'],
  emotionalTheme: 'A calm, watchful stillness gathers beside the dark lake.',
  interpretation:
    'The darkness beside the lake does not swallow the shore; standing at the edge turns the dark into something you can face, so the lake frames your own steadiness.',
  dailyLifeReflection:
    'Today you might carry the feeling of standing beside that dark lake, steady at the edge of something you cannot fully see.',
  conclusion: 'What did it feel like to stand at the edge of that dark lake?',
};
const DOOR = 'I saw a door on the beach.';
const LAKE = 'I stood beside a dark lake.';

type Pair = [told: string, symbol: string, prose: string, language: AppLanguage];

const safe: Pair[] = [
  [LAKE, 'darkness', 'The darkness beside the lake softens the shore.', 'en'],
  ['I cried at the station.', 'crying', 'The crying at the station softens the goodbye.', 'en'],
  ['Toplantı odasında sessizce bekledim.', 'sessizlik', 'Sessizlik toplantı odasını dolduruyordu.', 'tr'],
  ['Платформа была пустой.', 'пустота', 'Пустота платформы ощущалась тихо.', 'ru'],
];

const invented: Pair[] = [
  [DOOR, 'doorway', 'The doorway on the beach may frame the sense of distance.', 'en'],
  ['Water ran under the bridge.', 'waterfall', 'The waterfall under the bridge roars softly.', 'en'],
  ['Rain fell at night.', 'rainbow', 'The rainbow at night glows over the street.', 'en'],
  ['I felt fear in the hallway.', 'fearless', 'A fearless hallway opens ahead of you.', 'en'],
  ['Eski bir kapı gördüm.', 'kapıcı', 'Kapıcı eski kapının yanında duruyordu.', 'tr'],
  ['Denizde yüzdüm.', 'denizci', 'Denizci denizde bekliyordu.', 'tr'],
  ['На столе стояла лампа.', 'столица', 'Столица и лампа на столе рядом.', 'ru'],
  ['Красный шарф лежал на земле.', 'красота', 'Красота шарфа на земле.', 'ru'],
  ['Вода текла под мостом.', 'водопад', 'Водопад под мостом шумел.', 'ru'],
  ['Я увидела дверь в стене.', 'дворец', 'Дворец за стеной казался далёким.', 'ru'],
];

function leak([told, symbol, prose, language]: Pair) {
  const i = input(told, language);
  const grounded = groundDreamSymbols({ ...door, symbols: [symbol], interpretation: prose }, i);
  return { removed: grounded.removed, leaked: leakedSymbol(grounded.removed, grounded.data, i) };
}

describe('4C.1a — symbol prose leak gate (leakedSymbol itself)', () => {
  it.each(safe)('safe derivation: %s → %s is removed from the array but not a leak', (...pair) => {
    expect(leak(pair)).toEqual({ removed: [pair[1]], leaked: null });
  });

  it.each(invented)('same opening, different image: %s → %s leaks', (...pair) => {
    expect(leak(pair)).toEqual({ removed: [pair[1]], leaked: pair[1] });
  });

  it('the invented doorway is caught by the leak gate alone; every later gate would pass', () => {
    const i = input(DOOR);
    const { data, removed } = groundDreamSymbols(doorway, i);
    expect(leakedSymbol(removed, data, i)).toBe('doorway');
    expect(acceptDreamData(doorway, i)).toEqual({ data: null, failure: 'invented_symbol' });
    expect(evaluateDreamQuality(data, i)).toBeNull();
    expect(dreamHistoryClaimViolation(data, { narrative: DOOR, language: 'en' })).toBeNull();
    expect(evaluateDreamPremiumQuality(data, i)).toBeNull();
  });

  it('the symbol array stays strict: a safe derivation is still filtered out', () => {
    const accepted = acceptDreamData(lake, input(LAKE));
    expect(accepted.failure).toBeNull();
    expect(accepted.data?.symbols).toEqual(['lake']);
  });
});

describe('4C.1a — route red team (synthetic provider)', () => {
  it('invented doorway on a told door → invalid_response, one call', async () => {
    const { json, calls } = await serveDream(doorway, { narrative: DOOR, language: 'en' }, '4c1a-route-doorway-01');
    expect(calls).toBe(1);
    expect(json).toEqual({ success: false, error: { code: 'invalid_response' } });
  });

  it('control: the same reading with the told door → success, one call', async () => {
    const { json, calls } = await serveDream(door, { narrative: DOOR, language: 'en' }, '4c1a-route-door-01');
    expect(calls).toBe(1);
    expect(json.success).toBe(true);
  });

  it('control: darkness beside a told dark lake → success; darkness filtered from symbols', async () => {
    const { json, calls } = await serveDream(lake, { narrative: LAKE, language: 'en' }, '4c1a-route-lake-01');
    expect(calls).toBe(1);
    expect(json.success).toBe(true);
    expect(json.data.symbols).toEqual(['lake']);
    expect(json.data.interpretation).toContain('The darkness beside the lake');
  });
});
