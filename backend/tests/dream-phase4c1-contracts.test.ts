// Dream Phase 4C.1 — permanent contracts: the corrected gates accept only
// the truthful constructions and keep every strict negative.
import { describe, expect, it } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { acceptDreamData } from '../src/ai/dream-acceptance.js';
import { contradictsEmotion, honoursStatedEmotion } from '../src/ai/dream-emotion-contract.js';
import type { DreamHistoryItem } from '../src/ai/dream-history.js';
import { dreamHistoryClaimViolation } from '../src/ai/dream-history-quality.js';
import { isPlotRecap } from '../src/ai/dream-narrative-anchors.js';
import { unsupportedPersonalDomain } from '../src/ai/dream-personal-facts.js';
import type { DreamData } from '../src/ai/parse-provider.js';
import { enGood, enNarrative } from './dream-phase2-fixtures.js';

const BLANK: DreamData = { summary: 'x', symbols: [], emotionalTheme: 'x', interpretation: 'x', dailyLifeReflection: 'x', conclusion: 'x' };
const item = (kind: DreamHistoryItem['kind'], key: string, label: string): DreamHistoryItem =>
  ({ kind, key, label, level: 'recurring', priorCount: 2 });
const SEA = item('symbol', 'symbol:sea', 'sea');
const history = (language: AppLanguage, narrative: string, h: DreamHistoryItem, text: string) =>
  dreamHistoryClaimViolation({ ...BLANK, interpretation: text }, { narrative, history: [h], language });
const seaDream = 'I was walking by the sea at dusk.';

describe('4C.1 §1 — history claim unit', () => {
  it.each([
    ['en', seaDream, SEA, 'The sea, a recurring symbol in your dreams, might represent a familiar space of reflection.'],
    ['en', seaDream, SEA, 'The sea, a recurring element in your dreams, suggests a familiar source of calm and reflection.'],
    ['en', seaDream, SEA, 'The sea — a recurring element in your dreams — suggests calm.'],
    ['en', seaDream, SEA, 'The sea (recurring in your dreams) suggests calm.'],
    ['tr', 'Denizin kıyısındaydım.', item('symbol', 'symbol:sea', 'Deniz'), 'Denizin tekrarlayan bir motif olması, belki de bu huzurun ve dinginliğin hayatında önemli bir yere sahip olduğunu ya da sık sık arandığını gösteriyor.'],
    ['ru', 'Я гуляла по саду.', item('emotion', 'emotion:peaceful', 'спокойный'), 'Спокойствие, которое повторяется в снах, может свидетельствовать о потребности в стабильности или отдыхе.'],
  ] as const)('%s truthful: %s', (lang, narrative, h, text) => {
    expect(history(lang, narrative, h, text)).toBeNull();
  });

  it.each([
    ['en', seaDream, SEA, 'The red sea, a recurring symbol in your dreams, might represent calm.'],
    ['en', seaDream, SEA, 'The stormy sea has appeared in previous dreams.'],
    ['en', seaDream, SEA, 'The sea keeps coming back, red and heavy.'],
    ['tr', 'Kapıda bekledim.', item('symbol', 'symbol:door', 'Kapı'), 'Kapıda beklemek önceki rüyalarında da vardı, bu bugün bir eşiği düşündürebilir.'],
    ['tr', 'Denizin kıyısındaydım.', item('symbol', 'symbol:sea', 'Deniz'), 'Denizin sesi önceki rüyalarında da vardı, bu bugün sakinliği çağrıştırabilir.'],
    ['tr', 'Denizin kıyısındaydım.', item('symbol', 'symbol:sea', 'Deniz'), 'Kırmızı deniz sık sık karşına çıkıyor.'],
    ['ru', 'Я смотрела в окно.', item('symbol', 'symbol:window', 'окно'), 'Свет в окне уже встречался в прошлых снах, и сегодня это может что-то значить.'],
    ['ru', 'Я гуляла по саду.', item('emotion', 'emotion:peaceful', 'спокойный'), 'Неспокойствие, которое повторяется в снах, может говорить о многом.'],
  ] as const)('%s attribute stays unsupported: %s', (lang, narrative, h, text) => {
    expect(history(lang, narrative, h, text)).toBe('history_unsupported');
  });

  it('keeps the global count / date / fate / absolute safeguards', () => {
    expect(history('en', seaDream, SEA, 'The sea, a recurring symbol in 5 earlier dreams, returns.')).toBe('history_count');
    expect(history('en', seaDream, SEA, 'The sea, recurring in your dreams, is your destiny.')).toBe('history_fate');
    expect(history('en', seaDream, SEA, 'The sea, a recurring symbol, always returns in your dreams.')).toBe('history_absolute');
    expect(history('en', seaDream, SEA, 'The sea, a recurring symbol, first appeared on 12 March.')).toBe('history_date');
  });
});

describe('4C.1 §2 — emotion negation and contrast, per section', () => {
  it.each([
    ['Ama hiç korkmadım.', 'Merak ve sakinlik duygusu ön plandaydı; korku hissedilmiyordu.'],
    ['Ama hiç korkmadım.', 'Merak vardı, korku hissedilmedi.'],
    ['Ama hiç korkmadım.', 'Merak vardı; korku hissi yoktu.'],
    ['Ama hiç korkmadım.', 'Merak vardı, korku yoktu.'],
    ['Мне совсем не было страшно.', 'Любопытство и отсутствие страха.'],
    ['Мне совсем не было страшно.', 'Любопытство, нет страха.'],
    ['Мне совсем не было страшно.', 'Любопытство, страха не было.'],
    ['Мне совсем не было страшно.', 'Любопытство преобладает над страхом, открытие чего-то нового.'],
  ])('negated told "%s" honoured by "%s"', (told, claim) => {
    expect(contradictsEmotion(told, claim)).toBe(false);
  });

  it.each([
    ['Korkmadım.', 'Yoğun korku vardı.'],
    ['Мне не было страшно.', 'Страх был сильным.'],
    ['I was not afraid.', 'Fear dominated the dream.'],
  ])('true contradiction "%s" vs "%s"', (told, claim) => {
    expect(contradictsEmotion(told, claim)).toBe(true);
  });
});

describe('4C.1 §3 — personal domains', () => {
  const friend = 'I was at a train station saying goodbye to an old friend.';
  it('familiar never becomes family; family words still do', () => {
    expect(unsupportedPersonalDomain(['The sea feels like a familiar source of calm for you.'], seaDream)).toBeNull();
    expect(unsupportedPersonalDomain(['Your family may be waiting.'], seaDream)).toBe('family');
    expect(unsupportedPersonalDomain(['Your familial ties may echo here.'], seaDream)).toBe('family');
  });

  it('family evidence supports family relationships', () => {
    const told = 'Мы всей семьёй сидим за столом, с сестрой давно не разговаривали.';
    expect(unsupportedPersonalDomain(['Это может отражать дистанцию в ваших семейных отношениях.'], told)).toBeNull();
    expect(unsupportedPersonalDomain(['Это может отражать дистанцию в ваших семейных отношениях.'], seaDream)).toBe('family');
  });

  it('a friend supports social relationships, never a romantic claim', () => {
    expect(unsupportedPersonalDomain(['Consider the emotions you tie to past relationships.'], friend)).toBeNull();
    expect(unsupportedPersonalDomain(['Your romantic relationship is changing.'], friend)).toBe('relationship');
    expect(unsupportedPersonalDomain(['Your partner may feel distant.'], friend)).toBe('relationship');
    expect(unsupportedPersonalDomain(['Your relationship is entering a new phase.'], seaDream)).toBe('relationship');
    expect(unsupportedPersonalDomain(['Consider your past relationships.'], seaDream)).toBe('social');
  });
});

describe('4C.1 §4 — plot recap', () => {
  const told = "I was at a train station saying goodbye to an old friend I haven't seen in years. I felt relieved and happy to see her, but also heavy, as if I already knew the train would leave without me. We were laughing while I cried.";
  it('compressed line passes; lifted sentence and scene retelling fail', () => {
    expect(isPlotRecap(told, 'A bittersweet farewell at a train station with an old friend.')).toBe(false);
    expect(isPlotRecap(told, 'You were at a train station saying goodbye to an old friend you had not seen in years.')).toBe(true);
    expect(isPlotRecap(told, 'You stood at a train station, said goodbye to an old friend, felt relieved and happy, and laughed while you cried.')).toBe(true);
  });
});

describe('4C.1 §5 — symbol filtering', () => {
  const input = { narrative: enNarrative, symbols: [], emotions: [], language: 'en' as const };
  it('an invented provider symbol is removed; the same image in prose rejects', () => {
    const kept = acceptDreamData({ ...enGood, symbols: [...enGood.symbols, 'snake'] }, input);
    expect(kept.failure).toBeNull();
    expect(kept.data?.symbols).toEqual(enGood.symbols);
    const leak = { ...enGood, symbols: ['snake'], interpretation: `${enGood.interpretation} A snake coils by the door.` };
    expect(acceptDreamData(leak, input).failure).not.toBeNull();
    const owl = { ...enGood, symbols: ['owl'], interpretation: `${enGood.interpretation} An owl watches from the sand.` };
    expect(acceptDreamData(owl, input).failure).toBe('invented_symbol');
  });
});

describe('4C.1 §6 — emotional theme role grounding and morphology', () => {
  it.each([
    ['I felt relieved, happy and heavy.', 'A mix of relief, happiness and heaviness.'],
    ['Everything was calm.', 'Calmness and tranquility.'],
    ['I felt happy.', 'A quiet happiness.'],
    ['I was relieved.', 'Relief after the long wait.'],
    ['My legs felt heavy.', 'A heaviness that does not leave.'],
    ['I stayed calm.', 'A deep calmness.'],
  ])('"%s" grounds "%s"', (told, theme) => {
    expect(honoursStatedEmotion(told, theme)).toBe(true);
  });

  it('an unstated feeling never grounds the theme', () => {
    expect(honoursStatedEmotion('A red balloon in an empty room.', 'Isolation and hope.')).toBe(false);
    expect(honoursStatedEmotion('I was not afraid.', 'Fear everywhere.')).toBe(false);
  });
});
