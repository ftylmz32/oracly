// Dream Phase 4C.2a — live gate calibration: each false positive found in
// the immutable 4C.2 outputs is closed, and every strict negative stays.
import { describe, expect, it } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { contradictsEmotion, emotionStances } from '../src/ai/dream-emotion-contract.js';
import type { DreamHistoryItem } from '../src/ai/dream-history.js';
import { dreamHistoryClaimViolation } from '../src/ai/dream-history-quality.js';
import { lightFold, sameStrict } from '../src/ai/dream-lexical.js';
import { unsupportedPersonalDomain } from '../src/ai/dream-personal-facts.js';
import type { DreamData } from '../src/ai/parse-provider.js';

const stance = (text: string, emotion: string) => emotionStances(text).get(emotion as 'fear');
const NEGATED = { affirmed: false, negated: true };
const AFFIRMED = { affirmed: true, negated: false };

describe('4C.2a §1 — TR korkutmuyor family', () => {
  it('the required pair', () => {
    expect(contradictsEmotion('Korkmadım.', 'Bu ses beni korkutmuyor.')).toBe(false);
    expect(contradictsEmotion('Korkmadım.', 'Bu ses beni korkutuyor.')).toBe(true);
  });
  it.each(['korkutmuyor', 'korkutmadı', 'korkutmaz', 'korkutmayan', 'korkutmamış', 'korkutmayacak'])('%s denies fear', (w) => {
    expect(stance(`Ses seni ${w}.`, 'fear')).toEqual(NEGATED);
  });
  it.each(['korkutuyor', 'korkuttu', 'korkutucu', 'korkutmaya başladı', 'korkutmuş'])('%s still affirms fear', (w) => {
    expect(stance(`Ses seni ${w}.`, 'fear')).toEqual(AFFIRMED);
  });
  it('an explicit negative turn: "korkuya dönüşmediğini"', () => {
    expect(stance('Merakın korkuya dönüşmediğini görüyorsun.', 'fear')).toEqual(NEGATED);
    expect(stance('Merakın korkuya dönüştüğünü görüyorsun.', 'fear')).toEqual(AFFIRMED);
  });
});

describe('4C.2a §2 — RU "не вызывает … испуга", bounded', () => {
  it.each([
    'Этот звук не вызывает у тебя испуга.',
    'Капли не вызывали страха.',
    'Это не вызвало у меня никакого страха.',
  ])('negated: %s', (t) => expect(stance(t, 'fear')).toEqual(NEGATED));
  it.each([
    'Этот звук вызывает у тебя испуг.',
    'Он не вызывает сомнений, что страх уходит.',
    'Это не вызывает интереса у тебя и дальше растёт страх.',
  ])('affirmed: %s', (t) => expect(stance(t, 'fear')).toEqual(AFFIRMED));
});

describe('4C.2a §3 — EN `without` governs only its own feeling', () => {
  it('"without you feels heavy" affirms heaviness', () => {
    expect(stance('Walking on without you feels heavy.', 'heaviness')).toEqual(AFFIRMED);
  });
  it.each(['I went on without fear.', 'I waited without any anxiety.', 'I stood there without the slightest fear.'])('negated: %s', (t) => {
    const e = t.includes('anxiety') ? 'anxiety' : 'fear';
    expect(stance(t, e)).toEqual(NEGATED);
  });
});

const BLANK: DreamData = { summary: 'x', symbols: [], emotionalTheme: 'x', interpretation: 'x', dailyLifeReflection: 'x', conclusion: 'x' };
const item = (key: string, label: string): DreamHistoryItem => ({ kind: 'symbol', key, label, level: 'recurring', priorCount: 2 });
const SEA = item('symbol:sea', 'sea');
const DOOR = item('symbol:door', 'door');
const seaDream = 'I was walking by the sea at dusk. The waves were quiet and a small boat drifted away while I felt calm.';
const history = (text: string, h = SEA, narrative = seaDream, language: AppLanguage = 'en') =>
  dreamHistoryClaimViolation({ ...BLANK, interpretation: text }, { narrative, history: [h], language });

describe('4C.2a §4–5 — history claim scope', () => {
  it.each([
    'The sea has appeared before, though that alone does not establish a shared meaning.',
    'The recurring presence of the sea might reflect a consistent source of calm and contemplation in waking life, possibly serving as a reminder to find peace.',
    'The sea keeps returning and could suggest a familiar place to rest.',
  ])('commentary outside the claim: %s', (t) => expect(history(t)).toBeNull());

  it.each([
    ['The red sea has appeared before, though that alone does not establish a shared meaning.', SEA],
    ['The sea has appeared before, red and stormy.', SEA],
    ['The stormy sea, which has appeared before, might reflect calm.', SEA],
    ['The door keeps returning, red and heavy.', DOOR],
    ['The sea has appeared before, though this time it was calmer.', SEA],
    ['The recurring presence of the red sea might reflect calm.', SEA],
    ['The sea has appeared before, but it was red.', SEA],
  ] as const)('attribute stays unsupported: %s', (t, h) => {
    expect(history(t, h, h === DOOR ? 'I stood at a door in the dark.' : seaDream)).toBe('history_unsupported');
  });
});

describe('4C.2a §6 — RU mobile-vowel strict inflection', () => {
  const ru = (a: string, b: string) => sameStrict(lightFold(a), lightFold(b), 'ru');
  it.each([['перекрёсток', 'перекрёстке'], ['перекрёстке', 'перекрёсток'], ['перекрёсток', 'перекрёстку'], ['платок', 'платком'], ['замок', 'замке']])('%s ↔ %s', (a, b) => {
    expect(ru(a, b)).toBe(true);
  });
  it.each([['перекрёсток', 'перекрёстный'], ['цветок', 'цвета'], ['платок', 'плато'], ['потолок', 'потолочный'], ['дом', 'домик'], ['сок', 'ске']])('%s ≠ %s', (a, b) => {
    expect(ru(a, b)).toBe(false);
  });
});

describe('4C.2a §7 — TR "ilişkin" (regarding) is not a romantic domain', () => {
  const told = 'Rüyamda kalabalık bir salonda sunum yapıyordum.';
  it.each(['Sunuma ilişkin gerginliğin bu sahnede belirginleşiyor.', 'Anlatmaya ilişkin kaygın öne çıkıyor.'])('postposition: %s', (t) => {
    expect(unsupportedPersonalDomain([t], told)).toBeNull();
  });
  it.each([
    'Senin ilişkin değişiyor.',
    'İlişkini yeniden düşünüyorsun.',
    'İlişkin değişiyor.',
    'İlişkinde bir mesafe var.',
    'İlişkinizden uzaklaşıyorsunuz.',
    'Sevgilin seni bekliyor olabilir.',
    'Evliliğin bu sahnede yankılanıyor.',
  ])('real romantic domain still protected: %s', (t) => {
    expect(unsupportedPersonalDomain([t], told)).toBe('relationship');
  });
  it('romantic evidence still supports it', () => {
    expect(unsupportedPersonalDomain(['Senin ilişkin değişiyor.'], 'Rüyamda sevgilimle yürüyordum.')).toBeNull();
  });
});
