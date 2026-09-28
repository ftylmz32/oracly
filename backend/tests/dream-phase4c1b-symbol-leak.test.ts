// Dream Phase 4C.1b — the symbol prose-leak gate uses its own strict matcher
// (sameStrict or a safe-derivation root), never the general Phase 2 prose
// matcher `sameWord` and its shared six-letter lead. Synthetic provider only.
import { describe, expect, it } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { acceptDreamData } from '../src/ai/dream-acceptance.js';
import { dreamHistoryClaimViolation } from '../src/ai/dream-history-quality.js';
import { sameWord } from '../src/ai/dream-lexical.js';
import { evaluateDreamPremiumQuality } from '../src/ai/dream-premium-quality.js';
import { evaluateDreamQuality } from '../src/ai/dream-quality.js';
import { groundDreamSymbols, leakedSymbol } from '../src/ai/dream-symbol-grounding.js';
import type { DreamData } from '../src/ai/parse-provider.js';
import { serveDream } from './dream-phase4b-support.js';

const input = (narrative: string, language: AppLanguage = 'en') => ({ narrative, symbols: [], emotions: [], language });
const CANDLE = 'I saw a candle on the table.';

const candle: DreamData = {
  summary: 'A single candle resting on a table, small and steady in the room.',
  symbols: ['candle', 'table'],
  emotionalTheme: 'A quiet, attentive stillness gathers around the candle on the table.',
  interpretation:
    'The candle on the table gives the surface a centre: the table holds something small and steady, so the ordinary place becomes a point of attention rather than a background.',
  dailyLifeReflection:
    'Today you might notice something as small as that candle on the table, a steady detail that quietly gives an ordinary surface its centre.',
  conclusion: 'What would you notice if you sat down at that table beside the candle?',
};
const candlestick: DreamData = {
  ...candle,
  symbols: ['candlestick'],
  interpretation: `The candlestick beside the candle on the table gives the surface a centre: ${candle.interpretation.split(': ')[1]}`,
};

type Pair = [told: string, symbol: string, prose: string, language: AppLanguage];

const sixLetterLead: Pair[] = [
  [CANDLE, 'candlestick', 'The candlestick beside the candle glows softly.', 'en'],
  ['I waited at the station.', 'stationary', 'Everything stationary at the station felt calm.', 'en'],
  ['I looked through the window.', 'windowsill', 'The windowsill under the window held the light.', 'en'],
  ['I walked through the forest.', 'forestry', 'Forestry tools lay quietly in the forest.', 'en'],
  ['The season changed slowly.', 'seasonal', 'A seasonal wind moved through the season.', 'en'],
];
const earlierControls: Pair[] = [
  ['I saw a door on the beach.', 'doorway', 'The doorway on the beach may frame the distance.', 'en'],
  ['Water ran under the bridge.', 'waterfall', 'The waterfall under the bridge roars softly.', 'en'],
  ['Rain fell at night.', 'rainbow', 'The rainbow at night glows over the street.', 'en'],
  ['I felt fear in the hallway.', 'fearless', 'A fearless hallway opens ahead of you.', 'en'],
  ['Eski bir kapı gördüm.', 'kapıcı', 'Kapıcı eski kapının yanında duruyordu.', 'tr'],
  ['Denizde yüzdüm.', 'denizci', 'Denizci denizde bekliyordu.', 'tr'],
  ['На столе стояла лампа.', 'столица', 'Столица и лампа на столе рядом.', 'ru'],
  ['Красный шарф лежал на земле.', 'красота', 'Красота шарфа на земле.', 'ru'],
];
const safe: Pair[] = [
  ['I stood beside a dark lake.', 'darkness', 'The darkness beside the lake softens the shore.', 'en'],
  ['I cried at the station.', 'crying', 'The crying at the station softens the goodbye.', 'en'],
  ['Toplantı odasında sessizce bekledim.', 'sessizlik', 'Sessizlik toplantı odasını dolduruyordu.', 'tr'],
  ['Платформа была пустой.', 'пустота', 'Пустота платформы ощущалась тихо.', 'ru'],
];

function leak([told, symbol, prose, language]: Pair) {
  const i = input(told, language);
  const grounded = groundDreamSymbols({ ...candle, symbols: [symbol], interpretation: prose }, i);
  return { removed: grounded.removed, leaked: leakedSymbol(grounded.removed, grounded.data, i) };
}

describe('4C.1b — symbol prose leak gate is isolated from sameWord', () => {
  it.each(sixLetterLead)('six-letter lead is not the same image: %s → %s leaks', (...pair) => {
    expect(leak(pair)).toEqual({ removed: [pair[1]], leaked: pair[1] });
  });

  it.each(earlierControls)('4C.1a control still leaks: %s → %s', (...pair) => {
    expect(leak(pair)).toEqual({ removed: [pair[1]], leaked: pair[1] });
  });

  it.each(safe)('safe derivation still harmless: %s → %s', (...pair) => {
    expect(leak(pair)).toEqual({ removed: [pair[1]], leaked: null });
  });

  it('Phase 2 general grounding is unchanged: sameWord still relates six-letter leads', () => {
    expect(sameWord('seasonal', 'season', 'en')).toBe(true);
    expect(sameWord('candlestick', 'candle', 'en')).toBe(true);
    expect(sameWord('stationary', 'station', 'en')).toBe(true);
    expect(sameWord('windowsill', 'window', 'en')).toBe(true);
    expect(sameWord('forestry', 'forest', 'en')).toBe(true);
  });

  it('the invented candlestick is caught by the leak gate alone; every later gate would pass', () => {
    const i = input(CANDLE);
    const { data, removed } = groundDreamSymbols(candlestick, i);
    expect(leakedSymbol(removed, data, i)).toBe('candlestick');
    expect(acceptDreamData(candlestick, i)).toEqual({ data: null, failure: 'invented_symbol' });
    expect(evaluateDreamQuality(data, i)).toBeNull();
    expect(dreamHistoryClaimViolation(data, { narrative: CANDLE, language: 'en' })).toBeNull();
    expect(evaluateDreamPremiumQuality(data, i)).toBeNull();
  });
});

describe('4C.1b — route red team (synthetic provider)', () => {
  it('invented candlestick beside a told candle → invalid_response, one call', async () => {
    expect(candlestick.interpretation).toContain('The candlestick beside the candle');
    const { json, calls } = await serveDream(candlestick, { narrative: CANDLE, language: 'en' }, '4c1b-route-stick-01');
    expect(calls).toBe(1);
    expect(json).toEqual({ success: false, error: { code: 'invalid_response' } });
  });

  it('control: the same reading with only the told candle → success, one call', async () => {
    const { json, calls } = await serveDream(candle, { narrative: CANDLE, language: 'en' }, '4c1b-route-candle-01');
    expect(calls).toBe(1);
    expect(json.success).toBe(true);
  });
});
