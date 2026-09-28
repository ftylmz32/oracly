// Dream Phase 4C.1 — every live 4C gate false positive reproduced from the
// frozen artifact (read-only) and judged by the corrected gates. The
// frozen verdict is asserted first, so each case is anchored to evidence.
import { describe, expect, it } from 'vitest';
import { acceptDreamData } from '../src/ai/dream-acceptance.js';
import { contradictsEmotion, honoursStatedEmotion } from '../src/ai/dream-emotion-contract.js';
import { dreamHistoryClaimViolation } from '../src/ai/dream-history-quality.js';
import { isPlotRecap } from '../src/ai/dream-narrative-anchors.js';
import { unsupportedPersonalDomain } from '../src/ai/dream-personal-facts.js';
import { groundDreamSymbols, leakedSymbol } from '../src/ai/dream-symbol-grounding.js';
import { feelingsOf, frozen, frozenInput, proseOf } from './dream-phase4c1-support.js';

const dreamEvidence = (id: string) => {
  const i = frozenInput(frozen(id));
  return [i.narrative, ...i.symbols, ...i.emotions, i.memorySummary ?? ''].join(' ');
};

describe('4C.1 finding 1 — Phase 4A appositive / relative history claims', () => {
  it.each(['en-history', 'en-history#r2', 'tr-history#r2', 'ru-history#r2'])('%s: truthful claim unit passes', (id) => {
    const r = frozen(id);
    expect(r.stages.phase4A).toBe('history_unsupported');
    const i = frozenInput(r);
    expect(dreamHistoryClaimViolation(r.stages.parsed, { narrative: i.narrative, history: i.history, language: i.language })).toBeNull();
  });
});

describe('4C.1 finding 2 — TR / RU negated emotion', () => {
  it.each(['tr-negated-fear', 'ru-negated-fear', 'ru-negated-fear#r2'])('%s: no contradiction in any section', (id) => {
    const r = frozen(id);
    expect(r.stages.phase4B).toBe('emotion_contradiction');
    for (const section of [r.stages.parsed.summary, r.stages.parsed.emotionalTheme]) {
      expect(contradictsEmotion(feelingsOf(r), section), section).toBe(false);
    }
  });
});

describe('4C.1 findings 3–4 — personal domains', () => {
  it('familiar is never family (en-history, en-history#r2)', () => {
    expect(frozen('en-history').stages.diagnostic.phase4B).toBe('unsupported_personal_fact');
    for (const id of ['en-history', 'en-history#r2']) {
      expect(unsupportedPersonalDomain(proseOf(frozen(id).stages.parsed), dreamEvidence(id)), id).toBeNull();
    }
  });

  it.each(['ru-domain-family', 'en-mixed-emotion', 'en-mixed-emotion#r2', 'tr-mixed-emotion'])(
    '%s: told family / friend / childhood supports the reference',
    (id) => {
      expect(unsupportedPersonalDomain(proseOf(frozen(id).stages.parsed), dreamEvidence(id))).toBeNull();
    },
  );
});

describe('4C.1 finding 5 — compressed summary is not a recap', () => {
  it('en-mixed-emotion summary passes the recap detector', () => {
    const r = frozen('en-mixed-emotion');
    expect(r.stages.phase4B).toBe('plot_recap');
    expect(isPlotRecap(frozenInput(r).narrative, r.stages.parsed.summary)).toBe(false);
  });
});

describe('4C.1 finding 6 — provider symbol arrays are filtered, not fatal', () => {
  const expected: Record<string, [kept: string[], removed: string[]]> = {
    'tr-domain-work': [['toplantı odası', 'slaytlar'], ['sessizlik']],
    'en-negated-fear': [['lake', 'ripples', 'pale light'], ['darkness']],
    'en-negated-fear#r2': [['lake', 'something large', 'ripples', 'pale light'], ['darkness']],
    'en-mixed-emotion#r2': [['train station', 'old friend', 'train', 'laughing'], ['crying']],
    'ru-no-domain': [['платформа', 'поезд', 'часы'], ['пустота']],
    'ru-no-domain#r2': [['платформа', 'поезд', 'часы'], ['пустота']],
    'ru-memory': [['туман', 'освещённая дорога', 'тёмная дорога'], ['перекрёсток']],
  };
  it.each(Object.keys(expected))('%s: strict-label item removed, no prose leak, never invented_symbol', (id) => {
    const r = frozen(id);
    expect(r.stages.phase2).toBe('invented_symbol');
    const input = frozenInput(r);
    const grounded = groundDreamSymbols(r.stages.parsed, input);
    expect([grounded.data.symbols, grounded.removed]).toEqual(expected[id]);
    expect(leakedSymbol(grounded.removed, grounded.data, input)).toBeNull();
    expect(acceptDreamData(r.stages.parsed, input).failure).not.toBe('invented_symbol');
  });
});

describe('4C.1 emotional theme role grounding on live text', () => {
  it('en-mixed-emotion theme honours relief / happiness / heaviness', () => {
    const r = frozen('en-mixed-emotion');
    expect(honoursStatedEmotion(feelingsOf(r), r.stages.parsed.emotionalTheme)).toBe(true);
  });

  it('en-negated-fear theme invents curiosity and calm — still ungrounded', () => {
    const r = frozen('en-negated-fear');
    expect(honoursStatedEmotion(feelingsOf(r), r.stages.parsed.emotionalTheme)).toBe(false);
    expect(acceptDreamData(r.stages.parsed, frozenInput(r)).failure).toBe('ungrounded_section');
  });
});
