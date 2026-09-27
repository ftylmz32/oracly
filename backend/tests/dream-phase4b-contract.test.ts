import { describe, expect, it } from 'vitest';
import { dreamAcceptanceFailure } from '../src/ai/dream-acceptance.js';
import { contradictsEmotion, emotionStances } from '../src/ai/dream-emotion-contract.js';
import {
  isRichNarrative,
  RECAP_MAX_SHARE,
  RICH_MIN_CLUSTERS,
  RICH_MIN_TOUCHED,
  RICH_MIN_WORDS,
} from '../src/ai/dream-narrative-anchors.js';
import { unsupportedPersonalDomain } from '../src/ai/dream-personal-facts.js';
import { isOpenQuestion, MAX_SYMBOLS, PREMIUM_MIN_CHARS } from '../src/ai/dream-premium-quality.js';
import { enGood, enNarrative, trGood } from './dream-phase2-fixtures.js';
import { acceptanceInput, golden } from './dream-phase4b-support.js';

const en = { narrative: enNarrative, symbols: [], emotions: [], language: 'en' as const };

describe('Dream Phase 4B — documented thresholds', () => {
  it('keeps the documented values', () => {
    expect([RICH_MIN_WORDS, RICH_MIN_CLUSTERS, RICH_MIN_TOUCHED]).toEqual([5, 3, 2]);
    expect([RECAP_MAX_SHARE, PREMIUM_MIN_CHARS, MAX_SYMBOLS]).toEqual([0.6, 24, 8]);
  });

  it('never treats a sparse dream as rich', () => {
    for (const s of ['I dreamed of a white horse standing still.', 'Rüyamda kapalı bir kapı gördüm.', 'Мне снился пустой вокзал.']) {
      expect(isRichNarrative(s)).toBe(false);
    }
  });
});

describe('Dream Phase 4B — emotion contract', () => {
  it.each([
    ['I felt calm, not afraid.', 'Calm curiosity, with fear absent.'],
    ['I felt calm, not afraid.', 'Fear is notably absent.'],
    ['I felt calm, not afraid.', 'Tiredness without fear, the walk stays calm.'],
    ['I was afraid of the dog.', 'Fear runs through the whole walk.'],
    ['Hiç korkmadım, sadece merak ettim.', 'Korkusuz bir merak ağır basıyor.'],
    ['Мне не было страшно, было спокойно.', 'Спокойствие без страха.'],
  ])('%s → %s is consistent', (told, claim) => {
    expect(contradictsEmotion(told, claim)).toBe(false);
  });

  it.each([
    ['I felt calm, not afraid.', 'A deep fear settles over the beach.'],
    ['I felt frustrated and a little sad.', 'No sadness at all, only a practical mood.'],
    ['Hiç korkmadım, sadece merak ettim.', 'Derin bir korku hakim.'],
    ['Biraz tedirgindim.', 'Hiç tedirgin değil.'],
    ['Мне не было страшно.', 'Глубокий страх над озером.'],
    ['Я чувствовала тревогу.', 'Без тревоги, всё легко.'],
  ])('%s → %s contradicts', (told, claim) => {
    expect(contradictsEmotion(told, claim)).toBe(true);
  });

  it('reads word-level and post-positive negation', () => {
    expect(emotionStances('fear was absent').get('fear')).toEqual({ affirmed: false, negated: true });
    expect(emotionStances('korku yok').get('fear')).toEqual({ affirmed: false, negated: true });
    expect(emotionStances('бесстрашно').get('fear')).toEqual({ affirmed: false, negated: true });
  });
});

describe('Dream Phase 4B — questions, symbols, personal facts, memory', () => {
  it.each(['What was behind the door?', 'Kapının ardında ne vardı?', 'Что было за дверью?', 'Hangi kıyıya bakardın?'])(
    '%s is an open question',
    (q) => expect(isOpenQuestion(q)).toBe(true),
  );

  it.each(['Are you ready to open it?', 'Do you think it will open?', 'Kapıyı açacak mısın?', 'Ты готова открыть окно?'])(
    '%s is a leading yes/no question',
    (q) => expect(isOpenQuestion(q)).toBe(false),
  );

  it('allows the one question only in the conclusion', () => {
    for (const field of ['summary', 'emotionalTheme', 'interpretation', 'dailyLifeReflection'] as const) {
      const data = { ...enGood, [field]: `${enGood[field]} Why the red door?` };
      expect(dreamAcceptanceFailure(data, en)).toBe('extra_question');
    }
  });

  it('dedupes symbols after normalization', () => {
    expect(dreamAcceptanceFailure({ ...enGood, symbols: ['Beach', ' beach '] }, en)).toBe('symbol_list');
  });

  it('allows a life domain only with narrative or memory support; symbols pass', () => {
    expect(unsupportedPersonalDomain(['Your job may feel heavy.'], 'a red door')).toBe('work');
    expect(unsupportedPersonalDomain(['Your job may feel heavy.'], 'I was at my job')).toBeNull();
    expect(unsupportedPersonalDomain(['The work of the tide is slow.'], 'a beach')).toBeNull();
    expect(unsupportedPersonalDomain(['A door may stand for a new chapter.'], 'a door')).toBeNull();
  });

  it('accepts a memory-only reflection only when the safe memory was sent', () => {
    const g = golden('en-partner-supported-memory');
    const data = { ...g.data, dailyLifeReflection: 'Your recent context mentioned making space for something new; one small space could be enough today.' };
    expect(dreamAcceptanceFailure(data, acceptanceInput(g))).toBeNull();
    expect(dreamAcceptanceFailure(data, { ...acceptanceInput(g), memorySummary: undefined })).toBe('generic_reflection');
  });

  it('keeps the failure order: Phase 2 wins over 4B', () => {
    const data = { ...trGood, summary: `${trGood.summary} Neden?` };
    expect(dreamAcceptanceFailure(data, en)).toBe('language_mismatch');
  });
});
