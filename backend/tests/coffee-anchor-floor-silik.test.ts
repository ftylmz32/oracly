/**
 * Story-first closure — real targeted16 (gpt-5.6-sol, low):
 *   1. context_sequence false positive: "silik" matched inside "karşılık";
 *   2. sparse abstract_reading false positive: a DOTS reading anchored on its
 *      own cited clean band / dots counted as "floating" (no semantic sign) —
 *      fixed evidence-aware, WITHOUT making context a semantic sign;
 *   3. normal floors: overall 30 -> 28, lead 50 -> 48 (calibrated on all 119
 *      saved non-sparse stages; takeaway 10 unchanged).
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { coffeeContextSequence, coffeeVoiceProfile } from '../src/ai/human-quality.js';
import { coffeeContextEventPromotion, coffeeSparseContextAnchored } from '../src/ai/reading/coffee-diversity.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { palmWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Stage = { kind: string; quality: string | null; narrative: CoffeeNarrative };
type Case = { label: string; evidence: ReadingEvidenceItem[]; stages: Stage[] };
const t16 = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_qa_targeted16.json', 'utf8'),
) as { cases: Record<string, Case> };
const BIRD = t16.cases.case2;
const HANDLE = t16.cases.case5;
const DOTS = t16.cases.case9;
const LOW = t16.cases.case10;

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const meaning = (n: CoffeeNarrative) => [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
const empty = { text: '', evidenceIds: [] as string[] };

describe('1/2. the "silik" context token is word-bounded', () => {
  it('"karşılık" no longer triggers it', () => {
    expect(coffeeContextSequence(['Haber sana ulaştıktan sonra hayatında daha geniş bir karşılık bulacak.'])).toBeNull();
  });

  it('real "silik izler" still does', () => {
    expect(coffeeContextSequence(['Silik izler peş peşe yeni ayrıntılar getirecek.'])).not.toBeNull();
  });

  it('the saved targeted16 BIRD repair no longer fails context_sequence', () => {
    const repair = BIRD.stages[1].narrative;
    expect(BIRD.stages[1].quality).toBe('context_sequence');
    expect(coffeeContextSequence(meaning(repair))).toBeNull();
  });
});

describe('5. normal floors (overall 28, lead 48)', () => {
  it('3. the targeted16 BIRD writer (overall 28, lead 49) passes first pass', () => {
    const writer = BIRD.stages[0].narrative;
    expect(BIRD.stages[0].quality).toBe('too_short');
    expect(writer.overall.text.split(/\s+/).length).toBe(28);
    expect(coffeeQualityFailure(writer, 'tr', undefined, BIRD.evidence)).toBeNull();
    expect(bindCoffeeNarrative(writer, observation(BIRD.evidence), 'tr')).toBeNull();
  });

  it('4. trivial short non-sparse prose still fails', () => {
    const n: CoffeeNarrative = {
      visualObservation: { text: 'Ağza yakın küçük bir kuş var.', evidenceIds: ['e1'] },
      overall: { text: 'Kuş sana güzel bir haber getiriyor, her şey yoluna girecek.', evidenceIds: ['e1'] },
      love: empty,
      career: empty,
      money: empty,
      nearFuture: empty,
      takeaway: { text: 'Haber yakında gelecek ve seni sevindirecek.', evidenceIds: ['e1'] },
    };
    expect(coffeeQualityFailure(n, 'tr', undefined, BIRD.evidence)).toBe('too_short');
  });
});

describe('sparse context-anchored grounding (DOTS) — context, not a semantic sign', () => {
  it('5. DOTS repair anchored on its cited clean band / dots does not fail abstract_reading', () => {
    const repair = DOTS.stages[1].narrative;
    expect(DOTS.stages[1].quality).toBe('abstract_reading');
    const p = coffeeVoiceProfile(meaning(repair));
    expect(p.signKinds).toBe(0); // still not a semantic sign
    expect(p.lifeKinds).toBe(0);
    expect(coffeeSparseContextAnchored([repair.overall, repair.takeaway], DOTS.evidence)).toBe(true);
    expect(coffeeQualityFailure(repair, 'tr', undefined, DOTS.evidence)).toBeNull();
  });

  it('6. sparse floating mood prose with no evidence anchor still fails', () => {
    const n: CoffeeNarrative = {
      visualObservation: DOTS.stages[1].narrative.visualObservation,
      overall: { text: 'Şu sıralar hafif bir hava var. Her şey daha ferah olacak ve önünde güzel, sakin bir dönem açılacak; içinde de hafif bir rahatlık hissedeceksin.', evidenceIds: ['e1'] },
      love: empty,
      career: empty,
      money: empty,
      nearFuture: empty,
      takeaway: { text: 'Yakında içini ferahlatan sakin bir hava daha da belirginleşecek gibi.', evidenceIds: ['e1'] },
    };
    expect(coffeeSparseContextAnchored([n.overall, n.takeaway], DOTS.evidence)).toBe(false);
    expect(coffeeQualityFailure(n, 'tr', undefined, DOTS.evidence)).toBe('abstract_reading');
  });

  it('a sign cup never gets the context exemption', () => {
    expect(coffeeSparseContextAnchored([BIRD.stages[0].narrative.overall], BIRD.evidence)).toBe(false);
  });

  it('7. DOTS event / category promotion still fails context_event', () => {
    expect(coffeeQualityFailure(DOTS.stages[0].narrative, 'tr', undefined, DOTS.evidence)).toBe('context_event');
    expect(coffeeContextEventPromotion([DOTS.stages[0].narrative.overall], DOTS.evidence)).toContain('işlerin');
  });
});

describe('controls', () => {
  it('8. HANDLE sparse grounding still passes (targeted16)', () => {
    expect(bindCoffeeNarrative(HANDLE.stages[0].narrative, observation(HANDLE.evidence), 'tr')).toBeNull();
  });

  it('9. LOW-SYMBOL connection-only output still passes (targeted16)', () => {
    expect(bindCoffeeNarrative(LOW.stages[0].narrative, observation(LOW.evidence), 'tr')).toBeNull();
  });

  it('10. Palm untouched', () => {
    for (const text of [palmWriterSystem('tr'), repairWriterSystem('palm')]) {
      expect(text).not.toContain('NARRATIVELY SPARSE');
      expect(text).not.toContain('LOW-CAPACITY EVIDENCE');
    }
  });
});
